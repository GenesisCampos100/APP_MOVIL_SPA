
const crypto = require('crypto');
const bcrypt = require('bcrypt');
const { enviarCorreo } = require('./email.service');

const generarCodigo = () => {
    return crypto.randomInt(100000, 1000000).toString();
};

const enviarCodigoVerificacion = async (correo, codigo, tipo = 'registro') => {
    const esCambioCorreo = tipo === 'cambio_correo';

    const titulo = esCambioCorreo
        ? 'Confirma tu nuevo correo electrónico'
        : 'Verifica tu cuenta';

    const descripcion = esCambioCorreo
        ? 'Has solicitado cambiar el correo electrónico de tu cuenta AuraSpa. Introduce el siguiente código para confirmar que tienes acceso a esta dirección:'
        : 'Estás a un paso de disfrutar de la mejor experiencia de bienestar. Utiliza el siguiente código de verificación para completar tu registro:';

    const aviso = esCambioCorreo
        ? 'Si no solicitaste este cambio de correo, puedes ignorar este mensaje. Tu correo actual no será modificado.'
        : 'Si no solicitaste este registro, puedes ignorar este mensaje de forma segura.';

    const asunto = esCambioCorreo
        ? '✨ Confirma tu nuevo correo - AuraSpa'
        : '✨ Tu código de verificación - AuraSpa';

    const htmlContenido = `
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${titulo}</title>
    </head>

    <body style="margin: 0; padding: 0; background-color: #f4f7f6; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;">

        <table border="0" cellpadding="0" cellspacing="0" width="100%"
            style="table-layout: fixed; background-color: #f4f7f6; padding: 40px 0;">

            <tr>
                <td align="center">

                    <table border="0" cellpadding="0" cellspacing="0" width="600"
                        style="background-color: #ffffff; border-radius: 12px; overflow: hidden;">

                        <!-- Encabezado -->
                        <tr>
                            <td align="center"
                                style="background-color: #2c4a43; padding: 30px 0;">

                                <h1 style="color: #ffffff; margin: 0; font-size: 24px; font-weight: 500; letter-spacing: 2px;">
                                    AURA SPA
                                </h1>

                            </td>
                        </tr>

                        <!-- Contenido -->
                        <tr>
                            <td style="padding: 40px 30px; text-align: center;">

                                <h2 style="color: #333333; font-size: 20px; margin-top: 0; margin-bottom: 15px;">
                                    ${titulo}
                                </h2>

                                <p style="color: #666666; font-size: 15px; line-height: 1.5; margin-bottom: 30px;">
                                    ${descripcion}
                                </p>

                                <!-- Código -->
                                <div style="background-color: #f0f4f3; border: 1px dashed #2c4a43; border-radius: 8px; padding: 15px 0; margin-bottom: 30px;">

                                    <span style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #2c4a43;">
                                        ${codigo}
                                    </span>

                                </div>

                                <p style="color: #999999; font-size: 13px; margin-bottom: 0;">
                                    ⏰ Este código vence en <strong>10 minutos</strong>.
                                </p>

                                <p style="color: #999999; font-size: 13px; margin-top: 10px;">
                                    ${aviso}
                                </p>

                            </td>
                        </tr>

                        <!-- Pie de página -->
                        <tr>
                            <td align="center"
                                style="background-color: #fafafa; padding: 20px; border-top: 1px solid #eeeeee;">

                                <p style="color: #aaaaaa; font-size: 12px; margin: 0;">
                                    &copy; ${new Date().getFullYear()} AuraSpa. Todos los derechos reservados.
                                </p>

                            </td>
                        </tr>

                    </table>

                </td>
            </tr>

        </table>

    </body>
    </html>
    `;

    await enviarCorreo(correo, asunto, htmlContenido);
};

const crearCodigoVerificacion = async (correo, opciones = {}) => {
    const tipo = opciones.tipo || 'registro';

    const codigo = generarCodigo();
    const codigoHash = await bcrypt.hash(codigo, 10);

    await enviarCodigoVerificacion(correo, codigo, tipo);

    return {
        codigoHash,
        expiraEn: Date.now() + 10 * 60 * 1000
    };
};

module.exports = {
    crearCodigoVerificacion
};
