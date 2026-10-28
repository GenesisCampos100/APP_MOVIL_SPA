
const registrosPendientes = new Map();

const TIEMPO_EXPIRACION = 10 * 60 * 1000;
const MAX_INTENTOS = 5;

const guardarRegistro = (correo, datos) => {
    registrosPendientes.set(correo, {
        ...datos,
        expiraEn: Date.now() + TIEMPO_EXPIRACION,
        intentos: 0
    });
};

const obtenerRegistro = (correo) => {
    const registro = registrosPendientes.get(correo);

    if (!registro) {
        return null;
    }

    if (Date.now() >= registro.expiraEn) {
        registrosPendientes.delete(correo);
        return null;
    }

    return registro;
};

const incrementarIntentos = (correo) => {
    const registro = obtenerRegistro(correo);

    if (!registro) {
        return false;
    }

    registro.intentos += 1;

    if (registro.intentos >= MAX_INTENTOS) {
        registrosPendientes.delete(correo);
        return false;
    }

    return true;
};

const eliminarRegistro = (correo) => {
    registrosPendientes.delete(correo);
};

module.exports = {
    guardarRegistro,
    obtenerRegistro,
    incrementarIntentos,
    eliminarRegistro
};
