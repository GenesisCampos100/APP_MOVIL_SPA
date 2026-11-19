// Funciones exclusivas del personal de recepción.
// No modifica las rutas /api/citas utilizadas por la app Cliente.
const express = require('express');
const router = express.Router();
const verificarToken = require('../middlewares/verificarToken');
const { obtenerAgendaRecepcion } = require('../controllers/personal.controller');
const citasManuales = require('../controllers/citas_manuales.controller');
const inasistencias = require('../controllers/inasistencias.controller');

router.get('/agenda', verificarToken, obtenerAgendaRecepcion);
router.get('/citas-manuales/catalogo', verificarToken, citasManuales.catalogo);
router.get('/citas-manuales/clientes', verificarToken, citasManuales.buscarClientes);
router.get('/citas-manuales/disponibilidad', verificarToken, citasManuales.disponibilidad);
router.post('/citas-manuales', verificarToken, citasManuales.crearCitaManual);
router.post('/citas-manuales/sin-cuenta', verificarToken, citasManuales.crearCitaManualSinCuenta);
// Acciones explícitas del personal; no alteran las rutas /api/citas de app_cliente.
router.patch('/citas-manuales/:id/confirmar', verificarToken, citasManuales.confirmarCitaPersonal);
// Registra la asistencia comunicada realmente por el cliente, sin aceptar la reserva otra vez.
router.patch('/citas-manuales/:id/confirmar-asistencia', verificarToken, citasManuales.registrarAsistenciaVerbal);
router.patch('/citas-manuales/:id/cancelar', verificarToken, citasManuales.cancelarCitaPersonal);
router.patch('/citas-manuales/:id/completar', verificarToken, citasManuales.completarCitaPersonal);

// Rutas exclusivas de personal: nunca modifican /api/citas de app_cliente.
router.get('/citas-manuales/:id/reprogramacion', verificarToken, citasManuales.detalleParaReprogramar);
router.get('/citas-manuales/:id/reprogramacion/disponibilidad', verificarToken, citasManuales.disponibilidadReprogramacion);
router.patch('/citas-manuales/:id/reprogramar', verificarToken, citasManuales.reprogramarCitaPersonal);

// Etapa 3B: inasistencia reportada como Cancelada, validada por la API.
router.get('/citas-manuales/inasistencias-habilitadas', verificarToken, inasistencias.inasistenciasHabilitadas);
router.patch('/citas-manuales/:id/reportar-inasistencia', verificarToken, inasistencias.reportarInasistencia);
module.exports = router;
