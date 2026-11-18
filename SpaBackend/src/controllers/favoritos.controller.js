const pool = require('../db');

// Obtener el perfil del cliente desde el usuario autenticado.
const obtenerIdCliente = async (id_usuario) => {
    const resultado = await pool.query(
        `SELECT id_cliente
         FROM clientes
         WHERE id_usuario = $1`,
        [id_usuario]
    );

    return resultado.rows.length > 0
        ? resultado.rows[0].id_cliente
        : null;
};


// GET /api/favoritos/servicios
const obtenerServiciosFavoritos = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);

        if (!Number.isInteger(id_usuario) || id_usuario <= 0 || rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden consultar sus favoritos'
            });
        }

        const id_cliente = await obtenerIdCliente(id_usuario);

        if (!id_cliente) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const resultado = await pool.query(
            `SELECT
                s.id_servicio,
                s.id_categoria,
                cat.nombre AS categoria,
                s.nombre,
                s.descripcion,
                s.duracion,
                s.precio,
                s.imagen,
                s.estado
             FROM favoritos_servicios f
             INNER JOIN servicios s
                ON s.id_servicio = f.id_servicio
             LEFT JOIN categorias cat
                ON cat.id_categoria = s.id_categoria
             WHERE f.id_cliente = $1
               AND s.estado = true
             ORDER BY f.fecha DESC, f.id_servicio DESC`,
            [id_cliente]
        );

        return res.status(200).json({
            mensaje: 'Servicios favoritos obtenidos correctamente',
            servicios: resultado.rows
        });

    } catch (error) {
        console.error('Error al obtener servicios favoritos:', error.message);

        return res.status(500).json({
            error: 'Error interno al obtener los servicios favoritos'
        });
    }
};


// GET /api/favoritos/empleados
const obtenerEmpleadosFavoritos = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);

        if (!Number.isInteger(id_usuario) || id_usuario <= 0 || rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden consultar sus favoritos'
            });
        }

        const id_cliente = await obtenerIdCliente(id_usuario);

        if (!id_cliente) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const resultado = await pool.query(
            `SELECT
                e.id_empleado,
                e.nombre,
                e.apellido_p,
                e.apellido_m,
                u.foto,
                p.nombre AS puesto
             FROM favoritos_empleados f
             INNER JOIN empleados e
                ON e.id_empleado = f.id_empleado
             INNER JOIN usuarios u
                ON u.id_usuario = e.id_usuario
             INNER JOIN puestos p
                ON p.id_puesto = e.id_puesto
             WHERE f.id_cliente = $1
               AND u.estado = true
             ORDER BY f.fecha DESC, f.id_empleado DESC`,
            [id_cliente]
        );

        return res.status(200).json({
            mensaje: 'Empleados favoritos obtenidos correctamente',
            empleados: resultado.rows
        });

    } catch (error) {
        console.error('Error al obtener empleados favoritos:', error.message);

        return res.status(500).json({
            error: 'Error interno al obtener los empleados favoritos'
        });
    }
};


// GET /api/favoritos/ids
const obtenerIdsFavoritos = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);

        if (!Number.isInteger(id_usuario) || id_usuario <= 0 || rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden consultar sus favoritos'
            });
        }

        const id_cliente = await obtenerIdCliente(id_usuario);

        if (!id_cliente) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const [servicios, empleados] = await Promise.all([
            pool.query(
                `SELECT id_servicio
                 FROM favoritos_servicios
                 WHERE id_cliente = $1`,
                [id_cliente]
            ),
            pool.query(
                `SELECT id_empleado
                 FROM favoritos_empleados
                 WHERE id_cliente = $1`,
                [id_cliente]
            )
        ]);

        return res.status(200).json({
            servicios: servicios.rows.map(f => Number(f.id_servicio)),
            empleados: empleados.rows.map(f => Number(f.id_empleado))
        });

    } catch (error) {
        console.error('Error al obtener IDs favoritos:', error.message);

        return res.status(500).json({
            error: 'Error interno al obtener los IDs favoritos'
        });
    }
};


// POST /api/favoritos/servicios/:id
const agregarServicioFavorito = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);
        const id_servicio = Number(req.params.id);

        if (!Number.isInteger(id_usuario) || id_usuario <= 0 || rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden agregar favoritos'
            });
        }

        if (!Number.isInteger(id_servicio) || id_servicio <= 0) {
            return res.status(400).json({
                error: 'El ID del servicio no es válido'
            });
        }

        const id_cliente = await obtenerIdCliente(id_usuario);

        if (!id_cliente) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const servicio = await pool.query(
            `SELECT id_servicio
             FROM servicios
             WHERE id_servicio = $1
               AND estado = true`,
            [id_servicio]
        );

        if (servicio.rows.length === 0) {
            return res.status(404).json({
                error: 'El servicio no existe o está inactivo'
            });
        }

        await pool.query(
            `INSERT INTO favoritos_servicios (
                id_cliente,
                id_servicio,
                fecha
             )
             VALUES ($1, $2, CURRENT_DATE)
             ON CONFLICT (id_cliente, id_servicio)
             DO NOTHING`,
            [id_cliente, id_servicio]
        );

        return res.status(200).json({
            mensaje: 'Servicio agregado a favoritos',
            id_servicio
        });

    } catch (error) {
        console.error('Error al agregar servicio favorito:', error.message);

        return res.status(500).json({
            error: 'Error interno al agregar el servicio a favoritos'
        });
    }
};


// DELETE /api/favoritos/servicios/:id
const eliminarServicioFavorito = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);
        const id_servicio = Number(req.params.id);

        if (!Number.isInteger(id_usuario) || id_usuario <= 0 || rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden eliminar favoritos'
            });
        }

        if (!Number.isInteger(id_servicio) || id_servicio <= 0) {
            return res.status(400).json({
                error: 'El ID del servicio no es válido'
            });
        }

        const id_cliente = await obtenerIdCliente(id_usuario);

        if (!id_cliente) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const resultado = await pool.query(
            `DELETE FROM favoritos_servicios
             WHERE id_cliente = $1
               AND id_servicio = $2
             RETURNING id_servicio`,
            [id_cliente, id_servicio]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                error: 'El servicio no estaba en tus favoritos'
            });
        }

        return res.status(200).json({
            mensaje: 'Servicio eliminado de favoritos',
            id_servicio
        });

    } catch (error) {
        console.error('Error al eliminar servicio favorito:', error.message);

        return res.status(500).json({
            error: 'Error interno al eliminar el servicio de favoritos'
        });
    }
};


// POST /api/favoritos/empleados/:id
const agregarEmpleadoFavorito = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);
        const id_empleado = Number(req.params.id);

        if (!Number.isInteger(id_usuario) || id_usuario <= 0 || rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden agregar favoritos'
            });
        }

        if (!Number.isInteger(id_empleado) || id_empleado <= 0) {
            return res.status(400).json({
                error: 'El ID del empleado no es válido'
            });
        }

        const id_cliente = await obtenerIdCliente(id_usuario);

        if (!id_cliente) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const empleado = await pool.query(
            `SELECT e.id_empleado
             FROM empleados e
             INNER JOIN usuarios u
                ON u.id_usuario = e.id_usuario
             WHERE e.id_empleado = $1
               AND u.estado = true`,
            [id_empleado]
        );

        if (empleado.rows.length === 0) {
            return res.status(404).json({
                error: 'El empleado no existe o está inactivo'
            });
        }

        await pool.query(
            `INSERT INTO favoritos_empleados (
                id_cliente,
                id_empleado,
                fecha
             )
             VALUES ($1, $2, CURRENT_DATE)
             ON CONFLICT (id_cliente, id_empleado)
             DO NOTHING`,
            [id_cliente, id_empleado]
        );

        return res.status(200).json({
            mensaje: 'Empleado agregado a favoritos',
            id_empleado
        });

    } catch (error) {
        console.error('Error al agregar empleado favorito:', error.message);

        return res.status(500).json({
            error: 'Error interno al agregar el empleado a favoritos'
        });
    }
};


// DELETE /api/favoritos/empleados/:id
const eliminarEmpleadoFavorito = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);
        const id_empleado = Number(req.params.id);

        if (!Number.isInteger(id_usuario) || id_usuario <= 0 || rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden eliminar favoritos'
            });
        }

        if (!Number.isInteger(id_empleado) || id_empleado <= 0) {
            return res.status(400).json({
                error: 'El ID del empleado no es válido'
            });
        }

        const id_cliente = await obtenerIdCliente(id_usuario);

        if (!id_cliente) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const resultado = await pool.query(
            `DELETE FROM favoritos_empleados
             WHERE id_cliente = $1
               AND id_empleado = $2
             RETURNING id_empleado`,
            [id_cliente, id_empleado]
        );

        if (resultado.rowCount === 0) {
            return res.status(404).json({
                error: 'El empleado no estaba en tus favoritos'
            });
        }

        return res.status(200).json({
            mensaje: 'Empleado eliminado de favoritos',
            id_empleado
        });

    } catch (error) {
        console.error('Error al eliminar empleado favorito:', error.message);

        return res.status(500).json({
            error: 'Error interno al eliminar el empleado de favoritos'
        });
    }
};


module.exports = {
    obtenerServiciosFavoritos,
    obtenerEmpleadosFavoritos,
    obtenerIdsFavoritos,
    agregarServicioFavorito,
    eliminarServicioFavorito,
    agregarEmpleadoFavorito,
    eliminarEmpleadoFavorito
};