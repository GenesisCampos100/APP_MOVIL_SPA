const express = require('express');
const pool = require('../db');
const verificarToken = require('../middlewares/verificarToken');
const {
    listarEmpleadosAdmin,
    listarPuestosAdmin,
    crearEmpleadoAdmin,
    actualizarEmpleadoAdmin,
    cambiarEstadoEmpleadoAdmin,
} = require('../controllers/admin_empleados.controller');

const router = express.Router();

// Conserva la autorización activa de la Fase 01 para TODAS las rutas.
const autorizarAdministradorActivo = async (req, res, next) => {
    if (Number(req.usuario?.rol) !== 1) {
        return res.status(403).json({ error: 'Acceso exclusivo del Administrador' });
    }
    try {
        const admin = await pool.query(
            'SELECT 1 FROM usuarios WHERE id_usuario = $1 AND id_rol = 1 AND estado = true',
            [req.usuario.id_usuario]
        );
        if (!admin.rowCount) {
            return res.status(403).json({ error: 'Cuenta administrativa no autorizada' });
        }
        return next();
    } catch (error) {
        console.error('Error al verificar Administrador:', error.message);
        return res.status(500).json({ error: 'No se pudo comprobar el acceso' });
    }
};

router.use(verificarToken, autorizarAdministradorActivo);
router.get('/puestos', listarPuestosAdmin);
router.get('/', listarEmpleadosAdmin);
router.post('/', crearEmpleadoAdmin);
router.put('/:id/estado', cambiarEstadoEmpleadoAdmin);
router.put('/:id', actualizarEmpleadoAdmin);

module.exports = router;
