const express = require('express');
const router = express.Router();

const {
    registrarCita,
    obtenerCitas,
    obtenerCitasCliente
} = require('../controllers/citas.controller');

router.post('/', registrarCita);
router.get('/', obtenerCitas);
router.get('/cliente/:id_cliente', obtenerCitasCliente);

module.exports = router;