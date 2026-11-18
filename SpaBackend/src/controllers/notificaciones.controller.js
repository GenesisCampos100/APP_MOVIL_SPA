const pool = require('../db'); 

const obtenerNotificaciones = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;

        const resultado = await pool.query(
            `SELECT
                n.id_notificacion,
                n.id_cita,
                n.tipo,
                n.titulo,
                n.mensaje,
                n.fecha_envio,
                n.leida,
                CASE
                    WHEN n.tipo = 'confirmar_cita'
                    THEN (
                        c.id_cita IS NULL
                        OR c.estado <> 'Pendiente'
                    )
                    ELSE FALSE
                END AS atendida
             FROM notificaciones n
             LEFT JOIN citas c
                ON c.id_cita = n.id_cita
             WHERE n.id_usuario = $1
             ORDER BY n.fecha_envio DESC`,
            [id_usuario]
        );

        return res.json(resultado.rows);

    } catch (error) {
        console.error('Error al obtener notificaciones:', error);

        return res.status(500).json({
            error: 'Error al obtener las notificaciones'
        });
    }
};

const marcarNotificacionLeida = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;
        const { id_notificacion } = req.params;

        const resultado = await pool.query(
            `UPDATE notificaciones
             SET leida = TRUE
             WHERE id_notificacion = $1
               AND id_usuario = $2
             RETURNING id_notificacion, leida`,
            [id_notificacion, id_usuario]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                error: 'Notificación no encontrada'
            });
        }

        return res.json({
            mensaje: 'Notificación marcada como leída',
            notificacion: resultado.rows[0]
        });

    } catch (error) {
        console.error('Error al marcar notificación como leída:', error);

        return res.status(500).json({
            error: 'Error al actualizar la notificación'
        });
    }
};

const marcarTodasLeidas = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;

        const resultado = await pool.query(
            `UPDATE notificaciones
             SET leida = TRUE
             WHERE id_usuario = $1
               AND leida = FALSE
             RETURNING id_notificacion`,
            [id_usuario]
        );

        return res.json({
            mensaje: 'Notificaciones marcadas como leídas',
            actualizadas: resultado.rowCount
        });

    } catch (error) {
        console.error('Error al marcar todas las notificaciones:', error);

        return res.status(500).json({
            error: 'Error al actualizar las notificaciones'
        });
    }
};

const eliminarNotificacion = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;
        const id_notificacion = Number(req.params.id_notificacion);

        if (!Number.isInteger(id_notificacion) || id_notificacion <= 0) {
            return res.status(400).json({
                error: 'El identificador de la notificación no es válido'
            });
        }

        const resultado = await pool.query(
            `DELETE FROM notificaciones n
             WHERE n.id_notificacion = $1
               AND n.id_usuario = $2
               AND NOT (
                   n.tipo = 'confirmar_cita'
                   AND EXISTS (
                       SELECT 1
                       FROM citas c
                       WHERE c.id_cita = n.id_cita
                         AND c.estado = 'Pendiente'
                   )
               )
             RETURNING n.id_notificacion`,
            [id_notificacion, id_usuario]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                error: 'La notificación no existe o todavía requiere confirmación'
            });
        }

        return res.json({
            mensaje: 'Notificación eliminada',
            id_notificacion: resultado.rows[0].id_notificacion
        });
    } catch (error) {
        console.error('Error al eliminar notificación:', error);

        return res.status(500).json({
            error: 'Error al eliminar la notificación'
        });
    }
};

const eliminarNotificaciones = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;

        const resultado = await pool.query(
            `DELETE FROM notificaciones n
             WHERE n.id_usuario = $1
               AND NOT (
                   n.tipo = 'confirmar_cita'
                   AND EXISTS (
                       SELECT 1
                       FROM citas c
                       WHERE c.id_cita = n.id_cita
                         AND c.estado = 'Pendiente'
                   )
               )
             RETURNING n.id_notificacion`,
            [id_usuario]
        );

        return res.json({
            mensaje: 'Notificaciones eliminadas',
            eliminadas: resultado.rows.map(
                notificacion => notificacion.id_notificacion
            )
        });
    } catch (error) {
        console.error('Error al eliminar notificaciones:', error);

        return res.status(500).json({
            error: 'Error al eliminar las notificaciones'
        });
    }
};

module.exports = {
    obtenerNotificaciones,
    marcarNotificacionLeida,
    marcarTodasLeidas,
    eliminarNotificacion,
    eliminarNotificaciones
};