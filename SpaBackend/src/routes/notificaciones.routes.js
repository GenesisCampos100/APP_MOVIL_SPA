const express = require('express');
const router = express.Router();

const {
    obtenerNotificaciones,
    marcarNotificacionLeida,
    marcarTodasLeidas
} = require('../controllers/notificaciones.controller');

const verificarToken = require('../middlewares/verificarToken');

router.get('/', verificarToken, obtenerNotificaciones);
router.patch('/:id_notificacion/leida', verificarToken, marcarNotificacionLeida);
router.patch('/leidas', verificarToken, marcarTodasLeidas);

module.exports = router;