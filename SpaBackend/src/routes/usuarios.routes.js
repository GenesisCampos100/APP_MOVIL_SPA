
const express = require('express');
const router = express.Router();

const verificarToken = require('../middlewares/verificarToken');

const {
    obtenerPerfil,
    actualizarPerfil
} = require('../controllers/usuarios.controller');

router.get('/perfil', verificarToken, obtenerPerfil);
router.put('/perfil', verificarToken, actualizarPerfil);

module.exports = router;
