
const cron = require('node-cron');
const pool = require('../db');

// Buscar citas que necesitan un recordatorio.
const generarRecordatorios = async () => {
    try {
        const resultado = await pool.query(
            `INSERT INTO notificaciones (
                id_cita,
                tipo,
                fecha_envio,
                id_usuario,
                titulo,
                mensaje
            )
            SELECT
                c.id_cita,
                'confirmar_cita',
                NOW(),
                cl.id_usuario,
                'Confirma tu asistencia',
                'Tu cita está programada para dentro de 24 horas. Confirma tu asistencia.'
            FROM citas c
            INNER JOIN clientes cl
                ON cl.id_cliente = c.id_cliente
            WHERE c.estado = 'Pendiente'
              AND (c.fecha + c.hora_inicio) > NOW() + INTERVAL '23 hours 55 minutes'
              AND (c.fecha + c.hora_inicio) <= NOW() + INTERVAL '24 hours'
              AND NOT EXISTS (
                  SELECT 1
                  FROM notificaciones n
                  WHERE n.id_cita = c.id_cita
                    AND n.tipo = 'confirmar_cita'
              )
            RETURNING id_notificacion, id_cita`
        );

        if (resultado.rowCount > 0) {
            console.log(
                'Recordatorios creados:',
                resultado.rows
            );
        }

    } catch (error) {
        console.error('Error al generar recordatorios:', error);
    }
};

// Ejecutar la revisión cada 5 minutos.
const iniciarRecordatorios = () => {
    cron.schedule('*/5 * * * *', generarRecordatorios);

    console.log('Programador de recordatorios iniciado.');
};

module.exports = iniciarRecordatorios;
