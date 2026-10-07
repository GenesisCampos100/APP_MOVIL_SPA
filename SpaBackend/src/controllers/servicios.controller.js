
const pool = require('../db');


// CONSULTAR TODOS LOS SERVICIOS

const obtenerServicios = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
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
             WHERE s.estado = true
             ORDER BY s.id_servicio`
        );

        return res.json(result.rows);

    } catch (error) {
        console.error('Error al obtener servicios:', error.message);

        return res.status(500).json({
            error: 'Error al obtener los servicios'
        });
    }
};


// CONSULTAR UN SERVICIO POR ID

const obtenerServicioPorId = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `SELECT
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
             WHERE s.id_servicio = $1
               AND s.estado = true`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'Servicio no encontrado'
            });
        }

        return res.json(result.rows[0]);

    } catch (error) {
        console.error('Error al obtener servicio:', error.message);

        return res.status(500).json({
            error: 'Error al obtener el servicio'
        });
    }
};



// REGISTRAR SERVICIO

const crearServicio = async (req, res) => {
    try {
        const {
            id_categoria,
            nombre,
            descripcion,
            duracion,
            precio,
            imagen
        } = req.body;

        if (!id_categoria || !nombre || !duracion || precio === undefined) {
            return res.status(400).json({
                error: 'Categoría, nombre, duración y precio son obligatorios'
            });
        }

        const result = await pool.query(
            `INSERT INTO servicios (
                id_categoria,
                nombre,
                descripcion,
                duracion,
                precio,
                imagen,
                estado
            )
            VALUES ($1, $2, $3, $4, $5, $6, true)
            RETURNING
                id_servicio,
                id_categoria,
                nombre,
                descripcion,
                duracion,
                precio,
                imagen,
                estado`,
            [
                id_categoria,
                nombre,
                descripcion || null,
                duracion,
                precio,
                imagen || null
            ]
        );

        return res.status(201).json({
            mensaje: 'Servicio creado correctamente',
            servicio: result.rows[0]
        });

    } catch (error) {
        console.error('Error al crear servicio:', error.message);

        return res.status(500).json({
            error: 'Error al crear el servicio'
        });
    }
};



// MODIFICAR SERVICIO

const actualizarServicio = async (req, res) => {
    try {
        const { id } = req.params;

        const {
            id_categoria,
            nombre,
            descripcion,
            duracion,
            precio,
            imagen,
            estado
        } = req.body;

        if (!id_categoria || !nombre || !duracion || precio === undefined) {
            return res.status(400).json({
                error: 'Categoría, nombre, duración y precio son obligatorios'
            });
        }

        const result = await pool.query(
            `UPDATE servicios
             SET
                id_categoria = $1,
                nombre = $2,
                descripcion = $3,
                duracion = $4,
                precio = $5,
                imagen = $6,
                estado = COALESCE($7, estado)
             WHERE id_servicio = $8
             RETURNING
                id_servicio,
                id_categoria,
                nombre,
                descripcion,
                duracion,
                precio,
                imagen,
                estado`,
            [
                id_categoria,
                nombre,
                descripcion || null,
                duracion,
                precio,
                imagen || null,
                estado,
                id
            ]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'Servicio no encontrado'
            });
        }

        return res.json({
            mensaje: 'Servicio actualizado correctamente',
            servicio: result.rows[0]
        });

    } catch (error) {
        console.error('Error al actualizar servicio:', error.message);

        return res.status(500).json({
            error: 'Error al actualizar el servicio'
        });
    }
};



// DESACTIVAR SERVICIO

const eliminarServicio = async (req, res) => {
    try {
        const { id } = req.params;

        const result = await pool.query(
            `UPDATE servicios
             SET estado = false
             WHERE id_servicio = $1
             RETURNING id_servicio, nombre, estado`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'Servicio no encontrado'
            });
        }

        return res.json({
            mensaje: 'Servicio desactivado correctamente',
            servicio: result.rows[0]
        });

    } catch (error) {
        console.error('Error al desactivar servicio:', error.message);

        return res.status(500).json({
            error: 'Error al desactivar el servicio'
        });
    }
};

const obtenerEmpleadosPorServicio = async (req, res) => {
    try {
        const { id } = req.params;

        // Validar que el ID sea numérico
        if (!id || isNaN(id)) {
            return res.status(400).json({
                error: 'El ID del servicio debe ser válido'
            });
        }

        const result = await pool.query(
            `SELECT
                e.id_empleado,
                e.nombre,
                e.apellido_p,
                e.apellido_m,
                e.telefono
             FROM empleados e
             INNER JOIN empleado_servicios es
                ON es.id_empleado = e.id_empleado
             INNER JOIN servicios s
                ON s.id_servicio = es.id_servicio
             INNER JOIN usuarios u
                ON u.id_usuario = e.id_usuario
             WHERE es.id_servicio = $1
               AND u.estado = true
             ORDER BY e.nombre, e.apellido_p`,
            [id]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'No hay empleados disponibles para este servicio'
            });
        }

        return res.json({
            empleados: result.rows
        });

    } catch (error) {
        console.error(
            'Error al obtener empleados por servicio:',
            error.message
        );

        return res.status(500).json({
            error: 'Error al obtener los empleados del servicio'
        });
    }
};


module.exports = {
    obtenerServicios,
    obtenerServicioPorId,
    crearServicio,
    actualizarServicio,
    eliminarServicio,
    obtenerEmpleadosPorServicio
};

