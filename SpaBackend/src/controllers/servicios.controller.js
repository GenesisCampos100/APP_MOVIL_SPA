
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

// CONSULTAR SERVICIOS MÁS POPULARES DEL MES

const obtenerServiciosDestacados = async (req, res) => {
    try {
        const result = await pool.query(
            `SELECT
                s.id_servicio,
                s.id_categoria,
                cat.nombre AS categoria,
                s.nombre,
                s.descripcion,
                s.duracion,
                s.precio,
                s.imagen,
                s.estado,
                COUNT(c.id_cita)::int AS total_citas
             FROM servicios s
             INNER JOIN categorias cat
                ON cat.id_categoria = s.id_categoria
             INNER JOIN citas c
                ON c.id_servicio = s.id_servicio
             WHERE s.estado = true
               AND c.estado IN ('Confirmada', 'Completada')
               AND c.fecha >= DATE_TRUNC('month', CURRENT_DATE)::date
               AND c.fecha < (
                   DATE_TRUNC('month', CURRENT_DATE)
                   + INTERVAL '1 month'
               )::date
             GROUP BY
                s.id_servicio,
                s.id_categoria,
                cat.nombre
             ORDER BY
                total_citas DESC,
                s.nombre ASC
             LIMIT 6`
        );

        return res.json(result.rows);

    } catch (error) {
        console.error(
            'Error al obtener servicios destacados:',
            error.message
        );

        return res.status(500).json({
            error: 'Error al obtener los servicios destacados'
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



const obtenerResenasPorServicio = async (req, res) => {
    try {
        const servicioId = Number(req.params.id);

        // Validar ID del servicio.
        if (!Number.isInteger(servicioId) || servicioId <= 0) {
            return res.status(400).json({
                error: 'El ID del servicio no es válido'
            });
        }

        // Comprobar que el servicio exista.
        const servicioExiste = await pool.query(
            `SELECT id_servicio
             FROM servicios
             WHERE id_servicio = $1`,
            [servicioId]
        );

        if (!servicioExiste.rowCount) {
            return res.status(404).json({
                error: 'Servicio no encontrado'
            });
        }

        // Obtener reseñas.
        const result = await pool.query(
            `SELECT
                r.id_resena,
                r.id_cita,
                r.calificacion_ser,
                r.calificacion_emp,
                r.comentario,
                r.aspectos,
                r.fecha,
                CONCAT(cl.nombre, ' ', cl.apellido_p) AS autor,
                CONCAT(e.nombre, ' ', e.apellido_p) AS empleado_nombre,
                cat.nombre AS servicio_categoria
             FROM resenas r
             INNER JOIN citas c
                ON c.id_cita = r.id_cita
             INNER JOIN clientes cl
                ON cl.id_cliente = c.id_cliente
             INNER JOIN empleados e
                ON e.id_empleado = c.id_empleado
             INNER JOIN servicios s
                ON s.id_servicio = c.id_servicio
             INNER JOIN categorias cat
                ON cat.id_categoria = s.id_categoria
             WHERE c.id_servicio = $1
             ORDER BY r.fecha DESC, r.id_resena DESC`,
            [servicioId]
        );

        // Calcular promedios.
        const resumen = await pool.query(
            `SELECT
                COUNT(*)::int AS total_resenas,
                COALESCE(
                    ROUND(AVG(r.calificacion_ser)::numeric, 1),
                    0
                )::float AS promedio_servicio,
                COALESCE(
                    ROUND(AVG(r.calificacion_emp)::numeric, 1),
                    0
                )::float AS promedio_empleado
             FROM resenas r
             INNER JOIN citas c
                ON c.id_cita = r.id_cita
             WHERE c.id_servicio = $1`,
            [servicioId]
        );

        return res.json({
            resenas: result.rows,
            resumen: resumen.rows[0]
        });

    } catch (error) {
        console.error(
            'Error al obtener reseñas del servicio:',
            error.message
        );

        return res.status(500).json({
            error: 'Error al obtener las reseñas del servicio'
        });
    }
};


const crearResena = async (req, res) => {
    const client = await pool.connect();
    let transaccionIniciada = false;

    try {
        const servicioId = Number(req.params.id);
        const usuarioId = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);

        const {
            id_cita,
            calificacion,
            comentario,
            aspectos
        } = req.body;

        // Solo los clientes pueden publicar reseñas.
        if (rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden publicar reseñas'
            });
        }

        // Validar identificadores.
        const citaId = Number(id_cita);

        if (
            !Number.isInteger(servicioId) || servicioId <= 0 ||
            !Number.isInteger(citaId) || citaId <= 0 ||
            !Number.isInteger(usuarioId) || usuarioId <= 0
        ) {
            return res.status(400).json({
                error: 'Los identificadores proporcionados no son válidos'
            });
        }

        // Validar calificación.
        const calificacionNumero = Number(calificacion);

        if (
            !Number.isInteger(calificacionNumero) ||
            calificacionNumero < 1 ||
            calificacionNumero > 5
        ) {
            return res.status(400).json({
                error: 'La calificación debe estar entre 1 y 5'
            });
        }

        // Validar comentario.
        if (
            comentario !== undefined &&
            comentario !== null &&
            (
                typeof comentario !== 'string' ||
                comentario.trim().length > 200
            )
        ) {
            return res.status(400).json({
                error: 'El comentario no puede superar los 200 caracteres'
            });
        }

        // Validar aspectos.
        const aspectosPermitidos = [
            'atencion',
            'limpieza',
            'resultado',
            'puntualidad',
            'instalaciones'
        ];

        if (
            aspectos !== undefined &&
            (
                !Array.isArray(aspectos) ||
                aspectos.some(
                    aspecto =>
                        typeof aspecto !== 'string' ||
                        !aspectosPermitidos.includes(aspecto)
                ) ||
                new Set(aspectos).size !== aspectos.length
            )
        ) {
            return res.status(400).json({
                error: 'Los aspectos seleccionados no son válidos'
            });
        }

        await client.query('BEGIN');
        transaccionIniciada = true;

        // Verificar que la cita pertenezca al cliente autenticado.
        // Se bloquea la cita para evitar publicaciones simultáneas.
        const citaResult = await client.query(
            `SELECT
                c.id_cita,
                c.id_cliente,
                c.id_servicio,
                c.estado
             FROM citas c
             INNER JOIN clientes cl
                ON cl.id_cliente = c.id_cliente
             WHERE c.id_cita = $1
               AND cl.id_usuario = $2
             FOR UPDATE OF c`,
            [citaId, usuarioId]
        );

        if (!citaResult.rowCount) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(404).json({
                error: 'La cita no existe o no te pertenece'
            });
        }

        const cita = citaResult.rows[0];

        // Comprobar que la cita corresponda al servicio.
        if (Number(cita.id_servicio) !== servicioId) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(400).json({
                error: 'La cita no corresponde a este servicio'
            });
        }

        // Solo se permiten reseñas de citas completadas.
        if (cita.estado !== 'Completada') {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(409).json({
                error: 'Solo puedes reseñar citas completadas'
            });
        }

        // Evitar que una cita tenga más de una reseña.
        const resenaExistente = await client.query(
            `SELECT id_resena
             FROM resenas
             WHERE id_cita = $1`,
            [citaId]
        );

        if (resenaExistente.rowCount) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(409).json({
                error: 'Esta cita ya tiene una reseña'
            });
        }

        // Registrar la reseña.
        const resultado = await client.query(
            `INSERT INTO resenas (
                id_cita,
                calificacion_ser,
                calificacion_emp,
                comentario,
                fecha,
                aspectos
             )
             VALUES ($1, $2, $2, $3, CURRENT_DATE, $4)
             RETURNING
                id_resena,
                id_cita,
                calificacion_ser,
                calificacion_emp,
                comentario,
                fecha,
                aspectos`,
            [
                citaId,
                calificacionNumero,
                comentario?.trim() || null,
                aspectos || []
            ]
        );

        await client.query('COMMIT');
        transaccionIniciada = false;

        return res.status(201).json({
            mensaje: 'Reseña publicada correctamente',
            resena: resultado.rows[0]
        });

    } catch (error) {
        if (transaccionIniciada) {
            await client.query('ROLLBACK');
        }

        console.error('Error al publicar reseña:', error.message);

        return res.status(500).json({
            error: 'No se pudo publicar la reseña'
        });

    } finally {
        client.release();
    }
};





module.exports = {
    obtenerServicios,
    obtenerServicioPorId,
    crearServicio,
    actualizarServicio,
    eliminarServicio,
    obtenerEmpleadosPorServicio,
    obtenerResenasPorServicio,
    obtenerServiciosDestacados,
    crearResena
};

