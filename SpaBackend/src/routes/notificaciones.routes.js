const express = require('express');
const router = express.Router();

const {
    obtenerNotificaciones,
    marcarNotificacionLeida,
    marcarTodasLeidas,
    eliminarNotificacion,
    eliminarNotificaciones
} = require('../controllers/notificaciones.controller');

const verificarToken = require('../middlewares/verificarToken');

router.get('/', verificarToken, obtenerNotificaciones);
router.delete('/', verificarToken, eliminarNotificaciones);
router.patch('/:id_notificacion/leida', verificarToken, marcarNotificacionLeida);
router.patch('/leidas', verificarToken, marcarTodasLeidas);
router.delete('/:id_notificacion', verificarToken, eliminarNotificacion);

module.exports = router;