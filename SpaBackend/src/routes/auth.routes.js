const express = require('express');
const router = express.Router();

const {
    verificarCorreo,
    login,
    registro,
    verificarCodigo
} = require('../controllers/auth.controller');

router.post('/verificar-correo', verificarCorreo);
router.post('/login', login);
router.post('/registro', registro);
router.post('/verificar-codigo', verificarCodigo);

module.exports = router;