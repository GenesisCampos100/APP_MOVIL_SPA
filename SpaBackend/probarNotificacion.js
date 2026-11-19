
const pool = require('./src/db');

const {
    enviarNotificacionPush
} = require('./src/services/notificacionesPush.service');

const probarNotificacion = async () => {
    try {
        console.log('Buscando un dispositivo registrado...');

        const resultado = await pool.query(
            `SELECT token_fcm, id_usuario
             FROM dispositivos_fcm
             WHERE activo = TRUE
             ORDER BY fecha_actualizacion DESC
             LIMIT 1`
        );

        if (resultado.rows.length === 0) {
            console.log('No hay dispositivos registrados.');
            return;
        }

        const dispositivo = resultado.rows[0];

        console.log(
            `Dispositivo encontrado. Usuario: ${dispositivo.id_usuario}`
        );

        const respuesta = await enviarNotificacionPush({
            token: dispositivo.token_fcm,
            titulo: '¡Hola desde AuraSpa!',
            mensaje: 'Las notificaciones push están funcionando correctamente.',
            datos: {
                tipo: 'prueba',
                pantalla: 'inicio'
            }
        });

        if (respuesta.exitosa) {
            console.log('¡Notificación enviada correctamente!');
            console.log('ID del mensaje:', respuesta.messageId);
        } else {
            console.error('No se pudo enviar:', respuesta.error);
        }

    } catch (error) {
        console.error('Error en la prueba:', error);
    } finally {
        await pool.end();
    }
};

probarNotificacion();
