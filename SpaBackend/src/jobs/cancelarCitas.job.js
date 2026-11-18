
const cron = require('node-cron');
const pool = require('../db');
const { enviarNotificacionAUsuario } = require('../services/notificaciones.service');

// Cancelar citas que no fueron confirmadas a tiempo.
const cancelarCitasVencidas = async () => {
    try {
        const resultado = await pool.query(
            `WITH citas_vencidas AS (
                UPDATE citas c
                SET estado = 'Cancelada'
                WHERE c.estado IN ('Pendiente', 'Confirmada')
                  AND c.fecha_confirmacion IS NULL
                  AND c.fecha_limite IS NOT NULL
                  AND c.fecha_limite <= NOW()
                  -- Solo cancelar si se generó una solicitud de asistencia.
                  AND EXISTS (
                      SELECT 1
                      FROM notificaciones n
                      WHERE n.id_cita = c.id_cita
                        AND n.tipo = 'confirmar_cita'
                  )
                RETURNING
                    id_cita,
                    id_cliente
            )
            INSERT INTO notificaciones (
                id_cita,
                tipo,
                fecha_envio,
                id_usuario,
                titulo,
                mensaje
            )
            SELECT
                cv.id_cita,
                'cita_cancelada',
                timezone('America/Mexico_City', NOW()),
                cl.id_usuario,
                'Cita cancelada',
                'Tu cita fue cancelada automáticamente porque no confirmaste tu asistencia dentro del plazo establecido.'
            FROM citas_vencidas cv
            INNER JOIN clientes cl
                ON cl.id_cliente = cv.id_cliente
            RETURNING id_notificacion, id_cita, id_usuario, titulo, mensaje`
        );

        if (resultado.rowCount > 0) {
            console.log('Citas canceladas automáticamente:', resultado.rows.length);
            // El registro en PostgreSQL no depende de que Firebase esté disponible.
            for (const notificacion of resultado.rows) {
                try {
                    await enviarNotificacionAUsuario({
                        ...notificacion,
                        tipo: 'cita_cancelada'
                    });
                } catch (errorPush) {
                    console.error('No se pudo enviar push de cancelación:', errorPush.message);
                }
            }
        }

    } catch (error) {
        console.error(
            'Error al cancelar citas vencidas:',
            error
        );
    }
};

// Revisar cada 5 minutos.
const iniciarCancelacionCitas = () => {
    cron.schedule('*/5 * * * *', cancelarCitasVencidas);

    console.log('Programador de cancelación de citas iniciado.');
};

module.exports = iniciarCancelacionCitas;
