const express = require('express');
const router = express.Router();

const {
    registrarCita,
    obtenerCitas,
    obtenerCitasCliente,
    apartarHorario,
    confirmarApartado,
    cancelarApartado,
    obtenerDisponibilidad,
    cancelarCita,
    reagendarCita,
    confirmarCita
} = require('../controllers/citas.controller');

const verificarToken = require('../middlewares/verificarToken');

router.post('/', verificarToken, registrarCita);
router.get('/', verificarToken, obtenerCitas);
router.get('/cliente/:id_cliente', verificarToken, obtenerCitasCliente);
router.post('/apartar', verificarToken, apartarHorario);
router.post('/confirmar-apartado', verificarToken, confirmarApartado);
router.delete('/apartar/:id_reserva', verificarToken, cancelarApartado);
router.get(
    '/disponibilidad',
    (req, res, next) => {
        if (req.query.id_cita) {
            return verificarToken(req, res, next);
        }

        next();
    },
    obtenerDisponibilidad
);
router.patch('/:id_cita/cancelar', verificarToken, cancelarCita);
router.patch('/:id_cita/reagendar', verificarToken, reagendarCita);
router.patch('/:id_cita/confirmar', verificarToken, confirmarCita);

module.exports = router;