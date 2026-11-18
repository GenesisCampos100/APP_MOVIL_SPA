const express = require('express');
const router = express.Router();

const {
    obtenerServiciosFavoritos,
    obtenerEmpleadosFavoritos,
    obtenerIdsFavoritos,
    agregarServicioFavorito,
    eliminarServicioFavorito,
    agregarEmpleadoFavorito,
    eliminarEmpleadoFavorito
} = require('../controllers/favoritos.controller');

const verificarToken = require('../middlewares/verificarToken');

// Consultas
router.get('/servicios', verificarToken, obtenerServiciosFavoritos);
router.get('/empleados', verificarToken, obtenerEmpleadosFavoritos);
router.get('/ids', verificarToken, obtenerIdsFavoritos);

// Servicios
router.post('/servicios/:id', verificarToken, agregarServicioFavorito);
router.delete('/servicios/:id', verificarToken, eliminarServicioFavorito);

// Empleados
router.post('/empleados/:id', verificarToken, agregarEmpleadoFavorito);
router.delete('/empleados/:id', verificarToken, eliminarEmpleadoFavorito);

module.exports = router;