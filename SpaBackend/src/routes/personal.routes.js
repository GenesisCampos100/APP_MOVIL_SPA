// Funciones exclusivas del personal de recepción.
// No modifica las rutas /api/citas utilizadas por la app Cliente.
const express = require('express');
const router = express.Router();
const verificarToken = require('../middlewares/verificarToken');
const { obtenerAgendaRecepcion } = require('../controllers/personal.controller');

router.get('/agenda', verificarToken, obtenerAgendaRecepcion);

module.exports = router;
