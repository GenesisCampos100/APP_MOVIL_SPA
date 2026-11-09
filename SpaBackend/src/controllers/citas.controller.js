const pool = require('../db');

const registrarCita = async (req, res) => {
    const client = await pool.connect();

    try {
        const { id_usuario, rol } = req.usuario;

        // Solo los clientes pueden registrar citas
        if (Number(rol) !== 3) {
            return res.status(403).json({
                error: 'No tienes permiso para registrar citas'
            });
        }

        // Obtener el ID del cliente desde su sesión autenticada
        const clienteAutenticado = await client.query(
            `SELECT id_cliente
             FROM clientes
             WHERE id_usuario = $1`,
            [id_usuario]
        );

        if (clienteAutenticado.rows.length === 0) {
            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const id_cliente = clienteAutenticado.rows[0].id_cliente;

        // Los demás datos sí se reciben desde Flutter
        const {
            id_servicio,
            id_empleado,
            fecha,
            hora_inicio,
            observaciones
        } = req.body;

        // 1. Validar campos obligatorios
        if (
            !id_cliente ||
            !id_servicio ||
            !id_empleado ||
            !fecha ||
            !hora_inicio
        ) {
            return res.status(400).json({
                error: 'Cliente, servicio, empleado, fecha y hora son obligatorios'
            });
        }

        // 2. Validar que los IDs sean numéricos
        if (
            isNaN(id_cliente) ||
            isNaN(id_servicio) ||
            isNaN(id_empleado)
        ) {
            return res.status(400).json({
                error: 'Los IDs deben ser valores numéricos'
            });
        }

        // 3. Verificar que el cliente exista
        const clienteResult = await client.query(
            `SELECT id_cliente
             FROM clientes
             WHERE id_cliente = $1`,
            [id_cliente]
        );

        if (clienteResult.rows.length === 0) {
            return res.status(404).json({
                error: 'El cliente no existe'
            });
        }

        // 4. Verificar que el servicio exista y esté activo
        const servicioResult = await client.query(
            `SELECT
                id_servicio,
                duracion,
                precio
             FROM servicios
             WHERE id_servicio = $1
               AND estado = true`,
            [id_servicio]
        );

        if (servicioResult.rows.length === 0) {
            return res.status(404).json({
                error: 'El servicio no existe o está inactivo'
            });
        }

        const servicio = servicioResult.rows[0];

        // 5. Verificar que el empleado exista y esté activo
        const empleadoResult = await client.query(
            `SELECT
                e.id_empleado
             FROM empleados e
             INNER JOIN usuarios u
                ON u.id_usuario = e.id_usuario
             WHERE e.id_empleado = $1
               AND u.estado = true`,
            [id_empleado]
        );

        if (empleadoResult.rows.length === 0) {
            return res.status(404).json({
                error: 'El empleado no existe o está inactivo'
            });
        }

        // 6. Verificar que el empleado pueda realizar el servicio
        const relacionResult = await client.query(
            `SELECT 1
             FROM empleado_servicios
             WHERE id_empleado = $1
               AND id_servicio = $2`,
            [id_empleado, id_servicio]
        );

        if (relacionResult.rows.length === 0) {
            return res.status(400).json({
                error: 'El empleado no puede realizar este servicio'
            });
        }

        // 7. Verificar que el empleado tenga horario ese día
        const horarioResult = await client.query(
            `SELECT
                hora_inicio,
                hora_fin
             FROM horarios
             WHERE id_empleado = $1
               AND dia_semana =
                   CASE EXTRACT(DOW FROM $2::date)
                       WHEN 0 THEN 'Domingo'
                       WHEN 1 THEN 'Lunes'
                       WHEN 2 THEN 'Martes'
                       WHEN 3 THEN 'Miercoles'
                       WHEN 4 THEN 'Jueves'
                       WHEN 5 THEN 'Viernes'
                       WHEN 6 THEN 'Sabado'
                   END`,
            [id_empleado, fecha]
        );

        if (horarioResult.rows.length === 0) {
            return res.status(400).json({
                error: 'El empleado no tiene horario disponible ese día'
            });
        }

        // 8. Verificar que la hora de inicio esté dentro del horario
        const horaInicio = hora_inicio;
        const duracion = servicio.duracion;

        const horarioValido = horarioResult.rows.some(horario => {
            return horaInicio >= horario.hora_inicio &&
                   horaInicio < horario.hora_fin;
        });

        if (!horarioValido) {
            return res.status(400).json({
                error: 'La hora seleccionada está fuera del horario del empleado'
            });
        }

        // 9. Verificar conflictos con otras citas
        const conflictoResult = await client.query(
            `SELECT id_cita
             FROM citas
             WHERE id_empleado = $1
               AND fecha = $2
               AND estado IN ('Pendiente', 'Confirmada')
               AND (
                   $3::time <
                       (hora_inicio + (duracion_aplicada * INTERVAL '1 minute'))
                   AND
                   ($3::time + ($4 * INTERVAL '1 minute')) >
                       hora_inicio
               )`,
            [
                id_empleado,
                fecha,
                hora_inicio,
                duracion
            ]
        );

        if (conflictoResult.rows.length > 0) {
            return res.status(409).json({
                error: 'El empleado ya tiene una cita en ese horario'
            });
        }

        // 10. Verificar que la cita termine dentro del horario laboral
        const terminaDentroHorario = horarioResult.rows.some(horario => {
            return (
                horaInicio >= horario.hora_inicio &&
                (
                    new Date(`1970-01-01T${horaInicio}`).getTime()
                    + duracion * 60000
                ) <=
                new Date(`1970-01-01T${horario.hora_fin}`).getTime()
            );
        });

        if (!terminaDentroHorario) {
            return res.status(400).json({
                error: 'El servicio terminaría fuera del horario del empleado'
            });
        }

        // 11. Registrar la cita
        const citaResult = await client.query(
            `INSERT INTO citas (
                id_cliente,
                id_empleado,
                id_servicio,
                fecha,
                hora_inicio,
                duracion_aplicada,
                precio_aplicado,
                estado,
                observaciones
            )
            VALUES (
                $1, $2, $3, $4, $5,
                $6, $7, 'Pendiente', $8
            )
            RETURNING *`,
            [
                id_cliente,
                id_empleado,
                id_servicio,
                fecha,
                hora_inicio,
                servicio.duracion,
                servicio.precio,
                observaciones || null
            ]
        );

        return res.status(201).json({
            mensaje: 'Cita registrada correctamente',
            cita: citaResult.rows[0]
        });

    } catch (error) {
        console.error('Error al registrar cita:', error.message);

        return res.status(500).json({
            error: 'Error interno al registrar la cita'
        });

    } finally {
        client.release();
    }
};



const obtenerCitas = async (req, res) => {
    const client = await pool.connect();

    try {
        const { id_usuario, rol } = req.usuario;

        // Solo se permiten los roles definidos para AuraSpa
        if (![1, 2, 3].includes(rol)) {
            return res.status(403).json({
                error: 'No tienes permiso para consultar las citas'
            });
        }

        const resultado = await client.query(`
            SELECT
                c.id_cita,
                c.fecha,
                c.hora_inicio,
                c.duracion_aplicada,
                c.precio_aplicado,
                c.estado,
                c.observaciones,

                cl.id_cliente,
                CONCAT(
                    cl.nombre, ' ',
                    cl.apellido_p, ' ',
                    COALESCE(cl.apellido_m, '')
                ) AS cliente,

                s.id_servicio,
                s.nombre AS servicio,

                e.id_empleado,
                CONCAT(
                    e.nombre, ' ',
                    e.apellido_p, ' ',
                    COALESCE(e.apellido_m, '')
                ) AS empleado

            FROM citas c

            INNER JOIN clientes cl
                ON cl.id_cliente = c.id_cliente

            INNER JOIN servicios s
                ON s.id_servicio = c.id_servicio

            INNER JOIN empleados e
                ON e.id_empleado = c.id_empleado

            WHERE
                $1::integer = 1
                OR (
                    $1::integer = 2
                    AND e.id_usuario = $2
                )
                OR (
                    $1::integer = 3
                    AND cl.id_usuario = $2
                )

            ORDER BY c.fecha ASC, c.hora_inicio ASC
        `, [rol, id_usuario]);

        return res.status(200).json({
            mensaje: 'Citas obtenidas correctamente',
            citas: resultado.rows
        });

    } catch (error) {
        console.error('Error al obtener citas:', error.message);

        return res.status(500).json({
            error: 'Error interno al obtener las citas'
        });

    } finally {
        client.release();
    }
};



const obtenerCitasCliente = async (req, res) => {
    const client = await pool.connect();

    try {
        // Normalizar los datos del token JWT
        const id_usuario = Number(req.usuario?.id_usuario);
        const rol = Number(req.usuario?.rol);
        const id_cliente_solicitado = Number(req.params.id_cliente);

        // Validar identidad y rol
        if (
            !Number.isInteger(id_usuario) ||
            id_usuario <= 0 ||
            ![1, 3].includes(rol)
        ) {
            return res.status(403).json({
                error: 'No tienes permiso para consultar estas citas'
            });
        }

        // Validar ID de la URL
        if (
            !Number.isInteger(id_cliente_solicitado) ||
            id_cliente_solicitado <= 0
        ) {
            return res.status(400).json({
                error: 'El ID del cliente no es válido'
            });
        }

        let id_cliente_autorizado = id_cliente_solicitado;

        // El cliente solo puede consultar su propio perfil
        if (rol === 3) {
            const perfil = await client.query(
                `SELECT id_cliente
                 FROM clientes
                 WHERE id_usuario = $1`,
                [id_usuario]
            );

            if (perfil.rows.length === 0) {
                return res.status(403).json({
                    error: 'No se encontró un perfil de cliente autorizado'
                });
            }

            id_cliente_autorizado = Number(perfil.rows[0].id_cliente);

            if (id_cliente_solicitado !== id_cliente_autorizado) {
                return res.status(403).json({
                    error: 'Solo puedes consultar tus propias citas'
                });
            }
        }

        // Consultar únicamente las citas autorizadas
        const resultado = await client.query(
            `SELECT
                c.id_cita,
                c.fecha,
                c.hora_inicio,
                c.duracion_aplicada,
                c.precio_aplicado,
                c.estado,
                c.observaciones,
                cl.id_cliente,
                s.id_servicio,
                s.nombre AS servicio,
                e.id_empleado,
                CONCAT(
                    e.nombre, ' ',
                    e.apellido_p, ' ',
                    COALESCE(e.apellido_m, '')
                ) AS empleado
             FROM citas c
             INNER JOIN clientes cl
                ON cl.id_cliente = c.id_cliente
             INNER JOIN servicios s
                ON s.id_servicio = c.id_servicio
             INNER JOIN empleados e
                ON e.id_empleado = c.id_empleado
             WHERE c.id_cliente = $1
             ORDER BY c.fecha DESC, c.hora_inicio DESC`,
            [id_cliente_autorizado]
        );

        return res.status(200).json({
            mensaje: 'Citas del cliente obtenidas correctamente',
            citas: resultado.rows
        });

    } catch (error) {
        console.error(
            'Error al obtener citas del cliente:',
            error.message
        );

        return res.status(500).json({
            error: 'Error interno al obtener las citas del cliente'
        });
    } finally {
        client.release();
    }
};


const apartarHorario = async (req, res) => {
    const { id_usuario, rol } = req.usuario;

    // Solo los clientes pueden apartar horarios.
    if (Number(rol) !== 3) {
        return res.status(403).json({
            error: 'No tienes permiso para apartar horarios'
        });
    }

    const {
        id_servicio,
        id_empleado,
        fecha,
        hora_inicio
    } = req.body;

    const servicioId = Number(id_servicio);
    const empleadoId = id_empleado == null ? 0 : Number(id_empleado);

    // Validar datos recibidos.
    if (
        !Number.isInteger(servicioId) ||
        servicioId <= 0 ||
        !Number.isInteger(empleadoId) ||
        empleadoId < 0 ||
        !fecha ||
        !hora_inicio
    ) {
        return res.status(400).json({
            error: 'Servicio, fecha y hora son obligatorios y válidos'
        });
    }

    // Validar formato de fecha y hora.
    if (
        !/^\d{4}-\d{2}-\d{2}$/.test(fecha) ||
        !/^([01]\d|2[0-3]):[0-5]\d$/.test(hora_inicio)
    ) {
        return res.status(400).json({
            error: 'La fecha o la hora tienen un formato inválido'
        });
    }

    const client = await pool.connect();
    let transaccionIniciada = false;

    try {
        await client.query('BEGIN');
        transaccionIniciada = true;

        // 1. Obtener el cliente desde el JWT.
        const clienteResult = await client.query(
            `SELECT id_cliente
             FROM clientes
             WHERE id_usuario = $1`,
            [id_usuario]
        );

        if (clienteResult.rows.length === 0) {
            throw Object.assign(
                new Error('No se encontró el perfil del cliente'),
                { status: 404 }
            );
        }

        const id_cliente = clienteResult.rows[0].id_cliente;

        // 2. Validar que la fecha y hora sean futuras.
        const fechaValida = await client.query(
            `SELECT (
                $1::date > CURRENT_DATE
                OR (
                    $1::date = CURRENT_DATE
                    AND $2::time > LOCALTIME
                )
            ) AS es_futuro`,
            [fecha, hora_inicio]
        );

        if (!fechaValida.rows[0].es_futuro) {
            throw Object.assign(
                new Error('Selecciona una fecha y hora futuras'),
                { status: 400 }
            );
        }

        // 3. Obtener la duración del servicio activo.
        const servicioResult = await client.query(
            `SELECT id_servicio, duracion
             FROM servicios
             WHERE id_servicio = $1
               AND estado = true`,
            [servicioId]
        );

        if (servicioResult.rows.length === 0) {
            throw Object.assign(
                new Error('El servicio no existe o está inactivo'),
                { status: 404 }
            );
        }

        const duracion = servicioResult.rows[0].duracion;

        // 4. Eliminar apartados que ya vencieron.
        await client.query(
            `DELETE FROM reservas_temporales
             WHERE fecha_expiracion <= NOW()`
        );

        // 5. Obtener y bloquear especialistas elegibles.
        // FOR UPDATE evita que otra solicitud de este endpoint
        // aparte simultáneamente al mismo especialista.
        const empleadosResult = await client.query(
            `SELECT
                e.id_empleado,
                e.nombre,
                e.apellido_p,
                e.apellido_m,
                u.foto,
                p.nombre AS puesto

             FROM empleados e

             INNER JOIN usuarios u
                ON u.id_usuario = e.id_usuario

             INNER JOIN puestos p
                ON p.id_puesto = e.id_puesto

             INNER JOIN empleado_servicios es
                ON es.id_empleado = e.id_empleado

             WHERE es.id_servicio = $1
               AND u.estado = true
               AND (
                   $2::integer = 0
                   OR e.id_empleado = $2
               )

               AND EXISTS (
                   SELECT 1
                   FROM horarios h
                   WHERE h.id_empleado = e.id_empleado

                     AND h.dia_semana =
                         CASE EXTRACT(DOW FROM $3::date)
                             WHEN 0 THEN 'Domingo'
                             WHEN 1 THEN 'Lunes'
                             WHEN 2 THEN 'Martes'
                             WHEN 3 THEN 'Miercoles'
                             WHEN 4 THEN 'Jueves'
                             WHEN 5 THEN 'Viernes'
                             WHEN 6 THEN 'Sabado'
                         END

                     AND $4::time >= h.hora_inicio

                     AND (
                         $4::time +
                         ($5::integer * INTERVAL '1 minute')
                     ) <= h.hora_fin
               )

             ORDER BY e.id_empleado

             FOR UPDATE OF e`,
            [
                servicioId,
                empleadoId,
                fecha,
                hora_inicio,
                duracion
            ]
        );

        if (empleadosResult.rows.length === 0) {
            throw Object.assign(
                new Error(
                    'No hay especialistas que puedan realizar este servicio en ese horario'
                ),
                { status: 409 }
            );
        }

        // 6. Buscar un especialista que no tenga conflictos.
        let empleadoDisponible = null;

        for (const empleado of empleadosResult.rows) {

            // Comprobar citas definitivas.
            const citasResult = await client.query(
                `SELECT 1
                 FROM citas
                 WHERE id_empleado = $1
                   AND fecha = $2
                   AND estado IN ('Pendiente', 'Confirmada')
                   AND (
                       $3::time <
                           hora_inicio +
                           (duracion_aplicada * INTERVAL '1 minute')

                       AND

                       (
                           $3::time +
                           ($4::integer * INTERVAL '1 minute')
                       ) > hora_inicio
                   )
                 LIMIT 1`,
                [
                    empleado.id_empleado,
                    fecha,
                    hora_inicio,
                    duracion
                ]
            );

            if (citasResult.rows.length > 0) {
                continue;
            }

            // Comprobar apartados temporales vigentes.
            const reservasResult = await client.query(
                `SELECT 1
                 FROM reservas_temporales
                 WHERE id_empleado = $1
                   AND fecha = $2
                   AND fecha_expiracion > NOW()
                   AND (
                       $3::time <
                           hora_inicio +
                           (duracion * INTERVAL '1 minute')

                       AND

                       (
                           $3::time +
                           ($4::integer * INTERVAL '1 minute')
                       ) > hora_inicio
                   )
                 LIMIT 1`,
                [
                    empleado.id_empleado,
                    fecha,
                    hora_inicio,
                    duracion
                ]
            );

            if (reservasResult.rows.length > 0) {
                continue;
            }

            empleadoDisponible = empleado;
            break;
        }

        if (!empleadoDisponible) {
            throw Object.assign(
                new Error(
                    'El horario ya no está disponible. Selecciona otro especialista u horario'
                ),
                { status: 409 }
            );
        }

        // 7. Crear el apartado temporal.
        const reservaResult = await client.query(
            `INSERT INTO reservas_temporales (
                id_cliente,
                id_empleado,
                id_servicio,
                fecha,
                hora_inicio,
                duracion,
                fecha_expiracion
            )
            VALUES (
                $1, $2, $3, $4, $5, $6,
                NOW() + INTERVAL '5 minutes'
            )
            RETURNING
                id_reserva,
                fecha,
                hora_inicio,
                duracion,
                fecha_expiracion`,
            [
                id_cliente,
                empleadoDisponible.id_empleado,
                servicioId,
                fecha,
                hora_inicio,
                duracion
            ]
        );

        await client.query('COMMIT');
        transaccionIniciada = false;

        return res.status(201).json({
            mensaje: 'Horario apartado correctamente',
            reserva: reservaResult.rows[0],
            empleado: empleadoDisponible
        });

    } catch (error) {

        if (transaccionIniciada) {
            await client.query('ROLLBACK');
        }

        console.error('Error al apartar horario:', error.message);

        return res.status(error.status || 500).json({
            error: error.status
                ? error.message
                : 'Error interno al apartar el horario'
        });

    } finally {
        client.release();
    }
};



const confirmarApartado = async (req, res) => {
    const id_usuario = Number(req.usuario?.id_usuario);
    const rol = Number(req.usuario?.rol);

    const id_reserva = Number(req.body.id_reserva);
    const observaciones = req.body.observaciones?.trim() || null;

    if (rol !== 3) {
        return res.status(403).json({
            error: 'Solo los clientes pueden confirmar apartados'
        });
    }

    if (
        !Number.isInteger(id_usuario) || id_usuario <= 0 ||
        !Number.isInteger(id_reserva) || id_reserva <= 0
    ) {
        return res.status(400).json({
            error: 'El identificador del apartado no es válido'
        });
    }

    if (observaciones !== null &&
        (typeof observaciones !== 'string' || observaciones.length > 500)) {
        return res.status(400).json({
            error: 'Las observaciones no pueden superar 500 caracteres'
        });
    }

    const client = await pool.connect();
    let transaccionIniciada = false;

    try {
        await client.query('BEGIN');
        transaccionIniciada = true;

        // Obtener el cliente asociado al usuario autenticado.
        const cliente = await client.query(
            `SELECT id_cliente
             FROM clientes
             WHERE id_usuario = $1`,
            [id_usuario]
        );

        if (cliente.rows.length === 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(404).json({
                error: 'No se encontró el perfil del cliente'
            });
        }

        const id_cliente = cliente.rows[0].id_cliente;

        // Bloquear el apartado mientras se confirma.
        const apartado = await client.query(
            `SELECT
                id_reserva,
                id_cliente,
                id_empleado,
                id_servicio,
                fecha,
                hora_inicio,
                duracion,
                fecha_expiracion
             FROM reservas_temporales
             WHERE id_reserva = $1
               AND id_cliente = $2
             FOR UPDATE`,
            [id_reserva, id_cliente]
        );

        if (apartado.rows.length === 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(404).json({
                error: 'El apartado no existe o no te pertenece'
            });
        }

        const reserva = apartado.rows[0];

        // Verificar que el apartado siga vigente.
        const vigencia = await client.query(
            `SELECT fecha_expiracion > NOW() AS vigente
             FROM reservas_temporales
             WHERE id_reserva = $1`,
            [id_reserva]
        );

        if (!vigencia.rows[0].vigente) {
            await client.query(
                `DELETE FROM reservas_temporales
                 WHERE id_reserva = $1`,
                [id_reserva]
            );

            await client.query('COMMIT');
            transaccionIniciada = false;

            return res.status(410).json({
                error: 'El apartado ha expirado. Debes seleccionar otro horario'
            });
        }

        // Consultar el precio actual del servicio.
        const servicio = await client.query(
            `SELECT precio
             FROM servicios
             WHERE id_servicio = $1
               AND estado = true`,
            [reserva.id_servicio]
        );

        if (servicio.rows.length === 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(409).json({
                error: 'El servicio ya no está disponible'
            });
        }

        // Comprobar que el empleado siga activo.
        const empleado = await client.query(
            `SELECT 1
             FROM empleados e
             INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
             WHERE e.id_empleado = $1
               AND u.estado = true`,
            [reserva.id_empleado]
        );

        if (empleado.rows.length === 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(409).json({
                error: 'El especialista ya no está disponible'
            });
        }

        // Volver a comprobar que no exista otra cita que se cruce.
        const conflicto = await client.query(
            `SELECT 1
             FROM citas c
             WHERE c.id_empleado = $1
               AND c.fecha = $2
               AND c.estado IN ('Pendiente', 'Confirmada')
               AND $3::time <
                   c.hora_inicio + (c.duracion_aplicada * INTERVAL '1 minute')
               AND $3::time + ($4 * INTERVAL '1 minute') >
                   c.hora_inicio
             LIMIT 1`,
            [
                reserva.id_empleado,
                reserva.fecha,
                reserva.hora_inicio,
                reserva.duracion
            ]
        );

        if (conflicto.rows.length > 0) {
            await client.query('ROLLBACK');
            transaccionIniciada = false;

            return res.status(409).json({
                error: 'El horario ya no está disponible'
            });
        }

        // Crear la cita definitiva.
        const nuevaCita = await client.query(
            `INSERT INTO citas (
                id_cliente,
                id_empleado,
                id_servicio,
                fecha,
                hora_inicio,
                duracion_aplicada,
                precio_aplicado,
                estado,
                observaciones
            )
            VALUES ($1, $2, $3, $4, $5, $6, $7, 'Pendiente', $8)
            RETURNING *`,
            [
                id_cliente,
                reserva.id_empleado,
                reserva.id_servicio,
                reserva.fecha,
                reserva.hora_inicio,
                reserva.duracion,
                servicio.rows[0].precio,
                observaciones
            ]
        );

        // Eliminar el apartado temporal.
        await client.query(
            `DELETE FROM reservas_temporales
             WHERE id_reserva = $1`,
            [id_reserva]
        );

        await client.query('COMMIT');
        transaccionIniciada = false;

        return res.status(201).json({
            mensaje: 'Cita confirmada correctamente',
            cita: nuevaCita.rows[0]
        });

    } catch (error) {
        if (transaccionIniciada) {
            await client.query('ROLLBACK');
        }

        console.error('Error al confirmar apartado:', error);

        return res.status(500).json({
            error: 'Error al confirmar la cita'
        });

    } finally {
        client.release();
    }
};



const cancelarApartado = async (req, res) => {
    const id_usuario = Number(req.usuario?.id_usuario);
    const rol = Number(req.usuario?.rol);
    const id_reserva = Number(req.params.id_reserva);

    // Solo los clientes pueden cancelar sus apartados.
    if (rol !== 3) {
        return res.status(403).json({
            error: 'No tienes permiso para cancelar apartados'
        });
    }

    if (
        !Number.isInteger(id_usuario) ||
        id_usuario <= 0 ||
        !Number.isInteger(id_reserva) ||
        id_reserva <= 0
    ) {
        return res.status(400).json({
            error: 'El ID del apartado no es válido'
        });
    }

    const client = await pool.connect();

    try {
        // Eliminar únicamente un apartado perteneciente
        // al cliente identificado mediante el JWT.
        const resultado = await client.query(
            `DELETE FROM reservas_temporales r
             USING clientes c
             WHERE r.id_reserva = $1
               AND r.id_cliente = c.id_cliente
               AND c.id_usuario = $2
             RETURNING r.id_reserva`,
            [id_reserva, id_usuario]
        );

        if (resultado.rows.length === 0) {
            return res.status(404).json({
                error: 'El apartado no existe o ya no está disponible'
            });
        }

        return res.status(200).json({
            mensaje: 'Apartado cancelado correctamente',
            id_reserva: resultado.rows[0].id_reserva
        });

    } catch (error) {
        console.error('Error al cancelar apartado:', error.message);

        return res.status(500).json({
            error: 'Error interno al cancelar el apartado'
        });

    } finally {
        client.release();
    }
};


const obtenerDisponibilidad = async (req, res) => {
    try {
        const servicioId = Number(req.query.id_servicio);
        const fecha = req.query.fecha;

        // 1. Validar parámetros.
        if (
            !Number.isInteger(servicioId) ||
            servicioId <= 0 ||
            typeof fecha !== 'string' ||
            !/^\d{4}-\d{2}-\d{2}$/.test(fecha)
        ) {
            return res.status(400).json({
                error: 'El servicio y la fecha son obligatorios y válidos'
            });
        }

        // 2. Validar que la fecha exista.
        const [anio, mes, diaMes] = fecha.split('-').map(Number);
        const fechaComprobada = new Date(
            Date.UTC(anio, mes - 1, diaMes)
        );

        if (
            fechaComprobada.getUTCFullYear() !== anio ||
            fechaComprobada.getUTCMonth() !== mes - 1 ||
            fechaComprobada.getUTCDate() !== diaMes
        ) {
            return res.status(400).json({
                error: 'La fecha no existe'
            });
        }

        const dia = fechaComprobada.getUTCDay();

        if (dia === 0 || dia === 6) {
            return res.status(200).json({ horarios: [] });
        }

        // 3. Obtener duración del servicio.
        const servicioResult = await pool.query(
            `SELECT duracion
             FROM servicios
             WHERE id_servicio = $1
               AND estado = true`,
            [servicioId]
        );

        if (servicioResult.rows.length === 0) {
            return res.status(404).json({
                error: 'El servicio no existe o está inactivo'
            });
        }

        const duracion = Number(servicioResult.rows[0].duracion);

        if (!Number.isInteger(duracion) || duracion <= 0) {
            return res.status(500).json({
                error: 'La duración del servicio no es válida'
            });
        }

        // 4. Obtener día de la semana.
        const dias = [
            'Domingo',
            'Lunes',
            'Martes',
            'Miercoles',
            'Jueves',
            'Viernes',
            'Sabado'
        ];

        const diaSemana = dias[dia];

        // 5. Generar horarios desde la entrada de cada empleado.
        const resultado = await pool.query(
            `WITH RECURSIVE empleados_horarios AS (
                SELECT DISTINCT
                    e.id_empleado,
                    h.hora_inicio AS inicio_jornada,
                    h.hora_fin AS fin_jornada
                FROM empleados e
                INNER JOIN usuarios u
                    ON u.id_usuario = e.id_usuario
                INNER JOIN empleado_servicios es
                    ON es.id_empleado = e.id_empleado
                INNER JOIN horarios h
                    ON h.id_empleado = e.id_empleado
                WHERE es.id_servicio = $1
                  AND u.estado = true
                  AND h.dia_semana = $2
            ),
            horarios_generados AS (
                SELECT
                    id_empleado,
                    inicio_jornada AS hora_inicio,
                    fin_jornada
                FROM empleados_horarios

                UNION ALL

                SELECT
                    id_empleado,
                    hora_inicio + ($3::integer * INTERVAL '1 minute'),
                    fin_jornada
                FROM horarios_generados
                WHERE hora_inicio +
                    ($3::integer * INTERVAL '1 minute')
                    <= fin_jornada
            )
            SELECT DISTINCT
                TO_CHAR(g.hora_inicio, 'HH24:MI') AS hora
            FROM horarios_generados g
            WHERE
                g.hora_inicio +
                    ($3::integer * INTERVAL '1 minute')
                    <= g.fin_jornada

                -- Si es hoy, exigir una hora de anticipación.
                AND (
                    $4::date > CURRENT_DATE
                    OR (
                        $4::date = CURRENT_DATE
                        AND g.hora_inicio > LOCALTIME + INTERVAL '1 hour'
                    )
                )

                -- Excluir citas ocupadas.
                AND NOT EXISTS (
                    SELECT 1
                    FROM citas c
                    WHERE c.id_empleado = g.id_empleado
                      AND c.fecha = $4::date
                      AND c.estado IN ('Pendiente', 'Confirmada')
                      AND g.hora_inicio <
                          c.hora_inicio +
                          (c.duracion_aplicada * INTERVAL '1 minute')
                      AND g.hora_inicio +
                          ($3::integer * INTERVAL '1 minute') >
                          c.hora_inicio
                )

                -- Excluir apartados temporales vigentes.
                AND NOT EXISTS (
                    SELECT 1
                    FROM reservas_temporales r
                    WHERE r.id_empleado = g.id_empleado
                      AND r.fecha = $4::date
                      AND r.fecha_expiracion > NOW()
                      AND g.hora_inicio <
                          r.hora_inicio +
                          (r.duracion * INTERVAL '1 minute')
                      AND g.hora_inicio +
                          ($3::integer * INTERVAL '1 minute') >
                          r.hora_inicio
                )

            ORDER BY hora`,
            [servicioId, diaSemana, duracion, fecha]
        );

        return res.status(200).json({
            horarios: resultado.rows.map(row => row.hora)
        });

    } catch (error) {
        console.error(
            'Error al consultar disponibilidad:',
            error.message
        );

        return res.status(500).json({
            error: 'Error al consultar los horarios disponibles'
        });
    }
};



module.exports = {
    registrarCita,
    obtenerCitas,
    obtenerCitasCliente,
    apartarHorario,
    confirmarApartado,
    cancelarApartado,
    obtenerDisponibilidad
};