
const express = require('express');
const app = express();

// Reconocer el proxy inverso de Railway.
app.set('trust proxy', 1);

app.use(express.json());

// Rutas compartidas
const authRoutes = require('./routes/auth.routes');
const serviciosRoutes = require('./routes/servicios.routes');
const citasRoutes = require('./routes/citas.routes');
const pruebaRoutes = require('./routes/prueba.routes');
const dispositivosRoutes = require('./routes/dispositivos.routes');

// Rutas de Vanessa
const usuariosRoutes = require('./routes/usuarios.routes');
const notificacionesRoutes = require('./routes/notificaciones.routes');
const favoritosRoutes = require('./routes/favoritos.routes');

const iniciarRecordatorios = require('./jobs/recordatorios.job');
const iniciarCancelacionCitas = require('./jobs/cancelarCitas.job');

// Fotografías de perfil
const usuariosFotoRoutes = require('./routes/usuarios_foto.routes');
const {
  carpeta: carpetaFotosPerfil
} = require('./controllers/usuarios_foto.controller');

// Rutas administrativas de Génesis
const adminServiciosRoutes = require('./routes/admin_servicios.routes');
const adminServiciosImagenRoutes = require('./routes/admin_servicios_imagen.routes');

const {
  carpeta: carpetaImagenesServicios
} = require('./controllers/servicios_imagen.controller');

const adminEmpleadosRoutes = require('./routes/admin_empleados.routes');
const adminHorariosRoutes = require('./routes/admin_horarios.routes');
const personalRoutes = require('./routes/personal.routes');
const adminResenasRoutes = require('./routes/admin_resenas.routes');

// Registrar rutas compartidas
app.use('/api/auth', authRoutes);
app.use('/api/servicios', serviciosRoutes);
app.use('/api/citas', citasRoutes);
app.use('/api/prueba', pruebaRoutes);
app.use('/api/dispositivos', dispositivosRoutes);

// Registrar fotografías de perfil
app.use('/api/usuarios/foto', usuariosFotoRoutes);
app.use(
  '/uploads/perfiles',
  express.static(carpetaFotosPerfil, {
    index: false,
    dotfiles: 'deny'
  })
);

// Registrar rutas de usuarios
app.use('/api/usuarios', usuariosRoutes);

// Notificaciones y favoritos
app.use('/api/notificaciones', notificacionesRoutes);
app.use('/api/favoritos', favoritosRoutes);

// Registrar rutas administrativas
app.use('/api/admin/servicios', adminServiciosRoutes);
app.use('/api/admin/servicios/imagen', adminServiciosImagenRoutes);

app.use(
  '/uploads/servicios',
  express.static(carpetaImagenesServicios, {
    index: false,
    dotfiles: 'deny'
  })
);

app.use('/api/admin/empleados', adminEmpleadosRoutes);
app.use('/api/admin/horarios', adminHorariosRoutes);

// Rutas de Recepción
app.use('/api/personal', personalRoutes);

// Reseñas administrativas
app.use('/api/admin/resenas', adminResenasRoutes);


 // Procesos programados de Vanessa.
 // Se conservan para la integración definitiva, con activación independiente.
 // Ambos permanecen desactivados si no se configuran sus variables como 'true'.
 if (process.env.ENABLE_RECORDATORIOS_CRON === 'true') {
   iniciarRecordatorios();
 } else {
   console.log('Recordatorios automáticos desactivados.');
 }

 if (process.env.ENABLE_CANCELACION_CITAS_CRON === 'true') {
   iniciarCancelacionCitas();
 } else {
   console.log('Cancelaciones automáticas desactivadas.');
 }

 module.exports = app;

