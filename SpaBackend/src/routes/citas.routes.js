const express = require('express');
const router = express.Router();

const {
    registrarCita,
    obtenerCitas,
    obtenerCitasCliente
} = require('../controllers/citas.controller');

const verificarToken = require('../middlewares/verificarToken');

router.post('/', verificarToken, registrarCita);
router.get('/', verificarToken, obtenerCitas);
router.get('/cliente/:id_cliente', verificarToken, obtenerCitasCliente);

module.exports = router;