'use strict';

// Fotos de perfil: carpeta separada de servicios, JWT y consulta de cuenta activa.
const fs = require('node:fs/promises');
const path = require('node:path');
const {randomUUID} = require('node:crypto');
const pool = require('../db');

const carpeta = path.resolve(process.env.SPA_PROFILE_UPLOAD_DIR ||
    path.join(__dirname, '../../uploads/perfiles'));
const LIMITE = 3 * 1024 * 1024;

function detectarTipo(bytes) {
    if (bytes.length >= 3 && bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) {
        return {mime: 'image/jpeg', ext: '.jpg'};
    }
    if (bytes.length >= 8 && bytes.subarray(0, 8).equals(
        Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))) {
        return {mime: 'image/png', ext: '.png'};
    }
    if (bytes.length >= 12 && bytes.toString('ascii', 0, 4) === 'RIFF' &&
        bytes.toString('ascii', 8, 12) === 'WEBP') {
        return {mime: 'image/webp', ext: '.webp'};
    }
    return null;
}

async function subirFotoPerfil(req, res) {
    const idUsuario = Number(req.usuario?.id_usuario);
    if (!Number.isSafeInteger(idUsuario) || idUsuario < 1) {
        return res.status(401).json({error: 'Sesión inválida.'});
    }
    const bytes = req.body;
    if (!Buffer.isBuffer(bytes) || bytes.length < 16 || bytes.length > LIMITE) {
        return res.status(400).json({error: 'Selecciona una imagen de hasta 3 MB.'});
    }
    const tipo = detectarTipo(bytes);
    const declarado = (req.headers['content-type'] || '').split(';')[0].trim().toLowerCase();
    if (!tipo || declarado !== tipo.mime) {
        return res.status(415).json({error: 'Utiliza una imagen JPG, PNG o WebP válida.'});
    }

    const fileName = `${randomUUID()}${tipo.ext}`;
    const pathFile = path.join(carpeta, fileName);
    const foto = `/uploads/perfiles/${fileName}`;
    let created = false;
    try {
        // Verificación previa para no aceptar cuentas inactivas.
        const activo = await pool.query(
            'SELECT 1 FROM usuarios WHERE id_usuario = $1 AND id_rol = 2 AND estado = true',
            [idUsuario]
        );
        if (!activo.rowCount) {
            return res.status(403).json({error: 'Solo el personal activo puede actualizar su foto.'});
        }
        await fs.mkdir(carpeta, {recursive: true});
        await fs.writeFile(pathFile, bytes, {flag: 'wx'});
        created = true;
        const updated = await pool.query(
            'UPDATE usuarios SET foto = $1 WHERE id_usuario = $2 AND id_rol = 2 AND estado = true RETURNING foto',
            [foto, idUsuario]
        );
        if (!updated.rowCount) {
            await fs.unlink(pathFile).catch(() => {});
            return res.status(409).json({error: 'La cuenta ya no está activa.'});
        }
        return res.status(201).json({mensaje: 'Fotografía actualizada.', foto});
    } catch (e) {
        if (created) await fs.unlink(pathFile).catch(() => {});
        console.error('No se pudo actualizar foto de perfil:', e.message);
        return res.status(500).json({error: 'No se pudo guardar la fotografía.'});
    }
}

module.exports = {subirFotoPerfil, detectarTipo, carpeta};
