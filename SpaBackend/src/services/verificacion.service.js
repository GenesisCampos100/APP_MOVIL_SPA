
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const { enviarCorreo } = require('./email.service');

const generarCodigo = () => {
    return crypto.randomInt(100000, 1000000).toString();
};

const enviarCodigoVerificacion = async (correo, codigo) => {
    await enviarCorreo(
        correo,
        'Código de verificación - AuraSpa',
        `Tu código de verificación es: ${codigo}\n\n` +
        'Este código vence en 10 minutos. ' +
        'Si no solicitaste el registro, ignora este mensaje.'
    );
};

const crearCodigoVerificacion = async (correo) => {
    const codigo = generarCodigo();
    const codigoHash = await bcrypt.hash(codigo, 10);

    await enviarCodigoVerificacion(correo, codigo);

    return {
        codigoHash,
        expiraEn: Date.now() + 10 * 60 * 1000
    };
};

module.exports = {
    crearCodigoVerificacion
};
