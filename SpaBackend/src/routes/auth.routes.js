const express = require('express');
const router = express.Router();

const {
    verificarCorreo,
    login,
    registro,
    verificarCodigo,
    cambiarContrasena
} = require('../controllers/auth.controller');

const loginLimiter = require('../middlewares/loginLimite');
const verificarToken = require('../middlewares/verificarToken');

router.post('/verificar-correo', verificarCorreo);
router.post('/login', loginLimiter, login);
router.post('/registro', registro);
router.post('/verificar-codigo', verificarCodigo);
router.put('/cambiar-contrasena',verificarToken, cambiarContrasena);

module.exports = router;