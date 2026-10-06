const express = require('express');
const router = express.Router();

const {
    verificarCorreo,
    login,
    registro
} = require('../controllers/auth.controller');

router.post('/verificar-correo', verificarCorreo);
router.post('/login', login);
router.post('/registro', registro);

module.exports = router;