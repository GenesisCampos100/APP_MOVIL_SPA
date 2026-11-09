const pool = require('../db');

// Catálogo administrativo completo: activos e inactivos.
// La autorización se realiza en admin_servicios.routes.js.
const listarServiciosAdmin = async (req, res) => {
    try {
        const resultado = await pool.query(`
            SELECT
                s.id_servicio,
                s.id_categoria,
                c.nombre AS categoria,
                s.nombre,
                s.descripcion,
                s.duracion,
                s.precio,
                s.imagen,
                s.estado
            FROM servicios s
            INNER JOIN categorias c
                ON c.id_categoria = s.id_categoria
            ORDER BY s.estado DESC, s.nombre ASC, s.id_servicio ASC
        `);
        return res.status(200).json(resultado.rows);
    } catch (error) {
        console.error('Error al consultar el catálogo administrativo:', error.message);
        return res.status(500).json({error: 'No fue posible obtener el catálogo administrativo'});
    }
};

module.exports = {listarServiciosAdmin};
