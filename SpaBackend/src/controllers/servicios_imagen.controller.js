const fs = require('node:fs/promises');
const path = require('node:path');
const { randomUUID } = require('node:crypto');

// El volumen/directorio debe ser persistente en producción; nunca bajo la BD.
const carpeta = path.resolve(process.env.SPA_UPLOAD_DIR || path.join(__dirname, '../../uploads/servicios'));
const LIMITE = 3 * 1024 * 1024;

function tipoReal(bytes) {
    if (bytes.length >= 3 && bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) {
        return {mime: 'image/jpeg', ext: '.jpg'};
    }
    if (bytes.length >= 8 && Buffer.from(bytes.subarray(0, 8)).equals(
            Buffer.from([137,80,78,71,13,10,26,10]))) {
        return {mime: 'image/png', ext: '.png'};
    }
    if (bytes.length >= 12 && bytes.toString('ascii', 0, 4) === 'RIFF'
            && bytes.toString('ascii', 8, 12) === 'WEBP') {
        return {mime: 'image/webp', ext: '.webp'};
    }
    return null;
}

async function subirImagenServicio(req, res) {
    const bytes = req.body;
    if (!Buffer.isBuffer(bytes) || bytes.length < 16 || bytes.length > LIMITE) {
        return res.status(400).json({error: 'La imagen está vacía o supera los 3 MB.'});
    }
    const tipo = tipoReal(bytes);
    const declarado = (req.headers['content-type'] || '').split(';')[0].trim().toLowerCase();
    if (!tipo || declarado !== tipo.mime) {
        return res.status(415).json({error: 'Solo se permiten archivos JPG, PNG y WebP válidos.'});
    }
    const nombre = `${randomUUID()}${tipo.ext}`;
    try {
        await fs.mkdir(carpeta, {recursive: true});
        await fs.writeFile(path.join(carpeta, nombre), bytes, {flag: 'wx'});
        return res.status(201).json({imagen: `/uploads/servicios/${nombre}`});
    } catch (err) {
        console.error('No fue posible guardar la imagen del servicio:', err.message);
        return res.status(500).json({error: 'No se pudo almacenar la imagen del servicio.'});
    }
}

module.exports = {subirImagenServicio, carpeta, tipoReal};
