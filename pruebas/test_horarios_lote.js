'use strict';
// Pruebas aisladas sin PostgreSQL: no realizan escrituras reales.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../SpaBackend/src/controllers/admin_horarios.controller.js'), 'utf8');

async function invoke(body, handler) {
  const sent = [];
  const client = {
    async query(sql, args) {
      sent.push({ sql: sql.trim(), args });
      if (/^(BEGIN|COMMIT|ROLLBACK)$/i.test(sql.trim())) return {rowCount: 0, rows: []};
      return handler(sql, args);
    },
    release() { sent.push({ sql: 'released' }); },
  };
  const pool = { connect: async () => client, query: async () => ({rows:[], rowCount:0}) };
  const module = { exports: {} };
  vm.runInNewContext(source, { module, require: (requested) => {
    assert.equal(requested, '../db');
    return pool;
  }, console });
  let status = 200;
  let response;
  const res = { status(code){ status=code; return this; }, json(value){ response=value; return this; } };
  await module.exports.crearHorariosVariosAdmin({body},res);
  if (sent.length) assert.equal(sent.at(-1).sql,'released');
  return { status, response, sent };
}
const rows = (...data) => ({ rowCount: data.length, rows: data });
const valid = {
  id_empleado: 1,
  dias_semana: ['Lunes', 'Martes', 'Miércoles'],
  hora_inicio: '09:00', hora_fin: '17:00',
};
const handlerOkay = (sql) => {
  if (sql.includes('SELECT e.id_empleado')) return rows({id_empleado:1,estado:true});
  if (sql.includes('SELECT 1 FROM horarios')) return rows();
  if (sql.includes('INSERT INTO horarios')) return rows({id_horario:42});
  throw new Error('Unexpected query: '+sql);
};
(async () => {
  let r = await invoke(valid,handlerOkay);
  assert.equal(r.status,201);
  assert.equal(r.response.horarios.length,3);
  assert.deepEqual(r.sent.filter(q=>q.sql.includes('INSERT INTO horarios')).map(q=>q.args[1]),['Lunes','Martes','Miercoles']);
  assert.equal(r.sent.filter(q=>q.sql==='COMMIT').length,1);

  r = await invoke({...valid,dias_semana:[]},()=>{throw Error('unexpected database usage')});
  assert.equal(r.status,400);
  assert.equal(r.sent.length,0);

  r = await invoke({...valid,dias_semana:['Miércoles','Miercoles']},()=>{throw Error('unexpected database usage')});
  assert.equal(r.status,400);

  r = await invoke({...valid,dias_semana:['Lunes','Feriado']},()=>{throw Error('unexpected database usage')});
  assert.equal(r.status,400);

  r = await invoke(valid,(sql,args)=>{
    if (sql.includes('SELECT e.id_empleado')) return rows({id_empleado:1,estado:true});
    if (sql.includes('SELECT 1 FROM horarios')) return args[1]==='Martes'?rows({found:true}):rows();
    if (sql.includes('INSERT')) throw Error('Cannot insert before ALL validation');
    throw Error('Unexpected query '+sql);
  });
  assert.equal(r.status,409);
  assert(!r.sent.some(q=>q.sql.includes('INSERT INTO horarios')));
  assert(r.sent.some(q=>q.sql==='ROLLBACK'));

  let writes=0;
  r = await invoke(valid,(sql)=>{
    if (sql.includes('SELECT e.id_empleado')) return rows({id_empleado:1,estado:true});
    if (sql.includes('SELECT 1 FROM horarios')) return rows();
    if (sql.includes('INSERT INTO horarios')) {
      writes++;
      if (writes===2) throw Error('Simulated DB failure');
      return rows({id_horario:42});
    }
    throw Error('Unexpected query '+sql);
  });
  assert.equal(r.status,500);
  assert(r.sent.some(q=>q.sql==='ROLLBACK'));
  assert(!r.sent.some(q=>q.sql==='COMMIT'));

  console.log('OK: alta múltiple, normalización, días inválidos/repetidos, cruce y rollback.');
})().catch(error=>{console.error(error);process.exitCode=1});
