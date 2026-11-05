
const express = require('express');
const router = express.Router();

const {
    obtenerServicios,
    obtenerServicioPorId,
    crearServicio,
    actualizarServicio,
    eliminarServicio,
    obtenerEmpleadosPorServicio
} = require('../controllers/servicios.controller');

const verificarToken = require('../middlewares/verificarToken');

// Solo el administrador puede modificar servicios
const verificarAdministrador = (req, res, next) => {
    if (Number(req.usuario?.rol) !== 1) {
        return res.status(403).json({
            error: 'No tienes permiso para realizar esta operación'
        });
    }

    next();
};

// Consultar servicios: público
router.get('/', obtenerServicios);
router.get('/:id', obtenerServicioPorId);
router.get('/:id/empleados', obtenerEmpleadosPorServicio);

// Crear, actualizar y eliminar: solo administrador autenticado
router.post('/', verificarToken, verificarAdministrador, crearServicio);
router.put('/:id', verificarToken, verificarAdministrador, actualizarServicio);
router.delete('/:id', verificarToken, verificarAdministrador, eliminarServicio);

module.exports = router;
