
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


// GET /api/servicios
router.get('/', obtenerServicios);

// GET /api/servicios/:id
router.get('/:id', obtenerServicioPorId);

// POST /api/servicios
router.post('/', crearServicio);

// PUT /api/servicios/:id
router.put('/:id', actualizarServicio);

// DELETE /api/servicios/:id
router.delete('/:id', eliminarServicio);

// GET /api/servicios/:id/empleados
router.get('/:id/empleados', obtenerEmpleadosPorServicio);


module.exports = router;

