// Propuesta UI22 para revisión de Vanessa. Solo lectura: sin POST/PATCH/DELETE.
const express = require('express');
const verificarToken = require('../middlewares/verificarToken');
const pool = require('../db');
const { listarResenas, resumenResenas, detalleResena } = require('../controllers/admin_resenas.controller');

const router = express.Router();

async function administradorActivo(req, res, next) {
  if (Number(req.usuario?.rol) !== 1) {
    return res.status(403).json({ error: 'Acceso exclusivo del Administrador' });
  }
  try {
    const permiso = await pool.query(
      'SELECT 1 FROM usuarios WHERE id_usuario = $1 AND id_rol = 1 AND estado = true',
      [req.usuario.id_usuario]
    );
    if (permiso.rowCount === 0) {
      return res.status(403).json({ error: 'Cuenta administrativa no autorizada' });
    }
    return next();
  } catch (error) {
    console.error('Error comprobando acceso a reseñas:', error.message);
    return res.status(500).json({ error: 'No se pudo validar el acceso administrativo' });
  }
}

router.use(verificarToken, administradorActivo);
router.get('/resumen', resumenResenas); // antes de /:id
router.get('/', listarResenas);
router.get('/:id', detalleResena);
module.exports = router;
