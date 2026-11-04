
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_APP_PASSWORD
    }
});

const enviarCorreo = async (destinatario, asunto, mensaje) => {
    return await transporter.sendMail({
        from: `"AuraSpa" <${process.env.EMAIL_USER}>`,
        to: destinatario,
        subject: asunto,
        text: mensaje
    });
};

module.exports = { enviarCorreo };
