const pool = require('../db');

const registrarCita = async (req, res) => {
    const client = await pool.connect();

    try {
        const {
            id_cliente,
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

            ORDER BY c.fecha ASC, c.hora_inicio ASC
        `);

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

module.exports = {
    registrarCita,
    obtenerCitas
};