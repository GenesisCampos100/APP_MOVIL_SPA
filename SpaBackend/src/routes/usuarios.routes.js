
const express = require('express');
const router = express.Router();

const verificarToken = require('../middlewares/verificarToken');
const recibirFoto = require('../middlewares/subirFoto');

const {
    obtenerPerfil,
    actualizarPerfil,
    solicitarCambioCorreo,
    verificarCambioCorreo,
    subirFoto,
    eliminarFoto
} = require('../controllers/usuarios.controller');

router.get('/perfil', verificarToken, obtenerPerfil);
router.put('/perfil', verificarToken, actualizarPerfil);
router.put('/perfil/foto', verificarToken, recibirFoto, subirFoto);
router.delete('/perfil/foto', verificarToken, eliminarFoto);
router.post('/perfil/cambiar-correo', verificarToken, solicitarCambioCorreo);
router.post('/perfil/verificar-cambio-correo', verificarToken, verificarCambioCorreo);


module.exports = router;
