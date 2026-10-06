const express = require('express');
const pool = require('./db');


const app = express();
app.use(express.json());


const authRoutes = require('./routes/auth.routes'); // Rutas de autenticación
app.use('/api/auth', authRoutes);


module.exports = app;