
const express = require('express');
const pool = require('../db');
const verificarToken = require('../middlewares/verificarToken');

const router = express.Router();

const {
    obtenerServicios,
    obtenerServicioPorId,
    crearServicio,
    actualizarServicio,
    eliminarServicio,
    obtenerEmpleadosPorServicio,
    obtenerResenasPorServicio
} = require('../controllers/servicios.controller');

// Verificar que el usuario sea Administrador y su cuenta esté activa.
const autorizarAdministradorActivo = async (req, res, next) => {
    if (Number(req.usuario?.rol) !== 1) {
        return res.status(403).json({
            error: 'Acceso exclusivo del Administrador'
        });
    }

    try {
        const resultado = await pool.query(
            `SELECT 1
             FROM usuarios
             WHERE id_usuario = $1
               AND id_rol = 1
               AND estado = true`,
            [req.usuario.id_usuario]
        );

        if (!resultado.rowCount) {
            return res.status(403).json({
                error: 'Cuenta administrativa no autorizada'
            });
        }

        return next();
    } catch (error) {
        console.error('Error al validar Administrador:', error.message);

        return res.status(500).json({
            error: 'No se pudo comprobar el acceso'
        });
    }
};

// Consultas utilizadas por la aplicación Cliente.
// Se conservan públicas.
router.get('/', obtenerServicios);
router.get('/:id', obtenerServicioPorId);
router.get('/:id/empleados', obtenerEmpleadosPorServicio);
router.get('/:id/resenas', obtenerResenasPorServicio);

// Operaciones exclusivas del Administrador.
router.post(
    '/',
    verificarToken,
    autorizarAdministradorActivo,
    crearServicio
);

router.put(
    '/:id',
    verificarToken,
    autorizarAdministradorActivo,
    actualizarServicio
);

router.delete(
    '/:id',
    verificarToken,
    autorizarAdministradorActivo,
    eliminarServicio
);

module.exports = router;
