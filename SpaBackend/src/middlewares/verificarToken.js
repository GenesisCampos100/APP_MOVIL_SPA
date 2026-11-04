
const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;

if (!JWT_SECRET) {
    throw new Error(
        'Error de configuración: JWT_SECRET no está definido'
    );
}

const verificarToken = (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            error: 'Token de autenticación requerido'
        });
    }

    const token = authHeader.slice(7).trim();

    if (!token) {
        return res.status(401).json({
            error: 'Token de autenticación requerido'
        });
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET, {
            algorithms: ['HS256']
        });

        // Comprobar la estructura mínima del token
        if (
            !decoded ||
            typeof decoded !== 'object' ||
            decoded.id_usuario == null ||
            decoded.rol == null
        ) {
            return res.status(401).json({
                error: 'El token no contiene datos válidos'
            });
        }

        req.usuario = {
            id_usuario: decoded.id_usuario,
            rol: decoded.rol
        };

        return next();

    } catch (error) {
        return res.status(401).json({
            error: 'Token inválido o expirado'
        });
    }
};

module.exports = verificarToken;
