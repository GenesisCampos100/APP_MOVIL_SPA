
const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    limit: 10, // Máximo 10 solicitudes por ventana
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        error: 'Demasiados intentos de inicio de sesión. Inténtalo de nuevo en 15 minutos.'
    }
});

module.exports = loginLimiter;
