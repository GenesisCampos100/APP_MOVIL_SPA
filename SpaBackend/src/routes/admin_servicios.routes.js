const express = require('express');
const verificarToken = require('../middlewares/verificarToken');
const {listarServiciosAdmin} = require('../controllers/admin_servicios.controller');

const router = express.Router();

// NO modificar GET /api/servicios: el catálogo público sigue mostrando solo activos.
router.get('/', verificarToken, (req, res, next) => {
    if (Number(req.usuario?.rol) !== 1) {
        return res.status(403).json({
            error: 'Solo el Administrador puede consultar servicios inactivos'
        });
    }
    return next();
}, listarServiciosAdmin);

module.exports = router;
