
const pool = require('../db');

const registrarDispositivo = async (req, res) => {
    try {
        const { id_usuario } = req.usuario;
        const { token_fcm, plataforma = 'android' } = req.body;

        if (!token_fcm || typeof token_fcm !== 'string') {
            return res.status(400).json({
                error: 'El token FCM es obligatorio.'
            });
        }

        if (!['android', 'ios', 'web'].includes(plataforma)) {
            return res.status(400).json({
                error: 'La plataforma no es válida.'
            });
        }

        const resultado = await pool.query(
            `INSERT INTO dispositivos_fcm (
                id_usuario,
                token_fcm,
                plataforma,
                activo,
                fecha_actualizacion
            )
            VALUES ($1, $2, $3, TRUE, NOW())
            ON CONFLICT (token_fcm)
            DO UPDATE SET
                id_usuario = EXCLUDED.id_usuario,
                plataforma = EXCLUDED.plataforma,
                activo = TRUE,
                fecha_actualizacion = NOW()
            RETURNING id_dispositivo, id_usuario, plataforma, activo`,
            [id_usuario, token_fcm, plataforma]
        );

        return res.status(200).json({
            mensaje: 'Dispositivo registrado correctamente.',
            dispositivo: resultado.rows[0]
        });

    } catch (error) {
        console.error('Error al registrar dispositivo FCM:', error);

        return res.status(500).json({
            error: 'Error al registrar el dispositivo.'
        });
    }
};

module.exports = {
    registrarDispositivo
};
