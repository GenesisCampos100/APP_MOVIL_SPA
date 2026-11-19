const pool = require('../db');

// Operaciones exclusivas de Administrador: el router verifica JWT,
// rol 1 y estado activo antes de llamar estos controladores.
// No se modifica GET /api/servicios/:id/empleados (app Cliente).

const listarAsignacionesAdmin = async (_req, res) => {
    try {
        const resultado = await pool.query(`
            SELECT es.id_empleado, es.id_servicio
            FROM empleado_servicios es
            INNER JOIN empleados e ON e.id_empleado = es.id_empleado
            INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
            WHERE u.id_rol = 2
              AND u.estado = true
              AND e.id_puesto <> 5
            ORDER BY es.id_empleado, es.id_servicio
        `);
        return res.status(200).json(resultado.rows);
    } catch (error) {
        console.error('Error al consultar asignaciones:', error.message);
        return res.status(500).json({ error: 'No fue posible consultar las asignaciones.' });
    }
};

const reemplazarAsignacionesAdmin = async (req, res) => {
    const idEmpleado = Number(req.params.id);
    const ids = req.body?.id_servicios;

    if (!Number.isSafeInteger(idEmpleado) || idEmpleado <= 0) {
        return res.status(400).json({ error: 'El empleado no es válido.' });
    }
    if (!Array.isArray(ids) || ids.length > 100 ||
        !ids.every(id => Number.isSafeInteger(id) && id > 0)) {
        return res.status(400).json({ error: 'Selecciona una lista válida de servicios (máximo 100).' });
    }
    const solicitados = [...new Set(ids)];
    let db;
    let iniciada = false;
    try {
        db = await pool.connect();
        await db.query('BEGIN');
        iniciada = true;

        // Bloqueamos el registro para serializar modificaciones concurrentes
        // de las asignaciones de este empleado.
        const empleado = await db.query(`
            SELECT e.id_empleado, e.id_puesto, u.estado
            FROM empleados e
            INNER JOIN usuarios u ON u.id_usuario = e.id_usuario
            WHERE e.id_empleado = $1 AND u.id_rol = 2
            FOR UPDATE OF e
        `, [idEmpleado]);

        if (!empleado.rowCount) {
            await db.query('ROLLBACK');
            iniciada = false;
            return res.status(404).json({ error: 'El empleado no existe.' });
        }
        if (!empleado.rows[0].estado) {
            await db.query('ROLLBACK');
            iniciada = false;
            return res.status(409).json({ error: 'No se pueden asignar servicios a empleados inactivos.' });
        }
        if (Number(empleado.rows[0].id_puesto) === 5) {
            await db.query('ROLLBACK');
            iniciada = false;
            return res.status(409).json({ error: 'Recepción no realiza servicios especializados.' });
        }

        const actuales = await db.query(
            'SELECT id_servicio FROM empleado_servicios WHERE id_empleado = $1',
            [idEmpleado]
        );
        const idsActuales = new Set(actuales.rows.map(row => Number(row.id_servicio)));

        if (solicitados.length > 0) {
            const servicios = await db.query(
                'SELECT id_servicio, estado FROM servicios WHERE id_servicio = ANY($1::integer[])',
                [solicitados]
            );
            const disponibles = new Map(servicios.rows.map(s => [Number(s.id_servicio), s.estado]));
            const desconocidos = solicitados.filter(id => !disponibles.has(id));
            if (desconocidos.length > 0) {
                await db.query('ROLLBACK');
                iniciada = false;
                return res.status(400).json({ error: 'Uno o más servicios no existen.' });
            }
            // Se puede conservar o quitar una asignación anterior inactiva,
            // pero nunca asignar por primera vez un servicio desactivado.
            const nuevosInactivos = solicitados.filter(id => !disponibles.get(id) && !idsActuales.has(id));
            if (nuevosInactivos.length > 0) {
                await db.query('ROLLBACK');
                iniciada = false;
                return res.status(409).json({ error: 'No puedes asignar servicios inactivos.' });
            }
        }

        // La relación (empleado, servicio) es referenciada por citas.
        // NO borrar y reinsertar todas las filas: incluso borrar una fila sin
        // cambios rompe fk_citas_empleado_servicio si existen citas históricas.
        const idsSolicitados = new Set(solicitados);
        const agregar = solicitados.filter(id => !idsActuales.has(id));
        const retirar = [...idsActuales].filter(id => !idsSolicitados.has(id));

        if (retirar.length > 0) {
            // Toda cita (incluso cancelada/completada) forma parte del historial.
            // Sin cambios de esquema no se puede eliminar su relación FK.
            const vinculados = await db.query(`
                SELECT DISTINCT c.id_servicio, s.nombre
                FROM citas c
                INNER JOIN servicios s ON s.id_servicio = c.id_servicio
                WHERE c.id_empleado = $1
                  AND c.id_servicio = ANY($2::integer[])
                ORDER BY s.nombre
            `, [idEmpleado, retirar]);

            if (vinculados.rowCount > 0) {
                await db.query('ROLLBACK');
                iniciada = false;
                return res.status(409).json({
                    error: 'No puedes quitar servicios que ya tienen citas registradas. ' +
                           'Conserva esos servicios para proteger el historial.',
                    servicios_protegidos: vinculados.rows.map(row => ({
                        id_servicio: Number(row.id_servicio),
                        nombre: row.nombre,
                    })),
                });
            }
        }

        // Cambiamos únicamente las relaciones necesarias, en una transacción.
        // Esto permite guardar sin cambios o añadir servicios aunque existan
        // citas anteriores con el mismo especialista.
        if (agregar.length > 0) {
            await db.query(`
                INSERT INTO empleado_servicios (id_empleado, id_servicio)
                SELECT $1::integer, unnest($2::integer[])
                ON CONFLICT (id_empleado, id_servicio) DO NOTHING
            `, [idEmpleado, agregar]);
        }

        if (retirar.length > 0) {
            await db.query(`
                DELETE FROM empleado_servicios
                WHERE id_empleado = $1
                  AND id_servicio = ANY($2::integer[])
            `, [idEmpleado, retirar]);
        }
        await db.query('COMMIT');
        iniciada = false;
        return res.status(200).json({
            mensaje: 'Servicios asignados correctamente.',
            id_empleado: idEmpleado,
            id_servicios: solicitados,
        });
    } catch (error) {
        if (iniciada && db) await db.query('ROLLBACK').catch(() => {});
        console.error('Error al guardar asignaciones:', error.message);
        if (error.code === '23503') {
            return res.status(409).json({
                error: 'No se puede quitar la asignación porque existen citas ' +
                       'relacionadas. Se conservó el historial.'
            });
        }
        return res.status(500).json({ error: 'No fue posible guardar las asignaciones.' });
    } finally {
        if (db) db.release();
    }
};

module.exports = { listarAsignacionesAdmin, reemplazarAsignacionesAdmin };
