const express = require('express');
const router = express.Router();

const {
    registrarCita,
    obtenerCitas,
    obtenerCitasCliente,
    apartarHorario,
    confirmarApartado,
    cancelarApartado,
    obtenerDisponibilidad
} = require('../controllers/citas.controller');

const verificarToken = require('../middlewares/verificarToken');

router.post('/', verificarToken, registrarCita);
router.get('/', verificarToken, obtenerCitas);
router.get('/cliente/:id_cliente', verificarToken, obtenerCitasCliente);
router.post('/apartar', verificarToken, apartarHorario);
router.post('/confirmar-apartado', verificarToken, confirmarApartado);
router.delete('/apartar/:id_reserva', verificarToken, cancelarApartado);
router.get('/disponibilidad', obtenerDisponibilidad);

module.exports = router;