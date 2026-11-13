const bcrypt = require('bcrypt');
const pool = require('../db');

const ROL_EMPLEADO = 2;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const normalizarDatos = (body, nuevo) => {
    const correo = typeof body.correo === 'string' ? body.correo.trim().toLowerCase() : '';
    const nombre = typeof body.nombre === 'string' ? body.nombre.trim() : '';
    const apellido_p = typeof body.apellido_p === 'string' ? body.apellido_p.trim() : '';
    const apellido_m = typeof body.apellido_m === 'string' ? body.apellido_m.trim() : '';
    const telefono = typeof body.telefono === 'string' ? body.telefono.trim() : '';
    const id_puesto = Number(body.id_puesto);

    if (!EMAIL_RE.test(correo) || correo.length > 254 ||
        !nombre || nombre.length > 100 ||
        !apellido_p || apellido_p.length > 100 ||
        apellido_m.length > 100 || telefono.length > 25 ||
        !Number.isSafeInteger(id_puesto) || id_puesto <= 0) {
        return { error: 'Revisa correo, nombre, apellidos, teléfono y puesto.' };
    }
    if (nuevo) {
        const contrasenia = body.contrasenia;
        if (typeof contrasenia !== 'string' ||
            contrasenia.length < 12 ||
            Buffer.byteLength(contrasenia, 'utf8') > 72) {
            return { error: 'La contraseña inicial debe tener al menos 12 caracteres y no superar 72 bytes.' };
        }
        return { correo, nombre, apellido_p, apellido_m, telefono, id_puesto, contrasenia };
    }
    return { correo, nombre, apellido_p, apellido_m, telefono, id_puesto };
};

const consultarEmpleado = async (db, idEmpleado) => {
    const resultado = await db.query(`
        SELECT e.id_empleado, e.id_usuario, e.id_puesto,
               e.nombre, e.apellido_p, e.apellido_m, e.telefono,
               u.correo, u.estado, u.foto, p.nombre AS puesto
        FROM empleados e
        INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
        LEFT JOIN puestos p ON p.id_puesto = e.id_puesto
        WHERE e.id_empleado = $1 AND u.id_rol = $2
    `, [idEmpleado, ROL_EMPLEADO]);
    return resultado.rows[0] || null;
};

const listarEmpleadosAdmin = async (_req, res) => {
    try {
        const resultado = await pool.query(`
            SELECT e.id_empleado, e.id_usuario, e.id_puesto,
                   e.nombre, e.apellido_p, e.apellido_m, e.telefono,
                   u.correo, u.estado, u.foto, p.nombre AS puesto
            FROM empleados e
            INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
            LEFT JOIN puestos p ON p.id_puesto = e.id_puesto
            WHERE u.id_rol = $1
            ORDER BY u.estado DESC, e.nombre, e.apellido_p, e.id_empleado
        `, [ROL_EMPLEADO]);
        return res.json(resultado.rows);
    } catch (error) {
        console.error('Error al listar empleados:', error.message);
        return res.status(500).json({ error: 'No fue posible consultar los empleados' });
    }
};

const listarPuestosAdmin = async (_req, res) => {
    try {
        const resultado = await pool.query('SELECT id_puesto, nombre, descripcion FROM puestos ORDER BY nombre');
        return res.json(resultado.rows);
    } catch (error) {
        console.error('Error al consultar puestos:', error.message);
        return res.status(500).json({ error: 'No fue posible consultar los puestos' });
    }
};

const manejarErrorEscritura = (error, res) => {
    if (error.code === '23505') return res.status(409).json({ error: 'El correo ya está registrado.' });
    if (error.code === '23503') return res.status(400).json({ error: 'El puesto seleccionado no es válido.' });
    console.error('Error en gestión de empleados:', error.message);
    return res.status(500).json({ error: 'No fue posible guardar los cambios.' });
};

const crearEmpleadoAdmin = async (req, res) => {
    const datos = normalizarDatos(req.body || {}, true);
    if (datos.error) return res.status(400).json({ error: datos.error });
    let client;
    try {
        // El hash se calcula antes de comenzar la transacción para reducir bloqueos.
        const hash = await bcrypt.hash(datos.contrasenia, 12);
        client = await pool.connect();
        await client.query('BEGIN');
        const puesto = await client.query('SELECT 1 FROM puestos WHERE id_puesto = $1', [datos.id_puesto]);
        if (!puesto.rowCount) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Selecciona un puesto existente.' });
        }
        const repetido = await client.query('SELECT 1 FROM usuarios WHERE LOWER(correo) = $1', [datos.correo]);
        if (repetido.rowCount) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'El correo ya está registrado.' });
        }
        const usuario = await client.query(`
            INSERT INTO usuarios (id_rol, correo, contrasenia, estado)
            VALUES ($1, $2, $3, true) RETURNING id_usuario
        `, [ROL_EMPLEADO, datos.correo, hash]);
        const empleado = await client.query(`
            INSERT INTO empleados (id_usuario, id_puesto, nombre, apellido_p, apellido_m, telefono, fecha_ingreso)
            VALUES ($1, $2, $3, $4, $5, $6, CURRENT_DATE)
            RETURNING id_empleado
        `, [usuario.rows[0].id_usuario, datos.id_puesto, datos.nombre, datos.apellido_p,
            datos.apellido_m || null, datos.telefono || null]);
        const creado = await consultarEmpleado(client, empleado.rows[0].id_empleado);
        await client.query('COMMIT');
        return res.status(201).json({ mensaje: 'Empleado registrado correctamente.', empleado: creado });
    } catch (error) {
        if (client) await client.query('ROLLBACK').catch(() => {});
        return manejarErrorEscritura(error, res);
    } finally {
        if (client) client.release();
    }
};

const actualizarEmpleadoAdmin = async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isSafeInteger(id) || id <= 0) return res.status(400).json({ error: 'ID de empleado no válido.' });
    const datos = normalizarDatos(req.body || {}, false);
    if (datos.error) return res.status(400).json({ error: datos.error });
    let client;
    try {
        client = await pool.connect();
        await client.query('BEGIN');
        const actual = await client.query(`
            SELECT e.id_usuario FROM empleados e
            INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
            WHERE e.id_empleado = $1 AND u.id_rol = $2 FOR UPDATE OF e, u
        `, [id, ROL_EMPLEADO]);
        if (!actual.rowCount) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Empleado no encontrado.' });
        }
        const puesto = await client.query('SELECT 1 FROM puestos WHERE id_puesto = $1', [datos.id_puesto]);
        if (!puesto.rowCount) {
            await client.query('ROLLBACK');
            return res.status(400).json({ error: 'Selecciona un puesto existente.' });
        }
        const repetido = await client.query(
            'SELECT 1 FROM usuarios WHERE LOWER(correo) = $1 AND id_usuario <> $2',
            [datos.correo, actual.rows[0].id_usuario]);
        if (repetido.rowCount) {
            await client.query('ROLLBACK');
            return res.status(409).json({ error: 'Ese correo pertenece a otra cuenta.' });
        }
        await client.query('UPDATE usuarios SET correo = $1 WHERE id_usuario = $2',
            [datos.correo, actual.rows[0].id_usuario]);
        await client.query(`
            UPDATE empleados SET id_puesto = $1, nombre = $2, apellido_p = $3,
                apellido_m = $4, telefono = $5 WHERE id_empleado = $6
        `, [datos.id_puesto, datos.nombre, datos.apellido_p, datos.apellido_m || null,
            datos.telefono || null, id]);
        const editado = await consultarEmpleado(client, id);
        await client.query('COMMIT');
        return res.json({ mensaje: 'Empleado actualizado correctamente.', empleado: editado });
    } catch (error) {
        if (client) await client.query('ROLLBACK').catch(() => {});
        return manejarErrorEscritura(error, res);
    } finally {
        if (client) client.release();
    }
};

const cambiarEstadoEmpleadoAdmin = async (req, res) => {
    const id = Number(req.params.id);
    if (!Number.isSafeInteger(id) || id <= 0 || typeof req.body?.estado !== 'boolean') {
        return res.status(400).json({ error: 'Indica un empleado y un estado válido.' });
    }
    const estado = req.body.estado;
    let client;
    try {
        client = await pool.connect();
        await client.query('BEGIN');
        const actual = await client.query(`
            SELECT e.id_usuario, u.estado FROM empleados e
            INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
            WHERE e.id_empleado = $1 AND u.id_rol = $2 FOR UPDATE OF e, u
        `, [id, ROL_EMPLEADO]);
        if (!actual.rowCount) {
            await client.query('ROLLBACK');
            return res.status(404).json({ error: 'Empleado no encontrado.' });
        }
        if (!estado && actual.rows[0].estado) {
            // Evita desactivar personal con citas futuras sin atender o cancelar.
            const pendientes = await client.query(`
                SELECT COUNT(*)::int AS cantidad FROM citas
                WHERE id_empleado = $1 AND fecha >= CURRENT_DATE
                  AND LOWER(COALESCE(estado::text, '')) NOT IN
                    ('cancelada', 'cancelado', 'completada', 'completado')
            `, [id]);
            if (pendientes.rows[0].cantidad > 0) {
                await client.query('ROLLBACK');
                return res.status(409).json({
                    error: 'El empleado tiene citas futuras sin resolver. Reasígnalas o cancélalas antes de desactivarlo.'
                });
            }
        }
        await client.query('UPDATE usuarios SET estado = $1 WHERE id_usuario = $2',
            [estado, actual.rows[0].id_usuario]);
        const actualizado = await consultarEmpleado(client, id);
        await client.query('COMMIT');
        return res.json({ mensaje: estado ? 'Empleado reactivado.' : 'Empleado desactivado.', empleado: actualizado });
    } catch (error) {
        if (client) await client.query('ROLLBACK').catch(() => {});
        return manejarErrorEscritura(error, res);
    } finally {
        if (client) client.release();
    }
};

module.exports = {
    listarEmpleadosAdmin,
    listarPuestosAdmin,
    crearEmpleadoAdmin,
    actualizarEmpleadoAdmin,
    cambiarEstadoEmpleadoAdmin,
};
