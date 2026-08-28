import bcrypt from 'bcryptjs';
import dotenv from 'dotenv';
import readline from 'node:readline/promises';
import { pool } from '../db/pool.js';

dotenv.config();

const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

async function preguntar(texto: string, opcional = false): Promise<string | null> {
  const respuesta = await rl.question(`${texto}${opcional ? ' (opcional, Enter para omitir)' : ''}: `);
  return respuesta.trim() === '' ? null : respuesta.trim();
}

async function main() {
  console.log('--- Crear usuario admin ---\n');

  const primerNombre = await preguntar('Primer nombre');
  const segundoNombre = await preguntar('Segundo nombre', true);
  const primerApellido = await preguntar('Primer apellido');
  const segundoApellido = await preguntar('Segundo apellido', true);
  const cui = await preguntar('CUI/DPI', true);
  const nit = await preguntar('NIT', true);
  const telefono = await preguntar('Teléfono', true);
  const correo = await preguntar('Correo');
  const username = await preguntar('Username');
  const password = await preguntar('Password');

  rl.close();

  if (!primerNombre || !primerApellido || !correo || !username || !password) {
    console.error('\nPrimer nombre, primer apellido, correo, username y password son obligatorios.');
    process.exit(1);
  }

  const hash = await bcrypt.hash(password, 10);

  const tipoUsuario = await pool.query(
    `SELECT id_tipo_usuario FROM tc_tipo_usuario WHERE descripcion = 'staff'`
  );
  const tipoEmpleado = await pool.query(
    `SELECT id_tipo_empleado FROM tc_tipo_empleado WHERE descripcion = 'Admin'`
  );

  if (!tipoUsuario.rows[0] || !tipoEmpleado.rows[0]) {
    console.error(
      'No se encontraron los catálogos tc_tipo_usuario (staff) o tc_tipo_empleado (Admin). ¿Corriste seed_catalogos_v2.sql?'
    );
    process.exit(1);
  }

  const result = await pool.query(
    `CALL sp_crear_usuario(
      $1::varchar, $2::varchar, $3::varchar, $4::varchar, $5::varchar, $6::varchar, $7::varchar, $8::varchar,
      $9::varchar, $10::varchar, $11::integer, $12::integer, NULL
    )`,
    [
      primerNombre, segundoNombre, primerApellido, segundoApellido,
      cui, nit, telefono, correo,
      username, hash,
      tipoUsuario.rows[0].id_tipo_usuario, tipoEmpleado.rows[0].id_tipo_empleado,
    ]
  );

  console.log('\nUsuario admin creado con id_usuario:', result.rows[0].p_id_usuario);
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});