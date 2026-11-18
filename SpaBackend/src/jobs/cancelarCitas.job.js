
const cron = require('node-cron');
const pool = require('../db');

// Cancelar citas que no fueron confirmadas a tiempo.
const cancelarCitasVencidas = async () => {
    try {
        const resultado = await pool.query(
            `WITH citas_vencidas AS (
                UPDATE citas
                SET estado = 'Cancelada'
                WHERE estado = 'Pendiente'
                  AND fecha_limite IS NOT NULL
                  AND fecha_limite <= NOW()
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
            RETURNING id_notificacion, id_cita`
        );

        if (resultado.rowCount > 0) {
            console.log(
                'Citas canceladas automáticamente:',
                resultado.rows
            );
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
