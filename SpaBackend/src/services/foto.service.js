
const { randomUUID } = require('crypto');
const supabase = require('../config/supabase');

const BUCKET = process.env.SUPABASE_BUCKET_USUARIOS;

// Detectar el formato real mediante la firma del archivo.
const detectarFormato = (buffer) => {
    if (
        buffer.length >= 3 &&
        buffer[0] === 0xFF &&
        buffer[1] === 0xD8 &&
        buffer[2] === 0xFF
    ) {
        return { extension: 'jpg', mime: 'image/jpeg' };
    }

    if (
        buffer.length >= 8 &&
        buffer.subarray(0, 8).equals(
            Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])
        )
    ) {
        return { extension: 'png', mime: 'image/png' };
    }

    if (
        buffer.length >= 12 &&
        buffer.toString('ascii', 0, 4) === 'RIFF' &&
        buffer.toString('ascii', 8, 12) === 'WEBP'
    ) {
        return { extension: 'webp', mime: 'image/webp' };
    }

    return null;
};

// Generar URL firmada para consultar una fotografía.
const generarUrlFoto = async (ruta) => {
    if (!ruta) return null;

    const { data, error } = await supabase.storage
        .from(BUCKET)
        .createSignedUrl(ruta, 60 * 60);

    if (error) throw error;

    return data.signedUrl;
};

// Subir una nueva fotografía sin sobrescribir la anterior.
const subirFotoPerfil = async (idUsuario, archivo) => {
    if (!archivo?.buffer || !Buffer.isBuffer(archivo.buffer)) {
        throw new Error('No se recibió una fotografía válida');
    }

    const formato = detectarFormato(archivo.buffer);

    if (!formato) {
        throw new Error('El archivo no contiene una imagen JPG, PNG o WEBP válida');
    }

    const ruta = `${idUsuario}/${randomUUID()}.${formato.extension}`;

    const { error } = await supabase.storage
        .from(BUCKET)
        .upload(ruta, archivo.buffer, {
            contentType: formato.mime,
            upsert: false,
            cacheControl: '3600'
        });

    if (error) throw error;

    return ruta;
};

// Eliminar una fotografía.
const eliminarFotoPerfil = async (ruta) => {
    if (!ruta) return;

    const { error } = await supabase.storage
        .from(BUCKET)
        .remove([ruta]);

    if (error) throw error;
};

module.exports = {
    generarUrlFoto,
    subirFotoPerfil,
    eliminarFotoPerfil
};
