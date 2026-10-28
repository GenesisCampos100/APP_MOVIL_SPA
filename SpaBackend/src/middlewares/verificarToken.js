
const jwt = require('jsonwebtoken');

const verificarToken = (req, res, next) => {
    const authHeader = req.headers.authorization;

    // Comprobar que exista el encabezado Authorization
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            error: 'Token de autenticación requerido'
        });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(
            token,
            process.env.JWT_SECRET,
            {
                algorithms: ['HS256']
            }
        );

        // Guardar los datos del usuario autenticado
        req.usuario = decoded;

        next();
    } catch (error) {
        return res.status(401).json({
            error: 'Token inválido o expirado'
        });
    }
};

module.exports = verificarToken;
