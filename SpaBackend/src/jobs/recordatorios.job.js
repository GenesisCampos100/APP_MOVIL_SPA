
const cron = require('node-cron');
const pool = require('../db');

// Buscar citas que necesitan una solicitud de confirmación.
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
                timezone('America/Mexico_City', NOW()),
                cl.id_usuario,
                'Confirma tu asistencia',
                'Tu cita está programada para dentro de 48 horas. Confirma tu asistencia antes de la fecha límite.'
            FROM citas c
            INNER JOIN clientes cl
                ON cl.id_cliente = c.id_cliente
            WHERE c.estado = 'Pendiente'

              -- La cita debe estar dentro de las próximas 48 horas.
              AND (c.fecha + c.hora_inicio) <=
                  timezone('America/Mexico_City', NOW()) + INTERVAL '48 hours'

              -- La cita todavía no debe haber comenzado.
              AND (c.fecha + c.hora_inicio) >
                  timezone('America/Mexico_City', NOW())

              -- El plazo de confirmación todavía debe estar vigente.
              AND c.fecha_limite > NOW()

              -- Evitar notificaciones duplicadas.
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
                'Solicitudes de confirmación creadas:',
                resultado.rows
            );
        }

    } catch (error) {
        console.error(
            'Error al generar solicitudes de confirmación:',
            error
        );
    }
};

// Ejecutar la revisión cada 5 minutos.
const iniciarRecordatorios = () => {
    cron.schedule('*/5 * * * *', generarRecordatorios);

    console.log('Programador de recordatorios iniciado.');
};

module.exports = iniciarRecordatorios;
