
const express = require('express');

const app = express();

app.use(express.json());

// Rutas compartidas
const authRoutes = require('./routes/auth.routes');
const serviciosRoutes = require('./routes/servicios.routes');
const citasRoutes = require('./routes/citas.routes');
const pruebaRoutes = require('./routes/prueba.routes');

// Rutas de Vanessa
const usuariosRoutes = require('./routes/usuarios.routes');

// Rutas administrativas de GENESIS
const adminServiciosRoutes = require('./routes/admin_servicios.routes');
const adminEmpleadosRoutes = require('./routes/admin_empleados.routes');
const adminHorariosRoutes = require('./routes/admin_horarios.routes');

// Registrar rutas compartidas
app.use('/api/auth', authRoutes);
app.use('/api/servicios', serviciosRoutes);
app.use('/api/citas', citasRoutes);
app.use('/api/prueba', pruebaRoutes);

// Registrar rutas de usuarios
app.use('/api/usuarios', usuariosRoutes);

// Registrar rutas administrativas
app.use('/api/admin/servicios', adminServiciosRoutes);
app.use('/api/admin/empleados', adminEmpleadosRoutes);
app.use('/api/admin/horarios', adminHorariosRoutes);

module.exports = app;
