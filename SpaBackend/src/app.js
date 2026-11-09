const express = require('express');
const pool = require('./db');


const app = express();
app.use(express.json());


const authRoutes = require('./routes/auth.routes'); // Rutas de autenticación
const serviciosRoutes = require('./routes/servicios.routes'); //Rutas de servicios
const citasRoutes = require('./routes/citas.routes'); //Rutas de citas
const pruebaRoutes = require('./routes/prueba.routes'); // Rutas de prueba para verificar token
const adminServiciosRoutes = require('./routes/admin_servicios.routes');
const adminEmpleadosRoutes = require('./routes/admin_empleados.routes');
const adminHorariosRoutes = require('./routes/admin_horarios.routes');

app.use('/api/auth', authRoutes);
app.use('/api/servicios', serviciosRoutes);
app.use('/api/citas', citasRoutes);
app.use('/api/prueba', pruebaRoutes);
app.use('/api/admin/servicios', adminServiciosRoutes);
app.use('/api/admin/empleados', adminEmpleadosRoutes);
app.use('/api/admin/horarios', adminHorariosRoutes);

module.exports = app;