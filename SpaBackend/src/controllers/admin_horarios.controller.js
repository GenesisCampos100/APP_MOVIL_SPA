const pool = require('../db');

/**
 * Agenda semanal del personal. Los días se guardan con los nombres exactos que
 * utiliza actualmente el registro de citas de Aura SPA.
 */
const DIAS = Object.freeze([
  'Domingo', 'Lunes', 'Martes', 'Miercoles',
  'Jueves', 'Viernes', 'Sabado',
]);

const normalizarDia = (valor) => {
  if (typeof valor !== 'string') return null;
  const limpio = valor.trim().normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
  return DIAS.find((dia) => dia.toLowerCase() === limpio) || null;
};

const minutos = (valor) => {
  if (typeof valor !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d(?::[0-5]\d)?$/.test(valor)) {
    return null;
  }
  const [hora, minuto, segundo = '0'] = valor.split(':').map(Number);
  return hora * 60 + minuto + segundo / 60;
};

const enteroPositivo = (valor) => {
  const numero = Number(valor);
  return Number.isSafeInteger(numero) && numero > 0 ? numero : null;
};

const validarHorario = (body) => {
  const dia = normalizarDia(body?.dia_semana);
  const inicio = minutos(body?.hora_inicio);
  const fin = minutos(body?.hora_fin);
  if (!dia || inicio === null || fin === null) {
    return { error: 'Selecciona un día y horas válidas.' };
  }
  if (inicio >= fin) {
    return { error: 'La hora de salida debe ser posterior a la de entrada.' };
  }
  return {
    dia_semana: dia,
    hora_inicio: body.hora_inicio,
    hora_fin: body.hora_fin,
    inicio,
    fin,
  };
};

const listarHorariosAdmin = async (_req, res) => {
  try {
    const resultado = await pool.query(`
      SELECT e.id_empleado, e.nombre, e.apellido_p, e.apellido_m,
             p.nombre AS puesto, u.estado AS activo,
             h.id_horario, h.dia_semana, h.hora_inicio, h.hora_fin
      FROM empleados e
      INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
      LEFT JOIN puestos p ON p.id_puesto = e.id_puesto
      LEFT JOIN horarios h ON h.id_empleado = e.id_empleado
      WHERE u.id_rol = $1
      ORDER BY e.nombre, e.apellido_p, e.id_empleado, h.dia_semana, h.hora_inicio
    `, [2]);

    const mapa = new Map();
    for (const fila of resultado.rows) {
      if (!mapa.has(fila.id_empleado)) {
        mapa.set(fila.id_empleado, {
          id_empleado: fila.id_empleado,
          nombre: [fila.nombre, fila.apellido_p, fila.apellido_m]
            .filter(Boolean).join(' '),
          puesto: fila.puesto || 'Sin puesto asignado',
          activo: fila.activo === true,
          horarios: [],
        });
      }
      if (fila.id_horario != null) {
        mapa.get(fila.id_empleado).horarios.push({
          id_horario: fila.id_horario,
          dia_semana: fila.dia_semana,
          hora_inicio: fila.hora_inicio,
          hora_fin: fila.hora_fin,
        });
      }
    }
    return res.json(Array.from(mapa.values()));
  } catch (error) {
    console.error('Error al consultar horarios:', error.message);
    return res.status(500).json({ error: 'No fue posible consultar los horarios.' });
  }
};

const bloquearEmpleado = async (client, idEmpleado, { exigirActivo = false } = {}) => {
  const resultado = await client.query(`
    SELECT e.id_empleado, u.estado
    FROM empleados e
    JOIN usuarios u ON u.id_usuario = e.id_usuario
    WHERE e.id_empleado = $1 AND u.id_rol = 2
    FOR UPDATE OF e
  `, [idEmpleado]);
  if (!resultado.rowCount) return { error: 'No se encontró el empleado.', status: 404 };
  if (exigirActivo && resultado.rows[0].estado !== true) {
    return { error: 'Activa al empleado antes de asignarle un horario.', status: 409 };
  }
  return null;
};

const hayCruce = async (client, { idEmpleado, horario, excluirId = null }) => {
  const resultado = await client.query(`
    SELECT 1 FROM horarios
    WHERE id_empleado = $1 AND dia_semana = $2
      AND hora_inicio < $4::time AND hora_fin > $3::time
      AND ($5::integer IS NULL OR id_horario <> $5::integer)
    LIMIT 1
  `, [idEmpleado, horario.dia_semana, horario.hora_inicio, horario.hora_fin, excluirId]);
  return resultado.rowCount > 0;
};

/**
 * Antes de acortar/eliminar un turno, comprueba que todas las citas futuras
 * de ese día permanezcan completamente cubiertas por alguno de los turnos.
 * No toca las citas ni cambia su estado.
 */
const dejaCitasSinCobertura = async (client, idEmpleado, diaAfectado, excluirId) => {
  const [turnos, citas] = await Promise.all([
    client.query(`
      SELECT dia_semana, hora_inicio::text AS hora_inicio, hora_fin::text AS hora_fin
      FROM horarios WHERE id_empleado = $1 AND id_horario <> $2
    `, [idEmpleado, excluirId]),
    client.query(`
      SELECT fecha::text AS fecha, hora_inicio::text AS hora_inicio,
             duracion_aplicada
      FROM citas
      WHERE id_empleado = $1 AND fecha >= CURRENT_DATE
        AND LOWER(COALESCE(estado::text, '')) NOT IN
          ('cancelada', 'cancelado', 'completada', 'completado',
           'inasistencia', 'no asistio', 'no asistió')
    `, [idEmpleado]),
  ]);
  const dia = normalizarDia(diaAfectado);
  const disponibles = turnos.rows.filter((h) => normalizarDia(h.dia_semana) === dia);
  return citas.rows.some((cita) => {
    // Fecha YYYY-MM-DD obtenida con ::text, sin conversiones de zona horaria.
    const diaCita = DIAS[new Date(`${cita.fecha}T12:00:00Z`).getUTCDay()];
    if (diaCita !== dia) return false;
    const inicioCita = minutos(cita.hora_inicio);
    const finCita = inicioCita + Number(cita.duracion_aplicada);
    return !disponibles.some((h) =>
      minutos(h.hora_inicio) <= inicioCita && finCita <= minutos(h.hora_fin));
  });
};

const errorEscritura = (error, res) => {
  if (error.code === '23503') {
    return res.status(409).json({ error: 'El horario está relacionado con otro registro.' });
  }
  if (error.code === '23505' || error.code === '23P01') {
    return res.status(409).json({ error: 'Este horario entra en conflicto con otro turno.' });
  }
  console.error('Error al gestionar horarios:', error.message);
  return res.status(500).json({ error: 'No fue posible guardar los cambios del horario.' });
};

const crearHorarioAdmin = async (req, res) => {
  const idEmpleado = enteroPositivo(req.body?.id_empleado);
  const horario = validarHorario(req.body);
  if (!idEmpleado || horario.error) {
    return res.status(400).json({ error: horario.error || 'Selecciona un empleado válido.' });
  }
  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    const fallo = await bloquearEmpleado(client, idEmpleado, { exigirActivo: true });
    if (fallo) {
      await client.query('ROLLBACK');
      return res.status(fallo.status).json({ error: fallo.error });
    }
    if (await hayCruce(client, { idEmpleado, horario })) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Ya existe un turno que se cruza con esas horas.' });
    }
    // id_horario es IDENTITY: PostgreSQL lo asigna automáticamente.
    const resultado = await client.query(`
      INSERT INTO horarios (id_empleado, dia_semana, hora_inicio, hora_fin)
      VALUES ($1, $2, $3::time, $4::time)
      RETURNING id_horario, id_empleado, dia_semana, hora_inicio, hora_fin
    `, [idEmpleado, horario.dia_semana, horario.hora_inicio, horario.hora_fin]);
    await client.query('COMMIT');
    return res.status(201).json({ mensaje: 'Horario registrado.', horario: resultado.rows[0] });
  } catch (error) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return errorEscritura(error, res);
  } finally {
    if (client) client.release();
  }
};

/**
 * Alta masiva de horarios semanales. La selección completa se valida primero
 * y se registra dentro de una ÚNICA transacción: todos los días o ninguno.
 * No modifica horarios existentes; para ello se usa PUT /:id.
 */
const crearHorariosVariosAdmin = async (req, res) => {
  const idEmpleado = enteroPositivo(req.body?.id_empleado);
  const recibidos = req.body?.dias_semana;
  if (!idEmpleado || !Array.isArray(recibidos) ||
      recibidos.length < 1 || recibidos.length > 7) {
    return res.status(400).json({
      error: 'Selecciona un empleado y entre uno y siete días de trabajo.',
    });
  }

  // El servidor valida todos los días, incluso si Flutter ya los comprobó.
  const dias = recibidos.map(normalizarDia);
  if (dias.some((dia) => dia === null) || new Set(dias).size !== dias.length) {
    return res.status(400).json({
      error: 'Selecciona días válidos sin repetirlos.',
    });
  }
  const horario = validarHorario({
    dia_semana: dias[0],
    hora_inicio: req.body?.hora_inicio,
    hora_fin: req.body?.hora_fin,
  });
  if (horario.error) return res.status(400).json({ error: horario.error });

  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');

    // Evita altas simultáneas de turnos del mismo empleado por esta API.
    const fallo = await bloquearEmpleado(client, idEmpleado, { exigirActivo: true });
    if (fallo) {
      await client.query('ROLLBACK');
      return res.status(fallo.status).json({ error: fallo.error });
    }

    // Revisar TODOS los días ANTES de insertar el primero.
    for (const dia of dias) {
      if (await hayCruce(client, {
        idEmpleado,
        horario: { ...horario, dia_semana: dia },
      })) {
        await client.query('ROLLBACK');
        return res.status(409).json({
          error: `Ya existe un turno que coincide con las horas del ${dia}. No se guardó ningún horario.`,
        });
      }
    }

    const nuevos = [];
    for (const dia of dias) {
      const resultado = await client.query(`
        INSERT INTO horarios (id_empleado, dia_semana, hora_inicio, hora_fin)
        VALUES ($1, $2, $3::time, $4::time)
        RETURNING id_horario, id_empleado, dia_semana, hora_inicio, hora_fin
      `, [idEmpleado, dia, horario.hora_inicio, horario.hora_fin]);
      nuevos.push(resultado.rows[0]);
    }

    await client.query('COMMIT');
    return res.status(201).json({
      mensaje: nuevos.length === 1 ? 'Horario registrado.' : 'Horarios registrados.',
      horarios: nuevos,
    });
  } catch (error) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return errorEscritura(error, res);
  } finally {
    if (client) client.release();
  }
};

const editarHorarioAdmin = async (req, res) => {
  const idHorario = enteroPositivo(req.params.id);
  const horario = validarHorario(req.body);
  if (!idHorario || horario.error) {
    return res.status(400).json({ error: horario.error || 'Selecciona un horario válido.' });
  }
  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    // La edición no permite reasignar el horario a otro empleado.
    const actual = await client.query(
      'SELECT id_empleado FROM horarios WHERE id_horario = $1', [idHorario]);
    if (!actual.rowCount) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'No encontramos ese horario.' });
    }
    const idEmpleado = actual.rows[0].id_empleado;
    const fallo = await bloquearEmpleado(client, idEmpleado);
    if (fallo) {
      await client.query('ROLLBACK');
      return res.status(fallo.status).json({ error: fallo.error });
    }
    const bloqueActual = await client.query(
      'SELECT dia_semana FROM horarios WHERE id_horario = $1 FOR UPDATE', [idHorario]);
    if (!bloqueActual.rowCount) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'No encontramos ese horario.' });
    }
    if (await hayCruce(client, { idEmpleado, horario, excluirId: idHorario })) {
      await client.query('ROLLBACK');
      return res.status(409).json({ error: 'Este turno se cruza con otro horario del empleado.' });
    }
    // Verificar la cobertura después de aplicar el cambio, dentro de la transacción.
    const anteriores = await client.query(`
      SELECT dia_semana, hora_inicio::text AS hora_inicio, hora_fin::text AS hora_fin
      FROM horarios WHERE id_horario = $1
    `, [idHorario]);
    await client.query(`
      UPDATE horarios SET dia_semana = $2,
        hora_inicio = $3::time, hora_fin = $4::time
      WHERE id_horario = $1
    `, [idHorario, horario.dia_semana, horario.hora_inicio, horario.hora_fin]);
    // Solo es necesario comprobar el antiguo día (el único que puede perder cobertura).
    const cambioPeligroso = await dejaCitasSinCobertura(
      client, idEmpleado, anteriores.rows[0].dia_semana, -1);
    if (cambioPeligroso) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        error: 'El cambio dejaría citas futuras fuera del horario. Resuélvelas antes de modificarlo.',
      });
    }
    const actualizado = await client.query(`
      SELECT id_horario, id_empleado, dia_semana, hora_inicio, hora_fin
      FROM horarios WHERE id_horario = $1
    `, [idHorario]);
    await client.query('COMMIT');
    return res.json({ mensaje: 'Horario actualizado.', horario: actualizado.rows[0] });
  } catch (error) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return errorEscritura(error, res);
  } finally {
    if (client) client.release();
  }
};

const eliminarHorarioAdmin = async (req, res) => {
  const idHorario = enteroPositivo(req.params.id);
  if (!idHorario) return res.status(400).json({ error: 'Selecciona un horario válido.' });
  let client;
  try {
    client = await pool.connect();
    await client.query('BEGIN');
    const actual = await client.query(
      'SELECT id_empleado, dia_semana FROM horarios WHERE id_horario = $1', [idHorario]);
    if (!actual.rowCount) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'No encontramos ese horario.' });
    }
    const idEmpleado = actual.rows[0].id_empleado;
    const fallo = await bloquearEmpleado(client, idEmpleado);
    if (fallo) {
      await client.query('ROLLBACK');
      return res.status(fallo.status).json({ error: fallo.error });
    }
    await client.query('SELECT id_horario FROM horarios WHERE id_horario = $1 FOR UPDATE', [idHorario]);
    const afectaCitas = await dejaCitasSinCobertura(
      client, idEmpleado, actual.rows[0].dia_semana, idHorario);
    if (afectaCitas) {
      await client.query('ROLLBACK');
      return res.status(409).json({
        error: 'Ese horario tiene citas futuras. Resuélvelas antes de eliminar el turno.',
      });
    }
    await client.query('DELETE FROM horarios WHERE id_horario = $1', [idHorario]);
    await client.query('COMMIT');
    return res.json({ mensaje: 'Horario eliminado.' });
  } catch (error) {
    if (client) await client.query('ROLLBACK').catch(() => {});
    return errorEscritura(error, res);
  } finally {
    if (client) client.release();
  }
};

module.exports = {
  listarHorariosAdmin,
  crearHorarioAdmin,
  crearHorariosVariosAdmin,
  editarHorarioAdmin,
  eliminarHorarioAdmin,
};
