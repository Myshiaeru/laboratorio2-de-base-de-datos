// Programa de carga independiente: Online_game.csv -> MySQL (esquema videojuegos).
// Se hace como script y no como API por capas porque es una tarea de una sola ejecución,
// sin rutas ni usuarios; separar controladores y servicios solo añadiría código sin beneficio.
require('dotenv').config();
const fs = require('fs');
const { parse } = require('csv-parse/sync');
const mysql = require('mysql2/promise');

const CSV_PATH = process.argv[2] || process.env.CSV_PATH || './Online_game.csv';
const CHUNK = 1000;

const REGIONES = [
  { codigo: 'NA', nombre: 'Norteamérica', col: 'NA_Sales' },
  { codigo: 'EU', nombre: 'Europa', col: 'EU_Sales' },
  { codigo: 'JP', nombre: 'Japón', col: 'JP_Sales' },
  { codigo: 'OTHER', nombre: 'Resto del mundo', col: 'Other_Sales' }
];

// El CSV marca los datos faltantes con el texto 'N/A' (o 'Unknown' en Publisher).
const FALTANTE = v => v === '' || ['n/a', 'na', 'unknown'].includes(v.toLowerCase());

// Limpieza y validación de una fila. Devuelve la fila lista o lanza Error con el motivo.
function limpiar(r) {
  const nombre = (r.Name || '').trim();
  const plataforma = (r.Platform || '').trim();
  const genero = (r.Genre || '').trim();
  if (!nombre) throw new Error('Name vacío');
  if (!plataforma) throw new Error('Platform vacío');
  if (!genero) throw new Error('Genre vacío');

  let anio = null;
  if (!FALTANTE((r.Year || '').trim())) {
    anio = Number(r.Year);
    if (!Number.isInteger(anio) || anio < 1950 || anio > 2100) throw new Error(`Year inválido: ${r.Year}`);
  }

  // Publisher faltante ('N/A', 'Unknown' o vacío) -> NULL, para que no cuente como una editorial real
  let publisher = (r.Publisher || '').trim();
  if (FALTANTE(publisher)) publisher = null;

  const ventas = {};
  for (const reg of REGIONES) {
    const v = Number(r[reg.col]);
    if (!Number.isFinite(v) || v < 0) throw new Error(`${reg.col} inválido: ${r[reg.col]}`);
    ventas[reg.codigo] = v;
  }
  return { nombre, plataforma, genero, anio, publisher, ventas };
}

async function insertarEnLotes(conn, sql, filas) {
  for (let i = 0; i < filas.length; i += CHUNK) {
    await conn.query(sql, [filas.slice(i, i + CHUNK)]);
  }
}

async function mapaIds(conn, tabla, idCol, nombreCol) {
  const [rows] = await conn.query(`SELECT ${idCol} AS id, ${nombreCol} AS nombre FROM ${tabla}`);
  return new Map(rows.map(r => [r.nombre, r.id]));
}

async function main() {
  if (!fs.existsSync(CSV_PATH)) throw new Error(`No existe el archivo CSV: ${CSV_PATH}`);
  const registros = parse(fs.readFileSync(CSV_PATH, 'utf8'), { columns: true, skip_empty_lines: true, bom: true });
  console.log(`Filas leídas del CSV: ${registros.length}`);

  const validas = [];
  const rechazadas = [];
  registros.forEach((r, i) => {
    try { validas.push(limpiar(r)); }
    catch (e) { rechazadas.push(`fila ${i + 2} (Rank ${r.Rank}): ${e.message}`); }
  });
  if (rechazadas.length) {
    fs.writeFileSync('rechazadas.log', rechazadas.join('\n'));
    console.error(`ATENCIÓN: ${rechazadas.length} filas rechazadas por validación (ver rechazadas.log)`);
  }

  const conn = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    port: Number(process.env.DB_PORT || 3306),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'videojuegos'
  });

  try {
    const [[{ n }]] = await conn.query('SELECT COUNT(*) AS n FROM lanzamiento');
    if (n > 0) throw new Error('Las tablas ya tienen datos. Vacíelas (o recree el esquema) antes de volver a cargar.');

    await conn.beginTransaction();

    // 1) Catálogos (valores únicos)
    const unicos = f => [...new Set(validas.map(f).filter(v => v !== null))];
    await insertarEnLotes(conn, 'INSERT INTO genero (nombre) VALUES ?', unicos(v => v.genero).map(x => [x]));
    await insertarEnLotes(conn, 'INSERT INTO plataforma (codigo) VALUES ?', unicos(v => v.plataforma).map(x => [x]));
    await insertarEnLotes(conn, 'INSERT INTO publisher (nombre) VALUES ?', unicos(v => v.publisher).map(x => [x]));
    await insertarEnLotes(conn, 'INSERT INTO juego (nombre) VALUES ?', unicos(v => v.nombre).map(x => [x]));
    await insertarEnLotes(conn, 'INSERT INTO region (codigo, nombre) VALUES ?', REGIONES.map(r => [r.codigo, r.nombre]));

    const idGenero = await mapaIds(conn, 'genero', 'id_genero', 'nombre');
    const idPlat = await mapaIds(conn, 'plataforma', 'id_plataforma', 'codigo');
    const idPub = await mapaIds(conn, 'publisher', 'id_publisher', 'nombre');
    const idJuego = await mapaIds(conn, 'juego', 'id_juego', 'nombre');
    const idRegion = await mapaIds(conn, 'region', 'id_region', 'codigo');

    // 2) Lanzamientos (una fila válida = un lanzamiento) con id explícito para enlazar las ventas
    const lanzamientos = [];
    const ventas = [];
    const pares = new Set();
    const juegoGenero = [];
    validas.forEach((v, i) => {
      const idL = i + 1;
      const jg = idJuego.get(v.nombre);
      lanzamientos.push([idL, jg, idPlat.get(v.plataforma), v.publisher ? idPub.get(v.publisher) : null, v.anio]);
      for (const reg of REGIONES) ventas.push([idL, idRegion.get(reg.codigo), v.ventas[reg.codigo]]);
      const clave = `${jg}-${idGenero.get(v.genero)}`;
      if (!pares.has(clave)) { pares.add(clave); juegoGenero.push([jg, idGenero.get(v.genero)]); }
    });

    await insertarEnLotes(conn, 'INSERT INTO lanzamiento (id_lanzamiento, id_juego, id_plataforma, id_publisher, anio) VALUES ?', lanzamientos);
    await insertarEnLotes(conn, 'INSERT INTO juego_genero (id_juego, id_genero) VALUES ?', juegoGenero);
    await insertarEnLotes(conn, 'INSERT INTO venta (id_lanzamiento, id_region, unidades) VALUES ?', ventas);

    await conn.commit();
    console.log('Carga confirmada (COMMIT).');
  } catch (err) {
    await conn.rollback();
    console.error('ERROR en la carga, se hizo ROLLBACK:', err.code || '', err.message);
    process.exitCode = 1;
    await conn.end();
    return;
  }

  // 3) Verificación: conteo por tabla y cuadre de ventas contra el CSV
  console.log('\n== Verificación ==');
  for (const t of ['genero', 'plataforma', 'publisher', 'region', 'juego', 'lanzamiento', 'juego_genero', 'venta']) {
    const [[{ c }]] = await conn.query(`SELECT COUNT(*) AS c FROM ${t}`);
    console.log(`${t.padEnd(14)} ${c}`);
  }
  const [[{ s }]] = await conn.query('SELECT ROUND(SUM(unidades),2) AS s FROM venta');
  const esperado = validas.reduce((a, v) => a + Object.values(v.ventas).reduce((x, y) => x + y, 0), 0);
  console.log(`Suma de ventas en BD: ${s}  |  suma regional en CSV: ${esperado.toFixed(2)}`);
  const [[{ nulos }]] = await conn.query('SELECT SUM(anio IS NULL) AS nulos FROM lanzamiento');
  const [[{ nulosP }]] = await conn.query('SELECT SUM(id_publisher IS NULL) AS nulosP FROM lanzamiento');
  console.log(`Lanzamientos sin año: ${nulos} | sin publisher: ${nulosP}`);
  if (rechazadas.length || validas.length !== registros.length) process.exitCode = 1;
  await conn.end();
}

main().catch(e => { console.error('Fallo:', e.message); process.exit(1); });
