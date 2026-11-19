// UI22 adaptada al esquema REAL resenas/citas/clientes/empleados/servicios.
// Solo lectura. No modifica tablas, no habilita POST/PATCH/DELETE ni cambia app Cliente.
const pool = require('../db');

const entero = (valor, min, max) => {
  if (typeof valor !== 'string' || !/^\d+$/.test(valor)) return null;
  const n = Number(valor);
  return Number.isSafeInteger(n) && n >= min && n <= max ? n : null;
};

const fechaValida = (valor) => {
  if (typeof valor !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(valor)) return false;
  const f = new Date(`${valor}T00:00:00Z`);
  return !Number.isNaN(f.getTime()) && f.toISOString().slice(0, 10) === valor;
};

function construirFiltros(query, { permiteTexto = false, permiteEstrellas = false } = {}) {
  const partes = [];
  const params = [];
  const agregar = (valor) => { params.push(valor); return `$${params.length}`; };

  if (query.desde !== undefined) {
    if (!fechaValida(query.desde)) throw new Error('Fecha desde no válida (YYYY-MM-DD)');
    partes.push(`r.fecha >= ${agregar(query.desde)}::date`);
  }
  if (query.hasta !== undefined) {
    if (!fechaValida(query.hasta)) throw new Error('Fecha hasta no válida (YYYY-MM-DD)');
    partes.push(`r.fecha <= ${agregar(query.hasta)}::date`);
  }
  if (query.desde && query.hasta && query.desde > query.hasta) {
    throw new Error('El intervalo de fechas es inválido');
  }
  for (const [key, column] of [
    ['id_servicio', 'c.id_servicio'], ['id_empleado', 'c.id_empleado']
  ]) {
    if (query[key] !== undefined) {
      const n = entero(query[key], 1, 2147483647);
      if (n === null) throw new Error(`Filtro ${key} no válido`);
      partes.push(`${column} = ${agregar(n)}`);
    }
  }
  if (permiteEstrellas && query.estrellas !== undefined) {
    const n = entero(query.estrellas, 1, 5);
    if (n === null) throw new Error('La calificación debe ser de 1 a 5');
    partes.push(`r.calificacion_ser = ${agregar(n)}`);
  }
  if (permiteTexto && query.buscar !== undefined) {
    if (typeof query.buscar !== 'string' || query.buscar.length > 100) {
      throw new Error('Búsqueda demasiado larga');
    }
    const texto = query.buscar.trim();
    if (texto) {
      // POSITION evita que %, _ u otros caracteres sean comodines.
      const p = agregar(texto);
      partes.push(`(POSITION(LOWER(${p}) IN LOWER(COALESCE(r.comentario, ''))) > 0
        OR POSITION(LOWER(${p}) IN LOWER(CONCAT_WS(' ', cl.nombre, cl.apellido_p, cl.apellido_m))) > 0)`);
    }
  }
  return { where: partes.length ? `WHERE ${partes.join(' AND ')}` : '', params };
}

const joins = `FROM resenas r
  INNER JOIN citas c ON c.id_cita = r.id_cita
  LEFT JOIN servicios s ON s.id_servicio = c.id_servicio
  LEFT JOIN empleados e ON e.id_empleado = c.id_empleado
  LEFT JOIN clientes cl ON cl.id_cliente = c.id_cliente`;

function formato(row) {
  return {
    id_resena: row.id_resena,
    id_cita: row.id_cita,
    fecha_creacion: row.fecha_creacion,
    cliente: row.cliente ?? null,
    servicio: { id_servicio: row.id_servicio, nombre: row.servicio_nombre },
    empleado: { id_empleado: row.id_empleado, nombre: row.empleado_nombre },
    estrellas_servicio: row.estrellas_servicio,
    estrellas_terapeuta: row.estrellas_terapeuta,
    comentario: row.comentario,
    aspectos_destacados: row.aspectos_destacados || [],
  };
}

const columnas = `r.id_resena, r.id_cita,
  TO_CHAR(r.fecha, 'YYYY-MM-DD') AS fecha_creacion,
  NULLIF(TRIM(CONCAT_WS(' ', cl.nombre, cl.apellido_p, cl.apellido_m)), '') AS cliente,
  c.id_servicio, s.nombre AS servicio_nombre,
  c.id_empleado,
  NULLIF(TRIM(CONCAT_WS(' ', e.nombre, e.apellido_p, e.apellido_m)), '') AS empleado_nombre,
  r.calificacion_ser AS estrellas_servicio,
  r.calificacion_emp AS estrellas_terapeuta,
  r.comentario,
  ARRAY[]::text[] AS aspectos_destacados`;

function errorBD(error, res) {
  if (error.code === '42P01' || error.code === '42703') {
    return res.status(503).json({ error: 'Reseñas aún no habilitadas en PostgreSQL' });
  }
  console.error('Error consultando reseñas:', error.message);
  return res.status(500).json({ error: 'No fue posible consultar las reseñas' });
}

async function listarResenas(req, res) {
  try {
    // Acepta SOLO los filtros especificados para evitar parámetros inesperados.
    const q = req.query || {};
    const admitidos = new Set(['desde','hasta','id_servicio','id_empleado','estrellas','buscar','pagina','limite']);
    if (Object.keys(q).some(k => !admitidos.has(k))) {
      return res.status(400).json({ error: 'Parámetros de consulta no admitidos' });
    }
    const pagina = q.pagina === undefined ? 1 : entero(q.pagina, 1, 10000);
    const limite = q.limite === undefined ? 20 : entero(q.limite, 1, 100);
    if (pagina === null || limite === null) {
      return res.status(400).json({ error: 'Paginación no válida' });
    }
    let filtro;
    try { filtro = construirFiltros(q, { permiteTexto: true, permiteEstrellas: true }); }
    catch (e) { return res.status(400).json({ error: e.message }); }

    const totalSQL = `SELECT COUNT(*)::int AS total ${joins} ${filtro.where}`;
    const totalRes = await pool.query(totalSQL, filtro.params);
    const total = totalRes.rows[0].total;
    const offset = (pagina - 1) * limite;
    const listaSQL = `SELECT ${columnas} ${joins} ${filtro.where}
      ORDER BY r.fecha DESC, r.id_resena DESC
      LIMIT $${filtro.params.length + 1} OFFSET $${filtro.params.length + 2}`;
    const listaRes = await pool.query(listaSQL, [...filtro.params, limite, offset]);
    return res.json({
      resenas: listaRes.rows.map(formato),
      paginacion: { pagina, limite, total, total_paginas: Math.max(1, Math.ceil(total / limite)) },
    });
  } catch (error) { return errorBD(error, res); }
}

async function resumenResenas(req, res) {
  try {
    const q = req.query || {};
    const admitidos = new Set(['desde','hasta','id_servicio','id_empleado']);
    if (Object.keys(q).some(k => !admitidos.has(k))) {
      return res.status(400).json({ error: 'Parámetros de resumen no admitidos' });
    }
    let filtro;
    try { filtro = construirFiltros(q); }
    catch (e) { return res.status(400).json({ error: e.message }); }
    const resumenSQL = `SELECT COUNT(*)::int AS total,
      ROUND(AVG(r.calificacion_ser)::numeric, 2) AS promedio_servicios,
      ROUND(AVG(r.calificacion_emp)::numeric, 2) AS promedio_terapeutas,
      COUNT(*) FILTER (WHERE r.calificacion_ser = 1)::int AS estrella_1,
      COUNT(*) FILTER (WHERE r.calificacion_ser = 2)::int AS estrella_2,
      COUNT(*) FILTER (WHERE r.calificacion_ser = 3)::int AS estrella_3,
      COUNT(*) FILTER (WHERE r.calificacion_ser = 4)::int AS estrella_4,
      COUNT(*) FILTER (WHERE r.calificacion_ser = 5)::int AS estrella_5
      ${joins} ${filtro.where}`;
    const { rows } = await pool.query(resumenSQL, filtro.params);
    const r = rows[0];
    return res.json({
      total: r.total,
      promedio_servicios: r.promedio_servicios === null ? null : Number(r.promedio_servicios),
      promedio_terapeutas: r.promedio_terapeutas === null ? null : Number(r.promedio_terapeutas),
      distribucion_servicios: {
        '1': r.estrella_1, '2': r.estrella_2, '3': r.estrella_3,
        '4': r.estrella_4, '5': r.estrella_5,
      },
    });
  } catch (error) { return errorBD(error, res); }
}

async function detalleResena(req, res) {
  const id = entero(req.params.id, 1, 2147483647);
  if (id === null) return res.status(400).json({ error: 'Identificador no válido' });
  try {
    const resultado = await pool.query(`SELECT ${columnas} ${joins} WHERE r.id_resena = $1`, [id]);
    if (!resultado.rowCount) return res.status(404).json({ error: 'Reseña no encontrada' });
    return res.json(formato(resultado.rows[0]));
  } catch (error) { return errorBD(error, res); }
}

module.exports = { listarResenas, resumenResenas, detalleResena };
