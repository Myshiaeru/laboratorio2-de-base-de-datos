
CREATE SCHEMA IF NOT EXISTS `videojuegos` DEFAULT CHARACTER SET utf8mb4;
USE `videojuegos`;

CREATE TABLE IF NOT EXISTS `genero` (
  `id_genero` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(30) NOT NULL,
  PRIMARY KEY (`id_genero`),
  UNIQUE KEY `uq_genero_nombre` (`nombre`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `plataforma` (
  `id_plataforma` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `codigo` VARCHAR(10) NOT NULL,
  PRIMARY KEY (`id_plataforma`),
  UNIQUE KEY `uq_plataforma_codigo` (`codigo`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `publisher` (
  `id_publisher` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(120) NOT NULL,
  PRIMARY KEY (`id_publisher`),
  UNIQUE KEY `uq_publisher_nombre` (`nombre`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `region` (
  `id_region` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `codigo` VARCHAR(5) NOT NULL,
  `nombre` VARCHAR(40) NOT NULL,
  PRIMARY KEY (`id_region`),
  UNIQUE KEY `uq_region_codigo` (`codigo`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `juego` (
  `id_juego` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `nombre` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id_juego`),
  UNIQUE KEY `uq_juego_nombre` (`nombre`)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `lanzamiento` (
  `id_lanzamiento` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `id_juego` INT UNSIGNED NOT NULL,
  `id_plataforma` TINYINT UNSIGNED NOT NULL,
  `id_publisher` SMALLINT UNSIGNED NULL,
  `anio` SMALLINT UNSIGNED NULL,
  PRIMARY KEY (`id_lanzamiento`),
  KEY `idx_lanz_juego` (`id_juego`),
  KEY `idx_lanz_plataforma` (`id_plataforma`),
  KEY `idx_lanz_publisher` (`id_publisher`),
  KEY `idx_lanz_anio` (`anio`),
  CONSTRAINT `fk_lanz_juego` FOREIGN KEY (`id_juego`) REFERENCES `juego` (`id_juego`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_lanz_plataforma` FOREIGN KEY (`id_plataforma`) REFERENCES `plataforma` (`id_plataforma`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_lanz_publisher` FOREIGN KEY (`id_publisher`) REFERENCES `publisher` (`id_publisher`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `juego_genero` (
  `id_juego` INT UNSIGNED NOT NULL,
  `id_genero` TINYINT UNSIGNED NOT NULL,
  PRIMARY KEY (`id_juego`,`id_genero`),
  KEY `idx_jg_genero` (`id_genero`),
  CONSTRAINT `fk_jg_juego` FOREIGN KEY (`id_juego`) REFERENCES `juego` (`id_juego`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_jg_genero` FOREIGN KEY (`id_genero`) REFERENCES `genero` (`id_genero`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS `venta` (
  `id_lanzamiento` INT UNSIGNED NOT NULL,
  `id_region` TINYINT UNSIGNED NOT NULL,
  `unidades` DECIMAL(6,2) NOT NULL,
  PRIMARY KEY (`id_lanzamiento`,`id_region`),
  KEY `idx_venta_region` (`id_region`),
  CONSTRAINT `chk_venta_unidades` CHECK (`unidades` >= 0),
  CONSTRAINT `fk_venta_lanz` FOREIGN KEY (`id_lanzamiento`) REFERENCES `lanzamiento` (`id_lanzamiento`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_venta_region` FOREIGN KEY (`id_region`) REFERENCES `region` (`id_region`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;
