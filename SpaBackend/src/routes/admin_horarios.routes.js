const express = require('express');
const pool = require('../db');
const verificarToken = require('../middlewares/verificarToken');
const {
  listarHorariosAdmin,
  crearHorarioAdmin,
  crearHorariosVariosAdmin,
  editarHorarioAdmin,
  eliminarHorarioAdmin,
} = require('../controllers/admin_horarios.controller');

const router = express.Router();

// Se aplica a consulta, altas, ediciones y bajas de horarios.
router.use(verificarToken, async (req, res, next) => {
  if (Number(req.usuario?.rol) !== 1) {
    return res.status(403).json({ error: 'Acceso exclusivo del Administrador.' });
  }
  try {
    const resultado = await pool.query(
      'SELECT 1 FROM usuarios WHERE id_usuario = $1 AND id_rol = 1 AND estado = true',
      [req.usuario.id_usuario],
    );
    if (!resultado.rowCount) {
      return res.status(403).json({ error: 'Cuenta administrativa no autorizada.' });
    }
    return next();
  } catch (error) {
    console.error('Error al validar acceso a horarios:', error.message);
    return res.status(500).json({ error: 'No fue posible validar el acceso.' });
  }
});

router.get('/', listarHorariosAdmin);
router.post('/', crearHorarioAdmin);
router.post('/lote', crearHorariosVariosAdmin);
router.put('/:id', editarHorarioAdmin);
router.delete('/:id', eliminarHorarioAdmin);

module.exports = router;
