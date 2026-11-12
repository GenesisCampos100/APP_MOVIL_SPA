
const express = require('express');
const router = express.Router();

const verificarToken = require('../middlewares/verificarToken');

const {
    obtenerPerfil,
    actualizarPerfil,
    solicitarCambioCorreo,
    verificarCambioCorreo
} = require('../controllers/usuarios.controller');

router.get('/perfil', verificarToken, obtenerPerfil);
router.put('/perfil', verificarToken, actualizarPerfil);
router.post('/perfil/cambiar-correo', verificarToken, solicitarCambioCorreo);
router.post('/perfil/verificar-cambio-correo', verificarToken, verificarCambioCorreo);

module.exports = router;
