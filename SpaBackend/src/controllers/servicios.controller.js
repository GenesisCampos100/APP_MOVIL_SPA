
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

        // Validar campos obligatorios
        if (
            id_categoria === undefined ||
            !nombre ||
            duracion === undefined ||
            precio === undefined
        ) {
            return res.status(400).json({
                error: 'Categoría, nombre, duración y precio son obligatorios'
            });
        }

        // Validar categoría
        const categoriaId = Number(id_categoria);

        if (!Number.isInteger(categoriaId) || categoriaId <= 0) {
            return res.status(400).json({
                error: 'La categoría debe ser un ID válido'
            });
        }

        // Validar nombre
        if (typeof nombre !== 'string' || !nombre.trim()) {
            return res.status(400).json({
                error: 'El nombre del servicio no es válido'
            });
        }

        // Validar duración
        const duracionNumero = Number(duracion);

        if (!Number.isInteger(duracionNumero) || duracionNumero <= 0) {
            return res.status(400).json({
                error: 'La duración debe ser un número entero positivo'
            });
        }

        // Validar precio
        const precioNumero = Number(precio);

        if (!Number.isFinite(precioNumero) || precioNumero < 0) {
            return res.status(400).json({
                error: 'El precio debe ser un número válido y no negativo'
            });
        }

        // Comprobar que la categoría exista
        const categoriaExiste = await pool.query(
            `SELECT id_categoria
            FROM categorias
            WHERE id_categoria = $1`,
            [categoriaId]
        );

        if (categoriaExiste.rows.length === 0) {
            return res.status(404).json({
                error: 'La categoría seleccionada no existe'
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

        // Validar ID del servicio
        const servicioId = Number(id);

        if (!Number.isInteger(servicioId) || servicioId <= 0) {
            return res.status(400).json({
                error: 'El ID del servicio no es válido'
            });
        }

        // Validar campos obligatorios
        if (
            id_categoria === undefined ||
            !nombre ||
            duracion === undefined ||
            precio === undefined
        ) {
            return res.status(400).json({
                error: 'Categoría, nombre, duración y precio son obligatorios'
            });
        }

        // Validar categoría
        const categoriaId = Number(id_categoria);

        if (!Number.isInteger(categoriaId) || categoriaId <= 0) {
            return res.status(400).json({
                error: 'La categoría debe ser un ID válido'
            });
        }

        // Validar nombre
        if (typeof nombre !== 'string' || !nombre.trim()) {
            return res.status(400).json({
                error: 'El nombre del servicio no es válido'
            });
        }

        // Validar duración
        const duracionNumero = Number(duracion);

        if (!Number.isInteger(duracionNumero) || duracionNumero <= 0) {
            return res.status(400).json({
                error: 'La duración debe ser un número entero positivo'
            });
        }

        // Validar precio
        const precioNumero = Number(precio);

        if (!Number.isFinite(precioNumero) || precioNumero < 0) {
            return res.status(400).json({
                error: 'El precio debe ser un número válido y no negativo'
            });
        }

        // Validar estado
        if (estado !== undefined && typeof estado !== 'boolean') {
            return res.status(400).json({
                error: 'El estado debe ser verdadero o falso'
            });
        }

        // Comprobar que la categoría exista
        const categoriaExiste = await pool.query(
            `SELECT id_categoria
            FROM categorias
            WHERE id_categoria = $1`,
            [categoriaId]
        );

        if (categoriaExiste.rows.length === 0) {
            return res.status(404).json({
                error: 'La categoría seleccionada no existe'
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
                categoriaId,
                nombre.trim(),
                descripcion || null,
                duracionNumero,
                precioNumero,
                imagen || null,
                estado === undefined ? null : estado,
                servicioId
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

        // Validar ID del servicio
        const servicioId = Number(id);

        if (!Number.isInteger(servicioId) || servicioId <= 0) {
            return res.status(400).json({
                error: 'El ID del servicio no es válido'
            });
        }

        // Verificar que el servicio exista y esté activo
        const servicioExiste = await pool.query(
            `SELECT id_servicio, nombre, estado
             FROM servicios
             WHERE id_servicio = $1`,
            [servicioId]
        );

        if (servicioExiste.rows.length === 0) {
            return res.status(404).json({
                error: 'Servicio no encontrado'
            });
        }

        if (servicioExiste.rows[0].estado === false) {
            return res.status(409).json({
                error: 'El servicio ya se encuentra desactivado'
            });
        }

        // Desactivar servicio
        const result = await pool.query(
            `UPDATE servicios
             SET estado = false
             WHERE id_servicio = $1
             RETURNING id_servicio, nombre, estado`,
            [servicioId]
        );

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

        // Validar ID del servicio
        const servicioId = Number(id);

        if (!Number.isInteger(servicioId) || servicioId <= 0) {
            return res.status(400).json({
                error: 'El ID del servicio debe ser válido'
            });
        }

        // Verificar que el servicio exista y esté activo
        const servicioExiste = await pool.query(
            `SELECT id_servicio
             FROM servicios
             WHERE id_servicio = $1
               AND estado = true`,
            [servicioId]
        );

        if (servicioExiste.rows.length === 0) {
            return res.status(404).json({
                error: 'Servicio no encontrado o desactivado'
            });
        }

        // Obtener empleados activos asignados al servicio
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
             INNER JOIN usuarios u
                ON u.id_usuario = e.id_usuario
             WHERE es.id_servicio = $1
               AND u.estado = true
             ORDER BY e.nombre, e.apellido_p`,
            [servicioId]
        );

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

