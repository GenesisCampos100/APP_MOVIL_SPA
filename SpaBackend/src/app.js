const express = require('express');
const pool = require('./db');


const app = express();
app.use(express.json());


const authRoutes = require('./routes/auth.routes'); // Rutas de autenticación
const serviciosRoutes = require('./routes/servicios.routes'); //Rutas de servicios
const citasRoutes = require('./routes/citas.routes'); //Rutas de citas
const pruebaRoutes = require('./routes/prueba.routes'); // Rutas de prueba para verificar token
const usuariosRoutes = require('./routes/usuarios.routes'); // Rutas de usuarios

app.use('/api/auth', authRoutes);
app.use('/api/servicios', serviciosRoutes);
app.use('/api/citas', citasRoutes);
app.use('/api/prueba', pruebaRoutes);
app.use('/api/usuarios', usuariosRoutes);

module.exports = app;