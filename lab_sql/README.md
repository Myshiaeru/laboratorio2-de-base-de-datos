# Laboratorio SQL - Online_game.csv

1. Ejecutar `sql/01_ddl.sql` en MySQL (crea el esquema `videojuegos`).
2. Copiar `.env.example` a `.env` y poner la contraseña; dejar `Online_game.csv` en esta carpeta.
3. `npm install` y `npm run carga`.

El programa informa filas leídas, filas rechazadas (rechazadas.log), conteo por tabla y
cuadra la suma de ventas contra el CSV. Si algo falla hace ROLLBACK y termina con error.
