USE videojuegos;

SELECT COUNT(*) AS lanzamientos_ps_1995_2000
FROM lanzamiento
WHERE id_plataforma = (SELECT id_plataforma FROM plataforma WHERE codigo = 'PS')
  AND anio BETWEEN 1995 AND 2000
  AND id_publisher IS NOT NULL;

SELECT j.nombre, l.anio
FROM lanzamiento l
JOIN juego j ON j.id_juego = l.id_juego
WHERE l.anio > 2016
ORDER BY l.anio, j.nombre;

SELECT j.nombre AS juego, p.codigo AS plataforma, l.anio, v.unidades AS ventas_japon_millones
FROM lanzamiento l
JOIN juego j      ON j.id_juego = l.id_juego
JOIN plataforma p ON p.id_plataforma = l.id_plataforma
JOIN publisher pu ON pu.id_publisher = l.id_publisher
JOIN venta v      ON v.id_lanzamiento = l.id_lanzamiento
JOIN region r     ON r.id_region = v.id_region
WHERE pu.nombre = 'Nintendo' AND r.codigo = 'JP'
ORDER BY v.unidades DESC
LIMIT 10;

SELECT r.nombre AS region,
       ROUND(SUM(v.unidades), 2) AS unidades_millones,
       ROUND(100 * SUM(v.unidades) / (SELECT SUM(unidades) FROM venta), 1) AS porcentaje
FROM venta v
JOIN region r ON r.id_region = v.id_region
GROUP BY r.id_region, r.nombre
ORDER BY unidades_millones DESC;
