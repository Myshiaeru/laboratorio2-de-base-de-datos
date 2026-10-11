USE videojuegos;


WITH ventas_publisher_juego AS (
    SELECT l.id_publisher, l.id_juego, SUM(v.unidades) AS ventas
    FROM lanzamiento l
    JOIN venta v ON v.id_lanzamiento = l.id_lanzamiento
    WHERE l.id_publisher IS NOT NULL
    GROUP BY l.id_publisher, l.id_juego
),
por_publisher AS (
    SELECT id_publisher, COUNT(*) AS n_juegos, SUM(ventas) AS total, AVG(ventas) AS promedio
    FROM ventas_publisher_juego
    GROUP BY id_publisher
),
ranking AS (
    SELECT id_publisher, n_juegos, total, promedio,
           RANK() OVER (ORDER BY total DESC) AS pos_total,
           CASE WHEN n_juegos >= 10
                THEN RANK() OVER (PARTITION BY (n_juegos >= 10) ORDER BY promedio DESC) END AS pos_promedio_min10
    FROM por_publisher
)
SELECT pu.nombre AS publisher, r.n_juegos,
       ROUND(r.total, 2) AS total_millones, ROUND(r.promedio, 2) AS promedio_por_juego,
       r.pos_total, r.pos_promedio_min10
FROM ranking r
JOIN publisher pu ON pu.id_publisher = r.id_publisher
WHERE r.pos_total <= 8 OR r.pos_promedio_min10 <= 5
ORDER BY r.pos_total;


SET @genero = 'Action';
SET @anio   = 2010;
SELECT p.codigo AS plataforma, COUNT(DISTINCT l.id_juego) AS juegos
FROM lanzamiento l
JOIN plataforma p   ON p.id_plataforma = l.id_plataforma
JOIN juego_genero jg ON jg.id_juego = l.id_juego
JOIN genero g       ON g.id_genero = jg.id_genero
WHERE g.nombre = @genero AND l.anio > @anio
GROUP BY p.id_plataforma, p.codigo
ORDER BY juegos DESC
LIMIT 6;


SELECT j.nombre AS juego, p.codigo AS plataforma, g.nombre AS genero,
       vjp.unidades AS japon, vna.unidades AS norteamerica,
       ROUND(vjp.unidades - vna.unidades, 2) AS diferencia
FROM lanzamiento l
JOIN juego j         ON j.id_juego = l.id_juego
JOIN plataforma p    ON p.id_plataforma = l.id_plataforma
JOIN juego_genero jg ON jg.id_juego = l.id_juego
JOIN genero g        ON g.id_genero = jg.id_genero
JOIN venta vjp ON vjp.id_lanzamiento = l.id_lanzamiento
              AND vjp.id_region = (SELECT id_region FROM region WHERE codigo = 'JP')
JOIN venta vna ON vna.id_lanzamiento = l.id_lanzamiento
              AND vna.id_region = (SELECT id_region FROM region WHERE codigo = 'NA')
WHERE vjp.unidades > vna.unidades
ORDER BY diferencia DESC
LIMIT 10;

SELECT g.nombre AS genero,
       COUNT(*) AS lanzamientos,
       SUM(vjp.unidades > vna.unidades) AS japon_mayor_que_na,
       ROUND(100 * SUM(vjp.unidades > vna.unidades) / COUNT(*), 1) AS porcentaje
FROM lanzamiento l
JOIN juego_genero jg ON jg.id_juego = l.id_juego
JOIN genero g        ON g.id_genero = jg.id_genero
JOIN venta vjp ON vjp.id_lanzamiento = l.id_lanzamiento
              AND vjp.id_region = (SELECT id_region FROM region WHERE codigo = 'JP')
JOIN venta vna ON vna.id_lanzamiento = l.id_lanzamiento
              AND vna.id_region = (SELECT id_region FROM region WHERE codigo = 'NA')
GROUP BY g.id_genero, g.nombre
ORDER BY porcentaje DESC;

SELECT p.codigo AS plataforma,
       COUNT(*) AS lanzamientos,
       SUM(vjp.unidades > vna.unidades) AS japon_mayor_que_na,
       ROUND(100 * SUM(vjp.unidades > vna.unidades) / COUNT(*), 1) AS porcentaje
FROM lanzamiento l
JOIN plataforma p ON p.id_plataforma = l.id_plataforma
JOIN venta vjp ON vjp.id_lanzamiento = l.id_lanzamiento
              AND vjp.id_region = (SELECT id_region FROM region WHERE codigo = 'JP')
JOIN venta vna ON vna.id_lanzamiento = l.id_lanzamiento
              AND vna.id_region = (SELECT id_region FROM region WHERE codigo = 'NA')
GROUP BY p.id_plataforma, p.codigo
HAVING COUNT(*) >= 100
ORDER BY porcentaje DESC;


WITH ventas_juego AS (
    SELECT l.id_juego, SUM(v.unidades) AS ventas
    FROM lanzamiento l
    JOIN venta v ON v.id_lanzamiento = l.id_lanzamiento
    GROUP BY l.id_juego
),
por_genero AS (
    SELECT g.nombre AS genero, COUNT(*) AS n_juegos, AVG(vj.ventas) AS promedio
    FROM ventas_juego vj
    JOIN juego_genero jg ON jg.id_juego = vj.id_juego
    JOIN genero g        ON g.id_genero = jg.id_genero
    GROUP BY g.id_genero, g.nombre
)
SELECT genero, n_juegos, ROUND(promedio, 2) AS promedio_por_juego,
       RANK() OVER (ORDER BY promedio DESC) AS pos_promedio,
       RANK() OVER (ORDER BY n_juegos DESC) AS pos_cantidad
FROM por_genero
ORDER BY promedio DESC;
