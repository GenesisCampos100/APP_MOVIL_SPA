
const express = require('express');
const router = express.Router();

const verificarToken = require('../middlewares/verificarToken');

router.get('/privada', verificarToken, (req, res) => {
    res.status(200).json({
        mensaje: 'Acceso autorizado',
        usuario: req.usuario
    });
});

module.exports = router;
