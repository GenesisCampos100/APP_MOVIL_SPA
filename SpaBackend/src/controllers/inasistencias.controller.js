'use strict';
// Inasistencias: extension independiente de citas_manuales.controller.js.
// Administrador o Recepcion real; validacion de hora en la misma BD.
const pool = require('../db');

// Una ausencia cierra la cita como Cancelada sin modificar datos introducidos por el cliente.

const idSolicitado = req => {
    const texto = String(req.params.id ?? '');
    const valor = Number(texto);
    return /^[1-9]\d*$/.test(texto) && Number.isSafeInteger(valor) ? valor : null;
};

async function tienePermiso(req) {
    const rol = Number(req.usuario?.rol);
    const idUsuario = Number(req.usuario?.id_usuario);
    if (![1, 2].includes(rol) || !Number.isSafeInteger(idUsuario) || idUsuario <= 0) return false;
    const consulta = await pool.query(`
        SELECT 1 FROM usuarios u
        LEFT JOIN empleados e ON e.id_usuario = u.id_usuario
        WHERE u.id_usuario = $1 AND u.id_rol = $2 AND u.estado = true
          AND ($2::integer = 1 OR ($2::integer = 2 AND e.id_puesto = 5))
        LIMIT 1`, [idUsuario, rol]);
    return consulta.rows.length > 0;
}

async function inasistenciasHabilitadas(req, res) {
    try {
        if (!await tienePermiso(req)) {
            return res.status(403).json({ error: 'Solo Administracion y Recepcion pueden consultar inasistencias' });
        }
        const resultado = await pool.query(`
            SELECT id_cita FROM citas
            WHERE estado = 'Confirmada'
              AND (fecha + hora_inicio + duracion_aplicada * INTERVAL '1 minute') <= LOCALTIMESTAMP
            ORDER BY fecha DESC, hora_inicio DESC, id_cita DESC
            LIMIT 500`);
        return res.json({ ids_habilitados: resultado.rows.map(c => Number(c.id_cita)) });
    } catch (error) {
        console.error('Error al consultar inasistencias:', error.message);
        return res.status(500).json({ error: 'No fue posible consultar inasistencias habilitadas' });
    }
}

async function reportarInasistencia(req, res) {
    const id = idSolicitado(req);
    if (!id) return res.status(400).json({ error: 'El identificador de cita no es valido' });
    try {
        if (!await tienePermiso(req)) {
            return res.status(403).json({ error: 'Solo Administracion y Recepcion pueden registrar inasistencias' });
        }
        // Actualizacion atomica: solo cambia estado; NO escribe en observaciones.
        // El reloj de PostgreSQL evita registrar una ausencia antes del cierre del horario.
        const resultado = await pool.query(`
            UPDATE citas
            SET estado = 'Cancelada'
            WHERE id_cita = $1 AND estado = 'Confirmada'
              AND (fecha + hora_inicio + duracion_aplicada * INTERVAL '1 minute') <= LOCALTIMESTAMP
            RETURNING id_cita, estado, fecha, hora_inicio`, [id]);
        if (resultado.rows.length) {
            return res.json({ mensaje: 'Ausencia registrada: cita Cancelada; observaciones sin cambios.', cita: resultado.rows[0] });
        }
        const actual = await pool.query(`
            SELECT estado,
              (fecha + hora_inicio + duracion_aplicada * INTERVAL '1 minute') <= LOCALTIMESTAMP AS termino
            FROM citas WHERE id_cita = $1`, [id]);
        if (!actual.rows.length) return res.status(404).json({ error: 'La cita no existe' });
        if (actual.rows[0].estado !== 'Confirmada') {
            return res.status(409).json({ error: 'Solo se reportan inasistencias de citas Confirmadas' });
        }
        if (!actual.rows[0].termino) {
            return res.status(409).json({ error: 'El horario reservado todavia no termina' });
        }
        return res.status(409).json({ error: 'La cita fue actualizada por otro operador; vuelve a consultar' });
    } catch (error) {
        if (['23514', '22P02'].includes(error.code)) {
            return res.status(409).json({ error: 'PostgreSQL rechazo el cambio del estado de la cita.' });
        }
        console.error('Error al reportar inasistencia:', error.message);
        return res.status(500).json({ error: 'No se pudo registrar la inasistencia' });
    }
}

module.exports = { inasistenciasHabilitadas, reportarInasistencia };
