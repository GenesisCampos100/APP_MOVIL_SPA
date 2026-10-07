const pool = require('../db');

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

        if (!correo || !contrasenia) {
            return res.status(400).json({
                error: 'El correo y la contraseña son obligatorios'
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

        //Validar contraseña
        if (usuario.contrasenia !== contrasenia) {
            return res.status(401).json({
                error: 'Correo o contraseña incorrectos'
            });
        }

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
            return res.json({
                mensaje: 'Inicio de sesión exitoso',
                usuario: {
                    id_usuario: usuario.id_usuario,
                    id_cliente: cliente.id_cliente,
                    correo: usuario.correo,
                    nombre: cliente.nombre,
                    apellido_p: cliente.apellido_p,
                    apellido_m: cliente.apellido_m,
                    telefono: cliente.telefono,
                    fecha_nacimiento: cliente.fecha_nacimiento,
                    foto: usuario.foto,
                    rol: usuario.rol
                }
            });
        }

        if (usuario.id_rol === 1) {
            return res.json({
                mensaje: 'Inicio de sesión exitoso',
                usuario: {
                    id_usuario: usuario.id_usuario,
                    correo: usuario.correo,
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
    const client = await pool.connect();

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
        if (!correo || !contrasenia || !nombre || !apellido_p) {
            return res.status(400).json({
                error: 'Correo, contraseña, nombre y apellido paterno son obligatorios'
            });
        }

        await client.query('BEGIN');

        // Verificar que el correo no esté registrado
        const usuarioExistente = await client.query(
            `SELECT id_usuario
             FROM usuarios
             WHERE correo = $1`,
            [correo]
        );

        if (usuarioExistente.rows.length > 0) {
            await client.query('ROLLBACK');

            return res.status(409).json({
                error: 'El correo ya está registrado'
            });
        }

        const ID_ROL_CLIENTE = 3;


        // Crear usuario
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
                correo,
                contrasenia
            ]
        );

        const idUsuario = nuevoUsuario.rows[0].id_usuario;

        // Crear cliente
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
                nombre,
                apellido_p,
                apellido_m || null,
                telefono || null,
                fecha_nacimiento || null
            ]
        );

        await client.query('COMMIT');

        return res.status(201).json({
            mensaje: 'Cliente registrado correctamente',
            usuario: {
                id_usuario: idUsuario,
                id_cliente: nuevoCliente.rows[0].id_cliente,
                correo: correo,
                nombre: nombre,
                apellido_p: apellido_p,
                apellido_m: apellido_m || null,
                telefono: telefono || null,
                fecha_nacimiento: fecha_nacimiento || null
            }
        });

    } catch (error) {
        await client.query('ROLLBACK');

        console.error('Error al registrar cliente:', error.message);

        return res.status(500).json({
            error: 'Error al registrar el cliente'
        });

    } finally {
        client.release();
    }
};


module.exports = {
    verificarCorreo,
    login,
    registro
};