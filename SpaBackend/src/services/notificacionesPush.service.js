
const { getMessaging } = require('firebase-admin/messaging');


const enviarNotificacionPush = async ({
    token,
    titulo,
    mensaje,
    datos = {}
}) => {
    try {
        const firebaseApp = require('../config/firebaseAdmin');

        const respuesta = await getMessaging(firebaseApp).send({
            token,
            notification: {
                title: titulo,
                body: mensaje
            },
            data: Object.fromEntries(
                Object.entries(datos).map(([clave, valor]) => [
                    clave,
                    String(valor)
                ])
            ),
            android: {
                priority: 'high',
                notification: {
                    channelId: 'aura_spa_notificaciones'
                }
            }
        });

        return {
            exitosa: true,
            messageId: respuesta
        };

    } catch (error) {
        console.error('Error enviando notificación push:', error);

        return {
            exitosa: false,
            error: error.code || error.message
        };
    }
};

module.exports = {
    enviarNotificacionPush
};
