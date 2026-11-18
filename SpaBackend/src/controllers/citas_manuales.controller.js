'use strict';

// Citas manuales: clientes registrados o nuevos sin acceso a la app.
// Todas inician Pendiente; Admin y Recepción confirman/cancelan explícitamente.
// Las rutas públicas de app_cliente no se modifican.
const pool = require('../db');
const bcrypt = require('bcrypt');
const { randomUUID, randomBytes } = require('crypto');

// Cuentas tecnicas locales: NO tienen acceso ni correo real.
// El marcador identifica exclusivamente los perfiles creados por Recepcion/Admin.
const EMAIL_INTERNO_REGEX_SQL = "u.correo ~ '^sin-cuenta-[0-9a-f]{32}@auraspa[.]invalid$'";


const dias = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];
const idValido = valor => Number.isSafeInteger(Number(valor)) && Number(valor) > 0 && valor !== '' && valor != null;
const fechaValida = texto => {
    if (typeof texto !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(texto)) return false;
    const [anio, mes, dia] = texto.split('-').map(Number);
    const fecha = new Date(Date.UTC(anio, mes - 1, dia));
    return fecha.getUTCFullYear() === anio && fecha.getUTCMonth() === mes - 1 && fecha.getUTCDate() === dia;
};
const minutos = hora => {
    const v = String(hora).substring(0, 5);
    if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(v)) return NaN;
    return Number(v.substring(0, 2)) * 60 + Number(v.substring(3, 5));
};
const hhmm = valor => `${String(Math.floor(valor / 60)).padStart(2, '0')}:${String(valor % 60).padStart(2, '0')}`;

async function comprobarAcceso(req, db) {
    const rol = Number(req.usuario?.rol);
    const idUsuario = Number(req.usuario?.id_usuario);
    if (![1, 2].includes(rol) || !Number.isSafeInteger(idUsuario) || idUsuario <= 0) return false;
    const { rows } = await db.query(`
        SELECT 1 FROM usuarios u
        LEFT JOIN empleados e ON e.id_usuario = u.id_usuario
        WHERE u.id_usuario = $1 AND u.id_rol = $2 AND u.estado = true
          AND ($2::integer = 1 OR ($2::integer = 2 AND e.id_puesto = 5))
        LIMIT 1`, [idUsuario, rol]);
    return rows.length > 0;
}

async function catalogo(req, res) {
    try {
        if (!await comprobarAcceso(req, pool)) return res.status(403).json({ error: 'No tienes permiso para registrar citas manuales' });
        const [servicios, especialistas] = await Promise.all([
            pool.query(`SELECT id_servicio, nombre, duracion, precio FROM servicios WHERE estado = true ORDER BY nombre`),
            pool.query(`SELECT e.id_empleado, CONCAT_WS(' ', e.nombre, e.apellido_p, e.apellido_m) AS nombre,
                              es.id_servicio
                        FROM empleados e
                        JOIN usuarios u ON u.id_usuario = e.id_usuario
                        JOIN empleado_servicios es ON es.id_empleado = e.id_empleado
                        WHERE u.estado = true AND u.id_rol = 2 AND e.id_puesto IS NOT NULL AND e.id_puesto <> 5
                        ORDER BY e.nombre, e.apellido_p, e.id_empleado`)
        ]);
        return res.json({ servicios: servicios.rows, especialistas: especialistas.rows });
    } catch (error) {
        console.error('Error al consultar catálogo de citas manuales:', error.message);
        return res.status(500).json({ error: 'No se pudo consultar el catálogo' });
    }
}

async function buscarClientes(req, res) {
    try {
        if (!await comprobarAcceso(req, pool)) return res.status(403).json({ error: 'No tienes permiso para consultar clientes' });
        const q = typeof req.query.q === 'string' ? req.query.q.trim().slice(0, 80) : '';
        const resultado = await pool.query(`
            SELECT c.id_cliente, CONCAT_WS(' ', c.nombre, c.apellido_p, c.apellido_m) AS nombre,
                   CASE WHEN u.estado = true THEN u.correo ELSE NULL END AS correo,
                   (u.estado = false AND ${EMAIL_INTERNO_REGEX_SQL}) AS sin_cuenta
            FROM clientes c JOIN usuarios u ON u.id_usuario = c.id_usuario
            WHERE u.id_rol = 3 AND (u.estado = true OR (u.estado = false AND ${EMAIL_INTERNO_REGEX_SQL}))
              AND ($1::text = '' OR CONCAT_WS(' ', c.nombre, c.apellido_p, c.apellido_m) ILIKE '%' || $1 || '%'
                   OR (u.estado = true AND u.correo ILIKE '%' || $1 || '%')
                   OR c.telefono ILIKE '%' || $1 || '%')
            ORDER BY c.id_cliente DESC LIMIT 50`, [q]);
        return res.json({ clientes: resultado.rows });
    } catch (error) {
        console.error('Error al buscar clientes para citas manuales:', error.message);
        return res.status(500).json({ error: 'No se pudo consultar la lista de clientes' });
    }
}

// Consulta los horarios del especialista junto con citas y apartados temporales.
// El mismo cálculo se usa en GET y dentro de la transacción del POST.
async function horariosDisponibles(db, idServicio, idEmpleado, fecha, bloquearEmpleado = false, excluirIdCita = null) {
    const servicio = await db.query(
        `SELECT id_servicio, duracion, precio FROM servicios WHERE id_servicio = $1 AND estado = true`,
        [idServicio]
    );
    if (!servicio.rows.length) return { horas: [], razon: 'El servicio no está disponible' };
    const duracion = Number(servicio.rows[0].duracion);
    if (!Number.isSafeInteger(duracion) || duracion <= 0 || duracion > 1440) {
        return { horas: [], razon: 'La duración del servicio no es válida' };
    }

    const empleado = await db.query(`
        SELECT e.id_empleado FROM empleados e
        JOIN usuarios u ON u.id_usuario = e.id_usuario
        JOIN empleado_servicios es ON es.id_empleado = e.id_empleado
        WHERE e.id_empleado = $1 AND es.id_servicio = $2
          AND e.id_puesto IS NOT NULL AND e.id_puesto <> 5 AND u.estado = true AND u.id_rol = 2
        ${bloquearEmpleado ? 'FOR UPDATE OF e' : ''}`, [idEmpleado, idServicio]);
    if (!empleado.rows.length) return { horas: [], razon: 'El especialista no está habilitado para este servicio' };

    const dia = new Date(`${fecha}T00:00:00Z`).getUTCDay();
    // La app Cliente actual no permite reservar sábados ni domingos.
    if (dia === 0 || dia === 6) return { horas: [], razon: 'No hay reservaciones disponibles durante el fin de semana' };
    // Esta funcion tambien recibe un Client de pg con una transaccion abierta.
    // Una transaccion debe ejecutar sus consultas secuencialmente en el mismo Client:
    // Promise.all() aqui produce "Calling client.query() when the client is already executing a query".
    const jornadas = await db.query(
        `SELECT TO_CHAR(hora_inicio, 'HH24:MI') AS inicio, TO_CHAR(hora_fin, 'HH24:MI') AS fin
         FROM horarios WHERE id_empleado = $1 AND dia_semana = $2`, [idEmpleado, dias[dia]]
    );
    const citas = await db.query(
        `SELECT TO_CHAR(hora_inicio, 'HH24:MI') AS inicio, duracion_aplicada AS duracion
         FROM citas WHERE id_empleado = $1 AND fecha = $2::date
           AND estado IN ('Pendiente', 'Confirmada')
           AND ($3::integer IS NULL OR id_cita <> $3::integer)`, [idEmpleado, fecha, excluirIdCita]
    );
    const apartados = await db.query(
        `SELECT TO_CHAR(hora_inicio, 'HH24:MI') AS inicio, duracion
         FROM reservas_temporales WHERE id_empleado = $1 AND fecha = $2::date
           AND fecha_expiracion > NOW()`, [idEmpleado, fecha]
    );
    const fechaServidor = await db.query(
        `SELECT TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') AS hoy, TO_CHAR(LOCALTIME, 'HH24:MI') AS hora`
    );
    const hoy = fechaServidor.rows[0].hoy;
    const horaMinima = minutos(fechaServidor.rows[0].hora) + 60;
    if (fecha < hoy) return { horas: [], duracion, precio: servicio.rows[0].precio };
    const ocupados = [...citas.rows, ...apartados.rows];
    const libres = new Set();
    for (const jornada of jornadas.rows) {
        const inicio = minutos(jornada.inicio);
        const fin = minutos(jornada.fin);
        if (!Number.isFinite(inicio) || !Number.isFinite(fin) || fin <= inicio) continue;
        for (let hora = inicio; hora + duracion <= fin; hora += duracion) {
            if (fecha === hoy && hora <= horaMinima) continue;
            if (!ocupados.some(o => hora < minutos(o.inicio) + Number(o.duracion) && hora + duracion > minutos(o.inicio))) {
                libres.add(hhmm(hora));
            }
        }
    }
    return { horas: [...libres].sort(), duracion, precio: servicio.rows[0].precio };
}

function validarSeleccion(body) {
    if (!body || typeof body !== 'object' || !idValido(body.id_cliente) ||
        !idValido(body.id_servicio) || !idValido(body.id_empleado) ||
        !fechaValida(body.fecha) ||
        typeof body.hora_inicio !== 'string' ||
        !/^([01]\d|2[0-3]):[0-5]\d$/.test(body.hora_inicio)) return false;
    return body.observaciones == null ||
        (typeof body.observaciones === 'string' && body.observaciones.trim().length <= 500);
}

async function disponibilidad(req, res) {
    try {
        if (!await comprobarAcceso(req, pool)) return res.status(403).json({ error: 'No tienes permiso para consultar disponibilidad' });
        const { id_servicio, id_empleado, fecha } = req.query;
        if (!idValido(id_servicio) || !idValido(id_empleado) || !fechaValida(fecha)) {
            return res.status(400).json({ error: 'Selecciona un servicio, especialista y fecha válidos' });
        }
        const datos = await horariosDisponibles(pool, Number(id_servicio), Number(id_empleado), fecha);
        return res.json(datos);
    } catch (error) {
        console.error('Error al consultar disponibilidad manual:', error.message);
        return res.status(500).json({ error: 'No se pudo consultar la disponibilidad' });
    }
}

async function crearCitaManual(req, res) {
    if (!validarSeleccion(req.body)) {
        return res.status(400).json({ error: 'Revisa el cliente, servicio, especialista, fecha y hora seleccionados' });
    }
    const { id_cliente, id_servicio, id_empleado, fecha, hora_inicio, observaciones } = req.body;
    const client = await pool.connect();
    let abierta = false;
    try {
        if (!await comprobarAcceso(req, client)) return res.status(403).json({ error: 'No tienes permiso para registrar citas manuales' });
        await client.query('BEGIN'); abierta = true;
        const cliente = await client.query(`
            SELECT c.id_cliente FROM clientes c JOIN usuarios u ON u.id_usuario = c.id_usuario
            WHERE c.id_cliente = $1 AND u.id_rol = 3
              AND (u.estado = true OR (u.estado = false AND ${EMAIL_INTERNO_REGEX_SQL}))`, [Number(id_cliente)]);
        if (!cliente.rows.length) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(404).json({ error: 'No se encontró el perfil de cliente seleccionado' });
        }
        // FOR UPDATE OF e: mismo bloqueo usado al apartar un horario en app_cliente.
        const datos = await horariosDisponibles(client, Number(id_servicio), Number(id_empleado), fecha, true);
        if (!datos.horas.includes(hora_inicio)) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(409).json({ error: 'Ese horario ya no está disponible. Selecciona otro.' });
        }
        const resultado = await client.query(`
            INSERT INTO citas (id_cliente, id_empleado, id_servicio, fecha, hora_inicio,
                               duracion_aplicada, precio_aplicado, estado, observaciones)
            VALUES ($1, $2, $3, $4::date, $5::time, $6, $7, 'Pendiente', $8)
            RETURNING id_cita, fecha, hora_inicio, estado`, [
            Number(id_cliente), Number(id_empleado), Number(id_servicio), fecha, hora_inicio,
            datos.duracion, datos.precio, typeof observaciones === 'string' ? observaciones.trim() || null : null
        ]);
        await client.query('COMMIT'); abierta = false;
        return res.status(201).json({ mensaje: 'Cita creada correctamente', cita: resultado.rows[0] });
    } catch (error) {
        if (abierta) {
            try { await client.query('ROLLBACK'); } catch (_) { /* error original prevalece */ }
        }
        console.error('Error al crear cita manual:', error.message);
        return res.status(500).json({ error: 'No fue posible crear la cita manual' });
    } finally {
        client.release();
    }
}


// Cliente nuevo sin cuenta: conserva la FK clientes.id_usuario SIN crear acceso a la app.
// La cuenta tecnica permanece inactiva y su correo .invalid nunca se utiliza para enviar mensajes.
// La insercion de usuario, perfil y cita ocurre en UNA sola transaccion.
function validarClienteSinCuenta(body) {
    if (!body || typeof body !== 'object' || Array.isArray(body)) return null;
    const c = body.cliente;
    if (!c || typeof c !== 'object' || Array.isArray(c)) return null;
    const nombre = typeof c.nombre === 'string' ? c.nombre.trim().replace(/\s+/g, ' ') : '';
    const apellidoP = typeof c.apellido_p === 'string' ? c.apellido_p.trim().replace(/\s+/g, ' ') : '';
    const apellidoM = typeof c.apellido_m === 'string' ? c.apellido_m.trim().replace(/\s+/g, ' ') : '';
    const telefono = typeof c.telefono === 'string' ? c.telefono.replace(/[\s()\-]/g, '') : '';
    const telDigitos = telefono.startsWith('+52') ? telefono.slice(3) : telefono;
    if (!nombre || nombre.length > 80 || !apellidoP || apellidoP.length > 80 ||
        apellidoM.length > 80 || !/^\d{10}$/.test(telDigitos)) return null;
    return { nombre, apellido_p: apellidoP, apellido_m: apellidoM || null, telefono: telDigitos };
}

async function crearCitaManualSinCuenta(req, res) {
    // Misma validacion que cita registrada, excepto que el cliente todavia no tiene id.
    const cuerpo = req.body;
    const clienteNuevo = validarClienteSinCuenta(cuerpo);
    if (!clienteNuevo || !validarSeleccion({ ...cuerpo, id_cliente: 1 })) {
        return res.status(400).json({
            error: 'Completa nombre, apellido paterno, teléfono de 10 dígitos, servicio, especialista, fecha y hora'
        });
    }
    const { id_servicio, id_empleado, fecha, hora_inicio, observaciones } = cuerpo;
    let client;
    let abierta = false;
    try {
        // No generar hashes para usuarios sin permiso.
        if (!await comprobarAcceso(req, pool)) {
            return res.status(403).json({ error: 'No tienes permiso para crear citas manuales' });
        }
        // Se genera un secreto aleatorio que no se muestra ni se entrega a nadie.
        // El login publico exige estado=true y por ello nunca aceptara esta cuenta.
        const secretoHash = await bcrypt.hash(randomBytes(48).toString('base64url'), 12);
        const correoInterno = `sin-cuenta-${randomUUID().replace(/-/g, '')}@auraspa.invalid`;
        client = await pool.connect();
        await client.query('BEGIN'); abierta = true;
        if (!await comprobarAcceso(req, client)) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(403).json({ error: 'No tienes permiso para crear citas manuales' });
        }
        const datos = await horariosDisponibles(client, Number(id_servicio), Number(id_empleado), fecha, true);
        if (!datos.horas.includes(hora_inicio)) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(409).json({ error: 'Ese horario ya no está disponible. Selecciona otro.' });
        }
        // Evita duplicar el mismo perfil de atención al repetir nombre y teléfono.
        // Un teléfono puede ser compartido por familiares: solo se bloquea el mismo nombre completo.
        const duplicado = await client.query(`
            SELECT c.id_cliente FROM clientes c
            JOIN usuarios u ON u.id_usuario = c.id_usuario
            WHERE u.id_rol = 3
              AND RIGHT(REGEXP_REPLACE(COALESCE(c.telefono, ''), '[^0-9]', '', 'g'), 10) = $1
              AND LOWER(BTRIM(c.nombre)) = LOWER($2)
              AND LOWER(BTRIM(c.apellido_p)) = LOWER($3)
              AND LOWER(BTRIM(COALESCE(c.apellido_m, ''))) = LOWER($4)
              AND (u.estado = true OR (u.estado = false AND ${EMAIL_INTERNO_REGEX_SQL}))
            LIMIT 1`, [
            clienteNuevo.telefono, clienteNuevo.nombre, clienteNuevo.apellido_p,
            clienteNuevo.apellido_m || ''
        ]);
        if (duplicado.rows.length) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(409).json({
                error: 'Ya existe un cliente con ese nombre y teléfono. Selecciónalo en Cliente existente para evitar duplicados.'
            });
        }
        const usuario = await client.query(`
            INSERT INTO usuarios (id_rol, correo, contrasenia, estado)
            VALUES (3, $1, $2, false) RETURNING id_usuario`, [correoInterno, secretoHash]);
        const perfil = await client.query(`
            INSERT INTO clientes (id_usuario, nombre, apellido_p, apellido_m, telefono, fecha_nacimiento)
            VALUES ($1, $2, $3, $4, $5, NULL) RETURNING id_cliente`, [
            usuario.rows[0].id_usuario, clienteNuevo.nombre, clienteNuevo.apellido_p,
            clienteNuevo.apellido_m, clienteNuevo.telefono
        ]);
        const cita = await client.query(`
            INSERT INTO citas (id_cliente, id_empleado, id_servicio, fecha, hora_inicio,
                               duracion_aplicada, precio_aplicado, estado, observaciones)
            VALUES ($1, $2, $3, $4::date, $5::time, $6, $7, 'Pendiente', $8)
            RETURNING id_cita, fecha, hora_inicio, estado`, [
            perfil.rows[0].id_cliente, Number(id_empleado), Number(id_servicio), fecha,
            hora_inicio, datos.duracion, datos.precio,
            typeof observaciones === 'string' ? observaciones.trim() || null : null
        ]);
        await client.query('COMMIT'); abierta = false;
        return res.status(201).json({
            mensaje: 'Cliente sin cuenta y cita registrados correctamente',
            cita: cita.rows[0], id_cliente: perfil.rows[0].id_cliente
        });
    } catch (error) {
        if (abierta && client) {
            try { await client.query('ROLLBACK'); } catch (_) { /* preservar error original */ }
        }
        console.error('Error al crear cita de cliente sin cuenta:', error.message);
        return res.status(500).json({ error: 'No se pudo registrar la cita. No se guardaron datos parciales.' });
    } finally {
        if (client) client.release();
    }
}

// Mismas reglas que el Administrador: confirmar solamente Pendiente;
// cancelar Pendiente o Confirmada. No cancela ni confirma automáticamente.
// UPDATE condicional evita doble acción de dos operadores concurrentes.
async function cambiarEstadoCitaPersonal(req, res, accion) {
    const texto = String(req.params.id ?? '');
    const idCita = Number(texto);
    if (!/^[1-9]\d*$/.test(texto) || !Number.isSafeInteger(idCita)) {
        return res.status(400).json({ error: 'El identificador de la cita no es válido' });
    }
    try {
        if (!await comprobarAcceso(req, pool)) {
            return res.status(403).json({ error: 'Solo el Administrador y Recepción pueden gestionar las citas' });
        }
        const confirmar = accion === 'confirmar';
        const resultado = await pool.query(`
            UPDATE citas SET estado = $2
            WHERE id_cita = $1 AND estado ${confirmar ? "= 'Pendiente'" : "IN ('Pendiente', 'Confirmada')"}
            RETURNING id_cita, estado, fecha, hora_inicio`,
            [idCita, confirmar ? 'Confirmada' : 'Cancelada']
        );
        if (!resultado.rows.length) {
            const consulta = await pool.query('SELECT estado FROM citas WHERE id_cita = $1', [idCita]);
            if (!consulta.rows.length) return res.status(404).json({ error: 'La cita no existe' });
            return res.status(409).json({
                error: confirmar
                    ? 'Solo se pueden confirmar citas pendientes'
                    : 'Solo se pueden cancelar citas pendientes o confirmadas'
            });
        }
        return res.json({
            mensaje: confirmar ? 'Cita confirmada correctamente' : 'Cita cancelada correctamente',
            cita: resultado.rows[0]
        });
    } catch (error) {
        console.error('Error al actualizar una cita desde Recepción/Administración:', error.message);
        return res.status(500).json({ error: 'No se pudo actualizar la cita' });
    }
}

// Recepción registra una respuesta VERBAL real del cliente (telefono o presencial).
// A diferencia de confirmarCitaPersonal, no modifica el estado administrativo.
async function registrarAsistenciaVerbal(req, res) {
    const idCita = idCitaSolicitada(req);
    if (!idCita) return res.status(400).json({ error: 'El identificador de la cita no es válido' });

    const medio = req.body?.medio;
    if (medio !== 'telefono' && medio !== 'presencial') {
        return res.status(400).json({ error: 'Indica si el cliente confirmó por teléfono o presencialmente' });
    }

    try {
        // Reutiliza la verificación de rol, puesto y cuenta activa del módulo de personal.
        if (!await comprobarAcceso(req, pool)) {
            return res.status(403).json({ error: 'No tienes permiso para registrar confirmaciones' });
        }

        // UPDATE atómico: exige reserva aceptada, respuesta no registrada y
        // ventana real de 48 horas con plazo vigente, respetando la hora local.
        const resultado = await pool.query(`
            UPDATE citas c
               SET fecha_confirmacion = NOW()
             WHERE c.id_cita = $1
               AND c.estado = 'Confirmada'
               AND c.fecha_confirmacion IS NULL
               AND (c.fecha + c.hora_inicio) > timezone('America/Mexico_City', NOW())
               AND (c.fecha + c.hora_inicio) <=
                   timezone('America/Mexico_City', NOW()) + INTERVAL '48 hours'
               AND (c.fecha_limite IS NULL OR c.fecha_limite > NOW())
         RETURNING c.id_cita, c.estado, c.fecha_confirmacion`, [idCita]);

        if (resultado.rowCount === 0) {
            return res.status(409).json({
                error: 'La cita no es elegible: debe estar aceptada, sin asistencia registrada y dentro del plazo de confirmación'
            });
        }

        return res.status(200).json({
            mensaje: 'Asistencia registrada correctamente',
            medio, // Se devuelve al Cliente API; todavía no se almacena en otra columna.
            cita: resultado.rows[0]
        });
    } catch (error) {
        console.error('Error al registrar asistencia verbal:', error.message);
        return res.status(500).json({ error: 'No se pudo registrar la asistencia' });
    }
}

const confirmarCitaPersonal = (req, res) => cambiarEstadoCitaPersonal(req, res, 'confirmar');
const cancelarCitaPersonal = (req, res) => cambiarEstadoCitaPersonal(req, res, 'cancelar');

// Cierre administrativo de la atención. La cita solo puede completarse
// si estaba Confirmada y ya concluyó su franja reservada. La condición
// se valida en PostgreSQL en un UPDATE atómico para impedir carreras.
// Se utiliza el mismo reloj de la BD (LOCALTIME/CURRENT_DATE) que la
// disponibilidad; no se depende de la hora del teléfono o emulador.
async function completarCitaPersonal(req, res) {
    const idCita = idCitaSolicitada(req);
    if (!idCita) return res.status(400).json({ error: 'El identificador de cita no es válido' });
    try {
        if (!await comprobarAcceso(req, pool)) {
            return res.status(403).json({ error: 'Solo Administración y Recepción pueden completar citas' });
        }
        const resultado = await pool.query(`
            UPDATE citas SET estado = 'Completada'
            WHERE id_cita = $1
              AND estado = 'Confirmada'
              AND (fecha + hora_inicio + duracion_aplicada * INTERVAL '1 minute') <= LOCALTIMESTAMP
            RETURNING id_cita, estado, fecha, hora_inicio`, [idCita]);
        if (resultado.rows.length) {
            return res.json({ mensaje: 'Cita completada correctamente', cita: resultado.rows[0] });
        }
        const actual = await pool.query(`
            SELECT estado,
              (fecha + hora_inicio + duracion_aplicada * INTERVAL '1 minute') <= LOCALTIMESTAMP AS finalizada_hora
            FROM citas WHERE id_cita = $1`, [idCita]);
        if (!actual.rows.length) return res.status(404).json({ error: 'La cita no existe' });
        if (actual.rows[0].estado !== 'Confirmada') {
            return res.status(409).json({ error: 'Solo se pueden completar citas confirmadas. Actualiza la agenda.' });
        }
        if (!actual.rows[0].finalizada_hora) {
            return res.status(409).json({ error: 'El horario reservado todavía no termina. Completa la cita después de realizar el servicio.' });
        }
        return res.status(409).json({ error: 'La cita fue modificada por otra persona. Actualiza la agenda.' });
    } catch (error) {
        console.error('Error al completar cita:', error.message);
        return res.status(500).json({ error: 'No se pudo completar la cita' });
    }
}


// Reprogramacion exclusiva de personal autorizado. Siempre vuelve a Pendiente
// para requerir confirmacion explicita de la NUEVA fecha/hora.
// Nunca crea otra cita, altera el cliente, servicio ni el historial anterior.
const idCitaSolicitada = req => {
    const texto = String(req.params.id ?? '');
    const valor = Number(texto);
    return /^[1-9]\d*$/.test(texto) && Number.isSafeInteger(valor) ? valor : null;
};
const fechaCitaSQL = `TO_CHAR(c.fecha, 'YYYY-MM-DD') AS fecha,
                      TO_CHAR(c.hora_inicio, 'HH24:MI') AS hora_inicio`;

async function detalleParaReprogramar(req, res) {
    const idCita = idCitaSolicitada(req);
    if (!idCita) return res.status(400).json({ error: 'El identificador de cita no es válido' });
    try {
        if (!await comprobarAcceso(req, pool)) return res.status(403).json({ error: 'No tienes permiso para reprogramar citas' });
        const cita = await pool.query(`
            SELECT c.id_cita, c.id_cliente, c.id_servicio, c.id_empleado,
                   ${fechaCitaSQL}, c.estado,
                   s.nombre AS servicio, CONCAT_WS(' ', cl.nombre, cl.apellido_p, cl.apellido_m) AS cliente
            FROM citas c
            JOIN servicios s ON s.id_servicio = c.id_servicio
            JOIN clientes cl ON cl.id_cliente = c.id_cliente
            WHERE c.id_cita = $1`, [idCita]);
        if (!cita.rows.length) return res.status(404).json({ error: 'La cita no existe' });
        if (!['Pendiente', 'Confirmada'].includes(cita.rows[0].estado)) {
            return res.status(409).json({ error: 'Solo se pueden reprogramar citas pendientes o confirmadas' });
        }
        const especialistas = await pool.query(`
            SELECT e.id_empleado, CONCAT_WS(' ', e.nombre, e.apellido_p, e.apellido_m) AS nombre
            FROM empleados e
            JOIN usuarios u ON u.id_usuario = e.id_usuario
            JOIN empleado_servicios es ON es.id_empleado = e.id_empleado
            WHERE es.id_servicio = $1 AND e.id_puesto IS NOT NULL AND e.id_puesto <> 5
              AND u.estado = true AND u.id_rol = 2
            ORDER BY e.nombre, e.apellido_p, e.id_empleado`, [cita.rows[0].id_servicio]);
        return res.json({ cita: cita.rows[0], especialistas: especialistas.rows });
    } catch (error) {
        console.error('Error al obtener reprogramacion:', error.message);
        return res.status(500).json({ error: 'No se pudo consultar la cita' });
    }
}

async function disponibilidadReprogramacion(req, res) {
    const idCita = idCitaSolicitada(req);
    if (!idCita || !idValido(req.query.id_empleado) || !fechaValida(req.query.fecha)) {
        return res.status(400).json({ error: 'Selecciona una cita, especialista y fecha válidos' });
    }
    try {
        if (!await comprobarAcceso(req, pool)) return res.status(403).json({ error: 'No tienes permiso para consultar disponibilidad' });
        const cita = await pool.query('SELECT id_servicio, estado FROM citas WHERE id_cita = $1', [idCita]);
        if (!cita.rows.length) return res.status(404).json({ error: 'La cita no existe' });
        if (!['Pendiente', 'Confirmada'].includes(cita.rows[0].estado)) {
            return res.status(409).json({ error: 'Esta cita ya no se puede reprogramar' });
        }
        const datos = await horariosDisponibles(pool, Number(cita.rows[0].id_servicio),
            Number(req.query.id_empleado), req.query.fecha, false, idCita);
        return res.json(datos);
    } catch (error) {
        console.error('Error al consultar disponibilidad de reprogramacion:', error.message);
        return res.status(500).json({ error: 'No se pudo consultar la disponibilidad' });
    }
}

async function reprogramarCitaPersonal(req, res) {
    const idCita = idCitaSolicitada(req);
    const body = req.body ?? {};
    if (!idCita || !idValido(body.id_empleado) || !fechaValida(body.fecha) ||
        typeof body.hora_inicio !== 'string' || !/^([01]\d|2[0-3]):[0-5]\d$/.test(body.hora_inicio)) {
        return res.status(400).json({ error: 'Selecciona cita, especialista, fecha y hora válidos' });
    }
    let client;
    let abierta = false;
    try {
        client = await pool.connect();
        if (!await comprobarAcceso(req, client)) {
            return res.status(403).json({ error: 'Solo Administración y Recepción pueden reprogramar citas' });
        }
        await client.query('BEGIN'); abierta = true;
        // Bloquea la cita para que ninguna otra operación pueda cambiar su estado
        // durante la reprogramación. La validación final se ejecuta en la transacción.
        const actual = await client.query(`
            SELECT id_cita, id_servicio, id_empleado, estado,
                   TO_CHAR(fecha, 'YYYY-MM-DD') AS fecha,
                   TO_CHAR(hora_inicio, 'HH24:MI') AS hora_inicio
            FROM citas WHERE id_cita = $1 FOR UPDATE`, [idCita]);
        if (!actual.rows.length) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(404).json({ error: 'La cita no existe' });
        }
        const cita = actual.rows[0];
        if (!['Pendiente', 'Confirmada'].includes(cita.estado)) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(409).json({ error: 'Solo se pueden reprogramar citas pendientes o confirmadas' });
        }
        if (Number(cita.id_empleado) === Number(body.id_empleado) &&
            cita.fecha === body.fecha && cita.hora_inicio === body.hora_inicio) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(409).json({ error: 'La nueva programación es igual a la actual' });
        }
        // Mismo bloqueo por especialista usado para nuevas citas manuales.
        // Excluir solo esta cita evita que su horario anterior se marque como conflicto.
        const disponibilidad = await horariosDisponibles(client, Number(cita.id_servicio),
            Number(body.id_empleado), body.fecha, true, idCita);
        if (!disponibilidad.horas.includes(body.hora_inicio)) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(409).json({ error: 'El nuevo horario ya no está disponible. Elige otro.' });
        }
        const resultado = await client.query(`
            UPDATE citas SET id_empleado = $2, fecha = $3::date, hora_inicio = $4::time,
                            estado = 'Pendiente', fecha_confirmacion = NULL,
                            fecha_limite = CASE
                                WHEN ($3::date + $4::time) >
                                    timezone('America/Mexico_City', NOW()) + INTERVAL '48 hours'
                                THEN (($3::date + $4::time) - INTERVAL '24 hours')
                                    AT TIME ZONE 'America/Mexico_City'
                                ELSE (($3::date + $4::time) - INTERVAL '1 hour')
                                    AT TIME ZONE 'America/Mexico_City'
                            END
            WHERE id_cita = $1 AND estado IN ('Pendiente', 'Confirmada')
            RETURNING id_cita, id_empleado, TO_CHAR(fecha, 'YYYY-MM-DD') AS fecha,
                      TO_CHAR(hora_inicio, 'HH24:MI') AS hora_inicio, estado`,
            [idCita, Number(body.id_empleado), body.fecha, body.hora_inicio]);
        if (!resultado.rows.length) {
            await client.query('ROLLBACK'); abierta = false;
            return res.status(409).json({ error: 'El estado de la cita cambió. Actualiza la agenda.' });
        }

                // Archivar recordatorios del horario anterior sin eliminarlos.
        // La cita reprogramada necesitara una nueva confirmacion de asistencia.
        await client.query(
            `UPDATE notificaciones
             SET tipo = 'cita_reagendada',
                 titulo = 'Solicitud de asistencia anterior',
                 mensaje = 'Esta solicitud correspondía al horario anterior de tu cita.',
                 leida = TRUE
             WHERE id_cita = $1
               AND tipo = 'confirmar_cita'`,
            [idCita]
        );

        await client.query('COMMIT'); abierta = false;
        return res.json({
            mensaje: 'Cita reprogramada. Quedó Pendiente de confirmación.',
            cita: resultado.rows[0]
        });
    } catch (error) {
        if (abierta && client) {
            try { await client.query('ROLLBACK'); } catch (_) { /* mantener error original */ }
        }
        console.error('Error al reprogramar cita:', error.message);
        return res.status(500).json({ error: 'No se pudo reprogramar la cita' });
    } finally {
        if (client) client.release();
    }
}

module.exports = {
    catalogo, buscarClientes, disponibilidad, crearCitaManual, crearCitaManualSinCuenta,
    confirmarCitaPersonal, cancelarCitaPersonal, completarCitaPersonal,
    registrarAsistenciaVerbal,
    detalleParaReprogramar, disponibilidadReprogramacion, reprogramarCitaPersonal
};

