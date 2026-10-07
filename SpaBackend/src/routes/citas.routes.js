const express = require('express');
const router = express.Router();

const {
    registrarCita,
    obtenerCitas
} = require('../controllers/citas.controller');

router.post('/', registrarCita);
router.get('/', obtenerCitas);

module.exports = router;