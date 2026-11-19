
const pool = require('../db');

const {
    enviarNotificacionPush
} = require('./notificacionesPush.service');


const enviarNotificacionAUsuario = async ({
    id_usuario,
    id_notificacion,
    id_cita,
    tipo,
    titulo,
    mensaje
}) => {
    try {
        const dispositivos = await pool.query(
            `SELECT token_fcm
             FROM dispositivos_fcm
             WHERE id_usuario = $1
               AND activo = TRUE`,
            [id_usuario]
        );

        if (dispositivos.rows.length === 0) {
            console.log(
                `El usuario ${id_usuario} no tiene dispositivos activos.`
            );
            return;
        }

        const resultados = await Promise.all(
            dispositivos.rows.map(dispositivo =>
                enviarNotificacionPush({
                    token: dispositivo.token_fcm,
                    titulo,
                    mensaje,
                    datos: {
                        tipo,
                        id_notificacion,
                        id_cita
                    }
                })
            )
        );

        const exitosas = resultados.filter(
            resultado => resultado.exitosa
        ).length;

        console.log(
            `Notificación ${id_notificacion}: ${exitosas} de ${resultados.length} dispositivos notificados.`
        );

    } catch (error) {
        console.error(
            'Error al distribuir notificación push:',
            error.message
        );
    }
};

module.exports = {
    enviarNotificacionAUsuario
};
