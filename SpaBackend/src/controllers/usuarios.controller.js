const bcrypt = require('bcrypt');

const {
    guardarRegistro,
    obtenerRegistro,
    incrementarIntentos,
    eliminarRegistro
} = require('../utils/registroPendiente');

const {
    crearCodigoVerificacion
} = require('../services/verificacion.service');


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
            3: [
                'nombre',
                'apellido_p',
                'apellido_m',
                'foto',
                'telefono',
                'fecha_nacimiento'
            ]
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


        if (Object.hasOwn(valores, 'correo')) {
            await client.query(
                `UPDATE usuarios
                SET correo = $1
                WHERE id_usuario = $2`,
                [valores.correo, id_usuario]
            );
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
                'fecha_nacimiento',
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

        if (error.code === '23505') {
            return res.status(409).json({
                error: 'Este correo electrónico ya está registrado'
            });
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



// SOLICITAR CÓDIGO PARA CAMBIAR EL CORREO
const solicitarCambioCorreo = async (req, res) => {
    try {
        const id_usuario = req.usuario.id_usuario;
        const rol = Number(req.usuario.rol);
        const correo = req.body.correo?.trim().toLowerCase();

        if (rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden cambiar su correo'
            });
        }

        if (
            typeof req.body.correo !== 'string' ||
            !correo ||
            correo.length > 254 ||
            !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo)
        ) {
            return res.status(400).json({
                error: 'El correo electrónico no es válido'
            });
        }

        // Consultar el correo actual del usuario.
        const usuario = await pool.query(
            `SELECT correo
             FROM usuarios
             WHERE id_usuario = $1
               AND estado = true`,
            [id_usuario]
        );

        if (usuario.rows.length === 0) {
            return res.status(404).json({
                error: 'No se encontró un usuario activo'
            });
        }

        if (usuario.rows[0].correo.toLowerCase() === correo) {
            return res.status(400).json({
                error: 'El nuevo correo es igual al actual'
            });
        }

        // Comprobar que el correo no pertenezca a otra cuenta.
        const existente = await pool.query(
            `SELECT id_usuario
             FROM usuarios
             WHERE LOWER(correo) = $1
               AND id_usuario <> $2`,
            [correo, id_usuario]
        );

        if (existente.rows.length > 0) {
            return res.status(409).json({
                error: 'Este correo electrónico ya está registrado'
            });
        }

        // Generar y enviar el código al nuevo correo.
        const { codigoHash } = await crearCodigoVerificacion(
            correo,
            { tipo: 'cambio_correo' }
        );

        // Cada usuario tiene su propio cambio pendiente.
        const clave = `cambio-correo:${id_usuario}`;

        guardarRegistro(clave, {
            correo,
            codigoHash
        });

        return res.status(200).json({
            mensaje: 'Se envió un código de verificación al nuevo correo'
        });

    } catch (error) {
        console.error('Error al solicitar cambio de correo:', error.message);

        return res.status(500).json({
            error: 'No se pudo enviar el código de verificación'
        });
    }
};


// VERIFICAR CÓDIGO Y ACTUALIZAR CORREO
const verificarCambioCorreo = async (req, res) => {
    let client;
    let transaccionIniciada = false;

    try {
        const id_usuario = req.usuario.id_usuario;
        const rol = Number(req.usuario.rol);
        const correo = req.body.correo?.trim().toLowerCase();
        const codigo = req.body.codigo?.trim();

        if (rol !== 3) {
            return res.status(403).json({
                error: 'Solo los clientes pueden cambiar su correo'
            });
        }

        if (
            typeof correo !== 'string' ||
            !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo) ||
            typeof codigo !== 'string' ||
            !/^\d{6}$/.test(codigo)
        ) {
            return res.status(400).json({
                error: 'El correo o el código no son válidos'
            });
        }

        const clave = `cambio-correo:${id_usuario}`;
        const pendiente = obtenerRegistro(clave);

        if (!pendiente) {
            return res.status(400).json({
                error: 'El código expiró o no existe. Solicita uno nuevo'
            });
        }

        if (pendiente.correo !== correo) {
            return res.status(400).json({
                error: 'El código no corresponde a ese correo'
            });
        }

        const codigoCorrecto = await bcrypt.compare(
            codigo,
            pendiente.codigoHash
        );

        if (!codigoCorrecto) {
            const quedanIntentos = incrementarIntentos(clave);

            return res.status(400).json({
                error: quedanIntentos
                    ? 'El código es incorrecto'
                    : 'Se agotaron los intentos. Solicita un nuevo código'
            });
        }

        client = await pool.connect();

        await client.query('BEGIN');
        transaccionIniciada = true;

        // Bloquear la cuenta mientras se realiza el cambio.
        const usuario = await client.query(
            `SELECT id_usuario
             FROM usuarios
             WHERE id_usuario = $1
               AND id_rol = 3
               AND estado = true
             FOR UPDATE`,
            [id_usuario]
        );

        if (usuario.rows.length === 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(404).json({
                error: 'No se encontró un cliente activo'
            });
        }

        // Volver a comprobar que nadie haya registrado ese correo.
        const existente = await client.query(
            `SELECT id_usuario
             FROM usuarios
             WHERE LOWER(correo) = $1
               AND id_usuario <> $2`,
            [correo, id_usuario]
        );

        if (existente.rows.length > 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(409).json({
                error: 'Este correo electrónico ya está registrado'
            });
        }

        await client.query(
            `UPDATE usuarios
             SET correo = $1
             WHERE id_usuario = $2`,
            [correo, id_usuario]
        );

        // Obtener el perfil actualizado.
        const perfilResult = await client.query(
            `SELECT
                u.id_usuario,
                u.correo,
                u.foto,
                u.id_rol,
                r.nombre AS rol,
                c.id_cliente,
                c.nombre,
                c.apellido_p,
                c.apellido_m,
                c.telefono,
                c.fecha_nacimiento
             FROM usuarios u
             INNER JOIN roles r ON r.id_rol = u.id_rol
             LEFT JOIN clientes c ON c.id_usuario = u.id_usuario
             WHERE u.id_usuario = $1`,
            [id_usuario]
        );

        await client.query('COMMIT');
        transaccionIniciada = false;

        eliminarRegistro(clave);

        return res.status(200).json({
            mensaje: 'Correo electrónico actualizado correctamente',
            usuario: perfilResult.rows[0]
        });

    } catch (error) {
        console.error('Error al verificar cambio de correo:', error.message);

        if (client && transaccionIniciada) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;
        }

        if (error.code === '23505') {
            return res.status(409).json({
                error: 'Este correo electrónico ya está registrado'
            });
        }

        return res.status(500).json({
            error: 'No se pudo actualizar el correo electrónico'
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
    actualizarPerfil,
    solicitarCambioCorreo,
    verificarCambioCorreo
};
