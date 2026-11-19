const express = require('express');
const router = express.Router();

const {
    verificarCorreo,
    login,
    registro,
    verificarCodigo,
    cambiarContrasena,
    solicitarRecuperacion,
    verificarCodigoRecuperacion,
    restablecerContrasena
} = require('../controllers/auth.controller');

const loginLimiter = require('../middlewares/loginLimite');
const verificarToken = require('../middlewares/verificarToken');

router.post('/verificar-correo', verificarCorreo);
router.post('/login', loginLimiter, login);
router.post('/registro', registro);
router.post('/verificar-codigo', verificarCodigo);
router.put('/cambiar-contrasena',verificarToken, cambiarContrasena);
router.post('/recuperar/solicitar', solicitarRecuperacion);
router.post('/recuperar/verificar', verificarCodigoRecuperacion);
router.post('/recuperar/restablecer', restablecerContrasena);

module.exports = router;