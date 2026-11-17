const bcrypt = require('bcrypt');

const jwt = require('jsonwebtoken');

const pool = require('../db');

const {
    guardarRegistro,
    obtenerRegistro,
    incrementarIntentos,
    eliminarRegistro
} = require('../utils/registroPendiente');

const {
    crearCodigoVerificacion
} = require('../services/verificacion.service');

const { generarUrlFoto } = require('../services/foto.service');


const verificarCorreo = async (req, res) => {
    try {
        const { correo } = req.body;

        if (!correo) {
            return res.status(400).json({
                error: 'El correo es obligaatorio'
            });
        }

        const result = await pool.query(
            `SELECT u.id_usuario, u.correo
             FROM usuarios u
             INNER JOIN clientes c
                ON c.id_usuario = u.id_usuario
             WHERE u.correo = $1
               AND u.estado = true`,
            [correo]
        );

        if (result.rows.length > 0) {
            return res.json({
                existe: true
            });
        }

        return res.json({
            existe: false
        });

    } catch (error) {
        console.error('Error al verificar correo:', error.message);

        res.status(500).json({
            error: 'Error al verificar el correo'
        });
    }
};


const login = async (req, res) => {
    try {

        const { correo, contrasenia } = req.body;

        if (
            typeof correo !== 'string' ||
            typeof contrasenia !== 'string' ||
            !correo.trim() ||
            !contrasenia ||
            Buffer.byteLength(contrasenia, 'utf8') > 72
        ) {
            return res.status(400).json({
                error: 'Debes proporcionar un correo y una contraseña válidos'
            });
        }

        const usuarioResult = await pool.query( `SELECT
            u.id_usuario,
            u.id_rol,
            u.correo,
            u.contrasenia,
            u.foto,
            r.nombre AS rol
            FROM usuarios u
            INNER JOIN roles r
            ON r.id_rol = u.id_rol
            WHERE u.correo = $1
            AND u.estado = true`,
            [correo]
        );

        if (usuarioResult.rows.length === 0) {
            return res.status(401).json({
                error: 'Correo o contraseña incorrectos'
            });
        }

        const usuario = usuarioResult.rows[0];

        // Validar contraseña con bcrypt
        const contraseniaValida = await bcrypt.compare(
            contrasenia,
            usuario.contrasenia
        );

        if (!contraseniaValida) {
            return res.status(401).json({
                error: 'Correo o contraseña incorrectos'
            });
        }

        const token = jwt.sign(
            {
                id_usuario: usuario.id_usuario,
                rol: usuario.id_rol
            },
            process.env.JWT_SECRET,
            {
                expiresIn: process.env.JWT_EXPIRES_IN || '1h',
                algorithm: 'HS256'
            }
        );

        if (usuario.id_rol === 3) {
            const clienteResult = await pool.query(
                `SELECT c.id_cliente,
                c.nombre,
                c.apellido_p,
                c.apellido_m,
                c.telefono,
                c.fecha_nacimiento
                FROM clientes c
                WHERE c.id_usuario = $1`,
                [usuario.id_usuario]
            );

            if (clienteResult.rows.length === 0) {
                return res.status(500).json({
                    error: 'El usuario cliente no tiene información asociada'
                });
            }

            const cliente = clienteResult.rows[0];

            // Generar URL firmada para la foto del cliente
            const fotoUrl = await generarUrlFoto(usuario.foto);
            return res.json({
                mensaje: 'Inicio de sesión exitoso',
                token,
                usuario: {
                    id_usuario: usuario.id_usuario,
                    id_cliente: cliente.id_cliente,
                    correo: usuario.correo,
                    nombre: cliente.nombre,
                    apellido_p: cliente.apellido_p,
                    apellido_m: cliente.apellido_m,
                    telefono: cliente.telefono,
                    fecha_nacimiento: cliente.fecha_nacimiento,
                    foto: fotoUrl,
                    rol: usuario.rol
                }
            });
        }

        if (usuario.id_rol === 1) {
            return res.json({
                mensaje: 'Inicio de sesión exitoso',
                token,
                usuario: {
                    id_usuario: usuario.id_usuario,
                    correo: usuario.correo,
                    foto: usuario.foto,
                    rol: usuario.rol
                }
            });
        }


        // LOGIN EMPLEADO - ROL 2
        if (usuario.id_rol === 2) {
            const empleadoResult = await pool.query(
                `SELECT
                    id_empleado,
                    id_puesto,
                    nombre,
                    apellido_p,
                    apellido_m,
                    telefono
                 FROM empleados
                 WHERE id_usuario = $1`,
                [usuario.id_usuario]
            );

            if (empleadoResult.rows.length === 0) {
                return res.status(403).json({
                    error: 'El empleado no tiene un perfil asociado'
                });
            }

            const empleado = empleadoResult.rows[0];

            return res.status(200).json({
                mensaje: 'Inicio de sesión exitoso',
                token,
                usuario: {
                    id_usuario: usuario.id_usuario,
                    id_empleado: empleado.id_empleado,
                    id_puesto: empleado.id_puesto,
                    correo: usuario.correo,
                    nombre: empleado.nombre,
                    apellido_p: empleado.apellido_p,
                    apellido_m: empleado.apellido_m,
                    telefono: empleado.telefono,
                    foto: usuario.foto,
                    rol: usuario.rol
                }
            });
        }


        // Por seguridad, manejar cualquier rol no contemplado.
        return res.status(403).json({
            error: 'El rol del usuario no está permitido'
        });


    } catch (error) {
        console.error('Error al iniciar sesión:', error.message);

        return res.status(500).json({
            error: 'Error al iniciar sesión'
        });
    }
};


const registro = async (req, res) => {
    try {
        const {
            correo,
            contrasenia,
            nombre,
            apellido_p,
            apellido_m,
            telefono,
            fecha_nacimiento
        } = req.body;

        // Validar campos obligatorios
        if (
            !correo ||
            !contrasenia ||
            !nombre ||
            !apellido_p
        ) {
            return res.status(400).json({
                error: 'Correo, contraseña, nombre y apellido paterno son obligatorios'
            });
        }

        // Normalizar el correo
        const correoNormalizado = correo.trim().toLowerCase();

        // Validaciones básicas
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correoNormalizado)) {
            return res.status(400).json({
                error: 'El formato del correo no es válido'
            });
        }

        if (typeof contrasenia !== 'string' ||
            contrasenia.length < 8 ||
            Buffer.byteLength(contrasenia, 'utf8') > 72) {
            return res.status(400).json({
                error: 'La contraseña debe tener al menos 8 caracteres y no superar 72 bytes'
            });
        }

        if (
            typeof nombre !== 'string' ||
            typeof apellido_p !== 'string' ||
            !nombre.trim() ||
            !apellido_p.trim()
        ) {
            return res.status(400).json({
                error: 'El nombre y el apellido paterno no pueden estar vacíos'
            });
        }

        // Comprobar si ya existe una cuenta con ese correo
        const usuarioExistente = await pool.query(
            `SELECT id_usuario
             FROM usuarios
             WHERE LOWER(correo) = $1`,
            [correoNormalizado]
        );

        if (usuarioExistente.rows.length > 0) {
            return res.status(409).json({
                error: 'El correo ya está registrado'
            });
        }

        // Generar el hash de la contraseña
        const contraseniaHash = await bcrypt.hash(contrasenia, 12);

        // Generar y enviar el código por Gmail
        // Si falla el envío, no se guarda el registro pendiente.
        const codigo = await crearCodigoVerificacion(
            correoNormalizado
        );

        // Guardar los datos únicamente en memoria
        guardarRegistro(correoNormalizado, {
            contraseniaHash,
            nombre: nombre.trim(),
            apellido_p: apellido_p.trim(),
            apellido_m: apellido_m?.trim() || null,
            telefono: telefono?.trim() || null,
            fecha_nacimiento: fecha_nacimiento || null,
            codigoHash: codigo.codigoHash,
            expiraEnCodigo: codigo.expiraEn
        });

        return res.status(200).json({
            mensaje: 'Código enviado. Revisa tu correo para verificar tu cuenta.',
            requiereVerificacion: true
        });

    } catch (error) {
        console.error('Error al iniciar el registro:', error.message);

        return res.status(500).json({
            error: 'No se pudo iniciar el registro. Inténtalo nuevamente.'
        });
    }
};


const verificarCodigo = async (req, res) => {
    let client;
    let transaccionIniciada = false;

    try {
        const { correo, codigo } = req.body;

        if (
            typeof correo !== 'string' ||
            typeof codigo !== 'string' ||
            !/^\d{6}$/.test(codigo)
        ) {
            return res.status(400).json({
                error: 'Debes proporcionar un correo y un código de seis dígitos'
            });
        }

        const correoNormalizado = correo.trim().toLowerCase();

        // Buscar el registro pendiente en memoria
        const pendiente = obtenerRegistro(correoNormalizado);

        if (!pendiente) {
            return res.status(400).json({
                error: 'El registro no existe o ha expirado. Inicia el proceso nuevamente.'
            });
        }

        // Comprobar la expiración específica del código
        if (Date.now() >= pendiente.expiraEnCodigo) {
            eliminarRegistro(correoNormalizado);

            return res.status(400).json({
                error: 'El código ha expirado. Inicia el registro nuevamente.'
            });
        }

        // Comparar el código introducido con el hash almacenado
        const codigoValido = await bcrypt.compare(
            codigo,
            pendiente.codigoHash
        );

        if (!codigoValido) {
            const quedanIntentos = incrementarIntentos(
                correoNormalizado
            );

            if (!quedanIntentos) {
                return res.status(429).json({
                    error: 'Se agotaron los intentos. Inicia el registro nuevamente.'
                });
            }

            return res.status(400).json({
                error: 'Código incorrecto'
            });
        }

        // Obtener una conexión para crear ambos registros
        client = await pool.connect();

        await client.query('BEGIN');
        transaccionIniciada = true;

        // Comprobar otra vez para evitar duplicados
        const usuarioExistente = await client.query(
            `SELECT id_usuario
             FROM usuarios
             WHERE LOWER(correo) = $1`,
            [correoNormalizado]
        );

        if (usuarioExistente.rows.length > 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;
            eliminarRegistro(correoNormalizado);

            return res.status(409).json({
                error: 'El correo ya está registrado'
            });
        }

        const ID_ROL_CLIENTE = 3;

        // Crear usuario solamente después de verificar el correo
        const nuevoUsuario = await client.query(
            `INSERT INTO usuarios (
                id_rol,
                correo,
                contrasenia,
                estado
            )
            VALUES ($1, $2, $3, true)
            RETURNING id_usuario, correo`,
            [
                ID_ROL_CLIENTE,
                correoNormalizado,
                pendiente.contraseniaHash
            ]
        );

        const idUsuario = nuevoUsuario.rows[0].id_usuario;

        // Crear el perfil del cliente
        const nuevoCliente = await client.query(
            `INSERT INTO clientes (
                id_usuario,
                nombre,
                apellido_p,
                apellido_m,
                telefono,
                fecha_nacimiento
            )
            VALUES ($1, $2, $3, $4, $5, $6)
            RETURNING id_cliente`,
            [
                idUsuario,
                pendiente.nombre,
                pendiente.apellido_p,
                pendiente.apellido_m,
                pendiente.telefono,
                pendiente.fecha_nacimiento
            ]
        );

        await client.query('COMMIT');
        transaccionIniciada = false;

        // Eliminar los datos temporales después del registro exitoso
        eliminarRegistro(correoNormalizado);


        // Generar JWT para el cliente recién registrado.
        const token = jwt.sign(
            {
                id_usuario: idUsuario,
                rol: ID_ROL_CLIENTE
            },
            process.env.JWT_SECRET,
            {
                expiresIn: process.env.JWT_EXPIRES_IN || '1h',
                algorithm: 'HS256'
            }
        );


        return res.status(201).json({
            mensaje: 'Correo verificado y cliente registrado correctamente',
            token,
            usuario: {
                id_usuario: idUsuario,
                id_cliente: nuevoCliente.rows[0].id_cliente,
                correo: correoNormalizado,
                nombre: pendiente.nombre,
                apellido_p: pendiente.apellido_p,
                apellido_m: pendiente.apellido_m,
                telefono: pendiente.telefono,
                fecha_nacimiento: pendiente.fecha_nacimiento
            }
        });

    } catch (error) {
        if (client && transaccionIniciada) {
            try {
                await client.query('ROLLBACK');
            } catch (rollbackError) {
                console.error(
                    'Error al revertir la transacción:',
                    rollbackError.message
                );
            }
        }

        console.error(
            'Error al verificar el código:',
            error.message
        );

        return res.status(500).json({
            error: 'No se pudo verificar el código'
        });

    } finally {
        if (client) {
            client.release();
        }
    }
};


const cambiarContrasena = async (req, res) => {
    try {
        const id_usuario = Number(req.usuario?.id_usuario);

        const { contrasena_actual, contrasena_nueva } = req.body;

        // Validar identidad del usuario.
        if (!Number.isInteger(id_usuario) || id_usuario <= 0) {
            return res.status(401).json({
                error: 'La sesión no es válida'
            });
        }

        // Validar las contraseñas recibidas.
        if (
            typeof contrasena_actual !== 'string' ||
            typeof contrasena_nueva !== 'string' ||
            !contrasena_actual ||
            !contrasena_nueva
        ) {
            return res.status(400).json({
                error: 'Debes proporcionar ambas contraseñas'
            });
        }

        if (
            contrasena_nueva.length < 8 ||
            Buffer.byteLength(contrasena_nueva, 'utf8') > 72 ||
            !/[A-Za-z]/.test(contrasena_nueva) ||
            !/\d/.test(contrasena_nueva)
        ) {
            return res.status(400).json({
                error: 'La nueva contraseña debe tener al menos 8 caracteres, incluir letras y números y no superar 72 bytes'
            });
        }

        if (Buffer.byteLength(contrasena_actual, 'utf8') > 72) {
            return res.status(400).json({
                error: 'La contraseña actual no es válida'
            });
        }

        if (contrasena_actual === contrasena_nueva) {
            return res.status(400).json({
                error: 'La nueva contraseña debe ser diferente a la actual'
            });
        }

        // Obtener la contraseña almacenada del usuario autenticado.
        const resultado = await pool.query(
            `SELECT contrasenia
             FROM usuarios
             WHERE id_usuario = $1
               AND estado = true`,
            [id_usuario]
        );

        if (resultado.rows.length === 0) {
            return res.status(404).json({
                error: 'No se encontró el usuario'
            });
        }

        // Comprobar la contraseña actual.
        const coincide = await bcrypt.compare(
            contrasena_actual,
            resultado.rows[0].contrasenia
        );

        if (!coincide) {
            return res.status(400).json({
                error: 'La contraseña actual es incorrecta'
            });
        }

        // Generar el nuevo hash.
        const nuevoHash = await bcrypt.hash(contrasena_nueva, 12);

        // Actualizar la contraseña.
        await pool.query(
            `UPDATE usuarios
             SET contrasenia = $1
             WHERE id_usuario = $2
               AND estado = true`,
            [nuevoHash, id_usuario]
        );

        return res.status(200).json({
            mensaje: 'La contraseña se actualizó correctamente',
            actualizada: true
        });

    } catch (error) {
        console.error('Error al cambiar contraseña:', error);

        return res.status(500).json({
            error: 'No se pudo cambiar la contraseña'
        });
    }
};



module.exports = {
    verificarCorreo,
    login,
    registro,
    verificarCodigo,
    cambiarContrasena
};