const express = require('express');
const router = express.Router();

const {
    confirmarCitaAdmin,
    cancelarCitaAdmin,
    registrarCita,
    obtenerCitas,
    obtenerCitasCliente,
    apartarHorario,
    confirmarApartado,
    cancelarApartado,
    obtenerDisponibilidad,
    cancelarCita,
    reagendarCita
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

router.patch('/:id_cita/reagendar', verificarToken, reagendarCita);

router.patch('/:id/estado', verificarToken, confirmarCitaAdmin);

// Cancelación de citas según el rol autenticado.
// Conserva la misma URL para Cliente y Administrador.
router.patch('/:id/cancelar', verificarToken, (req, res) => {
    const rol = Number(req.usuario?.rol);

    // Cliente: solo puede cancelar sus propias citas.
    if (rol === 3) {
        req.params.id_cita = req.params.id;
        return cancelarCita(req, res);
    }

    // Administrador: conserva su controlador actual.
    if (rol === 1) {
        return cancelarCitaAdmin(req, res);
    }

    return res.status(403).json({
        error: 'No tienes permiso para cancelar citas'
    });
});

module.exports = router;