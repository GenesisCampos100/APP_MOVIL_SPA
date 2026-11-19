
const express = require('express');
const router = express.Router();

const {
    registrarDispositivo
} = require('../controllers/dispositivos.controller');

const verificarToken = require('../middlewares/verificarToken');

router.post('/', verificarToken, registrarDispositivo);

module.exports = router;
