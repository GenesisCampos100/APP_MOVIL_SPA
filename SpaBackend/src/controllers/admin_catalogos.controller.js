// Catálogos administrables existentes: categorias y puestos.
// Cada alta requiere un Administrador activo. No se cambian los roles de acceso.
const pool = require('../db');

const nombreValido = (value) => typeof value === 'string' &&
    value.trim().length >= 2 && value.trim().length <= 60;

const validarAdministradorActivo = async (req, res, next) => {
    const id = Number(req.usuario?.id_usuario);
    if (Number(req.usuario?.rol) !== 1 || !Number.isSafeInteger(id) || id <= 0) {
        return res.status(403).json({ error: 'Acceso exclusivo del Administrador.' });
    }
    try {
        const permiso = await pool.query(
            'SELECT 1 FROM usuarios WHERE id_usuario = $1 AND id_rol = 1 AND estado = true',
            [id]);
        if (!permiso.rowCount) {
            return res.status(403).json({ error: 'Cuenta administrativa no autorizada.' });
        }
        return next();
    } catch (error) {
        console.error('Error al verificar Administrador:', error.message);
        return res.status(500).json({ error: 'No se pudo comprobar la autorización.' });
    }
};

const listarCategoriasAdmin = async (_req, res) => {
    try {
        const result = await pool.query(
            'SELECT id_categoria, nombre FROM categorias ORDER BY nombre ASC, id_categoria ASC');
        return res.json(result.rows);
    } catch (error) {
        console.error('Error al consultar categorías:', error.message);
        return res.status(500).json({ error: 'No fue posible consultar las categorías.' });
    }
};

const crearCategoriaAdmin = async (req, res) => {
    if (!nombreValido(req.body?.nombre)) {
        return res.status(400).json({ error: 'Escribe una categoría de 2 a 60 caracteres.' });
    }
    const nombre = req.body.nombre.trim().replace(/\s+/g, ' ');
    try {
        const existente = await pool.query(
            'SELECT id_categoria FROM categorias WHERE LOWER(BTRIM(nombre)) = LOWER($1) LIMIT 1',
            [nombre]);
        if (existente.rowCount) {
            return res.status(409).json({ error: 'Ya existe una categoría con ese nombre.' });
        }
        const creado = await pool.query(
            'INSERT INTO categorias (nombre) VALUES ($1) RETURNING id_categoria, nombre',
            [nombre]);
        return res.status(201).json(creado.rows[0]);
    } catch (error) {
        if (error.code === '23505') {
            return res.status(409).json({ error: 'Ya existe una categoría con ese nombre.' });
        }
        if (error.code === '42501') {
            return res.status(403).json({ error: 'El usuario de la API no tiene permiso para crear categorías.' });
        }
        console.error('Error al registrar categoría:', error.message);
        return res.status(500).json({ error: 'No fue posible registrar la categoría. Revisa la configuración de PostgreSQL.' });
    }
};

const crearPuestoAdmin = async (req, res) => {
    if (!nombreValido(req.body?.nombre)) {
        return res.status(400).json({ error: 'Escribe un puesto de 2 a 60 caracteres.' });
    }
    const nombre = req.body.nombre.trim().replace(/\s+/g, ' ');
    const descripcion = req.body.descripcion == null ? '' : req.body.descripcion;
    if (typeof descripcion !== 'string' || descripcion.trim().length > 200) {
        return res.status(400).json({ error: 'La descripción no debe superar 200 caracteres.' });
    }
    try {
        const existente = await pool.query(
            'SELECT id_puesto FROM puestos WHERE LOWER(BTRIM(nombre)) = LOWER($1) LIMIT 1',
            [nombre]);
        if (existente.rowCount) {
            return res.status(409).json({ error: 'Ya existe un puesto con ese nombre.' });
        }
        const creado = await pool.query(
            'INSERT INTO puestos (nombre, descripcion) VALUES ($1, $2) RETURNING id_puesto, nombre, descripcion',
            [nombre, descripcion.trim() || null]);
        return res.status(201).json(creado.rows[0]);
    } catch (error) {
        if (error.code === '23505') {
            return res.status(409).json({ error: 'Ya existe un puesto con ese nombre.' });
        }
        if (error.code === '42501') {
            return res.status(403).json({ error: 'El usuario de la API no tiene permiso para crear puestos.' });
        }
        console.error('Error al registrar puesto:', error.message);
        return res.status(500).json({ error: 'No fue posible registrar el puesto. Revisa la configuración de PostgreSQL.' });
    }
};

module.exports = {
    validarAdministradorActivo, listarCategoriasAdmin, crearCategoriaAdmin, crearPuestoAdmin,
};
