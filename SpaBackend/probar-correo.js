
require('dotenv').config();

const { enviarCorreo } = require('./src/services/email.service');

const probarCorreo = async () => {
    try {
        await enviarCorreo(
            process.env.EMAIL_USER,
            'Prueba de correo - AuraSpa',
            '¡La configuración de correo de AuraSpa funciona correctamente!'
        );

        console.log('Correo de prueba enviado correctamente.');
    } catch (error) {
        console.error('Error al enviar el correo:', error.message);
    }
};

probarCorreo();
