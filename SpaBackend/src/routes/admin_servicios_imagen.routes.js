const express = require('express');
const pool = require('../db');
const verificarToken = require('../middlewares/verificarToken');
const {subirImagenServicio} = require('../controllers/servicios_imagen.controller');

const router = express.Router();

// Mismo criterio de Administrador activo que POST/PUT /api/servicios.
async function autorizarAdministrador(req, res, next) {
    if (Number(req.usuario?.rol) !== 1) {
        return res.status(403).json({error: 'Acceso exclusivo del Administrador'});
    }
    try {
        const r = await pool.query(
            'SELECT 1 FROM usuarios WHERE id_usuario = $1 AND id_rol = 1 AND estado = true',
            [req.usuario.id_usuario]
        );
        if (!r.rowCount) return res.status(403).json({error: 'Cuenta administrativa no autorizada'});
        next();
    } catch (e) {
        console.error('Error de autorización de carga de fotos:', e.message);
        return res.status(500).json({error: 'No se pudo comprobar el acceso'});
    }
}

router.post('/', verificarToken, autorizarAdministrador,
    express.raw({type: ['image/jpeg', 'image/png', 'image/webp'], limit: '3mb'}),
    subirImagenServicio);

module.exports = router;
