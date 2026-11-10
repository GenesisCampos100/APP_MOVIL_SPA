const pool = require('../db');

// Recepción puede ver la agenda general; los Especialistas siguen usando
// GET /api/citas, que limita las citas al empleado autenticado.
const obtenerAgendaRecepcion = async (req, res) => {
    const rol = Number(req.usuario?.rol);
    const idUsuario = Number(req.usuario?.id_usuario);

    if (rol !== 2 || !Number.isSafeInteger(idUsuario) || idUsuario <= 0) {
        return res.status(403).json({ error: 'Acceso exclusivo de Recepción' });
    }

    try {
        // Se consulta la base de datos en cada solicitud: el puesto y el
        // estado de la cuenta no se confían al cliente ni a un JWT antiguo.
        const permiso = await pool.query(`
            SELECT 1
            FROM empleados e
            INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
            WHERE e.id_usuario = $1
              AND e.id_puesto = 5
              AND u.id_rol = 2
              AND u.estado = true
            LIMIT 1
        `, [idUsuario]);

        if (permiso.rowCount === 0) {
            return res.status(403).json({ error: 'Personal no autorizado para consultar la agenda general' });
        }

        const resultado = await pool.query(`
            SELECT
                c.id_cita, c.id_cliente, c.id_empleado, c.id_servicio,
                c.fecha, c.hora_inicio, c.duracion_aplicada,
                c.precio_aplicado, c.estado, c.observaciones,
                CONCAT(cl.nombre, ' ', cl.apellido_p, ' ', COALESCE(cl.apellido_m, '')) AS cliente,
                s.nombre AS servicio,
                CONCAT(e.nombre, ' ', e.apellido_p, ' ', COALESCE(e.apellido_m, '')) AS empleado
            FROM citas c
            INNER JOIN clientes cl ON cl.id_cliente = c.id_cliente
            INNER JOIN servicios s ON s.id_servicio = c.id_servicio
            INNER JOIN empleados e ON e.id_empleado = c.id_empleado
            ORDER BY c.fecha DESC, c.hora_inicio DESC
            LIMIT 500
        `);

        return res.status(200).json({
            mensaje: 'Agenda general consultada correctamente',
            citas: resultado.rows
        });
    } catch (error) {
        console.error('Error al consultar agenda de Recepción:', error.message);
        return res.status(500).json({ error: 'No se pudo consultar la agenda' });
    }
};

module.exports = { obtenerAgendaRecepcion };
