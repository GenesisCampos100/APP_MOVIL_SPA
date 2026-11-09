
const pool = require('../db');

// CONSULTAR PERFIL DEL USUARIO AUTENTICADO
const obtenerPerfil = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;

        const result = await pool.query(
            `SELECT
                u.id_usuario,
                u.correo,
                u.foto,
                u.id_rol,
                r.nombre AS rol,

                c.id_cliente,
                e.id_empleado,

                COALESCE(c.nombre, e.nombre) AS nombre,
                COALESCE(c.apellido_p, e.apellido_p) AS apellido_p,
                COALESCE(c.apellido_m, e.apellido_m) AS apellido_m,
                COALESCE(c.telefono, e.telefono) AS telefono,

                c.fecha_nacimiento,
                e.fecha_ingreso,
                e.id_puesto

            FROM usuarios u

            INNER JOIN roles r
                ON r.id_rol = u.id_rol

            LEFT JOIN clientes c
                ON c.id_usuario = u.id_usuario

            LEFT JOIN empleados e
                ON e.id_usuario = u.id_usuario

            WHERE u.id_usuario = $1
              AND u.estado = true`,

            [id_usuario]
        );

        if (result.rows.length === 0) {
            return res.status(404).json({
                error: 'No se encontró el perfil del usuario'
            });
        }

        return res.status(200).json({
            mensaje: 'Perfil obtenido correctamente',
            usuario: result.rows[0]
        });

    } catch (error) {
        console.error('Error al obtener perfil:', error.message);

        return res.status(500).json({
            error: 'Error al consultar el perfil'
        });
    }
};

// ACTUALIZAR PERFIL DEL USUARIO AUTENTICADO
const actualizarPerfil = async (req, res) => {
    let client;
    let transaccionIniciada = false;

    try {
        const id_usuario = req.usuario.id_usuario;
        const datos = req.body;

        if (!datos || typeof datos !== 'object' || Array.isArray(datos)) {
            return res.status(400).json({
                error: 'Debes proporcionar los datos del perfil'
            });
        }

        if (Object.keys(datos).length === 0) {
            return res.status(400).json({
                error: 'Debes proporcionar al menos un campo para actualizar'
            });
        }

        client = await pool.connect();

        await client.query('BEGIN');
        transaccionIniciada = true;

        // Consultar el rol real y comprobar que la cuenta esté activa.
        const usuarioResult = await client.query(
            `SELECT id_rol
             FROM usuarios
             WHERE id_usuario = $1
               AND estado = true
             FOR UPDATE`,
            [id_usuario]
        );

        if (usuarioResult.rows.length === 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(404).json({
                error: 'No se encontró un usuario activo'
            });
        }

        const rol = Number(usuarioResult.rows[0].id_rol);

        // Campos que puede modificar cada rol.
        const camposPorRol = {
            1: ['nombre', 'apellido_p', 'apellido_m', 'foto'],
            2: ['nombre', 'apellido_p', 'apellido_m', 'foto'],
            3: ['nombre', 'apellido_p', 'apellido_m', 'foto']
        };

        const camposPermitidos = camposPorRol[rol];

        if (!camposPermitidos) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(403).json({
                error: 'El rol del usuario no está permitido'
            });
        }

        // Rechazar campos que no corresponden al rol.
        const camposRecibidos = Object.keys(datos);

        const campoNoPermitido = camposRecibidos.find(
            campo => !camposPermitidos.includes(campo)
        );

        if (campoNoPermitido) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(400).json({
                error: `No puedes modificar el campo: ${campoNoPermitido}`
            });
        }

        // Validar y normalizar los datos recibidos.
        const valores = {};

        for (const campo of camposRecibidos) {
            const valor = datos[campo];

            if (['nombre', 'apellido_p'].includes(campo)) {
                if (
                    typeof valor !== 'string' ||
                    !valor.trim() ||
                    valor.trim().length > 100
                ) {
                    return await responderError(
                        client,
                        res,
                        400,
                        `El campo ${campo} no es válido`
                    );
                }

                valores[campo] = valor.trim();
            }

            else if (campo === 'apellido_m') {
                if (valor !== null && (
                    typeof valor !== 'string' ||
                    valor.trim().length > 100
                )) {
                    return await responderError(
                        client,
                        res,
                        400,
                        'El apellido materno no es válido'
                    );
                }

                valores[campo] = valor === null
                    ? null
                    : valor.trim() || null;
            }

            else if (campo === 'telefono') {
                if (valor !== null && (
                    typeof valor !== 'string' ||
                    valor.trim().length > 15
                )) {
                    return await responderError(
                        client,
                        res,
                        400,
                        'El teléfono no es válido'
                    );
                }

                valores[campo] = valor === null
                    ? null
                    : valor.trim() || null;
            }

            else if (campo === 'fecha_nacimiento') {
                if (valor !== null) {
                    if (
                        typeof valor !== 'string' ||
                        !/^\d{4}-\d{2}-\d{2}$/.test(valor)
                    ) {
                        return await responderError(
                            client,
                            res,
                            400,
                            'La fecha debe tener el formato YYYY-MM-DD'
                        );
                    }

                    const fecha = new Date(`${valor}T00:00:00Z`);

                    if (
                        Number.isNaN(fecha.getTime()) ||
                        fecha.toISOString().slice(0, 10) !== valor
                    ) {
                        return await responderError(
                            client,
                            res,
                            400,
                            'La fecha de nacimiento no es válida'
                        );
                    }
                }

                valores[campo] = valor;
            }

            else if (campo === 'foto') {
                if (
                    valor !== null &&
                    (typeof valor !== 'string' || valor.length > 2048)
                ) {
                    return await responderError(
                        client,
                        res,
                        400,
                        'La foto no es válida'
                    );
                }

                valores[campo] = valor === null ? null : valor.trim() || null;
            }
        }

        // Actualizar datos generales del usuario.
        if (Object.hasOwn(valores, 'foto')) {
            await client.query(
                `UPDATE usuarios
                 SET foto = $1
                 WHERE id_usuario = $2`,
                [valores.foto, id_usuario]
            );
        }

        // Actualizar información específica del cliente.
        if (rol === 3) {
            const campos = [
                'nombre',
                'apellido_p',
                'apellido_m',
                'telefono',
                'fecha_nacimiento'
            ];

            const actualizaciones = campos.filter(
                campo => Object.hasOwn(valores, campo)
            );

            if (actualizaciones.length > 0) {
                const set = actualizaciones
                    .map((campo, i) => `"${campo}" = $${i + 1}`)
                    .join(', ');

                const params = actualizaciones.map(
                    campo => valores[campo]
                );

                params.push(id_usuario);

                const resultado = await client.query(
                    `UPDATE clientes
                     SET ${set}
                     WHERE id_usuario = $${params.length}`,
                    params
                );

                if (resultado.rowCount === 0) {
                    return await responderError(
                        client,
                        res,
                        404,
                        'No se encontró el perfil del cliente'
                    );
                }
            }
        }

        // Actualizar información específica del empleado.
        if (rol === 2) {
            const campos = [
                'nombre',
                'apellido_p',
                'apellido_m',
                'telefono'
            ];

            const actualizaciones = campos.filter(
                campo => Object.hasOwn(valores, campo)
            );

            if (actualizaciones.length > 0) {
                const set = actualizaciones
                    .map((campo, i) => `"${campo}" = $${i + 1}`)
                    .join(', ');

                const params = actualizaciones.map(
                    campo => valores[campo]
                );

                params.push(id_usuario);

                const resultado = await client.query(
                    `UPDATE empleados
                     SET ${set}
                     WHERE id_usuario = $${params.length}`,
                    params
                );

                if (resultado.rowCount === 0) {
                    return await responderError(
                        client,
                        res,
                        404,
                        'No se encontró el perfil del empleado'
                    );
                }
            }
        }

        // Consultar el perfil actualizado.
        const perfilResult = await client.query(
            `SELECT
                u.id_usuario,
                u.correo,
                u.foto,
                u.id_rol,
                r.nombre AS rol,
                c.id_cliente,
                e.id_empleado,
                COALESCE(c.nombre, e.nombre) AS nombre,
                COALESCE(c.apellido_p, e.apellido_p) AS apellido_p,
                COALESCE(c.apellido_m, e.apellido_m) AS apellido_m,
                COALESCE(c.telefono, e.telefono) AS telefono,
                c.fecha_nacimiento,
                e.fecha_ingreso,
                e.id_puesto
             FROM usuarios u
             INNER JOIN roles r ON r.id_rol = u.id_rol
             LEFT JOIN clientes c ON c.id_usuario = u.id_usuario
             LEFT JOIN empleados e ON e.id_usuario = u.id_usuario
             WHERE u.id_usuario = $1`,
            [id_usuario]
        );

        await client.query('COMMIT');
        transaccionIniciada = false;

        return res.status(200).json({
            mensaje: 'Perfil actualizado correctamente',
            usuario: perfilResult.rows[0]
        });

    } catch (error) {
        console.error('Error al actualizar perfil:', error.message);

        if (client && transaccionIniciada) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;
        }

        return res.status(500).json({
            error: 'Error al actualizar el perfil'
        });

    } finally {
        if (client) {
            client.release();
        }
    }
};

// Función auxiliar para responder errores y revertir la transacción.
const responderError = async (client, res, status, mensaje) => {
    await client.query('ROLLBACK');

    return res.status(status).json({
        error: mensaje
    });
};


module.exports = {
    obtenerPerfil,
    actualizarPerfil
};
