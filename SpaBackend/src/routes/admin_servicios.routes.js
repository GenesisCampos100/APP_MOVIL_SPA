const express = require('express');
const verificarToken = require('../middlewares/verificarToken');
const {listarServiciosAdmin} = require('../controllers/admin_servicios.controller');
const { validarAdministradorActivo, listarCategoriasAdmin, crearCategoriaAdmin } =
    require('../controllers/admin_catalogos.controller');

const router = express.Router();

// Catálogo de categorías completo, no deducido a partir de servicios existentes.
router.get('/categorias', verificarToken, validarAdministradorActivo, listarCategoriasAdmin);
router.post('/categorias', verificarToken, validarAdministradorActivo, crearCategoriaAdmin);

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
