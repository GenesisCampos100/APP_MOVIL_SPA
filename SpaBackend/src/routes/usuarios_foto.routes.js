'use strict';
const express = require('express');
const verificarToken = require('../middlewares/verificarToken');
const {subirFotoPerfil} = require('../controllers/usuarios_foto.controller');
const router = express.Router();
router.post('/', verificarToken,
    express.raw({type: ['image/jpeg', 'image/png', 'image/webp'], limit: '3mb'}),
    subirFotoPerfil);
module.exports = router;
