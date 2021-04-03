-- phpMyAdmin SQL Dump
-- version 5.0.3
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 03-04-2021 a las 20:51:51
-- Versión del servidor: 10.4.14-MariaDB
-- Versión de PHP: 7.3.23

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `siiup`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `PlaneacionpaConsultaRegistroEvaluaciones` (IN `p_idcampus` INT)  BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE v_activo int;
	DECLARE v_idregistro int;
	declare v_numrows int;
	DECLARE v_idcuatrimestre int;
    -- Insert statements for procedure here
	SET v_idcuatrimestre = (SELECT cuatrimestre.idcuatrimestre FROM Escolarescuatrimestre WHERE cuatrimestre.estatus = 46);
	SET v_activo = null;

	SET v_numrows = (SELECT COUNT (re.idregistro) AS nrows 
	FROM Planeacionregistro_evaluaciones as re,Planeacionregistro_evaluaciones_cuestionario as rec
	WHERE re.idcuatrimestre = v_idcuatrimestre AND re.idcampus = p_idcampus AND re.idregistro = rec.idregistro);
	
	IF (v_numrows = 1)
		THEN
			SET v_idregistro = (SELECT re.idregistro FROM Planeacionregistro_evaluaciones as re, Planeacionregistro_evaluaciones_cuestionario as rec
			WHERE re.idcuatrimestre = v_idcuatrimestre AND re.idcampus = p_idcampus AND re.idregistro = rec.idregistro);
			
			SET v_activo = (SELECT activo FROM Planeacionregistro_evaluaciones WHERE idcampus = p_idcampus AND idregistro = v_idregistro); 
			SELECT v_activo as activo;
	ELSE SELECT v_activo as activo;
	END IF;
END$$

--
-- Funciones
--
CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeCalcularCuatriXCreditos` (`p_idplan_estudios` INT, `p_creditos` SMALLINT) RETURNS SMALLINT(6) BEGIN
	
DECLARE v_cuatrimestre SMALLINT;

SET v_cuatrimestre =  (
SELECT cc.cuatrimestre
FROM EscolarescuatrimestreCreditos cc
WHERE cc.idplan_estudios = p_idplan_estudios
AND (p_creditos >= cc.rangoInicio AND p_creditos <= rangoFin)
);
RETURN v_cuatrimestre;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeCapacidadGrupo` (`p_idGrupo` INT) RETURNS INT(11) BEGIN

DECLARE v_total INT; 
DECLARE v_claveGrupoMixto INT;

SET v_claveGrupoMixto = IFNULL((SELECT claveGrupoMixto FROM escolaresgrupo WHERE idGrupo = p_idGrupo), 0);
IF v_claveGrupoMixto = 0
THEN
	SET v_total = (SELECT capacidad FROM escolaresgrupo WHERE grupo.idGrupo = p_idGrupo);
ELSE
	SET v_total = (SELECT TOP(1)capacidad FROM escolaresgrupo WHERE claveGrupoMixto = v_claveGrupoMixto);
END IF;

RETURN v_total;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeCarreraAprobados` (`p_idCarrera` INT, `p_idCuatrimestre` INT) RETURNS INT(11) BEGIN

DECLARE v_total INT;
SET v_total = (SELECT COUNT(*)
FROM(
SELECT 
(SELECT COUNT(*) FROM escolaresgrupo g JOIN escolaresgrupo_alumno ga ON ga.idgrupo = g.idgrupo AND g.idcuatrimestre =  p_idCuatrimestre AND g.activo = 1 AND ga.baja = 0 AND ga.idalumno = i.idalumno AND g.idplan_estudios = i.idplan_estudios 
AND ga.idmateria NOT IN (32,33,124,219,220) AND g.idplan_estudios IN (SELECT pe.idplan_estudios FROM escolares.plan_estudios pe WHERE pe.idcarrera = p_idCarrera)
)
-
(SELECT COUNT(*) FROM escolaresgrupo g JOIN escolaresgrupo_alumno ga ON ga.idgrupo = g.idgrupo AND g.idcuatrimestre =  p_idCuatrimestre AND g.activo = 1 AND ga.baja = 0 AND ga.idalumno = i.idalumno AND g.idplan_estudios = i.idplan_estudios 
AND ga.idmateria NOT IN (32,33,124,219,220) 
AND ga.final >=70 AND g.idplan_estudios IN (SELECT pe.idplan_estudios FROM escolares.plan_estudios pe WHERE pe.idcarrera = p_idCarrera))Diferencia
,(SELECT pe.idcarrera FROM escolaresplan_estudios pe WHERE pe.idplan_estudios = i.idplan_estudios)idCarrera
FROM escolaresinscripcion i
WHERE i.financiera = 1 AND i.idcuatrimestre = p_idCuatrimestre AND i.idplan_estudios IN (SELECT pe.idplan_estudios FROM escolaresplan_estudios pe WHERE pe.idcarrera = p_idCarrera)
AND (SELECT COUNT(*) FROM escolaresgrupo g JOIN escolaresgrupo_alumno ga ON ga.idgrupo = g.idgrupo AND g.idcuatrimestre =  p_idCuatrimestre AND g.activo = 1 AND ga.baja = 0 AND ga.idalumno = i.idalumno AND g.idplan_estudios = i.idplan_estudios  
AND ga.idmateria NOT IN (32,33,124,219,220)
) > 0
)t1 WHERE t1.Diferencia = 0);


RETURN v_total;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeCarreraReprobados` (`p_idCarrera` INT, `p_idCuatrimestre` INT) RETURNS INT(11) BEGIN

DECLARE v_total INT;
SET v_total = (SELECT COUNT(*)
FROM(
SELECT 
(SELECT COUNT(*) FROM escolaresgrupo g JOIN escolaresgrupo_alumno ga ON ga.idgrupo = g.idgrupo AND g.idcuatrimestre =  p_idCuatrimestre AND g.activo = 1 AND ga.baja = 0 AND ga.idalumno = i.idalumno AND g.idplan_estudios = i.idplan_estudios 
AND ga.idmateria NOT IN (32,33,124,219,220) 
AND g.idplan_estudios IN (SELECT pe.idplan_estudios FROM escolaresplan_estudios pe WHERE pe.idcarrera = p_idCarrera))-
(SELECT COUNT(*) FROM escolaresgrupo g JOIN escolaresgrupo_alumno ga ON ga.idgrupo = g.idgrupo AND g.idcuatrimestre =  p_idCuatrimestre AND g.activo = 1 AND ga.baja = 0 AND ga.idalumno = i.idalumno AND g.idplan_estudios = i.idplan_estudios 
AND ga.idmateria NOT IN (32,33,124,219,220) 
AND ga.final >=70 
AND g.idplan_estudios IN (SELECT pe.idplan_estudios FROM escolaresplan_estudios pe WHERE pe.idcarrera = p_idCarrera))Diferencia
,(SELECT pe.idcarrera FROM escolaresplan_estudios pe WHERE pe.idplan_estudios = i.idplan_estudios)idCarrera
FROM escolaresinscripcion i
WHERE i.financiera = 1 AND i.idcuatrimestre = p_idCuatrimestre AND i.idplan_estudios IN (SELECT pe.idplan_estudios FROM escolaresplan_estudios pe WHERE pe.idcarrera = p_idCarrera)
AND (SELECT COUNT(*) FROM escolaresgrupo g JOIN escolaresgrupo_alumno ga ON ga.idgrupo = g.idgrupo AND g.idcuatrimestre =  p_idCuatrimestre AND g.activo = 1 AND ga.baja = 0 AND ga.idalumno = i.idalumno AND g.idplan_estudios = i.idplan_estudios  
AND ga.idmateria NOT IN (32,33,124,219,220)
) > 0
)t1 WHERE t1.Diferencia > 0);
RETURN v_total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeConvertirMes` (`p_numeroMes` INT) RETURNS VARCHAR(20) CHARSET utf8 BEGIN
	-- Declare the return variable here
	DECLARE v_Mes NVARCHAR(20);

	IF(p_numeroMes = 1) THEN SET v_Mes = 'enero';   END IF;
	IF(p_numeroMes = 2) THEN SET v_Mes = 'febrero';   END IF;
	IF(p_numeroMes = 3) THEN SET v_Mes = 'marzo';  END IF;
	IF(p_numeroMes = 4) THEN SET v_Mes = 'abril';   END IF;
	IF(p_numeroMes = 5) THEN SET v_Mes = 'mayo';   END IF;
	IF(p_numeroMes = 6) THEN SET v_Mes = 'junio';   END IF;
	IF(p_numeroMes = 7) THEN SET v_Mes = 'julio';   END IF;
	IF(p_numeroMes = 8) THEN SET v_Mes = 'agosto';   END IF;
	IF(p_numeroMes = 9) THEN SET v_Mes = 'septiembre';   END IF;
	IF(p_numeroMes = 10) THEN SET v_Mes = 'octubre';   END IF;
	IF(p_numeroMes = 11) THEN SET v_Mes = 'noviembre';   END IF;
	IF(p_numeroMes = 12) THEN SET v_Mes = 'diciembre';   END IF;


	RETURN v_Mes;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeCuatriAnteriorInscrito` (`p_idAlumno` INT, `p_idPlanDeEstudios` INT) RETURNS INT(11) BEGIN

DECLARE v_ultimoCuatriCursado INT; DECLARE v_cuatriActual INT;

SET v_cuatriActual = (SELECT TOP(1)idCuatrimestre FROM Escolarescuatrimestre c WHERE NOW()>= c.fechaInicio AND NOW()<= c.fechaFin ORDER BY idcuatrimestre DESC);

SET v_ultimoCuatriCursado = (SELECT TOP(1)idcuatrimestre FROM Escolaresinscripcion WHERE idcuatrimestre<>v_cuatriActual AND financiera = 1 AND idalumno=p_idAlumno AND idplan_estudios = p_idPlanDeEstudios ORDER BY idCuatrimestre DESC);

RETURN IFNULL(v_ultimoCuatriCursado, v_cuatriActual);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeCuentaAlumnosCalificadosPorUnidadGrupo` (`p_idgrupo` INT, `p_unidad` TINYINT UNSIGNED) RETURNS TINYINT(3) UNSIGNED begin
	declare v_total tinyint unsigned;
	set v_total=
			(select
				COUNT(c.idAlumno)total
			from
				Escolaresgrupo_Alumno_Calificaciones c
			where
				c.baja=0
				and c.idGrupo=p_idgrupo
				and c.Unidad=p_unidad
				and c.Calificacion>0);
	return v_total;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeCuentaAlumnosEnGrupo` (`p_idgrupo` INT) RETURNS TINYINT(3) UNSIGNED begin
	declare v_numero tinyint unsigned;
	set v_numero=(	select
						COUNT(ga.idalumno) total
					from
						Escolaresgrupo_alumno ga
					where
						ga.baja=0 and
						ga.idgrupo=p_idgrupo
				);
	return v_numero;
end$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeHorarioReinscripcion` (`p_idAlumno` INT, `p_idPlanDeEstudios` INT, `p_idCuatrimestre` INT) RETURNS VARCHAR(25) CHARSET utf8 BEGIN

DECLARE v_fechaProgramada DATETIME; 
DECLARE v_resultado NVARCHAR(25); 
DECLARE v_fechaHoy DATETIME;

SET v_fechaHoy = NOW();
-- 1:Acceso Permitido; 2:Acceso denegado; 3:No tiene asignado horario
SET v_fechaProgramada = (SELECT TOP(1)fechaProgramada FROM EscolaresreinscripcionHorario WHERE idAlumno = p_idAlumno AND idCuatrimestre = p_idCuatrimestre AND idplanDeEstudios = p_idPlanDeEstudios ORDER BY fechaProgramada  DESC);

IF v_fechaProgramada<=v_fechaHoy THEN  SET v_resultado = 1;  END IF;
IF v_fechaProgramada>v_fechaHoy THEN SET v_resultado = v_fechaProgramada; END IF;
IF IFNULL(v_fechaProgramada, 0) = 0 THEN SET v_resultado = 'No tiene horario asignado';  END IF;

RETURN v_resultado;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeLugaresOcupadosEn1Grupo` (`p_idGrupo` INT) RETURNS INT(11) BEGIN

DECLARE v_total INT; DECLARE v_claveGrupoMixto INT;

SET v_claveGrupoMixto = IFNULL((SELECT claveGrupoMixto FROM escolaresgrupo WHERE idGrupo = p_idGrupo), 0);
IF v_claveGrupoMixto = 0
THEN
	SET v_total = (SELECT totalAlumnos FROM escolaresgrupo WHERE grupo.idGrupo = p_idGrupo);
ELSE
	SET v_total = (SELECT SUM(totalAlumnos) FROM escolaresgrupo WHERE claveGrupoMixto = v_claveGrupoMixto);
END IF;
RETURN v_total;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeNoMateriasReprobadasAlumno` (`p_idAlumno` INT, `p_idPlanDeEstudios` INT) RETURNS TINYINT(3) UNSIGNED BEGIN

DECLARE v_califMinima DECIMAL(18,2); 
DECLARE v_noMaterias TINYINT UNSIGNED;
SET v_califMinima = (SELECT pe.califMinimaAprobatoria FROM Escolaresplan_estudios pe WHERE pe.idplan_estudios = p_idPlanDeEstudios);
SET v_noMaterias = (SELECT COUNT(c.calificacion) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios AND c.calificacion<v_califMinima);
RETURN IFNULL(v_noMaterias, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeNumMateriasAlumnoXcuatri` (`p_idAlumno` INT, `p_idplan_estudios` INT, `p_idCuatrimestre` INT) RETURNS SMALLINT(6) BEGIN
	-- Declare the return variable here
	DECLARE v_total SMALLINT;
	
	SET v_total = (SELECT COUNT(ga.idalumno)
					FROM escolaresgrupo g
					JOIN escolaresgrupo_alumno ga ON ga.idgrupo = g.idgrupo AND g.idcuatrimestre = p_idCuatrimestre AND g.activo = 1 AND ga.baja = 0 AND ga.idalumno = p_idAlumno AND g.idplan_estudios =  p_idplan_estudios);

	-- Return the result of the function
	RETURN IFNULL(v_total, 0);

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeObtenerCalifAlumnoMateria` (`p_idAlumno` INT, `p_idGrupo` INT, `p_idPlanDeEstudio` INT, `p_idMateria` INT, `p_idCuatrimestre` INT) RETURNS SMALLINT(6) BEGIN

DECLARE v_numUnidades TINYINT UNSIGNED; DECLARE v_prom DECIMAL(18,2); DECLARE v_calificacion SMALLINT;
SET v_numUnidades = IFNULL((SELECT unidades FROM Escolaresplan_estudios_materia pem WHERE pem.idplan_estudios = p_idPlanDeEstudio AND pem.idmateria=p_idMateria), 0);
SET v_prom = (SELECT SUM(calificacion) FROM Escolaresgrupo_Alumno_Calificaciones gac WHERE gac.idAlumno =p_idAlumno AND gac.idGrupo = p_idGrupo AND gac.idPlanDeEstudios=p_idPlanDeEstudio AND gac.idCuatrimestre = p_idCuatrimestre);
SET v_prom = (v_prom / v_numUnidades);
SET v_calificacion = ROUND(v_prom, 0);  
-- SELECT @calificacion

IF IFNULL(v_calificacion, 0) = 0
THEN
	SET v_calificacion = (SELECT final 
	FROM Escolaresgrupo_alumno ga 
	JOIN escolaresgrupo g ON g.idGrupo = ga.idGrupo AND g.idMateria = ga.idMateria AND g.idCuatrimestre = p_idCuatrimestre AND g.idplan_estudios = p_idPlanDeEstudio AND ga.baja=0 
	AND ga.idAlumno = p_idAlumno AND ga.idGrupo = p_idGrupo);
END IF;

RETURN v_calificacion;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeObtenerClaveMateria` (`p_idMateria` INT, `p_idMateriaReferencia` INT, `p_idPlanDeEstudios` INT) RETURNS VARCHAR(100) CHARSET utf8 BEGIN

DECLARE v_Clave NVARCHAR(100);

IF p_idMateriaReferencia > 0
THEN
	SET v_Clave = (SELECT clave FROM Escolaresplan_estudios_materia pem WHERE pem.idMateria = p_idMateriaReferencia AND pem.idPlan_Estudios = p_idPlanDeEstudios);
END IF;

IF p_idMateriaReferencia = 0
THEN
	SET v_Clave = (SELECT clave FROM Escolaresplan_estudios_materia pem WHERE pem.idMateria = p_idMateria AND pem.idPlan_Estudios = p_idPlanDeEstudios);
END IF;

RETURN IFNULL(v_Clave, ' ');

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeObtenerCreditosMateria` (`p_idMateria` INT, `p_idMateriaReferencia` INT, `p_idPlanDeEstudios` INT) RETURNS TINYINT(3) UNSIGNED BEGIN
	
	DECLARE v_creditos TINYINT UNSIGNED;
	SET v_creditos = 0;

	IF p_idMateriaReferencia > 0 
	THEN
	SET v_creditos = (SELECT TOP(1) creditos FROM Escolaresplan_estudios_materia WHERE idMateria = p_idMateriaReferencia AND idplan_estudios = p_idPlanDeEstudios);
		-- SET @creditos = (SELECT TOP(1) creditos FROM Escolares.plan_estudios_materia WHERE idMateria = @idMateria AND idplan_estudios = @idPlanDeEstudios)	
	END IF;
	IF p_idMateriaReferencia = 0 
	THEN
	SET v_creditos = (SELECT TOP(1) creditos FROM Escolaresplan_estudios_materia WHERE idMateria = p_idMateria AND idplan_estudios = p_idPlanDeEstudios);
	END IF;
	RETURN IFNULL(v_creditos,0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeObtenerNivelDeDominio` (`p_Calificacion` DECIMAL(18,2)) RETURNS VARCHAR(20) CHARSET utf8 BEGIN
DECLARE v_clave NVARCHAR(20);
SET v_clave = (SELECT TOP(1)clave FROM escolaresNivelesDominioEscala WHERE p_Calificacion>=califMinima AND p_Calificacion<=califMaxima);
RETURN IFNULL(v_clave, 's/a');
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeObtenerNombreMateria` (`p_idMateria` INT, `p_idMateriaReferencia` INT) RETURNS VARCHAR(100) CHARSET utf8 BEGIN
DECLARE v_materia NVARCHAR(100);
IF p_idMateriaReferencia > 0
THEN
	SET v_materia = (SELECT nombre FROM Escolaresmateria m WHERE m.idmateria = p_idMateriaReferencia);
END IF;
IF p_idMateriaReferencia = 0
THEN
	SET v_materia = (SELECT nombre FROM Escolaresmateria m WHERE m.idmateria = p_idMateria);
END IF;
RETURN v_materia;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfeObtenerSede` (`p_idAlumno` INT) RETURNS VARCHAR(100) CHARSET utf8 BEGIN
	-- Declare the return variable here
	DECLARE v_Sede nvarchar(100);
	 SELECT
	(cam.Campus ) INTO v_Sede
	FROM
		EscolaresCampus cam join EscolaresAlumnoCarreras ca on cam.idCampus = ca.idCampus 
	WHERE
		 ca.IdAlumno = p_idAlumno ;
	-- Retornar el valor escalar
	RETURN v_Sede;
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfePromedioAlumno` (`p_idAlumno` INT, `p_idPlanDeEstudios` INT, `p_considerarReprobadas` TINYINT) RETURNS DECIMAL(18,2) BEGIN	
DECLARE v_promedio DECIMAL(18,2); 
DECLARE v_Suma DECIMAL(18,2); 
DECLARE v_noMaterias TINYINT UNSIGNED; 
DECLARE v_califMinima DECIMAL(18,2);

SET v_califMinima = (SELECT pe.califMinimaAprobatoria FROM Escolaresplan_estudios pe WHERE pe.idplan_estudios = p_idPlanDeEstudios);
IF p_considerarReprobadas = 0
THEN
	SET v_Suma = (SELECT SUM(IFNULL(c.calificacion,0)) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios AND c.calificacion>=v_califMinima);
	SET v_noMaterias = (SELECT COUNT(c.calificacion) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios AND c.calificacion>=v_califMinima);
ELSE
	SET v_Suma = (SELECT SUM(IFNULL(c.calificacion, 0)) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios);
	SET v_noMaterias = (SELECT COUNT(c.calificacion) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios);
END IF;
IF(v_noMaterias >0)
THEN
	SET v_promedio = v_Suma / v_noMaterias;
END IF;
RETURN IFNULL(v_promedio, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfnAlumno_CuatrimestreEscolar` (`p_idPlanEstudios` INT, `p_idAlumno` INT) RETURNS TINYINT(3) UNSIGNED BEGIN
	-- Declare the return variable here
	DECLARE v_CuatrimestreEscolar tinyint unsigned;
	-- Add the T-SQL statements to compute the return value here
	set v_CuatrimestreEscolar = (select COUNT(*) 
								from Escolaresinscripcion i 
								where i.idplan_estudios = p_idPlanEstudios and i.idalumno = p_idAlumno and i.financiera =1 and i.academica = 1 and i.valida = 1); -- modificado 20101208_0947
	-- si es cero no tiene registro en la tabla inscripcion, de 1 en adelante es el cuatrimestre en el que esta del 1-9
	RETURN ifnull(v_CuatrimestreEscolar, 0);
END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolaresfntjMatricula_ObtenerSiguiente2` (`p_tipoAlumno` INT) RETURNS VARCHAR(7) CHARSET utf8 BEGIN

	-- valor para tipoAlumno:
	-- 1 = alumno ingeniería
	-- 2 = alumno maestría

	declare v_MatriculaSiguiente nvarchar(7);
	
	if p_tipoAlumno = 1
	then
		set v_MatriculaSiguiente = (select max(matricula) + 1 Siguiente from Escolaresalumno where matricula not like 'POR%' and SUBSTRING(matricula,6,1) <> '9');
		-- para que no devuelva los de maestria	
	elseif p_tipoAlumno = 2
	then
		set v_MatriculaSiguiente = (select max(matricula) + 1 Siguiente from Escolaresalumno where matricula not like 'POR%' and SUBSTRING(matricula,6,1) = '9');
	end if;

	RETURN v_MatriculaSiguiente;

END$$

CREATE DEFINER=`root`@`localhost` FUNCTION `EscolarespromedioAlumno` (`p_idAlumno` INT, `p_idPlanDeEstudios` INT, `p_considerarReprobadas` TINYINT) RETURNS DECIMAL(18,2) BEGIN
	
DECLARE v_promedio DECIMAL(18,2); DECLARE v_Suma DECIMAL(18,2); DECLARE v_noMaterias TINYINT UNSIGNED; DECLARE v_califMinima DECIMAL(18,2);

SET v_califMinima = (SELECT pe.califMinimaAprobatoria FROM Escolaresplan_estudios pe WHERE pe.idplan_estudios = p_idPlanDeEstudios);
	
IF p_considerarReprobadas = 0
THEN
	SET v_Suma = (SELECT SUM(c.calificacion) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios AND c.calificacion>=v_califMinima);

	SET v_noMaterias = (SELECT COUNT(c.calificacion) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios AND c.calificacion>=v_califMinima);
ELSE
	SET v_Suma = (SELECT SUM(c.calificacion) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios);

	SET v_noMaterias = (SELECT COUNT(c.calificacion) FROM Escolarescardex c WHERE c.idalumno = p_idAlumno AND c.idplan_estudios = p_idPlanDeEstudios);
END IF;
SET v_promedio = v_Suma / v_noMaterias;
RETURN v_promedio;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `acreditacion`
--

CREATE TABLE `acreditacion` (
  `idalumno` double DEFAULT NULL,
  `idplan_estudios` double DEFAULT NULL,
  `idmateria` double DEFAULT NULL,
  `calificacion` double DEFAULT NULL,
  `tipo_curso` double DEFAULT NULL,
  `inscripciones` double DEFAULT NULL,
  `idcuatrimestre_prim_insc` double DEFAULT NULL,
  `idcuatrimestre_ult_insc` double DEFAULT NULL,
  `idMateriaReferencia` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `almacenarimagenes`
--

CREATE TABLE `almacenarimagenes` (
  `Id` int(11) NOT NULL,
  `Imagen` longblob DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `asistencia$`
--

CREATE TABLE `asistencia$` (
  `fecha` datetime(3) DEFAULT NULL,
  `NUM` double DEFAULT NULL,
  `matricula` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `mat` double DEFAULT NULL,
  `NOMBRE` varchar(255) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `aspirantes`
--

CREATE TABLE `aspirantes` (
  `idaspirante` bigint(20) UNSIGNED NOT NULL,
  `folio_ceneval` int(11) DEFAULT NULL,
  `puntos_ceneval` int(11) DEFAULT NULL,
  `anio_egreso` int(11) DEFAULT NULL,
  `promedio` decimal(8,2) DEFAULT NULL,
  `area_egreso` int(11) DEFAULT NULL,
  `idesc_procedencia` int(11) DEFAULT NULL,
  `idcarrera` int(11) DEFAULT NULL,
  `idPlanEstudio` int(11) DEFAULT NULL,
  `turno` int(11) DEFAULT NULL,
  `medio_promocion` int(11) DEFAULT NULL,
  `idpersona` int(11) DEFAULT NULL,
  `cuatri_ingreso` int(11) DEFAULT NULL,
  `registro_valido` int(11) DEFAULT NULL,
  `FolioPertenencia` int(11) DEFAULT NULL,
  `FechaRegistro` date DEFAULT NULL,
  `idcuatrimestre` int(11) DEFAULT NULL,
  `idCampus` int(11) DEFAULT NULL,
  `fechaExamen` datetime DEFAULT NULL,
  `numOpcion` int(11) DEFAULT NULL,
  `Resultado` int(11) DEFAULT NULL,
  `check1` int(11) DEFAULT NULL,
  `fechafin_eproc` date DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `aspirantes`
--

INSERT INTO `aspirantes` (`idaspirante`, `folio_ceneval`, `puntos_ceneval`, `anio_egreso`, `promedio`, `area_egreso`, `idesc_procedencia`, `idcarrera`, `idPlanEstudio`, `turno`, `medio_promocion`, `idpersona`, `cuatri_ingreso`, `registro_valido`, `FolioPertenencia`, `FechaRegistro`, `idcuatrimestre`, `idCampus`, `fechaExamen`, `numOpcion`, `Resultado`, `check1`, `fechafin_eproc`, `updated_at`, `created_at`) VALUES
(1, 55555, 1042, 2016, '9.00', 1, 1, 1, 1, 1, 1, 1, 163, 1, 1, '2020-01-08', 1, 1, '2020-01-08 00:00:00', 2, 1, 0, '0000-00-00', '2020-01-15 03:52:13', '0000-00-00 00:00:00'),
(2, 21453, 234, 2016, '18.20', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '0000-00-00', 0, 0, '0000-00-00 00:00:00', 0, 0, 0, '0000-00-00', '2020-01-15 03:59:55', '0000-00-00 00:00:00'),
(3, 55555, 12, 2014, '9.00', 2, 1, 3, 4, 5, 6, 1, 5, 0, 0, '2020-01-08', 1, 2, '2020-01-08 00:00:00', 2, 1, 1, '2020-01-08', '2020-01-16 01:52:47', '2020-01-16 01:52:47'),
(4, 55555, 12, 2014, '9.00', 2, 1, 3, 4, 5, 6, 1, 5, 0, 0, '2020-01-08', 1, 2, '2020-01-08 00:00:00', 2, 1, 1, '2020-01-08', '2020-01-16 01:55:24', '2020-01-16 01:55:24'),
(5, NULL, 9, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-16 02:50:54', '2020-01-16 02:50:54'),
(6, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-17 02:28:21', '2020-01-17 02:28:21'),
(7, NULL, 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-17 02:28:26', '2020-01-17 02:28:26'),
(8, NULL, 9876, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-17 23:42:53', '2020-01-17 23:42:53'),
(9, 1, 2, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-17 23:44:27', '2020-01-17 23:44:27'),
(10, 3, 4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-17 23:48:13', '2020-01-17 23:48:13'),
(11, 4, 5, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-18 00:19:46', '2020-01-18 00:19:46'),
(12, NULL, 7, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-18 00:20:45', '2020-01-18 00:20:45'),
(13, NULL, 9, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-18 00:22:08', '2020-01-18 00:22:08'),
(14, NULL, 44, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-01-18 10:34:58', '2020-01-18 10:34:58'),
(15, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 29, NULL, NULL, 83, NULL, 125, NULL, 4, 3, NULL, NULL, NULL, NULL, NULL, '2020-01-29 01:07:29', '2020-01-29 01:07:29'),
(16, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 29, NULL, NULL, 83, NULL, 125, NULL, 4, 3, NULL, NULL, NULL, NULL, NULL, '2020-01-29 01:07:40', '2020-01-29 01:07:40'),
(17, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 29, NULL, NULL, 83, NULL, 125, NULL, 4, 3, NULL, NULL, NULL, NULL, NULL, '2020-01-29 01:08:48', '2020-01-29 01:08:48'),
(18, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 29, NULL, NULL, 83, NULL, 125, NULL, 4, 3, NULL, NULL, NULL, NULL, NULL, '2020-01-29 01:08:50', '2020-01-29 01:08:50');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `bdmysql`
--

CREATE TABLE `bdmysql` (
  `idresultado` double DEFAULT NULL,
  `idcuatrimestre` double DEFAULT NULL,
  `cve_cuatrimestre` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `idcarrera` double DEFAULT NULL,
  `carrera` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `idplan_estudios` double DEFAULT NULL,
  `idgrupo` double DEFAULT NULL,
  `idalumno` double DEFAULT NULL,
  `matricula` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `alumno` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `materia` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `calificacion` double DEFAULT NULL,
  `asistencia` double DEFAULT NULL,
  `curso` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `idprofesor` double DEFAULT NULL,
  `profesor` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `my_idgrupo` double DEFAULT NULL,
  `my_cvegpo` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `my_idmateria` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadarea`
--

CREATE TABLE `calidadarea` (
  `IdArea` int(11) NOT NULL,
  `Nombre` varchar(50) CHARACTER SET utf8 NOT NULL,
  `IdModulo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidaddocumentosvariados`
--

CREATE TABLE `calidaddocumentosvariados` (
  `IdDocumento` int(11) NOT NULL,
  `Descripcion` varchar(200) CHARACTER SET utf8 NOT NULL,
  `Fecha` date NOT NULL,
  `Documento` varchar(200) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidaddocumentovariados_por_area`
--

CREATE TABLE `calidaddocumentovariados_por_area` (
  `IdDocumento` int(11) NOT NULL,
  `IdArea` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadformatosdocumentos`
--

CREATE TABLE `calidadformatosdocumentos` (
  `IdFormatoDocumento` int(11) NOT NULL,
  `Descripcion` varchar(200) CHARACTER SET utf8 NOT NULL,
  `fechaRegistro` date NOT NULL,
  `Documento` varchar(200) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadformatos_por_procedimiento`
--

CREATE TABLE `calidadformatos_por_procedimiento` (
  `IdProcedimiento` int(11) NOT NULL,
  `IdFormatoDocumento` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadformato_documento_area`
--

CREATE TABLE `calidadformato_documento_area` (
  `IdFormatoDocumento` int(11) NOT NULL,
  `IdArea` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadinstructivotrabajo`
--

CREATE TABLE `calidadinstructivotrabajo` (
  `IdInstructivoTrabajo` int(11) NOT NULL,
  `Descripcion` varchar(200) CHARACTER SET utf8 NOT NULL,
  `Documento` varchar(250) CHARACTER SET utf8 NOT NULL,
  `fechaRegistro` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadinstructivotrabajo_por_area`
--

CREATE TABLE `calidadinstructivotrabajo_por_area` (
  `IdInstructivoTrabajo` int(11) NOT NULL,
  `IdArea` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadinstructivo_por_procedimiento`
--

CREATE TABLE `calidadinstructivo_por_procedimiento` (
  `IdInstructivoTrabajo` int(11) NOT NULL,
  `IdProcedimiento` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadmodulo`
--

CREATE TABLE `calidadmodulo` (
  `IdModulo` int(11) NOT NULL,
  `Descripcion` varchar(50) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadorganigrama`
--

CREATE TABLE `calidadorganigrama` (
  `IdOrganigrama` int(11) NOT NULL,
  `Descripcion` varchar(50) CHARACTER SET utf8 NOT NULL,
  `fechaRegistro` date NOT NULL,
  `Documento` varchar(250) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadorganigrama_por_area`
--

CREATE TABLE `calidadorganigrama_por_area` (
  `IdArea` int(11) NOT NULL,
  `IdOrganigrama` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadprocedimiento`
--

CREATE TABLE `calidadprocedimiento` (
  `IdProcedimiento` int(11) NOT NULL,
  `Descripcion` varchar(200) CHARACTER SET utf8 NOT NULL,
  `fechaRegistro` date NOT NULL,
  `Documento` varchar(250) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadprocedimiento_por_area`
--

CREATE TABLE `calidadprocedimiento_por_area` (
  `IdArea` int(11) NOT NULL,
  `IdProcedimiento` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadpuesto`
--

CREATE TABLE `calidadpuesto` (
  `IdPuesto` int(11) NOT NULL,
  `Descripcion` varchar(100) CHARACTER SET utf8 NOT NULL,
  `fechaRegistro` date NOT NULL,
  `IdArea` int(11) NOT NULL,
  `Documento` varchar(250) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `calidadusuario`
--

CREATE TABLE `calidadusuario` (
  `IdUsuario` int(11) NOT NULL,
  `Nombre` varchar(50) CHARACTER SET utf8 NOT NULL,
  `Apellidos` varchar(50) CHARACTER SET utf8 NOT NULL,
  `usuario` varchar(50) CHARACTER SET utf8 NOT NULL,
  `contraseña` varchar(50) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `catalogosclasificacionmaterias`
--

CREATE TABLE `catalogosclasificacionmaterias` (
  `idCatalogo` smallint(6) NOT NULL,
  `Catalogo` varchar(100) NOT NULL,
  `activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `catalogosgeneral`
--

CREATE TABLE `catalogosgeneral` (
  `IdCatalogo` smallint(6) NOT NULL,
  `Clasificacion` smallint(6) NOT NULL,
  `Nombre` varchar(250) CHARACTER SET utf8 NOT NULL,
  `Descripcion` varchar(250) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `catalogosgeneral`
--

INSERT INTO `catalogosgeneral` (`IdCatalogo`, `Clasificacion`, `Nombre`, `Descripcion`) VALUES
(1, 1, 'Masculino', 'Genero'),
(2, 1, 'Femenino', 'Genero'),
(3, 2, 'Inscripciones', 'Tramite -- Inscripciones de Alumnos de Nuevo ingreso'),
(4, 3, 'Alumno Interno', 'Tipo de Alumno'),
(5, 3, 'Alumno Externo', 'Tipo de Alumno'),
(6, 4, 'Inscripcion', 'Periodo de Movimientos'),
(7, 4, 'Inscripcion Extemporanea', 'Periodo de Movimientos'),
(8, 4, 'Reinscripcion', 'Periodo de Movimientos'),
(9, 4, 'Reinscripcion Extemporanea', 'Periodo de Movimientos'),
(10, 5, 'Soltero', 'Estado Civil'),
(11, 5, 'Casado', 'Estado Civil'),
(12, 6, 'Activo', 'Estados del Alumno'),
(13, 6, 'Baja Temporal', 'Estados del Alumno'),
(14, 6, 'Baja Definitiva', 'Estados del Alumno'),
(15, 6, 'Egresado', 'Estados del Alumno'),
(16, 7, 'Físico-Matemáticas', 'Área de egreso'),
(17, 7, 'Químico-Biólogicas', 'Área de egreso'),
(18, 7, 'Económico-Adminístrativas', 'Área de egreso'),
(19, 7, 'Sociales-Humanidades', 'Área de egreso'),
(20, 7, 'Bachillerato general', 'Área de egreso'),
(21, 8, 'por publicidad en periódico', 'Medio de promoción'),
(22, 8, 'por publicidad en radio', 'Medio de promoción'),
(23, 8, 'por publicidad en TV', 'Medio de promoción'),
(24, 8, 'por página web y redes sociales', 'Medio de promoción'),
(25, 8, 'por promoción UPV en su IEMS', 'Medio de promoción'),
(26, 8, 'por visita guiada a la UPV', 'Medio de promoción'),
(27, 8, 'por recomendación', 'Medio de promoción'),
(28, 9, 'Matutino', 'Turno deseado del aspirante'),
(29, 9, 'Vespertino', 'Turno deseado del aspirante'),
(30, 9, 'Nocturno', 'Turno deseado del aspirante'),
(31, 4, 'Altas y Bajas', 'Periodo de Movimientos'),
(32, 10, 'Ordinario', 'Tipo de examen que presento el alumno'),
(33, 10, 'Recuperacion', 'Tipo de examen que presento el alumno'),
(34, 10, 'Global', 'Tipo de examen que presento el alumno'),
(35, 11, 'Docente', 'Tipo de empleado'),
(36, 11, 'Administrativo', 'Tipo de empleado'),
(37, 11, 'Docente administrativo', 'Tipo de empleado'),
(38, 11, 'Operativo', 'Tipo de empleado'),
(42, 12, 'Aula', 'Tipo de aula'),
(43, 12, 'Laboratorio', 'Tipo de aula'),
(44, 12, 'Taller', 'Tipo de aula'),
(45, 13, 'Pendiente', 'Estatus cuatrimestre'),
(46, 13, 'Activo', 'Estatus cuatrimestre'),
(47, 13, 'Concluido', 'Estatus cuatrimestre'),
(48, 14, 'Local', 'Tipo domicilio'),
(49, 14, 'Foraneo', 'Tipo domicilio'),
(50, 15, 'O', 'Tipo de acreditacion -- curso normal'),
(51, 15, 'R', 'Tipo de acreditacion -- curso repetición'),
(52, 15, 'ES', 'Tipo de acreditacion -- curso especial'),
(53, 15, 'REV', 'Tipo de acreditacion -- acreditación por revalidación'),
(54, 16, 'TR', 'Tipo materia -- TRANSVERSAL'),
(55, 16, 'CV', 'Tipo materia -- COLUMNA VERTEBRAL'),
(56, 16, 'ES', 'Tipo materia -- ESPECIFICA'),
(57, 16, 'OP', 'Tipo materia (maestria)'),
(58, 16, 'SEMINARIO', 'Tipo materia (maestria)'),
(59, 17, 'Ingenieria', 'NULL'),
(60, 17, 'Posgrado', 'NULL'),
(61, 17, 'Curso Externo', 'NULL'),
(62, 2, 'Reinscripcion', 'Trámite -- Reinscripciones de Alumnos 2 cuatrimestre en adelante'),
(63, 15, 'EQV', 'Tipo de acreditacion -- Equivalencia Cambio de Carrera'),
(64, 15, 'COM', 'Tipo de acreditacion -- Por Competencia'),
(65, 18, 'ING. ISMAEL ALBERTO PACHECO ZAVALETA', 'JEFE DEL DEPARTAMENTO DE SERVICIOS ESCOLARES'),
(66, 18, 'Universidad Politécnica de Victoria.', 'Mensaje para Horarios de Alumno'),
(67, 4, 'Consulta de Materias', 'Periodo de Movimientos'),
(68, 19, 'DESCONOCIDO', 'Tipo de sangre'),
(69, 19, 'O+', 'Tipo de sangre'),
(70, 19, 'O-', 'Tipo de sangre'),
(71, 19, 'A+', 'Tipo de sangre'),
(72, 19, 'A-', 'Tipo de sangre'),
(74, 19, 'B+', 'Tipo de sangre'),
(76, 19, 'B-', 'Tipo de sangre'),
(77, 19, 'AB+', 'Tipo de sangre'),
(78, 19, 'AB-', 'Tipo de sangre'),
(79, 20, 'DOMICILIO: AVENIDA NUEVAS TECNOLOGÍAS 5902 PARQUE CIENTÍFICO Y TECNOLÓGICO DE TAMAULIPAS 87138', 'Direccion de la Universidad'),
(80, 7, 'Ingeniería Electrónica', 'Área de egreso'),
(81, 7, 'Ingeniería Mecánica', 'Área de egreso'),
(82, 7, 'Ingeniería en Electrónica y Comunicaciones', 'Área de egreso'),
(83, 7, 'Ingeniería en Sistemas Computacionales', 'Área de egreso'),
(84, 7, 'Ingeniería en Telemática', 'Área de egreso'),
(85, 7, 'Licenciatura en Informática', 'Área de egreso'),
(86, 21, 'Asignado', 'Catalogo estatus asignacion estancia'),
(87, 21, 'Cancelado', 'Catalogo estatus asignacion estancia'),
(88, 21, 'En proceso', 'Catalogo estatus asignacion estancia'),
(89, 21, 'Concluido', 'Catalogo estatus asignacion estancia'),
(90, 7, 'Ingeniería Mecánica Eléctrica', 'Área de egreso'),
(91, 22, 'LIC.', 'Grado academico'),
(92, 22, 'ING.', 'Grado academico'),
(93, 22, 'M.C.', 'Grado academico'),
(94, 22, 'DR.', 'Grado academico'),
(95, 23, 'PADRE', 'Parentesco'),
(96, 23, 'MADRE', 'Parentesco'),
(97, 23, 'TUTOR', 'PARENTESCO'),
(98, 24, 'CENEVAL', 'Evaluacion Aspirantes'),
(99, 24, 'INTERNO', 'Evaluacion Aspirantes'),
(100, 7, 'Ingeniería en Tecnologías de la Información', 'Área de egreso'),
(101, 7, 'Licenciatura en Educación Media Física y Química', 'Área de egreso'),
(102, 7, 'Ingeniería Mecatrónica', 'Área de egreso'),
(103, 7, 'Ingeniería en Sistemas Electrónicos', 'Área de egreso'),
(104, 25, 'Beca UPV aprovechamiento', 'Tipo de beca'),
(106, 25, 'Beca Excelencia', 'Tipo de beca'),
(107, 25, 'Beca Maestria para trabajadores', 'Tipo de beca'),
(108, 26, 'Se asignó beca', 'Movimiento de becas'),
(109, 26, 'Se retiró beca', 'Movimiento de becas'),
(110, 6, 'Titulado', 'Estados del Alumno'),
(111, 7, 'Ciencias Exactas', 'Área de egreso'),
(112, 17, 'Licenciatura', 'NULL'),
(113, 27, '5', 'Cantidad maxima de materias a elegir para alumnos especiales'),
(114, 22, 'MTRO.', 'Grado academico'),
(115, 5, 'Divorciado', 'Estado Civil'),
(116, 5, 'Union Libre', 'Estado Civil'),
(117, 5, 'Viudo', 'Estado Civil'),
(118, 25, 'Beca 100%', 'Beca por promedio entre 90 y 100'),
(119, 25, 'Beca 50%', 'Beca por promedio entre 85 y 89'),
(120, 25, 'Beca 30%', 'Beca por promedio entre 80 y 84'),
(121, 7, 'Ingeniería Industrial', 'Área de egreso'),
(123, 6, 'Grado Académico', 'Estados del Alumno'),
(124, 22, 'M.A.P.', 'Grado Academico'),
(125, 24, 'EQUIVALENCIA', 'Evaluacion Aspirantes'),
(126, 28, 'Aceptado', 'Resultado Aspirante'),
(127, 28, 'Rechazado', 'Resultado Aspirante'),
(128, 28, 'Cuatrimestre 0', 'Resultado Aspirante'),
(130, 22, 'M.E.', 'Grado Academico'),
(131, 29, '3', 'Total materias a tomar junto con estadía'),
(132, 7, 'Ingeniería Civil', 'Área de egreso'),
(133, 30, 'Jp9P8xZJyRE2wQ2ZAEK6Oekf/TlfQHLfZUSWkcTIeYoYvAbnithkD1PwO2ZuLjhemjZJXat2z9PBGpiMYsIBEKdfJKaVasg89GMGppZqThCM8SUlYLVCjJjkjEA8Oe1P', 'Cuenta para envio de contraseñas SIIUPV'),
(134, 31, 'Baja Definitiva', 'Resolucion para especiales'),
(135, 31, 'Baja Temporal', 'Resolucion para especiales'),
(136, 31, 'Procede', 'Resolucion para especiales'),
(137, 6, 'Movilidad', 'Estados del Alumno'),
(138, 6, 'No ingresó', 'Estados del Alumno'),
(139, 32, 'Redondo', 'Tipo de Boleto de Transporte Escolar'),
(140, 32, 'Sencillo', 'Tipo de Boleto de Transporte Escolar'),
(144, 7, 'Ingeniería en Sistemas de Producción', 'Área de egreso'),
(145, 33, 'Pagado', 'Estatus de alumno-transporte'),
(146, 33, 'No Pagado', 'Estatus de alumno-transprte'),
(147, 31, 'Procede solo P.A.', 'Resolucion para especiales'),
(148, 34, 'Educativo', 'Clasificación de Sectores Empresariales'),
(149, 34, 'Privado', 'Clasificación de Sectores Empresariales'),
(150, 34, 'Público', 'Clasificación de Sectores Empresariales'),
(151, 34, 'Social', 'Clasificación de Sectores Empresariales'),
(152, 35, 'CANDIDATOS', 'Candidatos a estadía'),
(153, 35, 'INSCRITOS', 'Inscritos en estadía'),
(154, 36, 'Carta Presentacion', 'Tipo de Carta'),
(155, 36, 'Carta Aceptacion', 'Tipo de Carta'),
(156, 36, 'Carta Liberacion', 'Tipo de Carta'),
(157, 36, 'Carta Anteproyecto', 'Tipo de Carta'),
(161, 38, 'Seguro Interno', 'Tipo de Seguro'),
(162, 38, 'Seguro Externo', 'Tipo de Seguro');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `catalogosmovimientoestatusalumno`
--

CREATE TABLE `catalogosmovimientoestatusalumno` (
  `idMovimientoEstatusAlumno` smallint(6) NOT NULL,
  `Movimiento` varchar(100) CHARACTER SET utf8 NOT NULL,
  `Descripcion` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `catalogostitulacion`
--

CREATE TABLE `catalogostitulacion` (
  `idCatalogo` smallint(6) NOT NULL,
  `Catalogo` varchar(100) CHARACTER SET utf8 NOT NULL,
  `Clasificacion` smallint(6) DEFAULT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `catalogostitulacion`
--

INSERT INTO `catalogostitulacion` (`idCatalogo`, `Catalogo`, `Clasificacion`, `Activo`) VALUES
(1, 'Elaboración ', 1, 1),
(2, 'Legalización', 1, 1),
(3, 'UPV Legalizado', 1, 1),
(4, 'En DGP', 1, 1),
(5, 'UPV Concluido', 1, 1),
(6, 'Entregado', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cdx_mysql`
--

CREATE TABLE `cdx_mysql` (
  `idalumno` double DEFAULT NULL,
  `idplan_estudios` double DEFAULT NULL,
  `idmateria` double DEFAULT NULL,
  `calificacion` double DEFAULT NULL,
  `tipo_curso` double DEFAULT NULL,
  `inscripciones` double DEFAULT NULL,
  `idcuatrimestre_prim_insc` double DEFAULT NULL,
  `idcuatrimestre_ult_insc` double DEFAULT NULL,
  `idMateriaReferencia` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `correos$`
--

CREATE TABLE `correos$` (
  `email address` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `firstname` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `lastname` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `matricula` varchar(255) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresadeudosbiblioteca`
--

CREATE TABLE `escolaresadeudosbiblioteca` (
  `idAlumno` int(11) NOT NULL,
  `matricula` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `Carrera` varchar(200) CHARACTER SET utf8 DEFAULT NULL,
  `Alumno` varchar(200) CHARACTER SET utf8 DEFAULT NULL,
  `adeudo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumno`
--

CREATE TABLE `escolaresalumno` (
  `idalumno` int(11) NOT NULL,
  `idpersona` int(11) NOT NULL,
  `matricula` varchar(7) CHARACTER SET utf8 NOT NULL,
  `idTipoAlumno` tinyint(3) UNSIGNED NOT NULL,
  `num_seguridad` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `firma` longblob DEFAULT NULL,
  `estatus` int(11) NOT NULL,
  `idplanestudios` int(11) NOT NULL,
  `idtutor` int(11) DEFAULT NULL,
  `Aceptado` tinyint(4) NOT NULL,
  `numOpcion` tinyint(3) UNSIGNED DEFAULT NULL,
  `SSActivo` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresalumno`
--

INSERT INTO `escolaresalumno` (`idalumno`, `idpersona`, `matricula`, `idTipoAlumno`, `num_seguridad`, `firma`, `estatus`, `idplanestudios`, `idtutor`, `Aceptado`, `numOpcion`, `SSActivo`) VALUES
(67, 130, '1920001', 4, '7777', NULL, 12, 2, NULL, 0, 161, 1),
(68, 131, '1920002', 4, '1111123', NULL, 12, 30, NULL, 0, 161, 1),
(69, 132, '1920003', 4, '11111', NULL, 12, 5, NULL, 0, 161, 1),
(70, 133, '1920004', 4, '11111', NULL, 12, 4, NULL, 0, 161, 1),
(71, 134, '1920005', 4, '1111123', NULL, 12, 3, NULL, 0, 161, 1),
(72, 135, '1920006', 4, '4', NULL, 12, 4, NULL, 0, 161, 1),
(73, 136, '1920007', 4, '55551520', NULL, 12, 7, NULL, 0, 161, 1),
(74, 137, '1920008', 4, NULL, NULL, 12, 1, NULL, 0, 161, 1),
(75, 138, '1920009', 4, '4544126', NULL, 12, 10, NULL, 0, 161, 1),
(76, 139, '1920010', 4, NULL, NULL, 12, 27, NULL, 0, 162, 1),
(77, 140, '1920011', 4, NULL, NULL, 12, 3, NULL, 0, 161, NULL),
(78, 141, '1920012', 4, NULL, NULL, 12, 29, NULL, 0, 161, NULL),
(79, 142, '1920013', 4, NULL, NULL, 12, 19, NULL, 0, 162, NULL),
(80, 143, '1920014', 4, NULL, NULL, 12, 18, NULL, 0, 161, NULL),
(81, 144, '1920015', 4, NULL, NULL, 12, 4, NULL, 0, 161, NULL),
(82, 145, '1920016', 4, NULL, NULL, 12, 7, NULL, 0, 161, NULL),
(83, 148, '1920017', 4, '555501234', NULL, 12, 1, NULL, 0, 162, 1),
(84, 153, '1920018', 4, '7777', NULL, 12, 7, NULL, 0, 161, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumnobecas`
--

CREATE TABLE `escolaresalumnobecas` (
  `idAlumnoBeca` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `idBeca` int(11) NOT NULL,
  `Anotaciones` longtext DEFAULT NULL,
  `idplan_estudios` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumnobecashistorico`
--

CREATE TABLE `escolaresalumnobecashistorico` (
  `idAlumnoBecaHistorico` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `idBeca` int(11) NOT NULL,
  `fechaRegistro` datetime NOT NULL,
  `idMovimiento` smallint(6) NOT NULL,
  `idCuatrimestre` int(11) DEFAULT NULL,
  `MovimientoValido` tinyint(4) NOT NULL,
  `idplan_estudios` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresalumnobecashistorico`
--

INSERT INTO `escolaresalumnobecashistorico` (`idAlumnoBecaHistorico`, `idAlumno`, `idBeca`, `fechaRegistro`, `idMovimiento`, `idCuatrimestre`, `MovimientoValido`, `idplan_estudios`) VALUES
(1, 1, 3, '2020-02-07 18:51:29', 108, 3, 1, 5),
(4, 1, 1, '2020-02-07 19:21:43', 108, 4, 1, 5),
(5, 1, 1, '2020-02-07 19:40:35', 108, 4, 1, 5),
(6, 1, 2, '2020-02-07 19:40:51', 108, 4, 1, 5),
(8, 1, 2, '2020-02-07 20:21:45', 108, 5, 1, 5),
(9, 1, 3, '2020-02-07 20:21:47', 108, 5, 1, 5),
(10, 1, 6, '2020-02-07 20:21:51', 108, 5, 1, 5),
(11, 1, 5, '2020-02-07 20:21:53', 108, 5, 1, 5),
(12, 1, 2, '2020-02-07 20:31:04', 108, 36, 1, 5),
(13, 1, 1, '2020-02-07 23:00:20', 108, 2, 1, 5),
(14, 1, 2, '2020-02-07 23:00:27', 108, 1, 1, 5),
(15, 1, 4, '2020-02-07 23:00:28', 108, 1, 1, 5),
(16, 0, 1, '2020-02-18 21:06:01', 108, 1, 1, 5),
(17, 0, 1, '2020-02-18 22:45:14', 108, 3, 1, 5),
(18, 0, 2, '2020-02-18 22:54:01', 108, 3, 1, 5),
(19, 0, 5, '2020-02-18 22:54:12', 108, 3, 1, 5),
(20, 0, 1, '2020-02-19 17:01:58', 108, 2, 1, 5),
(21, 0, 2, '2020-02-19 17:02:06', 108, 2, 1, 5),
(22, 0, 3, '2020-02-19 20:55:31', 108, 1, 1, 5),
(23, 0, 1, '2020-02-20 21:59:53', 108, 1, 1, 0),
(24, 26, 1, '2020-02-20 22:09:36', 108, 2, 1, 4),
(25, 27, 1, '2020-02-20 22:24:10', 108, 4, 1, 4),
(26, 28, 1, '2020-02-25 19:16:40', 108, 1, 1, 2),
(27, 30, 1, '2020-03-04 19:07:49', 108, 1, 1, 29),
(28, 30, 2, '2020-03-04 19:07:51', 108, 1, 1, 29),
(29, 30, 3, '2020-03-04 19:07:53', 108, 1, 1, 29),
(30, 30, 5, '2020-03-04 19:07:54', 108, 1, 1, 29),
(31, 30, 2, '2020-03-04 19:09:28', 108, 1, 1, 1),
(32, 30, 1, '2020-03-04 19:10:42', 108, 5, 1, 5),
(33, 35, 1, '2020-03-06 04:08:23', 108, 1, 1, 1),
(34, 35, 2, '2020-03-06 04:08:26', 108, 1, 1, 1),
(35, 28, 1, '2020-03-11 23:19:39', 108, 1, 1, 1),
(36, 28, 2, '2020-03-11 23:19:42', 108, 1, 1, 1),
(37, 28, 3, '2020-03-11 23:19:43', 108, 1, 1, 1),
(38, 82, 1, '2020-03-28 01:29:19', 108, 1, 1, 7),
(39, 82, 2, '2020-03-28 01:29:22', 108, 1, 1, 7),
(40, 82, 4, '2020-03-28 01:29:24', 108, 1, 1, 7),
(41, 82, 5, '2020-03-28 01:29:25', 108, 1, 1, 7),
(42, 82, 6, '2020-03-28 01:29:28', 108, 1, 1, 7),
(43, 82, 9, '2020-03-28 01:29:33', 108, 1, 1, 7),
(44, 84, 2, '2020-04-05 00:00:16', 108, 2, 1, 7),
(45, 84, 4, '2020-04-05 00:00:18', 108, 2, 1, 7),
(46, 84, 5, '2020-04-05 00:00:19', 108, 2, 1, 7),
(47, 84, 6, '2020-04-05 00:00:21', 108, 2, 1, 7);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumnocarreras`
--

CREATE TABLE `escolaresalumnocarreras` (
  `IdAlumnoCarrera` int(11) NOT NULL,
  `IdAlumno` int(11) NOT NULL,
  `IdPlanEstudios` int(11) NOT NULL,
  `Estatus` smallint(6) NOT NULL,
  `Generacion` varchar(3) CHARACTER SET utf8 NOT NULL,
  `NoReinscripciones` tinyint(3) UNSIGNED NOT NULL,
  `idCampus` smallint(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresalumnocarreras`
--

INSERT INTO `escolaresalumnocarreras` (`IdAlumnoCarrera`, `IdAlumno`, `IdPlanEstudios`, `Estatus`, `Generacion`, `NoReinscripciones`, `idCampus`) VALUES
(38, 67, 2, 12, '192', 4, 1),
(39, 68, 30, 15, '192', 10, 1),
(40, 68, 22, 12, '192', 2, 1),
(41, 71, 1, 12, '192', 1, 1),
(42, 72, 1, 15, '192', 12, 1),
(43, 73, 7, 110, '192', 2, 1),
(44, 69, 7, 12, '192', 1, 1),
(45, 79, 2, 12, '192', 0, 1),
(46, 80, 1, 12, '192', 1, 1),
(47, 81, 4, 15, '192', 10, 1),
(48, 82, 2, 12, '192', 1, 1),
(49, 67, 3, 12, '192', 4, 1),
(50, 69, 3, 12, '192', 1, 1),
(51, 83, 1, 15, '192', 10, 1),
(52, 84, 7, 12, '192', 2, 1),
(53, 75, 7, 12, '192', 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumnohistoricodeestatus`
--

CREATE TABLE `escolaresalumnohistoricodeestatus` (
  `idAlumnoHistoricoDeEstatus` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `idPlanDeEstudio` int(11) NOT NULL,
  `idEstatus` int(11) NOT NULL,
  `fecha` datetime NOT NULL,
  `Anotaciones` longtext DEFAULT NULL,
  `idMotivo` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumnomateriasreprobadas`
--

CREATE TABLE `escolaresalumnomateriasreprobadas` (
  `idAlumno` int(11) DEFAULT NULL,
  `idPlanEstudios` int(11) DEFAULT NULL,
  `Matricula` longtext DEFAULT NULL,
  `NumReprobadas` smallint(6) DEFAULT NULL,
  `MaximoCuatri` smallint(6) DEFAULT NULL,
  `minimoMaterias` smallint(6) DEFAULT NULL,
  `maximoMaterias` int(11) DEFAULT NULL,
  `Estatus` int(11) DEFAULT NULL,
  `MateriasPorCursar` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumnomovilidad`
--

CREATE TABLE `escolaresalumnomovilidad` (
  `idAlumnoMovilidad` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `idMateria` int(11) NOT NULL,
  `Calificacion` tinyint(3) UNSIGNED NOT NULL,
  `idEscuela` int(11) NOT NULL,
  `idCuatrimestre` int(11) NOT NULL,
  `Observaciones` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumnospendientes`
--

CREATE TABLE `escolaresalumnospendientes` (
  `IdAlumnoPendiente` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `IdPlanEstudios` int(11) NOT NULL,
  `Matricula` varchar(7) CHARACTER SET utf8 NOT NULL,
  `Nombre` varchar(250) CHARACTER SET utf8 NOT NULL,
  `IdPendiente` int(11) NOT NULL,
  `PermitirleInscribirse` tinyint(4) NOT NULL,
  `Resuelto` tinyint(4) NOT NULL,
  `Nota` varchar(250) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresalumno_especial`
--

CREATE TABLE `escolaresalumno_especial` (
  `idalumno` int(11) NOT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `mesp` tinyint(3) UNSIGNED NOT NULL,
  `mrep` tinyint(3) UNSIGNED NOT NULL,
  `idpersona` int(11) NOT NULL,
  `dictamen` tinyint(4) DEFAULT NULL,
  `Observaciones` longtext DEFAULT NULL,
  `Resolucion` smallint(6) DEFAULT NULL,
  `Cuatri_PlanOCarrDife` smallint(6) DEFAULT NULL,
  `Cuatri_PlanCarreraActual` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresaspirante`
--

CREATE TABLE `escolaresaspirante` (
  `idaspirante` int(11) NOT NULL,
  `folio_ceneval` int(11) DEFAULT NULL,
  `puntos_ceneval` int(11) DEFAULT NULL,
  `anio_egreso` smallint(6) NOT NULL,
  `promedio` decimal(5,2) DEFAULT NULL,
  `area_egreso` tinyint(3) UNSIGNED DEFAULT NULL,
  `idesc_procedencia` int(11) DEFAULT NULL,
  `idcarrera` int(11) NOT NULL,
  `IdPlanEstudio` int(11) NOT NULL,
  `turno` tinyint(3) UNSIGNED NOT NULL,
  `medio_promocion` tinyint(3) UNSIGNED DEFAULT NULL,
  `idpersona` int(11) NOT NULL,
  `estatus` tinyint(3) UNSIGNED DEFAULT NULL,
  `cuatri_ingreso` int(11) DEFAULT NULL,
  `registro_valido` tinyint(4) DEFAULT NULL,
  `FolioPertenencia` int(11) NOT NULL,
  `FechaRegistro` date DEFAULT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `idCampus` smallint(6) NOT NULL,
  `fechaExamen` datetime DEFAULT NULL,
  `numOpcion` tinyint(3) UNSIGNED DEFAULT NULL,
  `Resultado` smallint(6) DEFAULT NULL,
  `check1` tinyint(4) NOT NULL,
  `fechafin_eproc` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresaspirante`
--

INSERT INTO `escolaresaspirante` (`idaspirante`, `folio_ceneval`, `puntos_ceneval`, `anio_egreso`, `promedio`, `area_egreso`, `idesc_procedencia`, `idcarrera`, `IdPlanEstudio`, `turno`, `medio_promocion`, `idpersona`, `estatus`, `cuatri_ingreso`, `registro_valido`, `FolioPertenencia`, `FechaRegistro`, `idcuatrimestre`, `idCampus`, `fechaExamen`, `numOpcion`, `Resultado`, `check1`, `fechafin_eproc`) VALUES
(79, 1503, 8523, 2007, '3.00', 16, 1, 2, 2, 28, 21, 130, NULL, 73, NULL, 98, '2020-03-21', 1, 1, '2020-03-22 01:00:00', 1, 126, 1, '2007-03-21'),
(80, 1111, 152257, 2018, '10.00', 16, 1, 15, 30, 28, 21, 131, NULL, 181, NULL, 98, '2020-03-21', 32, 1, '2020-03-28 01:30:00', 1, 126, 1, '2018-03-14'),
(81, 0, 0, 2020, '8.00', 16, 1, 5, 5, 29, 23, 132, NULL, 73, NULL, 98, '2020-03-22', 1, 1, '2020-01-01 01:00:00', 1, 126, 1, '2020-03-19'),
(82, 0, 0, 2015, '10.00', 16, 1, 4, 4, 28, 23, 133, NULL, 73, NULL, 98, '2020-03-21', 1, 4, NULL, 1, NULL, 1, '2020-03-27'),
(83, 1111, 1099, 2019, '4.00', 16, 1, 3, 3, 29, 23, 134, NULL, 83, NULL, 98, '2020-03-22', 4, 2, NULL, 3, NULL, 1, '2020-03-19'),
(84, 302050, 22222222, 2002, '10.00', 16, 1, 2, 2, 28, 24, 135, NULL, 192, NULL, 98, NULL, 36, 1, '2020-03-28 01:01:00', 6, 126, 1, '2020-03-28'),
(85, 0, 0, 2002, '2.00', 17, 1, 2, 7, 28, 24, 136, NULL, 73, NULL, 99, '2020-03-22', 1, 1, NULL, 3, NULL, 1, '2020-03-26'),
(86, 15100, 1099, 2015, '7.00', 18, 1, 1, 1, 28, 21, 137, NULL, 73, NULL, 98, '2020-03-22', 1, 1, NULL, 3, NULL, 1, '2020-03-06'),
(87, 4856415, 14515, 2004, '10.00', 16, 1, 7, 10, 28, 21, 138, NULL, 132, NULL, 98, '2020-03-24', 18, 1, NULL, 5, NULL, 1, '2004-03-13'),
(88, 0, 0, 2020, '70.00', 17, 4, 14, 27, 28, 23, 139, NULL, 73, NULL, 0, '2020-03-21', 1, 1, NULL, 4, NULL, 1, '2020-03-21'),
(89, 44541, 4525, 2002, '80.00', 16, 1, 3, 3, 28, 23, 140, NULL, 73, NULL, 98, '2020-03-26', 1, 1, '2020-03-29 02:00:00', 1, 126, 1, '2020-03-26'),
(90, 0, 0, 2016, '80.00', 100, 3, 2, 29, 28, 23, 141, NULL, 192, NULL, 99, '2020-03-26', 36, 1, '2020-03-26 08:00:00', 1, 126, 1, '2020-03-26'),
(91, 4151, 1151, 2013, '10.00', 132, 8, 11, 19, 28, 21, 142, NULL, 163, NULL, 98, '2020-03-26', 28, 1, '2020-03-29 13:00:00', 1, 128, 1, '2013-03-05'),
(92, 142521, 1099, 2014, '90.00', 111, 13, 9, 18, 28, 23, 143, NULL, 151, NULL, 98, '2016-07-14', 23, 1, '2016-07-14 13:00:00', 2, 126, 1, '2014-03-07'),
(93, 547425, 1099, 2009, '90.00', 17, 9, 4, 4, 28, 21, 144, NULL, 91, NULL, 99, '2020-03-21', 5, 1, NULL, 2, 128, 1, '2020-03-26'),
(94, 6155, 1506, 2009, '10.00', 16, 1, 2, 7, 28, 21, 145, NULL, 101, NULL, 98, '2020-03-28', 8, 1, '2020-03-22 13:00:00', 1, 126, 1, '2009-03-07'),
(95, 44, 9, 2002, '1.00', 16, 1, 11, 19, 29, 21, 147, NULL, 73, NULL, 98, '2020-02-26', 1, 0, '2020-03-28 13:30:00', 1, 126, 1, '2020-03-27'),
(96, 58749584, 15009, 2020, '10.00', 16, 1, 1, 1, 28, 21, 148, NULL, 83, NULL, 0, '2020-03-14', 4, 3, '2020-03-06 13:30:00', 1, 126, 1, '2020-03-20'),
(97, 15100, 1099, 2015, '10.00', 18, 41, 2, 7, 28, 22, 153, NULL, 121, NULL, 98, NULL, 14, 1, '2020-04-19 12:00:00', 2, 126, 1, '2020-04-23');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresaula`
--

CREATE TABLE `escolaresaula` (
  `idaula` int(11) NOT NULL,
  `nombre` varchar(50) CHARACTER SET utf8 NOT NULL,
  `capacidad` tinyint(3) UNSIGNED NOT NULL,
  `tipo` tinyint(3) UNSIGNED NOT NULL,
  `idedificio` tinyint(3) UNSIGNED DEFAULT NULL,
  `Descripcion` varchar(200) CHARACTER SET utf8 DEFAULT NULL,
  `disponible` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresbecas`
--

CREATE TABLE `escolaresbecas` (
  `idBeca` int(11) NOT NULL,
  `Beca` varchar(100) CHARACTER SET utf8 NOT NULL,
  `Activa` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresbecas`
--

INSERT INTO `escolaresbecas` (`idBeca`, `Beca`, `Activa`) VALUES
(1, 'PRONABES', 1),
(2, 'TELMEX', 1),
(3, 'CONACYT--POSGRADOS DE EXCELENCIA ', 1),
(4, 'CONACYT--MADRES SOLTERAS', 1),
(5, 'UNIVERSITARIAS', 1),
(6, 'TU PUEDES', 1),
(7, 'CUENTA CONMIGO', 1),
(8, 'EL QUE ESTUDIA NO PAGA', 1),
(9, 'EXCELENCIA ACADÉMICA', 1),
(10, 'CNBES-TITULACIÓN', 1),
(11, 'CNBES-MOVILIDAD NACIONAL', 1),
(12, 'CNBES-EXCELENCIA', 1),
(13, 'CNBES-VINCULACIÓN', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarescampus`
--

CREATE TABLE `escolarescampus` (
  `idCampus` smallint(6) NOT NULL,
  `Campus` varchar(100) CHARACTER SET utf8 NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolarescampus`
--

INSERT INTO `escolarescampus` (`idCampus`, `Campus`, `Activo`) VALUES
(1, 'VICTORIA', 1),
(2, 'GONZÁLEZ', 1),
(3, 'BURGOS', 1),
(4, 'JAUMAVE', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarescardex`
--

CREATE TABLE `escolarescardex` (
  `idalumno` int(11) NOT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `idmateria` int(11) NOT NULL,
  `calificacion` tinyint(3) UNSIGNED DEFAULT NULL,
  `tipo_curso` int(11) NOT NULL,
  `inscripciones` tinyint(3) UNSIGNED NOT NULL,
  `idcuatrimestre_prim_insc` int(11) NOT NULL,
  `idcuatrimestre_ult_insc` int(11) NOT NULL,
  `idMateriaReferencia` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarescarga`
--

CREATE TABLE `escolarescarga` (
  `idcarga` int(11) NOT NULL,
  `clave` varchar(50) CHARACTER SET utf8 NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `turno` tinyint(3) UNSIGNED DEFAULT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `duracion` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolarescarga`
--

INSERT INTO `escolarescarga` (`idcarga`, `clave`, `idcuatrimestre`, `turno`, `idplan_estudios`, `duracion`) VALUES
(1, 'ING', 8, 28, 2, 55),
(2, 'ITI 1-1', 8, 28, 2, 55),
(3, 'ITI 1-2', 8, 30, 2, 60),
(4, 'ITI 2-1', 8, 28, 2, 55),
(5, 'ITI 2-3', 8, 30, 2, 60),
(6, 'ITI 2-2', 8, 28, 2, 55),
(7, 'ITI MAT', 8, 29, 2, 55),
(8, 'ITI', 8, 30, 2, 60),
(9, 'ITI 4-1', 8, 28, 2, 55),
(10, 'ITI MAT2', 8, 29, 2, 55),
(11, 'ITI MAT3', 8, 30, 2, 60),
(12, 'ITI 5-1', 8, 28, 2, 55),
(13, 'ITI MAT4', 8, 29, 2, 55),
(14, 'ITI MAT-7', 8, 28, 2, 55),
(15, 'ITI MAT5', 8, 29, 2, 55),
(16, 'ITI MAT6', 8, 30, 2, 60),
(17, 'ITI 6-1', 8, 28, 2, 55),
(18, 'ITI MAT8', 8, 29, 2, 55),
(19, 'ITI MAT9', 8, 30, 2, 60),
(20, 'ITI 8-1', 8, 28, 2, 55),
(21, 'ITI MAT10', 8, 29, 2, 55),
(25, 'MEC 1-1', 9, 28, 1, 55),
(26, 'MEC 2-1', 9, 28, 1, 55),
(27, 'MEC 2-1M', 9, 29, 1, 55),
(28, 'MEC 3-1', 9, 28, 1, 55),
(29, 'MEC 3-1M', 9, 29, 1, 55),
(30, 'MEC 3-2', 9, 28, 1, 55),
(31, 'MEC 4-1', 9, 28, 1, 55),
(32, 'MEC 4-1M', 9, 29, 1, 55),
(33, 'MEC 5-1', 9, 28, 1, 55),
(34, 'MEC 5-2', 9, 29, 1, 55),
(35, 'MEC NOC5', 9, 30, 1, 55),
(36, 'MEC 6-1', 9, 28, 1, 55),
(37, 'MEC 6-1M', 9, 29, 1, 55),
(38, 'MEC 8-1', 9, 28, 1, 55),
(39, 'MEC 9-1', 9, 28, 1, 55),
(40, 'MEC 9-2', 9, 28, 1, 55),
(41, 'ITI M1', 9, 28, 2, 55),
(42, 'ITI 2-2 NOC', 9, 29, 2, 55),
(43, 'ITI-1-NOC', 9, 30, 2, 60),
(44, 'ITI-2-1', 9, 28, 2, 55),
(45, 'MECE 3-2-1', 9, 28, 1, 55),
(46, 'ITI 2-1 NOC', 9, 30, 2, 60),
(47, 'ITI 3-1', 9, 28, 2, 55),
(48, 'ITI 3-1 NOC', 9, 30, 2, 60),
(49, 'ITI 3-1-M', 9, 28, 2, 55),
(50, 'ITI 4-1', 9, 28, 2, 55),
(51, 'ITI 4-2', 9, 29, 2, 60),
(52, 'ITI 5-NOC', 9, 30, 2, 60),
(53, 'ITI 5-1M', 9, 28, 2, 55),
(54, 'ITI 5-2', 9, 29, 2, 55),
(55, 'ITI 6-1', 9, 28, 2, 55),
(56, 'ITI 9-1', 9, 28, 2, 55),
(57, 'ITI 9-2', 9, 29, 2, 55),
(58, 'ITM 1-1', 9, 28, 8, 55),
(59, 'ITM 2', 9, 28, 8, 55),
(60, 'ITM 2-1M', 9, 29, 8, 55),
(61, 'ITM 3-1', 9, 28, 8, 55),
(62, 'ITM 3-2', 9, 29, 8, 55),
(63, 'ITM 3-2M', 9, 28, 8, 55),
(64, 'ITI 9-4', 9, 28, 2, 55),
(65, 'ITI-NG1', 9, 28, 2, 55),
(66, 'ITI 8-1', 9, 29, 2, 55),
(67, 'MEC 8-1', 9, 29, 1, 55),
(68, 'MEC 7-1', 9, 29, 1, 55),
(69, '', 9, 29, 2, 55),
(70, 'MAN 7-1', 9, 29, 8, 55),
(71, 'MAN M', 9, 28, 8, 55),
(72, 'MEC M3', 9, 28, 1, 55),
(73, 'ITI M2', 9, 29, 2, 55),
(74, 'MAN 3M', 9, 29, 8, 55),
(75, 'ITI M3', 9, 29, 2, 55),
(76, 'MEC M4', 9, 28, 1, 55),
(77, 'ITI M3', 9, 28, 2, 55),
(78, 'MEC-102', 9, 30, 4, 60),
(79, 'MTI-102', 9, 30, 5, 55),
(80, 'PRUEBA 103', 9, 28, 2, 55),
(81, 'IM1-1', 10, 28, 6, 55),
(82, 'IM1-2', 10, 28, 6, 55),
(83, 'IM1-3', 10, 28, 6, 55),
(84, 'ITI 1-1', 10, 28, 7, 55),
(85, 'IM1-4', 10, 28, 6, 55),
(86, 'ITI 1-2', 10, 28, 7, 55),
(87, 'ITI1-3', 10, 28, 7, 55),
(88, 'ITI MATERIAS', 10, 28, 2, 55),
(89, 'ITI MATERIAS2', 10, 29, 2, 55),
(90, 'ITI MATERIAS3', 10, 28, 2, 55),
(91, 'ITI 2-1 MATERIA', 10, 29, 2, 60),
(92, 'ITI 3-1 NOCTURN', 10, 29, 2, 60),
(93, 'ITI 4-1', 10, 28, 2, 55),
(94, 'ITI 4-2', 10, 29, 2, 60),
(95, 'ITI 4-1 NOCTURN', 10, 28, 2, 55),
(96, 'ITI 5 MATERIAS', 10, 28, 2, 55),
(97, 'ITI 5 NOCTURNO', 10, 30, 2, 55),
(98, 'ITI 6-1', 10, 29, 2, 60),
(99, 'ITI 6 NOCTURNO', 10, 30, 2, 60),
(100, 'ITI 7-1', 10, 28, 2, 55),
(101, 'ITI 8-1 MATERIA', 10, 28, 2, 55),
(102, 'ITI 8-2 MAETRIA', 10, 29, 2, 55),
(103, 'IM2-1', 10, 28, 1, 55),
(104, 'ANDRES', 10, 28, 2, 55),
(105, 'IM2-1-1', 10, 29, 1, 60),
(106, 'IM-3-1', 10, 28, 1, 55),
(107, 'IM3-1-1', 10, 29, 1, 60),
(108, 'IM4-1', 10, 28, 1, 55),
(109, 'IM4-1-1', 10, 28, 1, 55),
(110, 'IM5-1', 10, 28, 1, 55),
(111, 'IM5-1-1', 10, 28, 1, 60),
(112, 'IM-NOC6', 10, 28, 1, 55),
(113, 'IM 7-1', 10, 28, 1, 55),
(114, 'IM 7-1INGLES', 10, 28, 1, 55),
(115, 'IM MATERIAS', 10, 29, 1, 60),
(116, 'IM 9-1', 10, 28, 1, 55),
(117, 'IM9-1-1', 10, 28, 1, 55),
(118, 'ITI-3-1-2', 10, 28, 2, 55),
(119, 'IM-6-2', 10, 29, 1, 60),
(120, 'ITM 4-1', 10, 28, 8, 55),
(121, 'ITM MATERIAS', 10, 28, 8, 60),
(122, 'ITM-1-1', 10, 28, 8, 55),
(123, 'ITI6-1-1', 10, 28, 2, 55),
(124, 'ITI 6-2', 10, 29, 2, 60),
(125, 'ITM -MATERIAS', 10, 29, 8, 60),
(126, 'ESTADIA', 10, 28, 1, 60),
(127, 'ESTADIA', 10, 28, 2, 60),
(128, 'IM 4-1 INGLES', 10, 28, 1, 55),
(129, 'ITI-C1', 10, 28, 2, 55),
(130, 'ITI-NOC-C2', 10, 30, 2, 60),
(131, 'ITI-C3', 10, 28, 2, 55),
(132, 'ITI-C4', 10, 28, 2, 55),
(133, 'IM-C1', 10, 28, 1, 55),
(134, 'IM-C2', 10, 30, 1, 60),
(135, 'ITM-C1', 10, 30, 8, 60),
(136, 'ITM-C2', 10, 30, 8, 60),
(137, 'IM 2-1-1', 10, 28, 1, 55),
(138, 'IM 9-2', 10, 29, 1, 55),
(139, 'ITI 8-3', 10, 28, 2, 55),
(140, 'ITI-COMPETITIVI', 10, 28, 2, 60),
(141, 'IM-COMPETITIVI', 10, 28, 1, 60),
(142, 'IM-INGVI', 10, 29, 1, 60),
(143, 'ITI-INGVI', 10, 29, 2, 60),
(145, 'C-A', 10, 29, 9, 60),
(146, 'CERO-B', 10, 29, 9, 60),
(147, 'ITI-7-1-1', 10, 28, 2, 55),
(148, 'ITM-ING', 10, 29, 8, 60),
(149, 'IM-CALCULO', 10, 28, 1, 55),
(150, 'IM-LIDERAZGO', 10, 29, 1, 60),
(151, 'IM-INGLES', 10, 28, 1, 55),
(152, 'IM-C-4', 10, 28, 1, 55),
(153, 'ITM 1-2009', 10, 28, 8, 55),
(154, 'ITM-4-1-2010', 10, 28, 8, 55),
(155, 'ITM 3-1-2010', 10, 29, 8, 60),
(156, 'ITM-MATERIAS-20', 10, 29, 8, 60),
(157, 'ITI-DESARROLLO', 10, 29, 2, 60),
(158, 'IM-C-5', 10, 28, 1, 55),
(159, 'ITI-ALG', 10, 28, 2, 55),
(160, 'ITM-INCL-ITI022', 10, 28, 8, 55),
(161, 'ITM-CLON-IM1-2', 10, 28, 8, 55),
(162, 'IM-ROBOTICA', 10, 28, 1, 55),
(163, 'IM-PROGRA', 10, 29, 1, 60),
(164, 'IM-CLON 1-3', 10, 28, 1, 55),
(165, 'IM-CLON-CYR', 10, 28, 1, 60),
(166, 'IM-CLON-DIB', 10, 28, 1, 55),
(167, 'IM-CALCULO', 10, 28, 1, 55),
(168, 'IM-INGLES', 10, 28, 1, 55),
(169, 'ITI-INTERFACES', 10, 28, 2, 55),
(170, 'ITI-PROC-PAR', 10, 29, 2, 55),
(171, 'IM-ING V', 10, 29, 6, 60),
(172, 'ITI-ING V', 10, 29, 7, 60),
(173, 'IM-ING III', 10, 28, 6, 55),
(178, 'MIM-01', 10, 29, 4, 60),
(180, 'MIM-002', 10, 29, 4, 60),
(181, 'MIM-03', 10, 29, 4, 60),
(182, 'MIM-04', 10, 29, 4, 60),
(183, 'MIM-05', 10, 29, 4, 60),
(184, 'MITI-01', 10, 29, 5, 60),
(185, 'MITI-02', 10, 29, 5, 60),
(186, 'MIM-007', 10, 29, 4, 60),
(187, 'IM ESTANCIAS103', 10, 29, 1, 60),
(188, 'ITI EST 103', 10, 29, 2, 60),
(190, 'IM10 1-1', 11, 28, 6, NULL),
(191, 'ITI10 1-1', 11, 28, 7, NULL),
(193, 'MIM09 1-1', 11, 28, 4, NULL),
(194, 'MITI09 1-1', 11, NULL, 5, NULL),
(196, 'ITI10 2-1', 11, 28, 7, NULL),
(199, 'ITI10 2-2', 11, 28, 7, NULL),
(200, 'ITI10 2-M', 11, 28, 7, NULL),
(201, 'IM10 2-2', 11, NULL, 6, NULL),
(202, 'ITI 1-M', 11, 28, 7, NULL),
(207, 'IM10 2-1', 11, 28, 6, NULL),
(208, 'IM10 2-3', 11, 28, 6, NULL),
(209, 'ITM10 2-1', 11, NULL, 8, NULL),
(210, 'IM07 4-1', 11, 28, 1, NULL),
(211, 'IM07 5-1', 11, 28, 1, NULL),
(212, 'IM07 6-1', 11, 28, 1, NULL),
(213, 'IM07 8-1', 11, 28, 1, NULL),
(214, 'IM07 9-1', 11, 28, 1, NULL),
(215, 'ITI7 1-M', 11, 28, 2, NULL),
(216, 'IM10 2-M', 11, NULL, 6, NULL),
(217, 'ITM10 1-M', 11, NULL, 8, NULL),
(218, 'IM07 1-M', 11, 28, 1, NULL),
(219, 'ITM09 1-M', 11, NULL, 8, NULL),
(220, 'ITM09 5-1', 11, 28, 8, NULL),
(221, 'ITI07 5-1', 11, 28, 2, NULL),
(222, 'ITI7 3-M', 11, 28, 2, NULL),
(224, 'ITI7 4-M', 11, 28, 2, NULL),
(225, 'ITI7 5-M', 11, 28, 2, NULL),
(226, 'ITI07 - M', 11, 28, 2, NULL),
(227, 'ITI7 6-M', 11, 28, 2, NULL),
(229, 'ITI07 8-1', 11, 28, 2, NULL),
(231, 'ITI7 8-M', 11, 28, 2, NULL),
(232, 'ITI7 9-M', 11, 28, 2, NULL),
(234, 'ESTANCIAS Y ESTADIA', 11, 28, 1, NULL),
(235, 'MATERIAS CUATRIMESTRE 4', 12, 28, 8, NULL),
(236, 'GRUPO 1: TERCER CUATRIMESTRE ', 12, 28, 8, NULL),
(237, 'MATERIAS CUATRIMESTRE 1 Y 3', 12, 28, 7, NULL),
(238, 'MATERIAS CUATRIMESTRE 3 Y 4', 12, 28, 2, NULL),
(240, 'GRUPO 1: SEGUNDO CUATRIMESTRE', 12, 28, 7, NULL),
(241, 'MATERIAS CUATRIMESTRE 3', 12, 28, 2, NULL),
(242, 'GRUPO 1: SEGUNDO CUATRIMESTRE', 12, 28, 6, NULL),
(243, 'MATERIAS CUATRIMESTRE 1', 12, 28, 7, NULL),
(244, 'MATERIAS CUATRIMESTRE 1', 12, 28, 6, NULL),
(245, 'GRUPO 2: TERCER CUATRIMESTRE ', 12, 28, 7, NULL),
(246, 'GRUPO 1: TERCER CUATRIMESTRE', 12, 28, 6, NULL),
(247, 'MATERIAS CUATRIMESTRE 3, 4 Y 6 ', 12, 28, 2, NULL),
(248, 'GRUPO 2: TERCER CUATRIMESTRE', 12, 28, 6, NULL),
(249, 'MATERIAS CUATRIMESTRE 3 Y 4', 12, 28, 6, NULL),
(251, 'GRUPO 1: QUINTO CUATRIMESTRE', 12, 28, 1, NULL),
(252, 'MATERIAS CUATRIMESTRE 3, 5 Y 7', 12, 28, 2, NULL),
(253, 'MATERIAS CUATRIMESTRE 5 Y 7', 12, 28, 1, NULL),
(254, 'GRUPO 2: SEXTO CUATRIMESTRE', 12, 28, 1, NULL),
(255, 'GRUPO 3: TERCER CUATRIMESTRE ', 12, 28, 7, NULL),
(256, 'MATERIAS CUATRIMESTRE 3, 4 Y 6', 12, 28, 2, NULL),
(257, 'MATERIAS CUATRIMESTRE 8', 12, 28, 1, NULL),
(258, 'GRUPO 3: NOVEVENO CUATRIMESTRE', 12, 28, 1, NULL),
(259, 'MATERIAS CUATRIMESTRE 3', 12, 28, 7, NULL),
(260, 'MATERIAS CUATRIMESTRE 5 Y 6', 12, 28, 2, NULL),
(261, 'MATERIAS CUATRIMESTRE 7 Y 8', 12, 28, 1, NULL),
(262, 'MATERIAS CUATRIMESTRE 4, 5 Y 6', 12, 28, 2, NULL),
(265, 'MIM 1', 12, 28, 4, NULL),
(266, 'MITI 1', 12, NULL, 5, NULL),
(267, 'MITI 2', 12, NULL, 5, NULL),
(268, 'MATERIAS CUATRIMESTRE 4 Y 7', 12, 28, 1, NULL),
(271, 'MIM 2', 12, 28, 4, NULL),
(272, 'MIM 3', 12, 28, 4, NULL),
(273, 'MITI 3', 12, NULL, 5, NULL),
(274, 'MIM 4', 12, 28, 4, NULL),
(275, 'MITI 4', 12, NULL, 5, NULL),
(276, 'MIM 5', 12, 28, 4, NULL),
(277, 'MITI 5', 12, NULL, 5, NULL),
(278, 'GRUPO 1: SEXTO CUATRIMESTRE', 12, 28, 2, NULL),
(279, 'MATERIAS CUATRIMESTRE 3, 4 Y 6', 12, 28, 7, NULL),
(280, 'MATERIAS CUATRIMESTRE 8', 12, 28, 2, NULL),
(283, 'GRUPO 2: NOVENO CUATRIMESTRE ', 12, 28, 2, NULL),
(284, 'MATERIAS CUATRIMESTRE 4', 12, 28, 2, NULL),
(286, 'MATERIAS CUATRIMESTRE 4, 7 Y 8', 12, 28, 2, NULL),
(287, 'MATERIAS CUATRIMESTRE 6', 12, 28, 2, NULL),
(288, 'ESTANCIAS Y ESTADIAS', 12, 28, 2, NULL),
(289, 'MATERIAS CUATRIMESTRE 6', 12, 28, 2, NULL),
(292, 'MATERIAS CUATRIMESTRE 7', 12, 28, 2, NULL),
(294, 'MATERIAS CUATRIMESTRE 1, 2 Y 3', 12, 28, 1, NULL),
(295, 'MATERIAS CUATRIMESTRE 1 Y 4', 12, 28, 6, NULL),
(296, 'MATERIAS CUATRIMESTRE 4', 12, 28, 1, NULL),
(297, 'MATERIAS CUATRIMESTRE 2 Y 3', 12, 28, 6, NULL),
(299, 'MATERIAS CUATRIMESTRE 3', 12, 28, 6, NULL),
(300, 'MATERIAS CUATRIMESTRE 1 Y 3', 12, 28, 1, NULL),
(301, 'MATERIAS CUATRIMESTRE 2 Y 4', 12, 28, 1, NULL),
(302, 'MATERIAS CUATRIMESTRE 2', 12, NULL, 1, NULL),
(303, 'ESTANCIAS Y ESTADIAS', 12, 28, 1, NULL),
(304, 'MATERIAS CUATRIMESTRE 1 Y 2', 12, 28, 8, NULL),
(305, 'MATERIAS CUATRIMESTRE 5 Y 7', 12, 28, 8, NULL),
(306, 'GRUPO 2: SEXTO CUATRIMESTRE', 12, 28, 8, NULL),
(307, 'MATERIAS CUATRIMESTRE 8', 12, 28, 8, NULL),
(309, 'ESTANCIAS', 11, 28, 2, NULL),
(310, 'ITI 1-1', 13, 28, 7, NULL),
(311, 'ITI - 3', 13, NULL, 2, NULL),
(312, 'ITI 1-2', 13, 28, 7, NULL),
(314, 'ITI 1-3', 13, 28, 7, NULL),
(315, 'ITM 1-1', 13, 28, 8, NULL),
(316, 'PYMES 1-1', 13, 28, 10, NULL),
(319, 'ITI - 4', 13, 28, 2, NULL),
(320, 'ITI 3-1', 13, 28, 7, NULL),
(322, 'ITI - 6', 13, 28, 2, NULL),
(323, 'ITI 4-1', 13, 28, 7, NULL),
(324, 'ITI - 5', 13, 28, 2, NULL),
(325, 'ITI 4-2', 13, 28, 7, NULL),
(327, 'ITI 7-1', 13, 28, 2, NULL),
(328, 'ITI 9', 13, 28, 2, NULL),
(330, 'ITI 2 Materias', 13, 29, 7, NULL),
(331, 'ITI 3 Materias', 13, 29, 7, NULL),
(332, 'ITI 5 ', 13, 29, 2, NULL),
(333, 'ITI 6', 13, 29, 2, NULL),
(334, 'ITI 7', 13, 29, 2, NULL),
(335, 'ITI 8', 13, 29, 2, NULL),
(337, 'ITI 1 ED', 13, 28, 7, NULL),
(338, 'IM 1-1', 13, 28, 6, NULL),
(339, 'IM 1-2', 13, 28, 6, NULL),
(340, 'IM 1-3', 13, 28, 6, NULL),
(341, 'C-1', 13, 28, 9, NULL),
(342, 'PYMES-VICTORIA', 13, 28, 10, NULL),
(343, 'IM-Materias 1 y 2', 13, 28, 6, NULL),
(344, 'ITM 4-1', 13, 28, 8, NULL),
(345, 'ITM 7-1', 13, 28, 8, NULL),
(347, 'IM 3-1', 13, 28, 6, NULL),
(348, 'IM 4-1', 13, 28, 6, NULL),
(349, 'IM 4-2', 13, 28, 6, NULL),
(351, 'IM Materias 5', 13, 28, 1, NULL),
(352, 'IM 6-1', 13, 28, 1, NULL),
(354, 'IM 7-1', 13, 28, 1, NULL),
(355, 'IM Materias 7', 13, 28, 1, NULL),
(356, 'IM 8-1', 13, 28, 1, NULL),
(357, 'IM 9-1', 13, 28, 1, NULL),
(359, 'IM Materias 3', 13, NULL, 6, NULL),
(360, 'ITM Materias 3', 13, NULL, 8, NULL),
(361, 'IM 10-1', 13, 28, 1, NULL),
(362, 'ITI 10-1', 13, 28, 2, NULL),
(363, 'MIM-1', 13, 28, 4, NULL),
(364, 'MITI-1', 13, 28, 5, NULL),
(365, 'Materias 3', 13, NULL, 10, NULL),
(366, 'GRUPO ITI-1', 14, 28, 7, NULL),
(368, 'GRUPO IM-1', 14, 28, 6, NULL),
(369, 'ITM 1-1', 14, 28, 8, NULL),
(371, 'PYMES 1-1', 14, 28, 10, NULL),
(372, 'ITI 2-1', 14, 28, 7, NULL),
(373, 'ITI 2-2', 14, 28, 7, NULL),
(374, 'ITI 2-3', 14, 28, 7, NULL),
(375, 'MATERIAS ITI 4', 14, 28, 7, NULL),
(376, 'MATERIAS IM 4', 14, 28, 6, NULL),
(377, 'MATERIAS ITM 4', 14, 28, 8, NULL),
(378, 'ITI 4-1', 14, 28, 7, NULL),
(379, 'IM 4-1', 14, 28, 6, NULL),
(380, 'MATERIAS ITI 3', 14, 28, 7, NULL),
(381, 'MATERIAS ITI 6', 14, 28, 2, NULL),
(382, 'ITI 5-1', 14, 28, 7, NULL),
(383, 'MATERIAS ITI 7', 14, 28, 2, NULL),
(384, 'ITI 5-2', 14, 28, 7, NULL),
(386, 'ITI 8-1', 14, 28, 2, NULL),
(387, 'ITM 2-1', 14, 28, 8, NULL),
(389, 'ITM 5-1', 14, 28, 8, NULL),
(393, 'IM 8-1', 14, 28, 1, NULL),
(394, 'MIM-121', 14, 28, 4, NULL),
(395, 'MITI-121', 14, NULL, 5, NULL),
(396, 'ITI 1-1', 14, 28, 7, NULL),
(397, 'MATERIAS IM 1', 14, 28, 6, NULL),
(398, 'ITM 8-1', 14, 28, 8, NULL),
(399, 'MATERIAS ITI 8', 14, 28, 2, NULL),
(400, 'MATERIAS ITI 9', 14, 28, 2, NULL),
(401, 'IM 9-1', 14, 28, 1, NULL),
(402, 'MATERIAS IM 7', 14, 28, 1, NULL),
(403, 'MATERIAS IM 5', 14, 28, 1, NULL),
(404, 'IM 2-1', 14, 28, 6, NULL),
(405, 'IM 5-1', 14, 28, 6, NULL),
(406, 'GRUPO IM 2-2', 14, 28, 6, NULL),
(407, 'MATERIAS IM 2', 14, 28, 6, NULL),
(408, 'MATERIAS ITI 2', 14, 28, 7, NULL),
(409, 'MATERIAS ITM 2', 14, 28, 8, NULL),
(410, 'GRUPO IM 2-3', 14, 28, 6, NULL),
(411, 'IM 5-2', 14, 28, 6, NULL),
(412, 'IM 7-1', 14, 28, 1, NULL),
(413, 'PYMES 2-1', 14, 28, 10, NULL),
(414, 'ITI -UPVAD', 14, 28, 7, NULL),
(415, 'MATERIAS 3-1', 14, 28, 6, NULL),
(416, 'MATERIAS IM 8', 14, 28, 1, NULL),
(417, 'MATERIAS IM 9', 14, 28, 1, NULL),
(418, 'IM ESTANCIAS Y ESTADIA', 14, 28, 1, NULL),
(419, 'MATERIAS IM 7', 14, 28, 6, NULL),
(420, 'IM ESTANCIAS Y ESTADIA', 14, 28, 6, NULL),
(421, 'MATERIAS ITI 3', 14, 28, 2, NULL),
(422, 'MATERIAS ITI 6', 14, 28, 7, NULL),
(424, 'ITI 2-1', 15, 28, 7, NULL),
(427, 'ITI 2-1 MATERIAS', 15, 28, 7, NULL),
(428, 'ITI 3-1', 15, 28, 7, NULL),
(429, 'ITI 6-1 MATERIAS', 15, 28, 2, NULL),
(430, 'ITI 3-2', 15, 28, 7, NULL),
(431, 'ITI 3-3', 15, 28, 7, NULL),
(432, 'ITI 5-1', 15, 28, 7, NULL),
(433, 'ITI 6-1', 15, 28, 7, NULL),
(434, 'ITI 6-2', 15, 28, 7, NULL),
(435, 'MIM 1-1', 15, 29, 4, NULL),
(436, 'MITI 1-1', 15, 28, 5, NULL),
(438, 'ITI 9-1', 15, 28, 2, NULL),
(439, 'MIM OPTATIVAS', 15, 28, 4, NULL),
(440, 'MITI OPTATIVAS', 15, 28, 5, NULL),
(442, 'MITI SEMINARIOS', 15, NULL, 5, NULL),
(443, 'MIM SEMINARIOS', 15, 28, 4, NULL),
(444, 'IM MATERIAS SEGUNDO', 15, 28, 6, NULL),
(445, 'MIXTOS', 15, 28, 2, NULL),
(446, 'MIXTOS', 15, 28, 8, NULL),
(447, 'MIXTOS', 15, 28, 7, NULL),
(448, 'IM 2-1', 15, 28, 6, NULL),
(449, 'IM MATERIAS 9', 15, NULL, 1, NULL),
(450, 'ITI 4-1 MATERIAS', 15, 28, 7, NULL),
(451, 'IM 3-1', 15, 28, 6, NULL),
(452, 'ITI 5-1 MATERIAS', 15, 28, 2, NULL),
(453, 'ITI 7-1 MATERIAS', 15, 28, 2, NULL),
(454, 'MIXTOS', 15, NULL, 1, NULL),
(455, 'IM 3-2', 15, 28, 6, NULL),
(456, 'ITI 8-1 MATERIAS', 15, 28, 2, NULL),
(457, 'IM MATERIAS PRIMERO', 15, 28, 6, NULL),
(458, 'MIXTOS', 15, NULL, 10, NULL),
(459, 'IM 5-1', 15, 28, 6, NULL),
(460, 'ITI 2-1 MATERIAS', 15, 28, 2, NULL),
(461, 'ITI 3-1 MATERIAS', 15, 28, 2, NULL),
(462, 'ITI 4-1 MATERIAS', 15, 28, 2, NULL),
(463, 'ITM MATERIAS 5', 15, NULL, 8, NULL),
(464, 'IM 6-1', 15, 28, 6, NULL),
(465, 'IM 6-2', 15, 28, 6, NULL),
(466, 'IM 7-1', 15, 28, 1, NULL),
(467, 'PYM 3-1D', 15, 28, 10, NULL),
(468, 'IM 8-1', 15, 28, 1, NULL),
(470, 'ITI 3 UPV@D', 15, 28, 7, NULL),
(471, 'IM 9-1', 15, 28, 1, NULL),
(473, 'IM INGLES', 15, 28, 6, NULL),
(474, 'ITM 3-1', 15, 28, 8, NULL),
(475, 'ITM 6-1', 15, 28, 8, NULL),
(476, 'ITM 9-1', 15, 28, 8, NULL),
(477, 'IM 4-1 MATERIAS', 15, 28, 6, NULL),
(478, 'IM10-1', 15, 28, 1, NULL),
(479, 'IM 10-1', 15, 28, 2, NULL),
(480, 'IM MATERIAS 3', 15, 28, 1, NULL),
(481, 'IM MATERIAS 5', 15, 28, 1, NULL),
(482, 'IM MATERIAS 6', 15, 28, 1, NULL),
(483, '', 15, NULL, 1, NULL),
(485, 'ITI 1-1', 16, 28, 7, NULL),
(486, 'ITI 1-2', 16, 28, 7, NULL),
(487, 'ITI 1-3', 16, 28, 7, NULL),
(488, 'ITI 3-1', 16, 28, 7, NULL),
(489, 'IM 3 MATERIAS', 16, 28, 6, NULL),
(490, 'ITI 4-1', 16, 28, 7, NULL),
(491, 'ITI 4-2', 16, 28, 7, NULL),
(492, 'ITI 4-3', 16, 28, 7, NULL),
(494, 'ITI 4-1 ED', 16, 28, 7, NULL),
(495, 'ITI 6-1', 16, 28, 7, NULL),
(496, 'ITI 7-1', 16, 28, 7, NULL),
(497, 'ITI 5 MATERIAS', 16, 28, 2, NULL),
(498, 'ITI 7-2', 16, 28, 7, NULL),
(499, 'IM 1-1', 16, 28, 6, NULL),
(501, 'IM 1-3', 16, 28, 6, NULL),
(502, 'IM 3-1', 16, 28, 6, NULL),
(503, 'PYMES-1-1', 16, 28, 10, NULL),
(504, 'IM 4-1', 16, 28, 6, NULL),
(505, 'IM 4-2', 16, 28, 6, NULL),
(506, 'PYMES-1-2', 16, 28, 10, NULL),
(507, 'PYMES-1-3D-ITI-JAUMAVE', 16, 28, 10, NULL),
(508, 'PYMES-4-1-MIXTO-VICTORIA-BURGOS-GONZÁLEZ', 16, 28, 10, NULL),
(509, 'IM 6-1', 16, 28, 6, NULL),
(510, 'IM 7-1', 16, 28, 6, NULL),
(511, 'IM 7-2', 16, 29, 6, NULL),
(512, 'ITI 8 ', 16, 29, 2, NULL),
(513, 'CERO ITI', 16, 28, 9, NULL),
(514, 'CERO IM', 16, 28, 9, NULL),
(515, 'ITI 1 ED', 16, 28, 7, NULL),
(516, 'ITM 1-1', 16, 28, 8, NULL),
(517, 'ITM 1-2', 16, 28, 8, NULL),
(518, 'ITM 4-1', 16, 28, 8, NULL),
(519, 'ITM 4to materias', 16, 28, 8, NULL),
(520, 'ITM 7-1', 16, 28, 8, NULL),
(521, 'ITM 9no', 16, 28, 8, NULL),
(523, 'IM 8-1', 16, 28, 1, NULL),
(524, 'IM 7 MATERIAS', 16, 28, 1, NULL),
(525, 'ITI 9 MATERIAS', 16, 28, 2, NULL),
(526, 'ITI 9o', 16, 28, 2, NULL),
(527, 'IM 9 MATERIAS', 16, 28, 1, NULL),
(528, 'IM 5-1', 16, 28, 6, NULL),
(529, 'MI-M', 16, 28, 4, NULL),
(530, 'MI-TI', 16, 28, 5, NULL),
(531, 'PYMES MATERIAS', 16, 28, 10, NULL),
(532, 'ITI-MATERIAS', 16, 28, 7, NULL),
(533, 'IM 10-1', 16, 28, 1, NULL),
(534, 'ITI 10-1', 16, 28, 2, NULL),
(535, 'ITM 10-1', 16, 28, 8, NULL),
(536, 'ITM 3ero', 16, 28, 8, NULL),
(537, 'ITM 2-1', 17, 28, 8, NULL),
(538, 'ITM 2-2', 17, 28, 8, NULL),
(539, 'ITM 5-1', 17, 28, 8, NULL),
(540, 'ITM 8-1', 17, 29, 8, NULL),
(541, 'ITM 8 Materias', 17, 28, 8, NULL),
(542, 'PY 2-1', 17, 28, 10, NULL),
(543, 'PY 2-2', 17, 28, 10, NULL),
(544, 'PY @2-3', 17, 28, 10, NULL),
(545, 'PY 5-1', 17, 28, 10, NULL),
(546, 'PY @ 5 - 2', 17, 28, 10, NULL),
(547, 'ITI 1-1', 17, 28, 7, NULL),
(548, 'ITI 2-1 SIN INGLÉS', 17, 28, 7, NULL),
(549, 'ITI 2-2', 17, 28, 7, NULL),
(550, 'ITI 2-3', 17, 28, 7, NULL),
(551, 'ITI @D 2-4', 17, 28, 7, NULL),
(552, 'ITI 4-1', 17, 28, 7, NULL),
(553, 'ITI 5-1 SIN INGLÉS', 17, 28, 7, NULL),
(554, 'ITI 5-2', 17, 28, 7, NULL),
(555, 'ITI 5-3', 17, 28, 7, NULL),
(556, 'ITI @D 5-4', 17, 28, 7, NULL),
(557, 'ITI 7-1', 17, 28, 7, NULL),
(558, 'ITI 8-1', 17, 28, 7, NULL),
(559, 'ITI 8 MATERIAS', 17, 28, 7, NULL),
(561, 'ITI 9-1', 17, 28, 2, NULL),
(562, 'ITI 2007 MATERIAS', 17, 28, 2, NULL),
(563, 'IM 1-1', 17, 28, 6, NULL),
(564, 'IM 2-1 SIN INGLÉS', 17, 28, 6, NULL),
(565, 'IM2-2', 17, 28, 6, NULL),
(566, 'IM 2-3', 17, 28, 6, NULL),
(567, 'IM 4-1', 17, 28, 6, NULL),
(568, 'IM 5-1', 17, 28, 6, NULL),
(569, 'IM 5-2', 17, 28, 6, NULL),
(570, 'IM 7-1', 17, 28, 6, NULL),
(571, 'IM 8-1', 17, 28, 6, NULL),
(572, 'IM 8-2', 17, 28, 6, NULL),
(573, 'IM 9-1', 17, 28, 1, NULL),
(574, 'IM 2010 MATERIAS', 17, 28, 6, NULL),
(575, 'IM 2007 MATERIAS', 17, 28, 1, NULL),
(576, 'IM 3 MATERIAS', 17, 28, 6, NULL),
(577, 'POSGRADO MEC', 17, 29, 4, NULL),
(578, 'POSGRADO TEC INF', 17, NULL, 5, NULL),
(579, 'SVAM', 17, 29, 16, NULL),
(580, 'MIM-132', 18, 28, 4, NULL),
(581, 'MTII-132', 18, 28, 5, NULL),
(582, 'PROP-MI', 18, 29, 17, NULL),
(583, 'PYMES 3-1', 18, 28, 10, NULL),
(584, 'PYMES 3 - 2', 18, 28, 10, NULL),
(585, 'PYMES 3-3 UPV@D', 18, 28, 10, NULL),
(586, 'PYMES 6-1 UPV@D', 18, 28, 10, NULL),
(587, 'ITM 3-1', 18, 28, 8, NULL),
(588, 'ITM 3-2', 18, 28, 8, NULL),
(589, 'ITM 6-1', 18, 28, 8, NULL),
(590, 'ITM 9-1', 18, 28, 8, NULL),
(591, 'ITM 10-1', 18, 28, 8, NULL),
(592, 'ITM 4 Materias', 18, 28, 8, NULL),
(593, 'ITM 7 Materias', 18, 28, 8, NULL),
(594, 'ITI 2-1', 18, 29, 7, NULL),
(595, 'ITI 3-1 NO INGLÉS', 18, 28, 7, NULL),
(596, 'ITI 3-2', 18, 28, 7, NULL),
(597, 'ITI 3-3', 18, 28, 7, NULL),
(598, 'ITI 3-4 UPV@D', 18, 28, 7, NULL),
(599, 'ITI 5-1', 18, 28, 7, NULL),
(600, 'ITI 6-1 NO INGLÉS', 18, 28, 7, NULL),
(601, 'ITI 6-2', 18, 28, 7, NULL),
(602, 'ITI 6-3', 18, 28, 7, NULL),
(603, 'ITI 8-1', 18, 28, 7, NULL),
(604, 'ITI 9-1', 18, 28, 7, NULL),
(605, 'ITI MATERIAS', 18, 28, 2, NULL),
(606, 'ITI 10-1', 18, 28, 7, NULL),
(607, 'ITI 4 MATERIAS', 18, 28, 7, NULL),
(608, 'ITI 7 MATERIAS', 18, 28, 7, NULL),
(609, 'ITI 6-4 UPV@D', 18, 28, 7, NULL),
(610, 'IM 2-1', 18, 28, 6, NULL),
(611, 'IM 3-1 NO INGLÉS', 18, 28, 6, NULL),
(612, 'IM 3-2', 18, 28, 6, NULL),
(613, 'IM 3-3', 18, 28, 6, NULL),
(614, 'IM 5-1', 18, 28, 6, NULL),
(615, 'IM 6-1', 18, 28, 6, NULL),
(616, 'IM 6-2', 18, 28, 6, NULL),
(617, 'IM 8-1', 18, 28, 6, NULL),
(618, 'IM 9-1', 18, 28, 6, NULL),
(619, 'IM 9-1', 18, 28, 1, NULL),
(620, 'IM MATERIAS INGLÉS', 18, 28, 6, NULL),
(621, 'IM MATERIAS', 18, 28, 6, NULL),
(622, 'ITI MATERIAS INGLÉS', 18, 28, 7, NULL),
(623, 'ITI CIENCIAS BÁSICAS', 18, 28, 7, NULL),
(624, 'IM CIENCIAS BÁSICAS', 18, 28, 6, NULL),
(625, 'IM DH', 18, 28, 6, NULL),
(626, 'ITI DH', 18, 28, 7, NULL),
(627, 'ITI DIVERSAS', 18, 28, 7, NULL),
(628, 'IM DIVERSAS', 18, 28, 6, NULL),
(629, 'ITI INGLÉS', 18, 28, 2, NULL),
(630, 'ITI 8 MATERIAS', 18, 28, 2, NULL),
(631, 'ITI 9 MATERIAS', 18, 28, 2, NULL),
(632, 'ITI 7 MATERIAS', 18, 28, 2, NULL),
(633, 'ITI 5 MATERIAS', 18, 28, 2, NULL),
(634, 'ITI 6 MATERIAS', 18, 28, 2, NULL),
(635, 'IM 6 MATERIAS', 18, 28, 1, NULL),
(636, 'IM 8 MATERIAS', 18, 28, 1, NULL),
(637, 'IM 9 MATERIAS', 18, 28, 1, NULL),
(638, 'PYMES INGLÉS', 18, 28, 10, NULL),
(639, 'INGLÉS', 18, 28, 1, NULL),
(640, 'INGLÉS', 18, NULL, 6, NULL),
(641, 'MATERIAS', 18, 28, 10, NULL),
(642, 'MIM-01', 19, 28, 4, NULL),
(643, 'MITI-01', 19, 28, 5, NULL),
(644, 'MIM-02', 19, 28, 4, NULL),
(645, 'MITI-02', 19, 28, 5, NULL),
(646, 'MIM-03', 19, 28, 4, NULL),
(647, 'MITI-03', 19, 28, 5, NULL),
(648, 'PyMES 1-1', 19, 28, 10, NULL),
(649, 'PyMES 1-2', 19, 28, 10, NULL),
(650, 'ITM 1 - 1', 19, 28, 8, NULL),
(651, 'ITM 1 - 2', 19, 28, 8, NULL),
(652, 'ITI 1-2', 19, 28, 7, NULL),
(653, 'ITI 1-1 SIN INGLÉS', 19, 28, 7, NULL),
(654, 'ITI 1-3 UPV@D', 19, 28, 7, NULL),
(655, 'ITI 1-4', 19, 29, 7, NULL),
(656, 'ITI 3-1', 19, 29, 7, NULL),
(657, 'ITI 4-1', 19, 28, 7, NULL),
(658, 'ITI 4-2', 19, 28, 7, NULL),
(659, 'ITI 4-3 UPV@D', 19, 28, 7, NULL),
(660, 'ITI 4-4', 19, 29, 7, NULL),
(661, 'ITI 6-1', 19, 29, 7, NULL),
(664, 'ITI 7-1', 19, 28, 7, NULL),
(666, 'ITI 7-2 UPV@D', 19, 28, 7, NULL),
(667, 'ITI 7-3', 19, 29, 7, NULL),
(668, 'ITI 9-1', 19, 29, 7, NULL),
(669, 'PyMES 1-3', 19, 29, 10, NULL),
(670, 'ITI 5 Materias', 19, 28, 2, NULL),
(671, 'ITI 6 Materias', 19, 28, 2, NULL),
(672, 'ITI 7 Materias', 19, 28, 2, NULL),
(673, 'ITI 8 Materias', 19, 28, 2, NULL),
(674, 'ITI 9 Materias ', 19, 28, 2, NULL),
(675, 'ITM 4 - 1', 19, 28, 8, NULL),
(676, 'ITI Inglés compartidos', 19, 28, 7, NULL),
(677, 'PyMES 1-4 (D)', 19, 28, 10, NULL),
(678, 'ITM 4 - 2', 19, 28, 8, NULL),
(679, 'PyMES 4-1', 19, 28, 10, NULL),
(680, 'ITM 7 - 1', 19, 28, 8, NULL),
(682, 'PyMES 4-2', 19, 29, 10, NULL),
(683, 'ITM MATERIAS 8-9', 19, 28, 8, NULL),
(684, 'PyMES 4-3 (D)', 19, 28, 10, NULL),
(685, 'PyMES 7-1', 19, 29, 10, NULL),
(686, 'PyMES 7-2 (D)', 19, 28, 10, NULL),
(692, 'PyMES - 0', 19, 29, 9, NULL),
(693, 'IM 4-3', 19, 28, 6, NULL),
(694, 'IM 0', 19, 28, 9, NULL),
(695, 'ITI 0', 19, 28, 9, NULL),
(696, 'IM 1-1 SIN INGLÉS', 19, 28, 6, NULL),
(697, 'IM 1-2', 19, 28, 6, NULL),
(698, 'IM 1-3', 19, 28, 6, NULL),
(699, 'IM 1-4', 19, 28, 6, NULL),
(700, 'IM 3-1', 19, 28, 6, NULL),
(701, 'IM 4-1', 19, 28, 6, NULL),
(702, 'IM 4-2', 19, 28, 6, NULL),
(703, 'IM 6-1', 19, 28, 6, NULL),
(704, 'IM 7-1', 19, 28, 6, NULL),
(705, 'IM 7-2', 19, 28, 6, NULL),
(706, 'IM 9-1', 19, 28, 6, NULL),
(707, 'ITI 10', 19, 28, 7, NULL),
(708, 'ITI 10 Materia', 19, 28, 2, NULL),
(709, 'Inglés Compartidos', 19, 28, 2, NULL),
(711, 'IM 1-10', 19, 28, 6, NULL),
(712, 'MEC MATERIAS 8', 19, 28, 6, NULL),
(713, 'IM 7mo.', 19, 28, 1, NULL),
(714, 'IM 8vo.', 19, 28, 1, NULL),
(715, 'IM 9no.', 19, 28, 1, NULL),
(716, 'IM 10mo.', 19, 28, 1, NULL),
(717, 'Inglés Extras', 19, 28, 6, NULL),
(720, 'INGLÉS COMPARTIDOS', 19, NULL, 10, NULL),
(722, 'RECURSAMIENTOS', 19, 29, 10, NULL),
(723, 'ITI 1-1', 20, 28, 7, NULL),
(724, 'ITI 2-1 SIN INGLÉS', 20, 28, 7, NULL),
(725, 'ITI 2-2', 20, 28, 7, NULL),
(726, 'ITI 2-3', 20, 29, 7, NULL),
(727, 'ITI 2-4 UPV@D', 20, 28, 7, NULL),
(728, 'ITI 4-1', 20, 29, 7, NULL),
(729, 'ITI 5-1 SIN INGLÉS', 20, 28, 7, NULL),
(730, 'ITI 5-2', 20, 28, 7, NULL),
(731, 'ITI 5-3', 20, 28, 7, NULL),
(732, 'ITI 5-4 UPV@D', 20, 28, 7, NULL),
(733, 'ITI 7-1', 20, 28, 7, NULL),
(734, 'ITI 8-1', 20, 28, 7, NULL),
(735, 'ITI 8-2', 20, 28, 7, NULL),
(736, 'ITI 8-3 UPV@D', 20, 28, 7, NULL),
(737, 'ITI 7 MATERIAS', 20, 28, 2, NULL),
(738, 'ITI 8 MATERIAS', 20, 28, 2, NULL),
(739, 'ITI 9 MATERIAS', 20, 28, 2, NULL),
(740, 'ITI 10-1', 20, 28, 7, NULL),
(741, 'ITI 10', 20, 28, 2, NULL),
(743, 'ITI INGLÉS COMPARTIDO', 20, 28, 7, NULL),
(744, 'ITI INGLÉS COMPARTIDO', 20, 28, 2, NULL),
(745, 'IM 1-1', 20, 28, 6, NULL),
(746, 'IM 2-1 SIN INGLÉS', 20, 28, 6, NULL),
(747, 'IM 2-2', 20, 28, 6, NULL),
(748, 'IM 2-3', 20, 28, 6, NULL),
(749, 'IM 2-4', 20, 28, 6, NULL),
(750, 'IM 4-1', 20, 28, 6, NULL),
(751, 'IM 5-1', 20, 28, 6, NULL),
(752, 'IM 5-2', 20, 28, 6, NULL),
(753, 'IM 7-1', 20, 28, 6, NULL),
(754, 'IM 8-1', 20, 28, 6, NULL),
(755, 'IM 8-2', 20, 28, 6, NULL),
(756, 'IM 9 MATERIAS ', 20, 28, 6, NULL),
(757, 'PYMES 1-1', 20, 29, 10, NULL),
(759, 'PYMES 2-1', 20, 28, 10, NULL),
(761, 'PYMES 2-2', 20, 28, 10, NULL),
(763, 'PYMES 2-3', 20, 29, 10, NULL),
(764, 'PYMES 2-4 UPV@D', 20, 28, 10, NULL),
(766, 'PYMES 5-1', 20, 28, 10, NULL),
(767, 'PYMES 5-2', 20, 29, 10, NULL),
(769, 'PYMES 5-3 UPV@D', 20, 28, 10, NULL),
(770, 'PYMES 8-1', 20, 29, 10, NULL),
(771, 'PYMES 8-2 UPV@D', 20, 28, 10, NULL),
(772, 'MATERIAS 7-8-9', 20, 28, 1, NULL),
(773, 'IM 10', 20, 28, 6, NULL),
(774, 'ITM 2-1', 20, 28, 8, NULL),
(775, 'ITM 2-2', 20, 28, 8, NULL),
(776, 'ITM 5-1', 20, 28, 8, NULL),
(777, 'ITM 5-2', 20, 28, 8, NULL),
(778, 'ITM 8-1', 20, 28, 8, NULL),
(779, 'ITM Materias', 20, 28, 8, NULL),
(780, 'MIM-01', 20, 28, 4, NULL),
(781, 'MITI-01', 20, 28, 5, NULL),
(782, 'MIM-02', 20, 28, 4, NULL),
(783, 'MIM-03', 20, 28, 4, NULL),
(784, 'MITI-02', 20, 28, 5, NULL),
(785, 'MITI-03', 20, 28, 5, NULL),
(786, 'IM 5-MATERIAS', 20, 28, 6, NULL),
(788, 'IDIOMA FRANCÉS', 20, 28, 18, NULL),
(789, 'MATERIAS DE INGLÉS', 20, 28, 6, NULL),
(790, 'GRUPOS DE INGLÉS PARA ADELANTAR', 20, 28, 10, NULL),
(791, 'REC ULT UNIDAD', 20, 28, 6, NULL),
(801, 'RECURSAMIENTOS DE MATERIAS', 20, 28, 10, NULL),
(802, 'RECURSAMIENTOS DE LA ÚLTIMA UNIDAD', 20, 28, 10, NULL),
(807, 'Recursamiento U. Unidad', 20, 28, 7, NULL),
(808, 'ITM 3-1 ', 21, 28, 8, NULL),
(810, 'ITM 3-2', 21, 28, 8, NULL),
(815, 'ITM 6-1', 21, 28, 8, NULL),
(816, 'ITM 6-2', 21, 28, 8, NULL),
(818, 'ITM 9-1', 21, 29, 8, NULL),
(828, 'ITI 8 MATERIAS', 21, 29, 2, NULL),
(829, 'ITI 9 MATERIAS', 21, 28, 2, NULL),
(833, 'ITI 10 MATERIAS', 21, 28, 2, NULL),
(836, 'ITI 7 MATERIAS', 21, 28, 2, NULL),
(837, 'ITI INGLÉS COMPARTIDOS', 21, 28, 2, NULL),
(838, 'ITI 2-1', 21, 29, 7, NULL),
(839, 'ITI 3-1', 21, 28, 7, NULL),
(840, 'ITI 3-2', 21, 28, 7, NULL),
(841, 'ITI 3-3', 21, 29, 7, NULL),
(842, 'ITI 3-4 UPV@D', 21, 28, 7, NULL),
(843, 'ITI 5-1', 21, 29, 7, NULL),
(844, 'ITI 6-1', 21, 28, 7, NULL),
(845, 'ITI 6-2', 21, 28, 7, NULL),
(846, 'ITI 6-3 UPV@D', 21, 28, 7, NULL),
(847, 'ITI 8-1', 21, 29, 7, NULL),
(848, 'ITI 9-1', 21, 28, 7, NULL),
(849, 'ITI 9-2', 21, 29, 7, NULL),
(850, 'ITI 9-3 UPV@D', 21, 28, 7, NULL),
(851, 'ITI 10-1', 21, 28, 7, NULL),
(852, 'ITI 4 MATERIAS', 21, 28, 7, NULL),
(853, 'ITI 7 MATERIAS', 21, 28, 7, NULL),
(854, 'ITI INGLÉS COMPARTIDOS', 21, 28, 7, NULL),
(855, 'ITI ÚLTIMA UNIDAD', 21, 28, 7, NULL),
(856, 'MEC 2-1', 21, 29, 6, NULL),
(857, 'MEC 3-1 SIN INGLÉS', 21, 28, 6, NULL),
(858, 'MEC 3-2', 21, 28, 6, NULL),
(859, 'MEC 3-3', 21, 28, 6, NULL),
(860, 'MEC 5-1', 21, 28, 6, NULL),
(861, 'MEC 6-1', 21, 28, 6, NULL),
(862, 'MEC 6-2', 21, 29, 6, NULL),
(863, 'MEC 8-1', 21, 29, 6, NULL),
(864, 'MEC 9-1', 21, 28, 6, NULL),
(865, 'MEC 9-2', 21, 28, 6, NULL),
(867, 'MEC ESTANCIAS Y ESTADÍAS', 21, 28, 6, NULL),
(871, 'MEC MATERIAS INGLÉS', 21, 28, 6, NULL),
(872, 'MEC ÚLTIMA UNIDAD', 21, 28, 6, NULL),
(873, 'MEC 8-1', 21, 28, 1, NULL),
(874, 'MEC 9-1', 21, 28, 1, NULL),
(875, 'MEC ESTADÍA', 21, 28, 1, NULL),
(876, 'PYMES 2-1', 21, 29, 10, NULL),
(877, 'PYMES 6-3 UPV@D', 21, 28, 10, NULL),
(878, 'PYMES 9-2 UPV@D', 21, 28, 10, NULL),
(879, 'MEC MATERIAS', 21, 28, 6, NULL),
(881, 'PYMES 3-1', 21, 28, 10, NULL),
(882, 'PYMES 3-2', 21, 28, 10, NULL),
(883, 'PYMES 3-3', 21, 29, 10, NULL),
(884, 'PYMES 3-4 UPV@D', 21, 28, 10, NULL),
(885, 'PYMES 6-1', 21, 28, 10, NULL),
(886, 'PYMES 6-2', 21, 29, 10, NULL),
(887, 'PYMES 9-1', 21, 29, 10, NULL),
(889, 'MIM', 21, 28, 4, NULL),
(890, 'MITI', 21, 28, 5, NULL),
(892, 'ITM MATERIAS INGLES', 21, 28, 8, NULL),
(893, 'PYMES MATERIAS INGLES', 21, 28, 10, NULL),
(894, 'INGLÉS', 21, 28, 6, NULL),
(895, 'INGLÉS', 21, NULL, 7, NULL),
(896, 'INGLÉS', 21, NULL, 8, NULL),
(897, 'INGLÉS', 21, NULL, 10, NULL),
(899, 'RECURSAMIENTO', 21, 28, 10, NULL),
(902, 'MIM', 22, 28, 4, NULL),
(903, 'MIITI', 22, 28, 5, NULL),
(904, 'Pymes 1-1', 22, 28, 10, NULL),
(905, 'Pymes 1-2', 22, 28, 10, NULL),
(906, 'Pymes 1-3', 22, 29, 10, NULL),
(907, 'Pymes 1-4', 22, 29, 10, NULL),
(908, 'Pymes 1-5 UPV@D', 22, 28, 10, NULL),
(909, 'Pymes 3-1', 22, 28, 10, NULL),
(910, 'Pymes 4-1', 22, 28, 10, NULL),
(911, 'Pymes 4-2', 22, 28, 10, NULL),
(912, 'Pymes 4-3', 22, 29, 10, NULL),
(913, 'Pymes 4-4 UPV@D', 22, 28, 10, NULL),
(914, 'Pymes 7-1', 22, 28, 10, NULL),
(915, 'Pymes 7-2', 22, 29, 10, NULL),
(916, 'Pymes 7-3 UPV@D', 22, 28, 10, NULL),
(918, 'ITM 1-1  ', 22, 28, 8, NULL),
(919, 'ITI 1-1', 22, 28, 7, NULL),
(920, 'ITI 1-2', 22, 28, 7, NULL),
(922, 'ITI 1-3 ', 22, 28, 7, NULL),
(923, 'ITI 1-4 UPV@d', 22, 28, 7, NULL),
(924, 'ITI 3-1', 22, 29, 7, NULL),
(925, 'IM 3-1', 22, 29, 6, NULL),
(926, 'ITI 4-1', 22, 28, 7, NULL),
(927, 'ITI 4-2 SIN INGLÉS', 22, 28, 7, NULL),
(928, 'ITI 4-3', 22, 29, 7, NULL),
(929, 'ITI 4-4 UPV@d', 22, 28, 7, NULL),
(930, 'ITI 6-1', 22, 28, 7, NULL),
(931, 'ITM 1-2 ', 22, 28, 8, NULL),
(933, 'ITI 7-1', 22, 28, 7, NULL),
(934, 'ITI 7-2', 22, 29, 7, NULL),
(935, 'ITI 7-3 UPV@D', 22, 28, 7, NULL),
(936, 'ITI 9-1', 22, 28, 7, NULL),
(937, 'ITI 9 MATERIAS', 22, 28, 7, NULL),
(938, 'ITI 10-1', 22, 28, 7, NULL),
(939, 'ITI INGLES COMPARTIDOS', 22, 28, 7, NULL),
(940, 'ITI 10-1', 22, 28, 2, NULL),
(941, 'ITI 9 MATERIAS', 22, 28, 2, NULL),
(942, 'ITI 8 MATERIAS', 22, 28, 2, NULL),
(943, 'ISA 1-1 ', 22, 28, 19, NULL),
(944, 'ISA 1-2 ', 22, 28, 19, NULL),
(945, 'ISA 1-3', 22, 28, 19, NULL),
(946, 'IM 1-1 ', 22, 28, 6, NULL),
(947, 'IM 1-2', 22, 28, 6, NULL),
(949, 'ITM 1-3 ', 22, 29, 8, NULL),
(950, 'ITM 4-1 ', 22, 28, 8, NULL),
(951, 'ITM 4-2 ', 22, 28, 8, NULL),
(952, 'ITM 7-1 ', 22, 29, 8, NULL),
(953, 'ITM 7-2 ', 22, 29, 8, NULL),
(954, 'ITM 10 ', 22, 29, 8, NULL),
(955, 'ITI NIVELACIÓN', 22, 28, 9, NULL),
(956, 'IM NIVELACIÓN', 22, 28, 9, NULL),
(957, 'ITM NIVELACIÓN', 22, 28, 9, NULL),
(958, 'IM 1-3', 22, 28, 6, NULL),
(959, 'IM 4-1 ', 22, 28, 6, NULL),
(960, 'IM 4-2', 22, 28, 6, NULL),
(961, 'IM 2 MATERIAS', 22, 28, 6, NULL),
(962, 'IM 4-3', 22, 28, 6, NULL),
(963, 'IM 6-1', 22, 28, 6, NULL),
(964, 'IM 7-1', 22, 28, 6, NULL),
(965, 'IM 7-2', 22, 28, 6, NULL),
(966, 'IM 9-1', 22, 28, 6, NULL),
(967, 'IM 10-1', 22, 28, 6, NULL),
(968, 'IM 10-1', 22, 28, 1, NULL),
(970, 'PYMES NIVELACIÓN', 22, 28, 9, NULL),
(971, 'Pymes -10', 22, 28, 10, NULL),
(972, 'VARIAS', 22, 28, 8, NULL),
(973, 'REC ULTIMA UNIDAD', 22, 28, 6, NULL),
(974, 'ITI 5 MATERIAS', 22, 28, 7, NULL),
(975, 'Recursamientos Última Unidad', 22, 28, 10, NULL),
(976, 'INGLÉS COMPARTIDOS', 22, 28, 6, NULL),
(977, 'INGLÉS COMPARTIDOS', 22, 28, 7, NULL),
(978, 'INGLÉS COMPARTIDOS', 22, 28, 8, NULL),
(979, 'INGLÉS COMPARTIDOS', 22, 28, 10, NULL),
(980, 'INGLÉS COMPARTIDOS', 22, 28, 19, NULL),
(981, 'ULTIMA UNIDAD', 22, 28, 7, NULL),
(982, 'Recursamientos', 22, 28, 10, NULL),
(983, 'PYM 1-1', 23, 29, 10, NULL),
(984, 'PYM 2-1', 23, 28, 10, NULL),
(986, 'PYM 2-2', 23, 28, 10, NULL),
(987, 'PYM 2-3', 23, 29, 10, NULL),
(988, 'PYM 2-4', 23, 29, 10, NULL),
(989, 'PYM 2-5 @ D', 23, 28, 10, NULL),
(990, 'PYM 4-1', 23, 28, 10, NULL),
(991, 'PYM 5-1', 23, 28, 10, NULL),
(993, 'PYM 5- 3', 23, 29, 10, NULL),
(994, 'PYM 5-4 @D', 23, 28, 10, NULL),
(995, 'PYM 5-2', 23, 28, 10, NULL),
(996, 'PYM 8-1', 23, 28, 10, NULL),
(997, 'PYM 8-2', 23, 29, 10, NULL),
(998, 'PYM 8-3 @D', 23, 28, 10, NULL),
(999, '', 23, NULL, 10, NULL),
(1001, 'ITI 1-1', 23, 28, 7, NULL),
(1002, 'ITI 2-2', 23, 28, 7, NULL),
(1003, 'ITI 2-3', 23, 28, 7, NULL),
(1004, 'ITI 2-4 UPV@d', 23, 28, 7, NULL),
(1006, 'ITI 4-1', 23, 28, 7, NULL),
(1007, 'ITI 5-1', 23, 28, 7, NULL),
(1009, 'ITI 5-2  SIN INGLES', 23, 28, 7, NULL),
(1010, 'ITI 5-3', 23, 28, 7, NULL),
(1011, 'MIM', 23, 28, 4, NULL),
(1012, 'MITI', 23, 28, 5, NULL),
(1013, '', 23, NULL, 4, NULL),
(1014, 'ITI 5-4 UPV@D', 23, 28, 7, NULL),
(1015, 'ITI 7-1', 23, 28, 7, NULL),
(1016, 'ITI 8-1', 23, 28, 7, NULL),
(1017, 'ITI 8-2', 23, 28, 7, NULL),
(1018, 'ITI 8-3 UPV@D', 23, 28, 7, NULL),
(1019, 'ITI 10-1', 23, 28, 2, NULL),
(1020, 'ITI 10-1', 23, 28, 7, NULL),
(1021, 'ITI INGLÉS COMPARTIDAS', 23, 28, 7, NULL),
(1024, '', 23, NULL, 8, NULL),
(1026, 'ITM 2-1 Aula: A1', 23, 28, 8, NULL),
(1027, 'ITM 2-2 Aula:2', 23, 28, 8, NULL),
(1028, 'ITM 2-3  Aula:2', 23, 29, 8, NULL),
(1029, 'ITM 5-1 Aula: Lab de Metrología', 23, 28, 8, NULL),
(1030, 'ITM 5-2 Aula: Lab de Diseño y Mont', 23, 28, 8, NULL),
(1031, 'ITM 8-1 Aula: Lab. de Diseño y Mont', 23, 29, 8, NULL),
(1032, 'IM 2-1 SIN INGLÉS', 23, 28, 6, NULL),
(1033, 'IM 2-2', 23, 28, 6, NULL),
(1034, 'ITM 8-2 Aula: Lab de Metrología', 23, 29, 8, NULL),
(1036, 'IM 1-1', 23, 28, 6, NULL),
(1037, 'IM 4-1', 23, 28, 6, NULL),
(1038, 'IM 5-1', 23, 28, 6, NULL),
(1039, 'ITM INGLES 6', 23, 29, 8, NULL),
(1040, 'IM 5-2', 23, 28, 6, NULL),
(1041, 'IM 5-3', 23, 28, 6, NULL),
(1042, 'IM 7-1', 23, 28, 6, NULL),
(1043, 'IM 8-1', 23, 28, 6, NULL),
(1044, 'IM 8-2', 23, 28, 6, NULL),
(1045, 'IM 9-1', 23, 28, 6, NULL),
(1046, 'IM 10-1', 23, 28, 6, NULL),
(1047, 'ISA 2-1', 23, 28, 19, NULL),
(1048, 'ISA 2-2', 23, 28, 19, NULL),
(1049, 'ISA 2-3', 23, 28, 19, NULL),
(1051, 'RECURSAMIENTO ULTIMA UNDIDAD', 23, 29, 10, NULL),
(1052, 'ITM REC DE ULTIMA UNIDAD', 23, 28, 8, NULL),
(1053, 'REC ULTIMA UNIDAD', 24, 28, 1, NULL),
(1054, 'REC ÚLTIMA UNIDAD', 24, 28, 6, NULL),
(1055, 'REC ULTIMA UNIDAD', 23, 28, 6, NULL),
(1056, 'COMPARTIDAS', 23, 28, 1, NULL),
(1057, 'GRUPOS COMPARTIDOS CON MANUFACTURA', 23, NULL, 8, NULL),
(1058, 'ingles IV COMPARTIDO ', 23, NULL, 8, NULL),
(1059, 'INGLÉS', 23, 28, 6, NULL),
(1060, 'INGLÉS COMPARTIDOS', 23, 28, 10, NULL),
(1061, 'INGLÉS COMPARTIDO', 23, 28, 19, NULL),
(1063, 'PYM 10-1', 23, 28, 10, NULL),
(1064, 'PYM 7-1', 23, 28, 10, NULL),
(1066, 'RECURSAMIENTO', 23, 28, 10, NULL),
(1070, '', 23, NULL, 10, NULL),
(1071, 'ITI 3-1', 24, 28, 7, NULL),
(1072, 'ITI 3-2', 24, 28, 7, NULL),
(1073, 'ITI 3-3', 24, 28, 7, NULL),
(1074, 'ITI 3-4 UPV@D', 24, 28, 7, NULL),
(1075, 'ITI 2-1', 24, 28, 7, NULL),
(1076, 'ITI 5-1', 24, 28, 7, NULL),
(1077, 'ITI 6-1', 24, 28, 7, NULL),
(1078, 'ITI 6-2', 24, 28, 7, NULL),
(1079, 'ITI 6-3 UPV@D', 24, 28, 7, NULL),
(1080, 'ITI 8-1', 24, 28, 7, NULL),
(1081, 'ITI 9-1', 24, 28, 7, NULL),
(1082, 'ITI 9-2', 24, 28, 7, NULL),
(1083, 'ITI 9-3 UPV@D', 24, 28, 7, NULL),
(1084, 'ITI 10-1', 24, 28, 7, NULL),
(1085, 'ITI ULTIMA UNIDAD', 24, 28, 7, NULL),
(1086, 'ITI COMPARTIDOS', 24, 28, 7, NULL),
(1087, 'ITI ESTANCIAS', 24, 28, 7, NULL),
(1088, 'ITI EXTRAS', 24, 28, 7, NULL),
(1089, 'IM 2-1', 24, 28, 6, NULL),
(1090, 'IM 3-1', 24, 28, 6, NULL),
(1091, 'IM 3-2', 24, 28, 6, NULL),
(1092, 'IM 5-1', 24, 28, 6, NULL),
(1093, 'IM 6-1', 24, 28, 6, NULL),
(1094, 'IM 6-2', 24, 28, 6, NULL),
(1095, 'IM 8-1', 24, 28, 6, NULL),
(1096, 'IM 9-1', 24, 28, 6, NULL),
(1097, 'IM 9-2', 24, 28, 6, NULL),
(1098, 'IM 10-1', 24, 28, 6, NULL),
(1099, 'ISA 3-1', 24, 28, 19, NULL),
(1100, 'ISA 3-2', 24, 28, 19, NULL),
(1101, 'ISA MATERIAS', 24, 28, 19, NULL),
(1102, 'ISA 2-1 MATERIAS', 24, 28, 19, NULL),
(1103, 'MIM', 24, 28, 4, NULL),
(1105, 'MITI', 24, 28, 5, NULL),
(1106, 'ITM 3-1 AULA 3', 24, 28, 8, NULL),
(1107, 'ITM 3-2 AULA 1 MAT', 24, 28, 8, NULL),
(1108, 'ITM 3-3 AULA 1 VESP', 24, 29, 8, NULL),
(1109, 'ITM 6-1 AULA SIST EMBEBIDOS MAT', 24, 28, 8, NULL),
(1110, 'ITM 6-2 AULA DIS ELECT MONT SUP', 24, 28, 8, NULL),
(1111, 'PyMES 2-1', 24, 28, 10, NULL),
(1112, 'PyMES 3-1', 24, 28, 10, NULL),
(1113, 'PyMES 3-2', 24, 28, 10, NULL),
(1114, 'PyMES 3-3', 24, 29, 10, NULL),
(1115, 'PyMES 3-4 @ distancia', 24, 28, 10, NULL),
(1116, 'ITM 9-1 DIS ELECT MONT SUP', 24, 29, 8, NULL),
(1117, 'PyMES 5-1', 24, 28, 10, NULL),
(1118, 'PyMES 6-1', 24, 28, 10, NULL),
(1119, 'PyMES 6-2', 24, 29, 10, NULL),
(1120, 'PyMES 6-3 @ distancia', 24, 28, 10, NULL),
(1122, 'PyMES 9-1', 24, 28, 10, NULL),
(1123, 'PyMES 9-2', 24, 29, 10, NULL),
(1124, 'PyMES 9-3 @ distancia', 24, 28, 10, NULL),
(1125, 'ITM 9-2 SIST EMBEBIDOS VESP', 24, 29, 8, NULL),
(1126, 'ITM ASESORIAS ', 24, 28, 8, NULL),
(1127, 'ITM ESTANCIAS Y ESTADIA', 24, 28, 8, NULL),
(1128, 'ITM RECURSAMIENTO ULTIMA UNIDAD', 24, 28, 8, NULL),
(1129, 'IM MATERIAS', 24, 28, 6, NULL),
(1130, 'PyMES 10-1', 24, 28, 10, NULL),
(1131, 'PyMES 7-1', 24, 28, 10, NULL),
(1132, 'GRUPOS DE INGLÉS', 24, 28, 8, NULL),
(1133, 'GRUPOS DE INGLÉS', 24, 28, 6, NULL),
(1134, 'GRUPOS DE INGLÉS', 24, 28, 7, NULL),
(1135, 'GRUPOS DE INGLÉS', 24, 28, 10, NULL),
(1136, 'GRUPOS DE INGLÉS', 24, 28, 19, NULL),
(1137, 'RECURSAMIENTO ULTIMA UNDAD', 24, 28, 10, NULL),
(1138, 'PyMES 4-1', 24, 28, 10, NULL),
(1139, 'REC ULTIMA UNIDAD', 24, 28, 19, NULL),
(1140, 'RECURSAMIENTO', 24, 29, 10, NULL),
(1141, 'Pymes 1-1', 25, 28, 10, NULL),
(1142, 'Pymes 1-2', 25, 28, 10, NULL),
(1143, 'Pymes 1-3', 25, 28, 10, NULL),
(1144, 'Pymes 3-1', 25, 29, 10, NULL),
(1145, 'Pymes 4-1', 25, 28, 10, NULL),
(1146, 'Pymes 4-2', 25, 28, 10, NULL),
(1147, 'Pymes 4-3', 25, 29, 10, NULL),
(1148, 'Pymes 4-4 @ distancia', 25, 28, 10, NULL),
(1150, 'Pymes 6-1 ', 25, 29, 10, NULL),
(1151, 'Pymes 7-1', 25, 28, 10, NULL),
(1152, 'Pymes 7-2', 25, 29, 10, NULL),
(1153, 'Pymes 7-3 @ distancia', 25, 28, 10, NULL),
(1154, 'Pymes 10-1', 25, 28, 10, NULL),
(1155, 'Pymes 10-2', 25, 28, 10, NULL),
(1156, 'Pymes 10-3 @ distancia', 25, 28, 10, NULL),
(1157, 'ITI 1-1', 25, 28, 7, NULL),
(1158, 'ITI 1-2', 25, 28, 7, NULL),
(1159, 'ITI 1-3', 25, 28, 7, NULL),
(1160, 'ITI 3-1', 25, 28, 7, NULL),
(1161, 'ITI 4-1', 25, 28, 7, NULL),
(1162, 'ITI 4-2', 25, 28, 7, NULL),
(1163, 'ITI 4-3', 25, 28, 7, NULL),
(1164, 'ITI 4-4 UPV@D', 25, 28, 7, NULL),
(1165, 'ITI 6-1', 25, 28, 7, NULL),
(1166, 'ITI 7-1', 25, 28, 7, NULL),
(1167, 'ITI 7-2', 25, 28, 7, NULL),
(1168, 'ITI 7-3 UPV@D', 25, 28, 7, NULL),
(1169, 'ITI 9-1', 25, 28, 7, NULL),
(1170, 'ITI 10-1', 25, 28, 7, NULL),
(1171, 'ITI 8 Materias', 25, 28, 7, NULL),
(1172, 'ITM 1-1 AULA I115 MAT', 25, 28, 8, NULL),
(1173, 'ITM 1-2 AULA I116 MAT', 25, 28, 8, NULL),
(1174, 'ITM 4-1 AULA I 104 MAT', 25, 28, 8, NULL),
(1175, 'ITM 4-2 AULA I114 MAT', 25, 28, 8, NULL),
(1176, 'ITM 4-3 AULA I114 VESP', 25, 29, 8, NULL),
(1177, 'ITM 7-1 AULA I115 VESP', 25, 29, 8, NULL),
(1178, 'ITM 7-2 AULA I104 VESP', 25, 29, 8, NULL),
(1179, 'ITM 10 ESTADIAS', 25, 28, 8, NULL),
(1180, 'ITM RECURSAMIENTOS', 25, 28, 8, NULL),
(1181, 'ISA 1-1', 25, 28, 19, NULL),
(1182, 'ISA 1-2', 25, 28, 19, NULL),
(1183, 'ISA 4-1', 25, 28, 19, NULL),
(1184, 'ISA 4-2', 25, 28, 19, NULL),
(1185, 'IM 1-1 SIN INGLES', 25, 28, 6, NULL),
(1186, 'IM 1-2', 25, 28, 6, NULL),
(1187, 'IM 1-3', 25, 28, 6, NULL),
(1188, 'NIVELACIÓN ISA', 25, 28, 9, NULL),
(1189, 'NIVELACIÓN ITI - IM', 25, 28, 9, NULL),
(1190, 'IM 3-1', 25, 28, 6, NULL),
(1191, 'IM 4-1', 25, 28, 6, NULL),
(1192, 'IM 4-2', 25, 28, 6, NULL),
(1193, 'IM 6-1', 25, 28, 6, NULL),
(1194, 'IM 7-1', 25, 28, 6, NULL),
(1195, 'IM 7-2', 25, 28, 6, NULL),
(1196, 'IM 9-1', 25, 28, 6, NULL),
(1197, 'IM 10-1', 25, 28, 6, NULL),
(1198, 'REC ULT UNIDAD', 25, 28, 6, NULL),
(1199, 'REC ULTIMA UNIDAD', 25, 28, 7, NULL),
(1203, 'MI 1-1', 25, 28, 20, NULL),
(1204, 'MIM-4', 25, 29, 4, NULL),
(1207, 'MITI-4', 25, 28, 5, NULL),
(1208, 'Recursamiento ultima unidad', 25, 28, 10, NULL),
(1209, 'GRUPOS INGLES', 25, 28, 6, NULL),
(1210, 'REC ULT UNIDAD', 25, 28, 19, NULL),
(1211, 'MATERIAS COMPARTIDAS', 25, 28, 6, NULL),
(1212, 'INGLÉS', 25, 28, 6, NULL),
(1213, 'INGLÉS', 25, 28, 7, NULL),
(1214, 'INGLÉS ', 25, 28, 8, NULL),
(1215, 'INGLÉS ', 25, 28, 10, NULL),
(1216, 'INGLÉS', 25, 28, 19, NULL),
(1217, 'MATERIAS COMPARTIDAS', 25, 28, 19, NULL),
(1218, 'Recursamientos', 25, 29, 10, NULL),
(1222, 'CARGA DE PRUEBA', 25, 28, 7, NULL),
(1223, 'CARGA DE PRUEBA IM', 25, NULL, 6, NULL),
(1229, 'ITM 2-1 MAT AULA  I118', 26, 28, 8, NULL),
(1230, 'ITM 2-2 MAT AULA I111', 26, 28, 8, NULL),
(1231, 'ITM 5-1 MAT AULA I103', 26, 28, 8, NULL),
(1232, 'Pymes 2-1', 26, 28, 10, NULL),
(1233, 'Pymes 2-2', 26, 28, 10, NULL),
(1234, 'Pymes 2-3', 26, 29, 10, NULL),
(1235, 'Pymes 4-1', 26, 29, 10, NULL),
(1237, 'Pymes 5-1', 26, 28, 10, NULL),
(1238, 'Pymes 5-2', 26, 28, 10, NULL),
(1239, 'Pymes 5-3', 26, 29, 10, NULL),
(1240, 'Pymes 5-4 Distancia', 26, 28, 10, NULL),
(1241, 'Pymes 7-1', 26, 28, 10, NULL),
(1242, 'Pymes 8-1', 26, 28, 10, NULL),
(1243, 'Pymes 8-2', 26, 29, 10, NULL),
(1244, 'Pymes 8-3 Distancia', 26, 28, 10, NULL),
(1245, 'ITM 5-2 MAT AULA I117', 26, 28, 8, NULL),
(1246, 'ITM 5-3 VESP AULA I103', 26, 29, 8, NULL),
(1247, 'ITM 8-1 VESP AULA I117', 26, 29, 8, NULL),
(1248, 'ITM 8-2 VESP AULA I118', 26, 29, 8, NULL),
(1249, 'ITM ESTANCIAS/ ESTADIAS', 26, 28, 8, NULL),
(1250, 'ITM VARIAS', 26, 28, 8, NULL),
(1251, 'MER 1-1', 26, 28, 22, NULL),
(1252, 'ISA 1-1', 26, 29, 19, NULL),
(1253, 'ISA 2-1', 26, 28, 19, NULL),
(1254, 'ISA 2-2', 26, 28, 19, NULL),
(1255, 'ISA 5-1', 26, 28, 19, NULL),
(1256, 'ISA 5-2', 26, 29, 19, NULL),
(1257, 'IM 1-1', 26, 29, 6, NULL),
(1258, 'IM 2-1', 26, 28, 6, NULL),
(1259, 'IM 2-2', 26, 28, 6, NULL),
(1260, 'IM 2-3', 26, 28, 6, NULL),
(1261, 'IM 4-1', 26, 29, 6, NULL),
(1262, 'IM 5-1', 26, 28, 6, NULL),
(1263, 'IM 5-2', 26, 28, 6, NULL),
(1265, 'IM 7-1', 26, 28, 6, NULL),
(1266, 'IM 8-1', 26, 28, 6, NULL),
(1267, 'IM 8-2', 26, 28, 6, NULL),
(1268, 'IM 10-1', 26, 28, 6, NULL),
(1269, 'ITI 1-1', 26, 29, 7, NULL),
(1270, 'ITI 2-1', 26, 28, 7, NULL),
(1271, 'ITI 2-2', 26, 28, 7, NULL),
(1272, 'ITI 2-3', 26, 29, 7, NULL),
(1273, 'ITI 4-1', 26, 29, 7, NULL),
(1274, 'ITI 5-1', 26, 28, 7, NULL),
(1275, 'ITI 5-2', 26, 28, 7, NULL),
(1276, 'ITI 5-3 UPV@D', 26, 28, 7, NULL),
(1277, 'ITI 5-4', 26, 28, 7, NULL),
(1278, 'ITI 7-1', 26, 29, 7, NULL),
(1279, 'ITI 8-1', 26, 28, 7, NULL),
(1280, 'ITI 8-2 UPV@D', 26, 28, 7, NULL),
(1281, 'ITI 8-3', 26, 28, 7, NULL),
(1282, 'ITI 10-1', 26, 28, 7, NULL),
(1283, '2', 26, 28, 20, NULL),
(1284, '5', 26, 28, 5, NULL),
(1285, '5a', 26, 28, 4, NULL),
(1286, 'Recursamiento ultima unidad', 26, 28, 10, NULL),
(1287, 'REC ULT UNIDAD', 26, 28, 6, NULL),
(1288, 'REC ULT UNIDAD', 26, 28, 19, NULL),
(1289, 'MATERIAS INGLES', 26, 28, 6, NULL),
(1290, 'ITI COMPARTIDAS', 26, 28, 7, NULL),
(1291, 'ITI REC ULT UNIDAD', 26, 28, 7, NULL),
(1292, 'MATERIAS', 26, 28, 6, NULL),
(1293, 'Pymes 10-1', 26, 28, 10, NULL),
(1294, 'ISA MATERIAS', 26, 28, 19, NULL),
(1295, 'INGLÉS COMPARTIDO', 26, 28, 7, NULL),
(1296, 'INGLÉS COMPARTIDO', 26, 28, 8, NULL),
(1297, 'INGLÉS COMPARTIDO', 26, 28, 6, NULL),
(1298, 'INGLÉS COMPARTIDO', 26, 28, 10, NULL),
(1299, 'INGLÉS COMPARTIDO', 26, 28, 19, NULL),
(1300, '5', 26, NULL, 5, NULL),
(1301, 'Ingles V', 26, NULL, 3, NULL),
(1302, 'Pymes 4-2 Distancia', 26, 28, 10, NULL),
(1303, '3-1 Pymes', 27, 28, 10, NULL),
(1304, '3-2 Pymes', 27, 28, 10, NULL),
(1305, '3-3 Pymes', 27, 29, 10, NULL),
(1306, '5-1 Pymes', 27, 29, 10, NULL),
(1307, '6-1 Pymes', 27, 28, 10, NULL),
(1308, '6-2 Pymes', 27, 28, 10, NULL),
(1309, '6-3 Pymes', 27, 29, 10, NULL),
(1310, '6-4 Pymes@distancia', 27, 28, 10, NULL),
(1311, '8-1 Pymes', 27, 28, 10, NULL),
(1312, '9-1 Pymes', 27, 28, 10, NULL),
(1313, '9-2 Pymes', 27, 29, 10, NULL),
(1314, '9-3 Pymes@distancia', 27, 28, 10, NULL),
(1315, 'IM 2-1', 27, 28, 6, NULL),
(1316, 'IM 3-1', 27, 28, 6, NULL),
(1317, 'IM 3-2', 27, 28, 6, NULL),
(1318, 'IM 3-3', 27, 28, 6, NULL),
(1319, 'IM 5-1', 27, 28, 6, NULL),
(1320, 'IM 6-1', 27, 28, 6, NULL),
(1321, 'IM 6-2', 27, 28, 6, NULL),
(1322, 'IM 8-1', 27, 28, 6, NULL),
(1323, 'IM 9-1', 27, 28, 6, NULL),
(1324, 'IM 9-2', 27, 28, 6, NULL),
(1325, 'IM 10-1', 27, 28, 6, NULL),
(1326, 'ISA 2-1', 27, 28, 19, NULL),
(1327, 'ISA 3-1', 27, 28, 19, NULL),
(1328, 'ISA 3-2', 27, 28, 19, NULL),
(1329, 'ISA 6-1', 27, 28, 19, NULL),
(1330, 'ISA 6-2', 27, 28, 19, NULL),
(1331, 'ITI 2-1', 27, 28, 7, NULL),
(1332, 'ITI 3-1', 27, 28, 7, NULL),
(1333, 'ITI 3-2', 27, 28, 7, NULL),
(1334, 'ITI 3-3', 27, 28, 7, NULL),
(1335, 'ITI 5-1', 27, 28, 7, NULL),
(1336, 'ITI 6-1', 27, 28, 7, NULL),
(1337, 'ITI 6-2', 27, 28, 7, NULL),
(1338, 'ITI 6-3', 27, 28, 7, NULL),
(1339, 'ITI 6-4 UPV@d', 27, 28, 7, NULL),
(1340, 'ITI 8-1', 27, 28, 7, NULL),
(1341, 'ITI 9-1', 27, 28, 7, NULL),
(1342, 'ITI 9-2', 27, 28, 7, NULL),
(1343, 'ITI 9-3 UPV@d', 27, 28, 7, NULL),
(1344, 'ITI ESTANCIAS Y ESTADÍAS', 27, 28, 7, NULL),
(1345, 'ITI ÚLTIMA UNIDAD', 27, 28, 7, NULL),
(1346, 'ITI INGLÉS COMPARTIDOS', 27, 28, 7, NULL),
(1347, 'ITM 3-1 AULA I103', 27, 28, 8, NULL),
(1348, 'ITM 3-2 AULA I111', 27, 28, 8, NULL),
(1349, 'ITM 6-1 AULA I117', 27, 28, 8, NULL),
(1350, 'ITM 6-2 AULA  I118', 27, 28, 8, NULL),
(1351, 'ITM 6-3 AULA I117', 27, 29, 8, NULL),
(1352, 'ITM 9-1 AULA I103', 27, 29, 8, NULL),
(1353, 'ITM 9-2 AULA I118', 27, 29, 8, NULL),
(1354, 'ESTANCIAS Y ESTADIAS', 27, 28, 8, NULL),
(1355, 'Sem3', 27, 28, 20, NULL),
(1356, ' ITM REC ULTIMA UNIDAD', 27, 29, 8, NULL),
(1357, 'MER-2', 27, 28, 22, NULL),
(1358, 'Recursamiento ultima unidad', 27, 28, 10, NULL),
(1359, 'sexto', 27, 28, 4, NULL),
(1360, 'sexto', 27, 28, 5, NULL),
(1361, 'REC ULT UNIDAD', 27, 28, 6, NULL),
(1362, 'REC ULT UNIDAD', 27, 28, 19, NULL),
(1363, 'INGLES COMPARTIDO', 27, 28, 6, NULL),
(1364, 'INGLES COMPARTIDO', 27, 28, 19, NULL),
(1365, 'INGLÉS COMPARTIDO', 27, 28, 8, NULL),
(1366, 'INGLÉS COMPARTIDO', 27, 28, 10, NULL),
(1367, '10-1 Pymes', 27, 28, 10, NULL),
(1368, '4-1 Pymes', 27, 28, 10, NULL),
(1369, 'ISA MATERIAS', 27, 28, 19, NULL),
(1370, 'MEC MATERIAS', 27, 28, 6, NULL),
(1371, '', 27, NULL, 8, NULL),
(1372, '7-1 Pymes', 27, 28, 10, NULL),
(1373, 'ITI 10', 27, 28, 2, NULL),
(1374, 'Pymes 1-1', 28, 28, 10, NULL),
(1375, 'Pymes 1-2', 28, 28, 10, NULL),
(1376, 'Pymes 1-3', 28, 29, 10, NULL),
(1377, 'Pymes 4-1', 28, 28, 10, NULL),
(1378, 'Pymes 4-2', 28, 28, 10, NULL),
(1379, 'Pymes 4-3', 28, 29, 10, NULL),
(1380, 'Pymes 6-1', 28, 29, 10, NULL),
(1381, 'Pymes 7-1', 28, 28, 10, NULL),
(1382, 'Pymes 7-2', 28, 28, 10, NULL),
(1383, 'Pymes 7-3', 28, 29, 10, NULL),
(1384, 'Pymes 7-4@ distancia', 28, 28, 10, NULL),
(1385, 'Pymes 9-1', 28, 28, 10, NULL),
(1386, 'Pymes 10-1', 28, 28, 10, NULL),
(1387, 'Pymes 10-2', 28, 29, 10, NULL),
(1388, 'Pymes 10-3 @distancia', 28, 28, 10, NULL),
(1389, 'ITI 1-1', 28, 28, 7, NULL),
(1390, 'ITI 1-2', 28, 28, 7, NULL),
(1392, 'ITI 1-3', 28, 28, 7, NULL),
(1394, 'ITI 3-1', 28, 28, 7, NULL),
(1395, 'ITI 4-1', 28, 28, 7, NULL),
(1396, 'ITI 4-2', 28, 28, 7, NULL),
(1398, 'ITI 4-3', 28, 28, 7, NULL),
(1399, 'ITI 6-1', 28, 28, 7, NULL),
(1400, 'ITI 7-1', 28, 28, 7, NULL),
(1401, 'ITI 7-2', 28, 28, 7, NULL),
(1404, 'ITM 1-1 MAT AULA 117', 28, 28, 8, NULL),
(1405, 'ITM 1-2 MAT AULA I102', 28, 28, 8, NULL),
(1406, 'ITM 4-1 MAT AULA  I114', 28, 28, 8, NULL),
(1407, 'ITM 4-2 MAT AULA I118', 28, 28, 8, NULL),
(1408, 'ITI 7-3 UPV@D', 28, 28, 7, NULL),
(1409, 'ITI 9-1', 28, 28, 7, NULL),
(1410, 'ITM 7-1 VESP AULA I117', 28, 29, 8, NULL),
(1411, 'ITM 7-2 VESP AULA I118', 28, 29, 8, NULL),
(1413, 'ITM 10 VESP I103', 28, 29, 8, NULL),
(1414, 'ISA 1-1 ', 28, 28, 19, NULL),
(1415, 'ITI 10-1', 28, 28, 7, NULL),
(1416, 'IM 1-1', 28, 28, 6, NULL),
(1417, 'IM 1-2', 28, 28, 6, NULL),
(1418, 'IM 1-3', 28, 28, 6, NULL),
(1419, 'IM 3-1', 28, 28, 6, NULL),
(1420, 'IM 4-1', 28, 28, 6, NULL),
(1421, 'IM 4-2', 28, 28, 6, NULL),
(1422, 'IM 4-3', 28, 28, 6, NULL),
(1423, 'IM 6-1', 28, 28, 6, NULL),
(1424, 'IM 7-1', 28, 28, 6, NULL),
(1425, 'IM 7-2', 28, 28, 6, NULL),
(1426, 'IM 9-1', 28, 28, 6, NULL),
(1427, 'IM 10-1', 28, 28, 6, NULL),
(1428, 'ISA 1-2', 28, 28, 19, NULL),
(1429, 'ISA 3-1', 28, 28, 19, NULL),
(1430, 'ISA 4-1', 28, 28, 19, NULL),
(1431, 'ISA 4-2', 28, 28, 19, NULL),
(1432, 'ISA 7-1', 28, 28, 19, NULL),
(1433, 'ISA 7-2', 28, 28, 19, NULL),
(1435, 'ITI / IM / ISA', 28, 28, 9, NULL),
(1436, 'RECURSAMIENTOS ', 28, 28, 8, NULL),
(1437, 'ESTANCIAS Y ESTADIAS', 28, 28, 8, NULL),
(1438, 'VARIOS', 28, 28, 8, NULL),
(1439, 'MER 1-1', 28, 28, 22, NULL),
(1440, 'MER 3-1', 28, 28, 22, NULL),
(1441, 'INGLES COMPARTIDO', 28, 28, 8, NULL),
(1445, 'Recursamientos de la Última Unidad', 28, 29, 10, NULL),
(1446, 'MI-1', 28, 28, 20, NULL),
(1447, 'MI- 4', 28, 28, 20, NULL),
(1448, 'REC ULT UNIDAD', 28, 28, 19, NULL),
(1449, 'REC ULT UNIDAD', 28, 28, 6, NULL),
(1450, 'INGLES COMP', 28, 28, 6, NULL),
(1451, 'COMPARTIDAS', 28, 28, 19, NULL),
(1452, 'COMPARTIDAS', 28, 28, 6, NULL),
(1453, 'INGLÉS COMPARTIDO', 28, 28, 7, NULL),
(1454, 'INGLÉS COMPARTIDO', 28, 28, 10, NULL),
(1455, 'INGLÉS COMPARTIDO', 28, 28, 19, NULL),
(1456, 'ITI COMPARTIDOS VARIOS', 28, 28, 7, NULL),
(1458, 'seminario', 28, 28, 4, NULL),
(1464, 'Pymes 2-1', 29, 28, 10, NULL),
(1465, '', 29, NULL, 10, NULL),
(1466, 'Pymes 2-2', 29, 28, 10, NULL),
(1467, 'Pymes 2-3', 29, 29, 10, NULL),
(1468, 'Pymes 5-1', 29, 28, 10, NULL),
(1469, 'Pymes 5-2', 29, 28, 10, NULL),
(1470, 'Pymes 5-3', 29, 29, 10, NULL),
(1472, 'Pymes 7-1', 29, 29, 10, NULL),
(1474, 'Pymes 8-1', 29, 28, 10, NULL),
(1475, 'Pymes 8-2', 29, 28, 10, NULL),
(1476, 'Pymes 8-3', 29, 29, 10, NULL),
(1477, 'Pymes 8-4 Distancia', 29, 28, 10, NULL),
(1478, 'ITI 1-1', 29, 28, 7, NULL),
(1479, 'ITI 2-1', 29, 28, 7, NULL),
(1480, 'ITI 2-2', 29, 28, 7, NULL),
(1483, 'ITI 2-3', 29, 28, 7, NULL),
(1484, 'ITI 4-1', 29, 28, 7, NULL),
(1485, 'ITI 5-1', 29, 28, 7, NULL),
(1487, 'ITI 5-2', 29, 28, 7, NULL),
(1488, 'ITI 7-1', 29, 28, 7, NULL),
(1489, 'ITI 8-1', 29, 28, 7, NULL),
(1491, 'ITI 8-2', 29, 28, 7, NULL),
(1492, 'ITI 8-3 UPV@D', 29, 28, 7, NULL),
(1493, 'ITM 2-1 A I111', 29, 28, 8, NULL),
(1494, 'ITM 2-2 AI114', 29, 28, 8, NULL),
(1495, 'ITM 5-1 A I117', 29, 28, 8, NULL),
(1496, 'MEC 1-1', 29, 28, 6, NULL),
(1498, 'MEC 2-1', 29, 28, 6, NULL),
(1499, 'MEC 2-2 SIN INGLES', 29, 28, 6, NULL),
(1501, 'MEC 2-3', 29, 28, 6, NULL),
(1502, 'MEC 4-1', 29, 28, 6, NULL),
(1503, 'ITM 5-2 A I102', 29, 28, 8, NULL),
(1504, 'MEC 5-1', 29, 28, 6, NULL),
(1505, 'MEC 5-2', 29, 28, 6, NULL),
(1506, 'MEC 7-1', 29, 28, 6, NULL),
(1507, 'MEC 8-1', 29, 28, 6, NULL),
(1508, 'MEC 8-2', 29, 28, 6, NULL),
(1509, 'MEC 9-1', 29, 28, 6, NULL),
(1510, 'ITM 8-1 A114', 29, 29, 8, NULL),
(1511, 'ITM 8-2 A117', 29, 29, 8, NULL),
(1512, 'ESTANCIAS Y ESTADIAS', 29, 28, 8, NULL),
(1513, 'RECURSAMIENTOS', 29, 28, 8, NULL),
(1514, 'ITM 10', 29, 28, 8, NULL),
(1515, 'INGLES COMPARTIDO', 29, 28, 8, NULL),
(1516, 'ITI 10-1', 29, 28, 7, NULL),
(1517, 'ITI INGLÉS COMPARTIDO', 29, 28, 7, NULL),
(1518, 'MEC 10-1', 29, 28, 6, NULL),
(1519, 'ISA 2-1', 29, 28, 19, NULL),
(1520, 'ISA 1-1', 29, 28, 19, NULL),
(1521, 'ISA 2-2', 29, 28, 19, NULL),
(1522, 'ISA 4-1', 29, 28, 19, NULL),
(1523, 'ISA 5-1', 29, 28, 19, NULL),
(1524, 'ISA 5-2', 29, 28, 19, NULL),
(1525, 'ISA 8-1', 29, 28, 19, NULL),
(1526, 'ISA 8-2', 29, 28, 19, NULL),
(1527, 'Recursamientos', 29, 29, 10, NULL),
(1528, 'MI-Cuatri-2', 29, 28, 20, NULL),
(1529, 'MI-Cuatri-5', 29, 28, 20, NULL),
(1530, 'REC ULT UNIDAD', 29, 28, 6, NULL),
(1531, 'ITI 9 Materias', 29, 28, 7, NULL),
(1532, 'MER CUARTO', 29, 28, 22, NULL),
(1533, 'MER SEGUNDO', 29, 28, 22, NULL),
(1534, 'REC ULT UNIDAD', 29, 28, 19, NULL),
(1535, 'MATERIAS', 29, 28, 6, NULL),
(1536, 'ISA MATERIAS', 29, 28, 19, NULL),
(1537, 'Inglés Compartido', 29, 29, 10, NULL),
(1538, 'Pymes 10-1', 29, 28, 10, NULL),
(1539, 'GRUPOS DE INGLÉS COMPARTIDOS', 29, 28, 6, NULL),
(1540, 'GRUPOS DE INGLÉS COMPARTIDOS', 29, 28, 19, NULL),
(1541, 'Pymes 4-1', 29, 28, 10, NULL),
(1542, 'ITI Última unidad', 29, 28, 7, NULL),
(1543, 'PyMES 3-1', 30, 28, 10, NULL),
(1544, 'PyMES 3-2', 30, 28, 10, NULL);
INSERT INTO `escolarescarga` (`idcarga`, `clave`, `idcuatrimestre`, `turno`, `idplan_estudios`, `duracion`) VALUES
(1545, 'PyMES 3-3', 30, 29, 10, NULL),
(1546, 'PyMES 6-1', 30, 28, 10, NULL),
(1547, 'PyMES 6-2', 30, 28, 10, NULL),
(1548, 'PyMES 6-3', 30, 29, 10, NULL),
(1549, 'PyMES 8-1', 30, 29, 10, NULL),
(1550, 'PyMES 9-1', 30, 28, 10, NULL),
(1551, 'PyMES 9-2', 30, 28, 10, NULL),
(1552, 'PyMES 9-3', 30, 29, 10, NULL),
(1553, 'PyMES 9-4 Distancia', 30, 28, 10, NULL),
(1554, 'ITM 3-1- I114', 30, 28, 8, NULL),
(1555, 'ITM 3-2-I117', 30, 28, 8, NULL),
(1556, 'IM 2-1', 30, 29, 6, NULL),
(1557, 'ITM 6-1-I107', 30, 28, 8, NULL),
(1558, 'ITM 6-2-I111', 30, 28, 8, NULL),
(1559, 'ITM 9-1- I114', 30, 29, 8, NULL),
(1560, 'ITM 9-2-I111', 30, 29, 8, NULL),
(1561, 'ESTANCIAS I Y II', 30, 28, 8, NULL),
(1562, 'ESTADIA', 30, 28, 8, NULL),
(1563, 'RECURSAMIENTOS', 30, 28, 8, NULL),
(1564, 'ISA 2-1', 30, 29, 19, NULL),
(1565, 'ISA 3-1', 30, 28, 19, NULL),
(1566, 'ISA 3-2', 30, 28, 19, NULL),
(1568, 'ISA 5-1', 30, 29, 19, NULL),
(1569, 'ISA 6-1', 30, 28, 19, NULL),
(1570, 'ISA 6-2', 30, 29, 19, NULL),
(1571, 'ISA 9-1', 30, 28, 19, NULL),
(1572, 'IM 3-1', 30, 28, 6, NULL),
(1573, 'ISA 9-2', 30, 29, 19, NULL),
(1574, 'ISA MATERIAS', 30, 28, 19, NULL),
(1575, 'REC ULT UNIDAD', 30, 28, 19, NULL),
(1576, 'IM 3-2', 30, 28, 6, NULL),
(1577, 'ITI 2-1', 30, 29, 7, NULL),
(1578, 'IM 3-3', 30, 29, 6, NULL),
(1581, 'IM 5-1', 30, 29, 6, NULL),
(1586, 'IM 6-1', 30, 28, 6, NULL),
(1587, 'IM 6-2', 30, 29, 6, NULL),
(1588, 'IM 8-1', 30, 29, 6, NULL),
(1589, 'ITI 3-1', 30, 28, 7, NULL),
(1590, 'ITI 3-2', 30, 28, 7, NULL),
(1591, 'IM 9-1', 30, 28, 6, NULL),
(1592, 'ESTANCIAS', 30, 28, 19, NULL),
(1593, 'IM 9-2', 30, 29, 6, NULL),
(1594, 'ITI 3-3', 30, 29, 7, NULL),
(1595, 'Estancia I', 30, 28, 6, NULL),
(1596, 'Estancia II', 30, 28, 6, NULL),
(1597, 'Estadia', 30, 28, 6, NULL),
(1598, 'IM Materias', 30, 28, 6, NULL),
(1600, 'Rec Ult Unidad', 30, 28, 6, NULL),
(1602, 'ITI 5-1', 30, 29, 7, NULL),
(1603, 'ITI 6-1', 30, 28, 7, NULL),
(1604, 'ITI 6-2', 30, 29, 7, NULL),
(1605, 'ITI 8-1', 30, 29, 7, NULL),
(1606, 'ITI 9-1', 30, 28, 7, NULL),
(1607, 'ITI 9-2', 30, 28, 7, NULL),
(1608, 'ITI@D 9-3', 30, 28, 7, NULL),
(1609, 'ITI@D_E', 30, 28, 7, NULL),
(1610, 'RECURSAMIENTOS', 30, 28, 10, NULL),
(1611, 'MI-6', 30, 28, 20, NULL),
(1614, 'MI-3', 30, 29, 20, NULL),
(1615, 'PyMES 10-1', 30, 28, 10, NULL),
(1616, 'ESTADIAS', 30, 28, 7, NULL),
(1617, 'ESTANCIAS I Y II', 30, 28, 7, NULL),
(1620, 'INGLÉS COMPARTIDO', 30, 28, 6, NULL),
(1621, 'INGLÉS COMPARTIDO', 30, 28, 7, NULL),
(1622, 'INGLÉS COMPARTIDO', 30, 28, 8, NULL),
(1623, 'INGLÉS COMPARTIDO', 30, 28, 10, NULL),
(1624, 'INGLÉS COMPARTIDO', 30, 28, 19, NULL),
(1625, 'PyMES 7-1', 30, 28, 10, NULL),
(1627, 'PyMES 4-1', 30, 28, 10, NULL),
(1628, 'MER 5-1', 30, 28, 22, NULL),
(1629, 'MER 3-1', 30, 28, 22, NULL),
(1630, 'Ultima_Unidad', 30, 28, 7, NULL),
(1631, 'compartidos', 30, 28, 7, NULL),
(1632, 'GRUPOS COMPARTIDOS', 30, 28, 10, NULL),
(1633, 'cargadeprueba', 28, 28, 1, NULL),
(1634, 'PyMES 1-1 (B 203)', 31, 28, 10, NULL),
(1635, 'PyMES 1-2 (B 202)', 31, 28, 10, NULL),
(1636, 'PyMES 1-3 (B 202)', 31, 29, 10, NULL),
(1637, 'PyMES 4-1 (B 201)', 31, 28, 10, NULL),
(1638, 'PyMES 4-2 (B 206)', 31, 28, 10, NULL),
(1639, 'PyMES 4-3 (B 203)', 31, 29, 10, NULL),
(1640, 'PyMES 7-1 (B 105)', 31, 28, 10, NULL),
(1641, 'PyMES 7-2 (I 116)', 31, 28, 10, NULL),
(1643, 'PyMES 7-3 (B 201)', 31, 29, 10, NULL),
(1645, 'PyMES 9-1 (B 206)', 31, 29, 10, NULL),
(1649, 'PyMES Distancia', 31, 28, 9, NULL),
(1650, 'IM 1-1 (Sin inglés)', 31, 28, 23, NULL),
(1651, 'IM 1-2', 31, 28, 23, NULL),
(1652, 'IM 1-3', 31, 29, 23, NULL),
(1653, 'ITM 1-1 AULA I114', 31, 28, 8, NULL),
(1654, 'ITM 1-2 AULA I111', 31, 28, 8, NULL),
(1655, 'ITM 4-1 AULA I107', 31, 28, 8, NULL),
(1656, 'ITM 4-2 AULA I117', 31, 28, 8, NULL),
(1657, 'ITM 7-1 AULA I118/I117', 31, 29, 8, NULL),
(1658, 'MATERIAS ', 31, 29, 8, NULL),
(1659, 'RECURSAMIENTOS DE LA ULTIMA UNIDAD', 31, 28, 8, NULL),
(1660, 'ESTANCIAS I Y II', 31, 28, 8, NULL),
(1661, 'ESTADIA', 31, 28, 8, NULL),
(1663, 'IM 3-1', 31, 29, 6, NULL),
(1664, 'IM 4-1', 31, 28, 6, NULL),
(1665, 'IM 4-2', 31, 28, 6, NULL),
(1666, 'IM 6-1', 31, 29, 6, NULL),
(1667, 'IM 7-1', 31, 28, 6, NULL),
(1668, 'IM 7-2', 31, 29, 6, NULL),
(1670, 'ISA 1-1', 31, 28, 19, NULL),
(1672, 'ISA 1-2', 31, 28, 19, NULL),
(1673, 'ISA 1-3', 31, 29, 19, NULL),
(1674, 'ISA 3-1', 31, 29, 19, NULL),
(1675, 'ISA 4-1', 31, 28, 19, NULL),
(1676, 'ISA 4-2', 31, 28, 19, NULL),
(1677, 'ISA 6-1', 31, 28, 19, NULL),
(1678, 'ISA 7-1', 31, 28, 19, NULL),
(1679, 'ISA 7-2', 31, 29, 19, NULL),
(1680, 'IM 9-1', 31, 29, 6, NULL),
(1681, 'Estadía', 31, 28, 6, NULL),
(1682, 'IM Nivelación', 31, 29, 9, NULL),
(1683, 'ITI 1-1 (sin inglés)', 31, 28, 7, NULL),
(1684, 'ITI 1-2', 31, 28, 7, NULL),
(1685, 'ITI 1-3', 31, 29, 7, NULL),
(1686, 'ITI 3-1 (Inglés comp. IM)', 31, 29, 7, NULL),
(1687, 'ITI 4-1', 31, 28, 7, NULL),
(1688, 'ITI 4-2', 31, 28, 7, NULL),
(1689, 'ITI 4-3', 31, 29, 7, NULL),
(1690, 'ITI 6-1', 31, 29, 7, NULL),
(1692, 'ITI 7-1', 31, 28, 7, NULL),
(1693, 'ITI 7-2', 31, 29, 7, NULL),
(1694, 'REC ULT UNIDAD', 31, 28, 19, NULL),
(1695, 'INGLES COMPARTIDO', 31, 28, 19, NULL),
(1696, 'ITI 9-1', 31, 29, 7, NULL),
(1697, 'ESTANCIAS Y ESTADÍAS', 31, 28, 7, NULL),
(1699, 'ISA - ITI', 31, 29, 9, NULL),
(1700, 'PyMES 10-1', 31, 28, 10, NULL),
(1701, 'ESTANCIAS', 31, 28, 10, NULL),
(1702, 'RECURSAMIENTOS ÚLTIMA UNIDAD', 31, 28, 10, NULL),
(1703, 'Rec Ult unidad', 31, 28, 6, NULL),
(1704, 'Cuarto', 31, 28, 20, NULL),
(1705, 'Distancia', 31, 28, 7, NULL),
(1706, 'ISA 10-1', 31, 28, 19, NULL),
(1707, 'test', 21, NULL, 23, NULL),
(1708, 'Primero', 33, 28, 6, NULL),
(1709, 'Carga de prueba creada por MR', 34, 28, 6, NULL),
(1710, 'ITI 1-1', 34, NULL, 7, NULL),
(2709, '', 33, NULL, 6, NULL),
(3709, 'SEPTIMO_PRUEBA', 33, 28, 7, NULL),
(3710, 'prueba_est', 35, 28, 7, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarescarrera`
--

CREATE TABLE `escolarescarrera` (
  `idcarrera` int(11) NOT NULL,
  `nombre` varchar(100) CHARACTER SET utf8 NOT NULL,
  `idDirector` int(11) DEFAULT NULL,
  `Descripcion` varchar(300) CHARACTER SET utf8 DEFAULT NULL,
  `siglas` varchar(10) NOT NULL,
  `idGradoAcademico` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolarescarrera`
--

INSERT INTO `escolarescarrera` (`idcarrera`, `nombre`, `idDirector`, `Descripcion`, `siglas`, `idGradoAcademico`) VALUES
(1, 'INGENIERÍA MECATRÓNICA', 54, 'ENCARGADO DE LA DIRECCIÓN DEL PROGRAMA EDUCATIVO DE INGENIERÍA MECATRÓNICA', 'IM', 94),
(2, 'INGENIERÍA EN TECNOLOGÍAS DE LA INFORMACIÓN', 3, 'ENCARGADO DE LA DIRECCIÓN DEL PROGRAMA EDUCATIVO DE INGENIERÍA EN TECNOLOGÍAS DE LA INFORMACIÓN', 'ITI', 94),
(3, 'INGENIERÍA EN TECNOLOGÍAS DE MANUFACTURA', 180, 'COORDINADORA DEL PROGRAMA EDUCATIVO DE INGENIERÍA EN TECNOLOGÍAS DE MANUFACTURA', 'ITM', 130),
(4, 'MAESTRÍA EN INGENIERÍA ESPECIALIDAD MECATRÓNICA', 172, 'ENCARGADO DE LA DIRECCIÓN DE POSGRADO', 'MIM', 94),
(5, 'MAESTRÍA EN INGENIERÍA ESPECIALIDAD TECNOLOGÍAS DE LA INFORMACIÓN', 172, 'ENCARGADO DE LA DIRECCIÓN DE POSGRADO', 'MITI', 94),
(6, 'NIVELACIÓN ACADÉMICA', 103, 'SECRETARIO ADMINISTRATIVO', 'NA', 94),
(7, 'LICENCIATURA EN ADMINISTRACIÓN Y GESTIÓN DE PEQUEÑAS Y MEDIANAS EMPRESAS', 251, 'DIRECTOR DEL PROGRAMA EDUCATIVO DE LICENCIATURA EN ADMINISTRACIÓN Y GESTIÓN DE PYMES', 'PYMES', 91),
(9, 'IDIOMAS', 22, 'CURSOS DE IDIOMAS', 'ID', 114),
(10, 'CURSO PROPEDÉUTICO', 0, '', 'C. PROP', 0),
(11, 'INGENIERÍA EN SISTEMAS AUTOMOTRICES', 68, 'DIRECTOR DEL PROGRAMA EDUCATIVO DE INGENIERÍA EN SISTEMAS AUTOMOTRICES.', 'ISA', 92),
(12, 'MAESTRÍA EN INGENIERÍA', 172, 'ENCARGADO DE LA DIRECCIÓN DE POSGRADO', 'MI', 94),
(13, 'MAESTRÍA EN ENERGÍAS RENOVABLES', 34, 'ENCARGADO DE LA DIRECCIÓN DEL PROGRAMA EDUCATIVO DE MAESTRÍA EN ENERGÍAS RENOVABLES', 'MER', 94),
(14, 'PROFESIONAL ASOCIADO EN ING. INDUSTRIAL', 180, '', 'PA ING IND', 92),
(15, 'LICENCIATURA EN ADMINISTRACION Y GESTION EMPRESARIAL', 257, '', 'LAyGE-2018', 154);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresciclos`
--

CREATE TABLE `escolaresciclos` (
  `idciclo` int(11) NOT NULL,
  `Ciclo` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarescompetenciasporciclo`
--

CREATE TABLE `escolarescompetenciasporciclo` (
  `idCompetencia` int(11) NOT NULL,
  `Competencia` longtext NOT NULL,
  `idPlanDeEstudios` int(11) NOT NULL,
  `NoCiclo` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresconfiguracionhorasgrupos`
--

CREATE TABLE `escolaresconfiguracionhorasgrupos` (
  `idConfiguracionHorasGrupos` int(11) NOT NULL,
  `rangoHoraInicio` time(5) NOT NULL,
  `rangoHoraFin` time(5) NOT NULL,
  `minutos` smallint(6) NOT NULL,
  `tipo` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarescuatrimestre`
--

CREATE TABLE `escolarescuatrimestre` (
  `idcuatrimestre` int(11) NOT NULL,
  `clave` varchar(3) CHARACTER SET utf8 NOT NULL,
  `cuatrimestre` varchar(50) CHARACTER SET utf8 NOT NULL,
  `estatus` tinyint(3) UNSIGNED NOT NULL,
  `fechaInicio` date DEFAULT NULL,
  `fechaFin` date DEFAULT NULL,
  `ciclo_escolar` varchar(10) CHARACTER SET utf8 NOT NULL,
  `abreviado` varchar(50) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolarescuatrimestre`
--

INSERT INTO `escolarescuatrimestre` (`idcuatrimestre`, `clave`, `cuatrimestre`, `estatus`, `fechaInicio`, `fechaFin`, `ciclo_escolar`, `abreviado`) VALUES
(1, '073', 'SEPTIEMBRE-DICIEMBRE 2007', 47, '2007-08-27', '2007-12-20', '2007-2008', 'SEP-DIC 2007'),
(2, '081', 'ENERO-ABRIL 2008', 47, '2008-01-07', '2008-05-02', '2007-2008', 'ENE-ABR 2008'),
(3, '082', 'MAYO-AGOSTO 2008', 47, '2008-05-05', '2008-08-29', '2007-2008', 'MAY-AGO 2008'),
(4, '083', 'SEPTIEMBRE-DICIEMBRE 2008', 47, '2008-09-01', '2008-12-19', '2008-2009', 'SEP-DIC 2008'),
(5, '091', 'ENERO-ABRIL 2009', 47, '2009-01-05', '2009-04-24', '2008-2009', 'ENE-ABR 2009'),
(6, '092', 'MAYO - AGOSTO 2009', 47, '2009-05-07', '2009-08-29', '2008-2009', 'MAY-AGO 2009'),
(7, '093', 'SEPTIEMBRE-DICIEMBRE 2009', 47, '2009-08-31', '2009-12-16', '2009-2010', 'SEP-DIC 2009'),
(8, '101', 'ENERO - ABRIL 2010', 47, '2010-01-06', '2010-04-30', '2009-2010', 'ENE-ABR 2010'),
(9, '102', 'MAYO-AGOSTO 2010', 47, '2010-05-03', '2010-08-26', '2009-2010', 'MAY-AGO 2010'),
(10, '103', 'SEPTIEMBRE-DICIEMBRE 2010', 47, '2010-08-30', '2010-12-16', '2010-2011', 'SEP-DIC 2010'),
(11, '111', 'ENERO-ABRIL 2011', 47, '2011-01-03', '2011-04-19', '2010-2011', 'ENE-ABR 2011'),
(12, '112', 'MAYO-AGOSTO 2011', 47, '2011-04-25', '2011-08-24', '2010-2011', 'MAY-AGO 2011'),
(13, '113', 'SEPTIEMBRE-DICIEMBRE 2011', 47, '2011-08-29', '2011-12-14', '2011-2012', 'SEP-DIC 2011'),
(14, '121', 'ENERO-ABRIL 2012', 47, '2012-01-04', '2012-04-20', '2011-2012', 'ENE-ABR 2012'),
(15, '122', 'MAYO-AGOSTO 2012', 47, '2012-04-30', '2012-08-24', '2011-2012', 'MAY-AGO 2012'),
(16, '123', 'SEPTIEMBRE-DICIEMBRE 2012', 47, '2012-09-03', '2012-12-12', '2012-2013', 'SEP-DIC 2012'),
(17, '131', 'ENERO-ABRIL 2013', 47, '2013-01-07', '2013-04-19', '2012-2013', 'ENE-ABR 2013'),
(18, '132', 'MAYO-AGOSTO 2013', 47, '2013-04-29', '2013-08-23', '2012-2013', 'MAY-AGO 2013'),
(19, '133', 'SEPTIEMBRE-DICIEMBRE 2013', 47, '2013-09-02', '2013-12-11', '2013-2014', 'SEP-DIC 2013'),
(20, '141', 'ENERO-ABRIL 2014', 47, '2014-01-06', '2014-04-18', '2013-2014', 'ENE-ABR 2014'),
(21, '142', 'MAYO-AGOSTO 2014', 47, '2014-04-28', '2014-08-22', '2013-2014', 'MAY-AGO 2014'),
(22, '143', 'SEPTIEMBRE-DICIEMBRE 2014', 47, '2014-09-01', '2014-12-10', '2014-2015', 'SEP-DIC 2014'),
(23, '151', 'ENERO-ABRIL 2015', 47, '2015-01-05', '2015-04-17', '2014-2015', 'ENE-ABR 2015'),
(24, '152', 'MAYO-AGOSTO 2015', 47, '2015-04-27', '2015-08-21', '2014-2015', 'MAY-AGO 2015'),
(25, '153', 'SEPTIEMBRE-DICIEMBRE 2015', 47, '2015-08-31', '2015-12-09', '2015-2016', 'SEP-DIC 2015'),
(26, '161', 'ENERO-ABRIL 2016', 47, '2016-01-04', '2016-04-22', '2015-2016', 'ENE-ABR 2016'),
(27, '162', 'MAYO-AGOSTO 2016', 47, '2016-05-02', '2016-08-26', '2015-2016', 'MAY-AGO 2016'),
(28, '163', 'SEPTIEMBRE-DICIEMBRE 2016', 47, '2016-09-05', '2016-12-14', '2016-2017', 'SEP-DIC 2016'),
(29, '171', 'ENERO-ABRIL 2017', 47, '2017-01-09', '2017-04-21', '2016-2017', 'ENE-ABR 2017'),
(30, '172', 'MAYO-AGOSTO 2017', 47, '2017-05-02', '2017-08-25', '2016-2017', 'MAY-AGO 2017'),
(31, '173', 'SEPTIEMBRE-DICIEMBRE 2017', 47, '2017-09-04', '2017-12-15', '2017-2018', 'SEP-DIC 2017'),
(32, '181', 'ENERO-ABRIL 2018', 47, '2018-01-08', '2018-07-21', '2017-2018', 'ENE-ABR 2018'),
(33, '182', 'MAYO-AGOSTO 2018', 47, '2018-02-14', '2018-09-20', '2017-2018', 'MAY-AGO 2018'),
(34, '183', 'SEPTIEMBRE-DICIEMBRE 2018', 47, '2018-09-01', '2018-12-23', '2018-2019', 'SEP-DIC 2018'),
(35, '191', 'ENERO-ABRIL 2019', 47, '2019-01-07', '2019-05-01', '2018-2019', 'ENE-ABR 2019'),
(36, '192', 'MAYO-AGOSTO 2019', 46, '2019-01-07', '2019-10-01', '2018-2019', 'MAY-AGO 2019');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarescuatrimestrecreditos`
--

CREATE TABLE `escolarescuatrimestrecreditos` (
  `idCuatrimestreCreditos` smallint(6) NOT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `cuatrimestre` tinyint(3) UNSIGNED NOT NULL,
  `rangoInicio` smallint(6) NOT NULL,
  `rangoFin` smallint(6) NOT NULL,
  `rango1` smallint(6) DEFAULT NULL,
  `rango2` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresdirectoresdecarrera`
--

CREATE TABLE `escolaresdirectoresdecarrera` (
  `idDirectorCarrera` int(11) NOT NULL,
  `idCarrera` int(11) NOT NULL,
  `idPlanDeEstudios` int(11) NOT NULL,
  `idEmpleado` int(11) NOT NULL,
  `Descripcion` varchar(200) CHARACTER SET utf8 NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresdocumentos`
--

CREATE TABLE `escolaresdocumentos` (
  `idDocumento` smallint(6) NOT NULL,
  `Documento` varchar(50) CHARACTER SET utf8 NOT NULL,
  `Descripcion` varchar(300) CHARACTER SET utf8 DEFAULT NULL,
  `Activo` tinyint(4) NOT NULL,
  `simbolo` varchar(10) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresdocumentos`
--

INSERT INTO `escolaresdocumentos` (`idDocumento`, `Documento`, `Descripcion`, `Activo`, `simbolo`) VALUES
(1, 'CERTIFICADO DE BACHILLERATO', 'CERTIFICADO DE BACHILLERATO', 1, NULL),
(2, 'ACTA DE NACIMIENTO', 'ACTA DE NACIMIENTO', 1, NULL),
(3, 'CURP', 'CURP', 1, NULL),
(4, 'FOTOGRAFIA', 'FOTOGRAFIA', 1, NULL),
(5, 'COMPROBANTE DE DOMICILIO', 'COMPROBANTE DE DOMICILIO', 1, NULL),
(6, 'COPIA NOTARIADA DE TÍTULO NIVEL LICENCIATURA', 'COPIA DE TÍTULO EXPEDIDA POR NOTARIO PÚBLICO', 1, NULL),
(7, 'COPIA NOTARIADA DE CERTIFICADO NIVEL LICENCIATURA', 'COPIA DE CERTIFICADO EXPEDIDA POR NOTARIO PÚPLICO', 1, NULL),
(8, 'COPIA DE CERTIFICADO', 'COPIA DE CERTIFICADO', 1, NULL),
(9, 'CONSTANCIA DE BACHILLERATO', 'CONSTANCIA DE BACHILLERATO', 1, NULL),
(10, 'COPIA DE ACTA DE NACIMIENTO', 'COPIA DE ACTA DE NACIMIENTO', 1, NULL),
(11, 'COMPROBANTE DE ESTANCIA LEGAL EN EL PAIS', 'COMPROBANTE DE ESTANCIA LEGAL EN EL PAIS', 1, NULL),
(12, 'OFICIO DE EQUIVALENCIA DE ESTUDIOS', 'OFICIO DE EQUIVALENCIA DE ESTUDIOS', 1, NULL),
(13, 'COPIA NOTARIADA DE CEDULA PROFESIONAL', 'COPIA NOTARIADA DE CEDULA PROFESIONAL', 1, NULL),
(14, 'COPIA DEL NUMERO DE AFILIACION DEL IMSS', 'COPIA DEL NUMERO DE AFILIACION DEL IMSS', 1, NULL),
(15, 'DESIGNACIÓN DE BENEFICIARIOS', 'FORMATO METLIFE', 1, NULL),
(16, 'PÓLIZA DE SEGURO DE VIDA', 'PÓLIZA DE SEGURO DE VIDA', 0, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresdocumentosconfiguracion`
--

CREATE TABLE `escolaresdocumentosconfiguracion` (
  `IdDocumentoConfiguracion` int(11) NOT NULL,
  `IdDocumento` smallint(6) NOT NULL,
  `IdCatalogo` int(11) NOT NULL,
  `Activo` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresdocumentosnotas`
--

CREATE TABLE `escolaresdocumentosnotas` (
  `idDocumentoNotas` smallint(6) NOT NULL,
  `Nota` longtext NOT NULL,
  `visible` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresdocumentosplandeestudio`
--

CREATE TABLE `escolaresdocumentosplandeestudio` (
  `idDocumentoPlanDeEstudio` int(11) NOT NULL,
  `idDocumento` int(11) NOT NULL,
  `idPlanDeEstudio` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresdocumentosrecibidos`
--

CREATE TABLE `escolaresdocumentosrecibidos` (
  `IdDocumentoRecibido` int(11) NOT NULL,
  `IdAlumno` int(11) NOT NULL,
  `IdDocumento` smallint(6) NOT NULL,
  `IdCatalogo` int(11) NOT NULL,
  `ruta` varchar(255) DEFAULT NULL,
  `Fecha` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresdocumentosrecibidos`
--

INSERT INTO `escolaresdocumentosrecibidos` (`IdDocumentoRecibido`, `IdAlumno`, `IdDocumento`, `IdCatalogo`, `ruta`, `Fecha`) VALUES
(1, 1, 2, 3, 'documentos/stDvQo378fbBfGUyOPtyKvRSuUZCrOgNUCQBved4.pdf', '2020-01-22 00:00:00'),
(15, 5, 1, 3, 'documentos/NMI5wcrUHn8Xrs1CZi9382FjQrZpsjJpE1y18qat.png', '2020-02-05 21:01:20'),
(16, 5, 2, 3, 'documentos/Tz4fzvzvBpmTCMbnPPCMneyBfZcDJ0EPuieBRdfz.png', '2020-02-05 21:15:29'),
(17, 5, 4, 3, 'documentos/ELKVtH97OQNszwdgYSVIzh78rdrm3ySKjazBM7b8.jpeg', '2020-02-06 19:15:30'),
(18, 5, 3, 3, 'documentos/7Fed3xQYzcRLPwbK1cvDbjRQn8XCT2nuwxCs2Qtn.png', '2020-02-06 19:16:24'),
(19, 5, 1, 3, 'documentos/cELOqxDRYvYcWg17dohJDb1z6Vks7Rngkulc9dkp.jpeg', '2020-02-06 19:18:56'),
(20, 5, 3, 3, 'documentos/GdpM2oZIo7tdFpcUxNwg68QAI2DBdraDlgZZ4A12.png', '2020-02-06 19:31:36'),
(21, 5, 14, 3, 'documentos/Xf7Lg6DiJlkkFV7yzXH5Ovk9G8nYksyrPVSCR5iv.png', '2020-02-06 19:31:51'),
(22, 13, 11, 3, 'documentos/Uy9Nro9fI7AyJazUPwbesB0RAuykPcgs3NREEAiE.pdf', '2020-02-19 17:49:45'),
(23, 14, 2, 3, 'documentos/onW30wAGZctJSeO0YsX8tfjQGm9zOp4TyqLXiOQP.pdf', '2020-02-19 18:30:30'),
(24, 15, 4, 3, 'documentos/K6iYrqfCJyhVgxUGUmGFvFp6hsOdSXYNYvLKdO2y.pdf', '2020-02-19 18:30:44'),
(25, 15, 1, 3, 'documentos/6uCml9lDBmVtglWctvFBT1dJHJbZ8jhSqts16grz.pdf', '2020-02-19 18:35:50'),
(26, 18, 2, 3, '', '2020-02-19 20:48:03'),
(27, 19, 1, 3, '', '2020-02-19 20:54:30'),
(28, 27, 2, 3, '', '2020-02-20 22:25:19'),
(29, 27, 1, 3, '', '2020-02-20 22:28:13'),
(30, 28, 2, 3, 'documentos/T121h2lLsgTeSBc4SJtz4l5HCkhQjImDuq383o04.txt', '2020-02-25 19:16:19'),
(31, 29, 1, 3, 'documentos/KPdMf7wBHTjLIWo2WljHjexvyo4f6yF5qvJvMSTj.png', '2020-03-02 16:50:42'),
(32, 30, 1, 3, 'documentos/gpAJuGZAJubWn162QAAk76kLa6RD9FJOjd9ptwhB.png', '2020-03-03 18:20:46'),
(33, 30, 3, 3, 'documentos/L8BmOW7WtqbkG6LSimYrj4B0xRyXYrFYWYfbgVMN.png', '2020-03-03 18:20:52'),
(34, 30, 1, 3, 'documentos/EdQwawEXlG35Y5Sa4uVykJpcCJXetWGQbDZFP4WM.png', '2020-03-03 18:36:11'),
(35, 30, 4, 3, 'documentos/aqiBPniYMXheNVJ8tQCOJQvqiRM1N5syxpP4tnNo.png', '2020-03-03 18:38:12'),
(36, 24, 1, 3, '', '2020-03-04 16:52:44'),
(37, 30, 1, 3, '', '2020-03-04 16:57:50'),
(38, 30, 1, 3, 'documentos/SKDsCbfUVJZKAG5fCtZ4BeEyKQkeh4Tig5reG6gh.png', '2020-03-04 17:36:21'),
(39, 30, 1, 3, 'documentos/Yes13hshHy0YeWLrEXMEazKqU16rMek8NKzbc9N4.png', '2020-03-04 17:37:08'),
(40, 29, 14, 3, 'documentos/ZA9ZwEObVl7zCTEPf6Mpdm7oMWn7bozfdzAtJhWc.png', '2020-03-04 17:42:55'),
(41, 29, 14, 3, 'documentos/DUaqBl2eQOSizQCWX8x0PfnXOL13gtTu9rzgalSN.png', '2020-03-04 17:44:12'),
(42, 22, 3, 3, 'documentos/bzv4qmTaibKF8EKdGpKLjelfpSNqKW41P4gsjFGn.png', '2020-03-04 17:56:03'),
(43, 22, 4, 3, 'documentos/Sb5CjgdiJq95udMOmNhG4e5ZUIpefIAu1TByowEi.png', '2020-03-04 17:56:32'),
(44, 22, 4, 3, 'documentos/GbSkgPX7QNRuTOnNTOKxfaY5TBcwMmh0u4TQJXnz.png', '2020-03-04 18:02:38'),
(45, 22, 5, 3, '', '2020-03-04 18:03:12'),
(46, 21, 6, 3, 'documentos/vczfmZQDeqYRH2cjo4gm9UzGlHjlvzra8md8yuNH.png', '2020-03-04 18:10:21'),
(47, 21, 9, 3, '', '2020-03-04 18:10:28'),
(48, 21, 13, 3, '', '2020-03-04 18:11:24'),
(49, 30, 14, 3, '', '2020-03-04 19:12:22'),
(50, 35, 1, 3, '', '2020-03-06 04:07:55'),
(51, 28, 3, 3, 'documentos/eN8a61unfEnPDeUhTFW8ho3JGnquD5muWbk33J9p.tex', '2020-03-11 23:14:10'),
(52, 28, 4, 3, 'documentos/B4KdMY2ovMrGhbHYDC9cc2NM7jn4RvHsJetcgyCA.pdf', '2020-03-11 23:17:16'),
(53, 70, 1, 3, 'documentos/IO61UYTjpJRSaHIucuyYb3tieileKhiehCpyYzxv.png', '2020-03-26 19:15:21'),
(54, 74, 1, 3, 'documentos/mBRyj7X9sKdmafXpGGJWpo7cde0lqJICR3OKJObW.png', '2020-03-26 19:34:50'),
(55, 82, 1, 3, 'documentos/VMZX4yMCnkNUnrC4EqN9wkjOhzzo5AYlPXEK60wR.png', '2020-03-28 01:24:50'),
(56, 82, 3, 3, '', '2020-03-28 01:24:57'),
(57, 82, 4, 3, 'documentos/LxVa0zzQDH7l3M43oasXcEMJ1146thCDVXk0IJ76.jpeg', '2020-03-28 01:25:20'),
(58, 82, 10, 3, 'documentos/ZyufjkuDvapYPJMOiTuJdWdCHuUQWCNS5fFggQvt.png', '2020-03-28 01:25:47'),
(59, 82, 5, 3, '', '2020-03-28 01:26:00'),
(60, 82, 9, 3, 'documentos/S1UKZIELTohphGDOnDTZ3EDFRWhy34ozqbFBed5E.png', '2020-03-28 01:26:20'),
(61, 83, 4, 3, 'documentos/pZoWDPOlExMpGK68ckMOoEe74oWy9prYgumNaGuw.png', '2020-03-30 02:51:35'),
(62, 83, 4, 3, '', '2020-03-30 02:52:55'),
(63, 83, 4, 3, '', '2020-03-30 02:54:07'),
(64, 84, 1, 3, 'documentos/3LGGN1a9lLELkR2d3o05l6UFnVuTZ2Q976wcq871.pdf', '2020-04-04 23:55:35'),
(65, 84, 3, 3, 'documentos/K0Vn4reUw12rGUHQzTOcyB6VWE6mGl8HpqZEIej3.png', '2020-04-04 23:56:05'),
(66, 84, 4, 3, 'documentos/Bg4GHF29u1Lk1FTrRgnNYQoho2SSK7PTAB6vDlIs.png', '2020-04-04 23:56:30'),
(67, 84, 13, 3, 'documentos/kSWa8VNrVT8k9iBQGu5elN9kb8T4Rap4n4aq48dK.png', '2020-04-04 23:56:44'),
(68, 84, 15, 3, 'documentos/oHxdsv10HSF1hTxMpxpcmZBh0PbyFsl0WqfU4Ghw.png', '2020-04-04 23:57:06'),
(69, 71, 1, 3, 'documentos/UoEq489HGZ4znP2RnLgDH1kpXYHsdoEgPgXKnmsa.pdf', '2020-04-10 19:58:05');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresedificios`
--

CREATE TABLE `escolaresedificios` (
  `idEdificio` smallint(6) NOT NULL,
  `Edificio` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresesc_procedencia`
--

CREATE TABLE `escolaresesc_procedencia` (
  `idesc_procedencia` int(11) NOT NULL,
  `nombre` varchar(255) CHARACTER SET utf8 NOT NULL,
  `localidad` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `idmunicipio` int(11) NOT NULL,
  `idestado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresesc_procedencia`
--

INSERT INTO `escolaresesc_procedencia` (`idesc_procedencia`, `nombre`, `localidad`, `idmunicipio`, `idestado`) VALUES
(1, 'CENTRO DE BACHILLERATO TECNOLÓGICO AGROPECUARIO--NÚM. 270', 'NULL', 223, 28),
(2, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 015', '', 2003, 28),
(3, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 024', '', 2033, 28),
(4, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 030', '', 2133, 30),
(5, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 073', '', 2025, 28),
(6, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 098', '', 2035, 28),
(7, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 105', '', 1995, 28),
(8, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 119', '', 2033, 28),
(9, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 208', '', 1993, 28),
(10, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 210', '', 2010, 28),
(11, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 219', '', 2022, 28),
(12, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 236', '', 2033, 28),
(13, 'CENTRO DE ESTUDIOS DE BACHILLERATO -- MTRO. LAURO AGUIRRE', 'SAN JOSÉ DE LAS FLORES', 2008, 28),
(14, 'CENTRO DE ESTUDIOS TECNOLÓGICOS INDUSTRIAL Y DE SERVICIOS -- NÚM. 106', '', 1841, 24),
(15, 'CENTRO DE ESTUDIOS TECNOLÓGICOS INDUSTRIAL Y DE SERVICIOS -- NÚM. 129', '', 2027, 28),
(16, 'COLEGIO DE BACHILLERES DEL ESTADO DE SAN LUIS POTOSÍ -- NÚM. 006', '', 1842, 24),
(17, 'COLEGIO DE BACHILLERES DEL ESTADO DE SAN LUIS POTOSÍ -- NÚM. 015', '', 1844, 24),
(18, 'COLEGIO DE BACHILLERES DEL ESTADO DE TAMAULIPAS -- NÚM. 005 VICTORIA', '', 2033, 28),
(19, 'COLEGIO DE BACHILLERES DEL ESTADO DE TAMAULIPAS -- NÚM. 012 LLERA', '', 2012, 28),
(20, 'COLEGIO DE BACHILLERES DEL ESTADO DE TAMAULIPAS -- NÚM. 016 SOTO LA MARINA', '', 2029, 28),
(21, 'COLEGIO DE BACHILLERES DEL ESTADO DE VERACRUZ -- NÚM. 038', '', 2177, 30),
(22, 'COLEGIO JOSÉ DE ESCANDÓN LA SALLE', '', 2033, 28),
(23, 'COLEGIO NACIONAL DE EDUCACIÓN PROFESIONAL TÉCNICA -- NÚM. 149 SAN MARTÍN TEXMELU', 'SANTA MARÍA MOYOTZINGO', 1712, 21),
(24, 'COLEGIO NACIONAL DE EDUCACIÓN PROFESIONAL TÉCNICA -- NÚM. 172 CD. VICTORIA', '', 2033, 28),
(25, 'ESCUELA PREPARATORIA , UAT -- 11', '', 2003, 28),
(26, 'EXTRANJERO -- EXTRANJERO', 'EXTRANJERO', 2476, 33),
(27, 'INSTITUTO DE CIENCIAS Y ESTUDIOS SUPERIORES DE TAMAULIPAS, A.C. -- CAMPUS VICTOR', '', 2033, 28),
(28, 'INSTITUTO EN COMPUTACIÓN ELECTRÓNICA E INFORMÁTICA DE TAMAULIPAS, A.C.', '', 2033, 28),
(29, 'INSTITUTO IBEROAMERICANO DE IDIOMAS', '', 2033, 28),
(30, 'INSTITUTO TAMAULIPECO DE CAPACITACIÓN PARA EL EMPLEO -- UNIDAD CIUDAD VICTORIA', '', 2033, 28),
(31, 'PREPARATORIA FEDERAL POR COOPERACIÓN No. 2 -- LIC. ANICETO VILLANUEVA MARTÍNEZ', '', 2033, 28),
(32, 'PREPARATORIA FEDERALIZADA -- NÚM.001 ING. MARTE R. GÓMEZ', '', 2033, 28),
(33, 'PREPARATORIA, UANL -- NÚM. 006 MONTEMORELOS', '', 981, 19),
(34, 'COLEGIO NACIONAL DE EDUCACIÓN PROFESIONAL TÉCNICA -- NÚM. 055 MATAMOROS', '', 2014, 28),
(35, 'CENTRO DE ESTUDIOS TECNOLÓGICOS INDUSTRIAL Y DE SERVICIOS -- NÚM. 133', '', 2217, 30),
(36, 'CENTRO DE BACHILLERATO TECNOLÓGICO AGROPECUARIO--NÚM. 055', '', 2022, 28),
(37, 'COLEGIO DE BACHILLERES DEL ESTADO DE TAMAULIPAS -- NÚM. 010 JIMÉNEZ', '', 2011, 28),
(38, 'ESCUELA PREPARATORIA FEDERALIZADA NOCTURNA PARA TRABAJADORES CARLOS ADRIAN AVIL', '', 2033, 28),
(39, 'CENTRO DE EDUCACIÓN MEDIA SUPERIOR A DISTANCIA EN EL EDO. TAMAULIPAS -- CASAS', '', 2000, 28),
(40, 'CENTRO DE BACHILLERATO TECNOLÓGICO INDUSTRIAL Y DE SERVICIOS -- NÚM. 007', '', 2024, 28),
(41, 'COLEGIO DE BACHILLERES DEL ESTADO DE TAMAULIPAS -- NÚM. 003 MANTE', '', 2003, 28),
(42, 'INSTITUTO TECNOLÓGICO DE CD. VICTORIA', ' ', 2033, 28),
(43, 'INSTITUTO TECNOLÓGICO DE CD. MADERO', ' ', 2001, 28),
(44, 'INSTITUTO POLITÉCNICO NACIONAL- ESIME', ' ', 260, 9),
(45, 'INSTITUTO TECNOLÓGICO Y DE ESTUDIOS SUPERIORES DE MONTERREY', ' ', 982, 19),
(47, 'UNIVERSIDAD AUTÓNOMA DE TAMAULIPAS-UAM AGRONOMÍA Y CIENCIAS', ' ', 2033, 28),
(48, 'UNIVERSIDAD AUTÓNOMA DE TAMAULIPAS- UAM DE COMERCIO Y ADMINISTRACIÓN VICTORIA', ' ', 2033, 28),
(49, 'CENTRO DE BACHILLERATO TECNOLÓGICO AGROPECUARIO--NÚM. 275', ' ', 2024, 28),
(50, 'ACUERDO 286', ' ', 260, 9),
(51, 'CENTRO DE EDUCACIÓN MEDIA SUPERIOR A DISTANCIA EN EL EDO. TAMAULIPAS--10', ' ', 2018, 28);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresgrupo`
--

CREATE TABLE `escolaresgrupo` (
  `idgrupo` int(11) NOT NULL,
  `clave` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `idmateria` int(11) NOT NULL,
  `idMateriaReferencia` int(11) DEFAULT NULL,
  `idempleado` int(11) DEFAULT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `idcarga` int(11) DEFAULT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `capacidad` tinyint(3) UNSIGNED NOT NULL,
  `totalAlumnos` tinyint(3) UNSIGNED NOT NULL,
  `calificado` tinyint(4) NOT NULL,
  `activo` tinyint(4) NOT NULL,
  `esOptativa` tinyint(4) NOT NULL,
  `claveGrupoMixto` int(11) NOT NULL,
  `idProfesorAdjunto` int(11) NOT NULL,
  `Configuracion` longtext DEFAULT NULL,
  `Recursamiento` tinyint(4) NOT NULL,
  `Modalidad` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresgrupo`
--

INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(46, 'IITI', 59, NULL, 101, 1, NULL, 2, 30, 28, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(55, 'IITI', 59, NULL, 101, 1, NULL, 2, 30, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(64, 'IITI', 59, NULL, 26, 1, NULL, 2, 31, 31, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(72, 'IITI', 59, NULL, 26, 1, NULL, 2, 30, 18, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(76, 'IITI', 59, NULL, 104, 1, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(119, 'ITI-11', 90, NULL, 21, 2, NULL, 2, 30, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(120, 'ITI-11', 3, NULL, 100, 2, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(121, 'ITI-23', 78, NULL, 43, 2, NULL, 2, 30, 28, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(122, 'ITI-21', 86, NULL, 114, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(123, 'ITI-21', 42, NULL, 104, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(124, 'ITI-12', 14, NULL, 23, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(125, 'ITI-11', 40, NULL, 111, 2, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(126, 'ITI-REC', 12, NULL, 56, 2, NULL, 2, 30, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(127, 'ITI-22', 90, NULL, 113, 2, NULL, 2, 30, 20, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(128, 'ITI-12', 90, NULL, 100, 2, NULL, 2, 32, 32, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(129, 'ITI-11', 14, NULL, 93, 2, NULL, 2, 30, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(130, 'ITI-22', 86, NULL, 114, 2, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(131, 'ITI-REC', 3, NULL, 10, 2, NULL, 2, 30, 8, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(132, 'ITI-12', 65, NULL, 129, 2, NULL, 2, 31, 32, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(133, 'ITI-22', 42, NULL, 104, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(134, 'ITI-23', 104, NULL, 23, 2, NULL, 2, 31, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(135, 'ITI-21', 50, NULL, 22, 2, NULL, 2, 30, 28, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(136, 'ITI-11', 108, NULL, 56, 2, NULL, 2, 30, 28, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(137, 'ITI-21', 41, NULL, 72, 2, NULL, 2, 30, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(138, 'ITI-11', 49, NULL, 81, 2, NULL, 2, 35, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(139, 'ITI-23', 90, NULL, 100, 2, NULL, 2, 32, 32, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(140, 'ITI-21', 104, NULL, 93, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(141, 'ITI-12', 49, NULL, 74, 2, NULL, 2, 33, 33, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(142, 'ITI-23', 86, NULL, 114, 2, NULL, 2, 30, 28, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(143, 'ITI-REC', 66, NULL, 10, 2, NULL, 2, 34, 31, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(144, 'ITI-12', 40, NULL, 15, 2, NULL, 2, 33, 33, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(145, 'ITI-23', 42, NULL, 104, 2, NULL, 2, 30, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(146, 'ITI-11', 65, NULL, 43, 2, NULL, 2, 30, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(147, 'ITI-22', 50, NULL, 22, 2, NULL, 2, 30, 21, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(148, 'ITI-21', 108, NULL, 56, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(149, 'ITI-22', 41, NULL, 72, 2, NULL, 2, 30, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(150, 'ITI-22', 104, NULL, 93, 2, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(151, 'ITI-23', 50, NULL, 74, 2, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(152, 'ITI-REC', 49, NULL, 25, 2, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(153, 'ITI-21', 78, NULL, 43, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(154, 'ITI-11', 59, NULL, 101, 2, NULL, 2, 30, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(155, 'ITI-22', 78, NULL, 56, 2, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(156, 'ITI-23', 41, NULL, 72, 2, NULL, 2, 35, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(157, 'ITI-REC', 2, NULL, 68, 2, NULL, 2, 34, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(158, 'ITI-12', 3, NULL, 66, 2, NULL, 2, 32, 32, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(159, 'ITI-22', 108, NULL, 43, 2, NULL, 2, 32, 31, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(160, 'ITI-12', 59, NULL, 101, 2, NULL, 2, 31, 32, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(161, 'ITI-23', 108, NULL, 56, 2, NULL, 2, 32, 31, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(162, 'ITI-21', 90, NULL, 113, 2, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(194, 'ITI204', 104, NULL, 23, 3, NULL, 2, 26, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(195, 'ITI208', 50, NULL, 22, 3, NULL, 2, 15, 13, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(196, 'ITI216', 100, NULL, 101, 3, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(197, 'ITI212', 35, NULL, 72, 3, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(198, 'ITI221', 39, NULL, 105, 3, NULL, 2, 30, 31, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(199, 'ITI235', 86, NULL, 80, 3, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(200, 'ITI207', 50, NULL, 74, 3, NULL, 2, 26, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(201, 'ITI213', 91, NULL, 43, 3, NULL, 2, 30, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(202, 'ITI231', 50, NULL, 22, 3, NULL, 2, 10, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(203, 'ITI217', 100, NULL, 101, 3, NULL, 2, 30, 31, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(204, 'ITI205', 51, NULL, 46, 3, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(205, 'ITI215', 91, NULL, 56, 3, NULL, 2, 30, 14, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(206, 'ITI222', 3, NULL, 72, 3, NULL, 2, 30, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(207, 'ITI229', 42, NULL, 105, 3, NULL, 2, 30, 32, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(208, 'ITI218', 85, NULL, 113, 3, NULL, 2, 30, 12, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(209, 'ITI202', 62, NULL, 93, 3, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(210, 'ITI230', 65, NULL, 43, 3, NULL, 2, 30, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(211, 'ITI236', 49, NULL, 22, 3, NULL, 2, 15, 4, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(212, 'ITI227', 78, NULL, 56, 3, NULL, 2, 30, 34, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(213, 'ITI214', 62, NULL, 93, 3, NULL, 2, 15, 9, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(214, 'ITI209', 103, NULL, 100, 3, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(215, 'ITI234', 78, NULL, 43, 3, NULL, 2, 30, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(216, 'ITI224', 66, NULL, 10, 3, NULL, 2, 30, 11, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(217, 'ITI233', 104, NULL, 93, 3, NULL, 2, 10, 6, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(218, 'ITI219', 85, NULL, 80, 3, NULL, 2, 30, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(219, 'ITI210', 103, NULL, 100, 3, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(220, 'ITI226', 12, NULL, 2, 3, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(221, 'ITI225', 86, NULL, 10, 3, NULL, 2, 30, 28, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(222, 'ITI203', 62, NULL, 23, 3, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(223, 'ITI223', 90, NULL, 30, 3, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(224, 'ITI211', 35, NULL, 72, 3, NULL, 2, 30, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(225, 'ITI220', 39, NULL, 105, 3, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(226, 'ITI228', 41, NULL, 80, 3, NULL, 2, 30, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(227, 'ITI206', 51, NULL, 74, 3, NULL, 2, 30, 12, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(328, 'ITI-15', 65, NULL, 4, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(329, 'ITI-11', 108, NULL, 11, 4, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(330, 'ITI-17', 14, NULL, 118, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(332, 'ITI-16', 108, NULL, 56, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(335, 'ITI-17', 40, NULL, 7, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(336, 'ITI-13', 14, NULL, 89, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(338, 'ITI-17', 49, NULL, 74, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(340, 'ITI-16', 14, NULL, 85, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(342, 'ITI-11', 49, NULL, 95, 4, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(344, 'ITI-15', 108, NULL, 43, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(345, 'ITI-16', 65, NULL, 4, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(347, 'ITI-13', 108, NULL, 11, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(348, 'ITI-11', 59, NULL, 64, 4, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(353, 'ITI-14', 108, NULL, 125, 4, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(354, 'ITI-11', 40, NULL, 115, 4, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(360, 'ITI-14', 49, NULL, 95, 4, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(363, 'ITI-15', 59, NULL, 11, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(364, 'ITI-12', 59, NULL, 64, 4, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(365, 'ITI-12', 49, NULL, 50, 4, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(369, 'ITI-15', 40, NULL, 125, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(370, 'ITI-12', 40, NULL, 115, 4, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(371, 'ITI-11', 14, NULL, 13, 4, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(374, 'ITI-11', 65, NULL, 82, 4, NULL, 2, 30, 30, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(376, 'ITI-14', 3, NULL, 52, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(377, 'ITI-15', 49, NULL, 95, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(379, 'ITI-13', 3, NULL, 100, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(381, 'ITI-17', 65, NULL, 122, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(382, 'ITI-12', 65, NULL, 398, 4, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(383, 'ITI-13', 59, NULL, 64, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(385, 'ITI-13', 49, NULL, 46, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(386, 'ITI-16', 59, NULL, 125, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(387, 'ITI-14', 40, NULL, 115, 4, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(388, 'ITI-14', 14, NULL, 13, 4, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(390, 'ITI-12', 3, NULL, 72, 4, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(392, 'ITI-16', 40, NULL, 80, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(393, 'ITI-16', 3, NULL, 82, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(394, 'ITI-13', 40, NULL, 7, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(395, 'ITI-16', 49, NULL, 121, 4, NULL, 2, 30, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(397, 'ITI-17', 108, NULL, 100, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(399, 'ITI-13', 65, NULL, 398, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(400, 'ITI-17', 3, NULL, 64, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(405, 'ITI-15', 3, NULL, 72, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(406, 'ITI-17', 59, NULL, 80, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(408, 'ITI-14', 59, NULL, 7, 4, NULL, 2, 30, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(409, 'ITI-12', 14, NULL, 89, 4, NULL, 2, 30, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(410, 'ITI-14', 65, NULL, 398, 4, NULL, 2, 30, 24, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(411, 'ITI-15', 14, NULL, 85, 4, NULL, 2, 30, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1251, 'ITI-001', 3, 0, 100, 10, 84, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1252, 'ITI-002', 49, 0, 143, 10, 84, 7, 35, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1253, 'ITI-003', 156, 0, 120, 10, 84, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1254, 'ITI-004', 40, 0, 1, 10, 84, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1255, 'ITI-005', 206, 0, 56, 10, 84, 7, 30, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1256, 'ITI-006', 59, 0, 7, 10, 84, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1257, 'ITI-007', 65, 0, 144, 10, 84, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1268, 'ITI-008', 206, 0, 84, 10, 86, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1269, 'ITI-009', 3, 0, 100, 10, 86, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1270, 'ITI-010', 49, 0, 143, 10, 86, 7, 35, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1271, 'ITI-011', 40, 0, 1, 10, 86, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1272, 'ITI-012', 156, 0, 78, 10, 86, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1273, 'ITI-013', 65, 0, 144, 10, 86, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1274, 'ITI-014', 59, 0, 7, 10, 86, 7, 35, 37, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1275, 'ITI-015', 206, 0, 77, 10, 87, 7, 35, 36, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1276, 'ITI-016', 156, 0, 85, 10, 87, 7, 35, 36, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1278, 'ITI-018', 3, 0, 105, 10, 87, 7, 35, 36, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1279, 'ITI-019', 49, 0, 143, 10, 87, 7, 35, 33, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1281, 'ITI-021', 59, 0, 7, 10, 87, 7, 35, 36, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1282, 'ITI-022', 51, 0, 62, 10, 88, 2, 15, 1, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1283, 'ITI-023', 12, 0, 138, 10, 89, 2, 22, 21, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1284, 'ITI-024', 86, 0, 60, 10, 89, 2, 35, 26, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1287, 'ITI-027', 91, 0, 56, 10, 91, 2, 35, 14, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1288, 'ITI-028', 103, 0, 138, 10, 91, 2, 35, 38, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1289, 'ITI-029', 85, 0, 149, 10, 91, 2, 30, 36, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1290, 'ITI-030', 51, 0, 25, 10, 92, 2, 20, 19, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1291, 'ITI-031', 39, 0, 105, 10, 92, 2, 35, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1292, 'ITI-032', 91, 0, 100, 10, 92, 2, 35, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1293, 'ITI-033', 14, 0, 118, 10, 92, 2, 35, 5, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1294, 'ITI-034', 35, 0, 125, 10, 93, 2, 35, 27, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1295, 'ITI-035', 100, 0, 7, 10, 93, 2, 35, 31, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1296, 'ITI-036', 87, 0, 145, 10, 93, 2, 35, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1297, 'ITI-037', 52, 0, 102, 10, 93, 2, 35, 34, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1298, 'ITI-038', 79, 0, 14, 10, 93, 2, 35, 35, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1299, 'ITI-039', 62, 0, 23, 10, 94, 2, 35, 34, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1300, 'ITI-040', 79, 0, 111, 10, 94, 2, 35, 11, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1301, 'ITI-041', 87, 0, 145, 10, 95, 2, 35, 18, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1302, 'ITI-042', 52, 0, 25, 10, 95, 2, 20, 16, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1303, 'ITI-043', 35, 0, 125, 10, 95, 2, 35, 7, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1304, 'ITI-044', 100, 0, 84, 10, 95, 2, 35, 12, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1305, 'ITI-045', 2, 0, 131, 10, 96, 2, 5, 4, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1306, 'ITI-046', 53, 0, 102, 10, 96, 2, 10, 5, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1307, 'ITI-047', 22, 0, 64, 10, 97, 2, 35, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1309, 'ITI-049', 111, 0, 146, 10, 97, 2, 35, 9, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1310, 'ITI-050', 92, 0, 14, 10, 98, 2, 35, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1312, 'ITI-052', 23, 0, 138, 10, 98, 2, 35, 29, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1313, 'ITI-053', 9, 0, 149, 10, 99, 2, 25, 21, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1314, 'ITI-054', 106, 0, 56, 10, 99, 2, 30, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1315, 'ITI-055', 88, 0, 64, 10, 99, 2, 35, 13, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1316, 'ITI-056', 55, 0, 25, 10, 99, 2, 15, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1322, 'ITI-058', 23, 0, 147, 10, 100, 2, 35, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1323, 'ITI-059', 55, 0, 22, 10, 100, 2, 35, 16, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1324, 'ITI-060', 58, 0, 64, 10, 100, 2, 35, 32, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1325, 'ITI-061', 107, 0, 52, 10, 100, 2, 35, 20, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1326, 'ITI-062', 106, 0, 14, 10, 100, 2, 35, 23, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1327, 'ITI-063', 144, 0, 105, 10, 101, 2, 35, 8, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1333, 'ITI-065', 72, 0, 54, 10, 102, 2, 5, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1335, 'ITI-067', 56, 0, 141, 10, 102, 2, 15, 7, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1336, 'ITI-068', 135, 0, 95, 10, 102, 2, 15, 6, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1339, 'ITI-057', 13, 0, 136, 10, 104, 2, 17, 16, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1385, 'ITI-051', 80, 0, 132, 10, 118, 2, 25, 19, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1401, 'ITI-020', 40, 0, 84, 10, 87, 7, 35, 36, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1402, 'ITI-017', 65, 0, 88, 10, 87, 7, 35, 36, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1404, 'ITI-048', 21, 0, 125, 10, 97, 2, 35, 15, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1405, 'ITI-064', 88, 0, 145, 10, 123, 2, 35, 9, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1407, 'ITI-069', 54, 0, 141, 10, 124, 2, 10, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1411, 'ITI-026', 100, 0, 137, 10, 90, 2, 35, 20, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1412, 'ITI-025', 35, 0, 137, 10, 90, 2, 35, 19, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1413, 'ITI-066', 152, 0, 82, 10, 101, 2, 35, 11, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1414, 'ITI-070', 101, 0, 82, 10, 101, 2, 35, 7, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1416, 'ITI-081', 124, 0, 43, 10, 127, 2, 30, 13, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1417, 'ITI-071', 62, 0, 23, 10, 94, 2, 35, 34, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1419, 'ITI-072', 78, 0, 84, 10, 129, 2, 2, 3, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1420, 'ITI-073', 3, 0, 100, 10, 129, 2, 2, 3, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1421, 'ITI-074', 78, 0, 56, 10, 129, 2, 6, 5, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1422, 'ITI-075', 59, 0, 7, 10, 129, 2, 1, 2, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1423, 'ITI-076', 59, 0, 7, 10, 129, 2, 0, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1424, 'ITI-077', 72, 0, 65, 10, 130, 2, 2, 1, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1425, 'ITI-078', 112, 0, 85, 10, 131, 2, 2, 2, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1426, 'ITI-079', 40, 0, 1, 10, 131, 2, 0, 1, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1427, 'ITI-080', 9, 0, 123, 10, 132, 2, 1, 2, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1438, 'ITI-082', 143, 0, 60, 10, 139, 2, 30, 6, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1439, 'ITI-083', 7, 0, 144, 10, 139, 2, 30, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1440, 'ITI-084', 13, 0, 118, 10, 140, 2, 20, 20, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1443, 'ITI-085', 54, 0, 95, 10, 143, 2, 28, 25, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1457, 'ITI-086', 114, 0, 105, 10, 147, 2, 2, 1, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1462, 'ITI-086', 103, 0, 149, 10, 89, 2, 30, 11, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1463, 'ITI-087', 62, 0, 85, 10, 143, 2, 15, 8, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1464, 'ITI-088', 65, 0, 144, 10, 131, 2, 1, 2, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1465, 'ITI-089', 49, 0, 143, 10, 129, 2, 1, 2, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1487, 'ITI-090', 18, 0, 118, 10, 157, 2, 5, 2, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1490, 'ITI-091', 3, 0, 100, 10, 159, 2, 1, 0, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1505, 'ITI-092', 57, 0, 64, 10, 169, 2, 12, 1, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1506, 'ITI-093', 83, 0, 149, 10, 170, 2, 1, 1, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1508, 'ITI-094', 53, 0, 141, 10, 172, 7, 2, 2, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1525, 'MITI-001', 173, NULL, 59, 10, 184, 5, 30, 10, 1, 1, 1, 0, 0, 'NULL', 0, 1),
(1526, 'MITI-002', 71, NULL, 107, 10, 184, 5, 30, 11, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1527, 'MITI-003', 115, NULL, 103, 10, 184, 5, 30, 17, 1, 1, 1, 0, 0, 'NULL', 0, 1),
(1528, 'MITI-004', 171, NULL, 87, 10, 184, 5, 30, 4, 1, 1, 1, 0, 0, 'NULL', 0, 1),
(1529, 'MITI-005', 203, NULL, 82, 10, 184, 5, 12, 3, 1, 1, 1, 0, 0, 'NULL', 0, 1),
(1530, 'MITI-006', 168, NULL, 12, 10, 185, 5, 30, 9, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1531, 'MITI-007', 197, NULL, 54, 10, 185, 5, 30, 3, 1, 1, 1, 0, 0, 'NULL', 0, 1),
(1532, 'MITI-008', 199, NULL, 87, 10, 185, 5, 12, 2, 1, 1, 1, 0, 0, 'NULL', 0, 1),
(1535, 'ITI-101', 33, 0, 52, 10, 188, 2, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(1543, 'ITI-7001', 3, NULL, 100, 11, 191, 7, 35, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(1544, 'ITI-7002', 40, NULL, 125, 11, 191, 7, 34, 39, 1, 1, 0, 43, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(1545, 'ITI-7003', 49, NULL, 143, 11, 191, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1546, 'ITI-7004', 156, NULL, 85, 11, 191, 7, 30, 38, 1, 1, 0, 38, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1547, 'ITI-7005', 206, NULL, 56, 11, 191, 7, 30, 38, 1, 1, 0, 30, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(1548, 'ITI-7006', 59, NULL, 7, 11, 191, 7, 35, 39, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1549, 'ITI-7008', 65, NULL, 88, 11, 191, 7, 35, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(1550, 'ITI-1318', 33, NULL, 52, 9, NULL, 2, 30, 10, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(1560, 'ITI-07009', 214, NULL, 144, 11, 196, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1562, 'ITI-07010', 39, NULL, 105, 11, 196, 7, 35, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(1563, 'ITI-07011', 215, NULL, 56, 11, 196, 7, 31, 31, 1, 1, 0, 32, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1564, 'ITI-07012', 216, NULL, 52, 11, 196, 7, 33, 33, 1, 1, 0, 33, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1565, 'ITI-07013', 66, NULL, 138, 11, 196, 7, 34, 32, 1, 1, 0, 49, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(1566, 'ITI-07014', 137, NULL, 118, 11, 196, 7, 30, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1567, 'ITI-07015', 50, NULL, 95, 11, 199, 7, 5, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1568, 'ITI-07016', 216, NULL, 100, 11, 199, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1569, 'ITI-07017', 214, NULL, 144, 11, 199, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1570, 'ITI-07018', 137, NULL, 78, 11, 199, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1571, 'ITI-07019', 39, NULL, 105, 11, 199, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(1572, 'ITI-07020', 215, NULL, 14, 11, 199, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1573, 'ITI-07021', 66, NULL, 138, 11, 199, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(1574, 'ITI-07022', 50, NULL, 143, 11, 196, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1575, 'ITI-07023', 215, NULL, 84, 11, 200, 7, 30, 28, 1, 1, 0, 31, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1576, 'ITI-07024', 65, NULL, 144, 11, 200, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(1577, 'ITI-07025', 50, NULL, 148, 11, 200, 7, 15, 15, 1, 1, 0, 1, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1579, 'ITI-07026', 214, NULL, 137, 11, 200, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(1580, 'ITI-07027', 39, NULL, 105, 11, 200, 7, 22, 22, 1, 1, 0, 24, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1581, 'ITI-07028', 137, NULL, 118, 11, 200, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1582, 'ITI-07029', 3, NULL, 149, 11, 202, 7, 30, 26, 1, 1, 0, 47, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(1639, 'ITI-02319', 9, NULL, 107, 11, 215, 2, 2, 2, 1, 1, 0, 3, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1647, 'ITI-02320', 62, NULL, 23, 11, 215, 2, 15, 9, 1, 1, 0, 5, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1648, 'ITI-02321', 80, NULL, 154, 11, 215, 2, 15, 10, 1, 1, 0, 6, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(1655, 'ITI-02322', 55, NULL, 25, 11, 215, 2, 0, 20, 1, 1, 0, 7, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1657, 'ITI-07030', 55, NULL, 25, 11, 202, 7, 0, 2, 1, 1, 0, 7, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1661, 'ITI-02323', 135, NULL, 25, 11, 215, 2, 1, 1, 1, 1, 0, 8, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1667, 'ITI-02324', 56, NULL, 25, 11, 215, 2, 1, 4, 1, 1, 0, 9, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1688, 'ITI-02325', 53, NULL, 95, 11, 221, 2, 34, 33, 1, 1, 0, 22, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1689, 'ITI-02326', 22, NULL, 64, 11, 221, 2, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1690, 'ITI-02327', 85, NULL, 132, 11, 222, 2, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1691, 'ITI-02328', 21, NULL, 60, 11, 221, 2, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(1692, 'ITI-02329', 66, NULL, 132, 11, 222, 2, 20, 18, 1, 1, 0, 29, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(1693, 'ITI-02330', 2, NULL, 137, 11, 221, 2, 35, 41, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(1694, 'ITI-02331', 47, NULL, 7, 11, 221, 2, 35, 40, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(1695, 'ITI-02332', 62, NULL, 23, 11, 224, 2, 30, 9, 1, 1, 0, 61, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1696, 'ITI-02333', 18, NULL, 118, 11, 221, 2, 35, 40, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(1697, 'ITI-02334', 87, NULL, 149, 11, 224, 2, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1698, 'ITI-02335', 35, NULL, 125, 11, 224, 2, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(1699, 'ITI-02336', 79, NULL, 84, 11, 224, 2, 35, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(1700, 'ITI-02337', 111, NULL, 156, 11, 221, 2, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(1701, 'ITI-02338', 43, NULL, 156, 11, 225, 2, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1702, 'ITI-02339', 21, NULL, 125, 11, 225, 2, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1</colorFondo></Grupo></Campos>', 0, 1),
(1703, 'ITI-02340', 47, NULL, 84, 11, 225, 2, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(1704, 'ITI-02341', 92, NULL, 56, 11, 225, 2, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1706, 'ITI-02342', 88, NULL, 156, 11, 227, 2, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(1707, 'ITI-02343', 46, NULL, 100, 11, 227, 2, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(1708, 'ITI-07033', 137, NULL, 85, 11, 202, 7, 3, 2, 1, 1, 0, 11, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1709, 'ITI-02344', 78, NULL, 77, 11, 226, 2, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(1710, 'ITI-02345', 7, NULL, 138, 11, 227, 2, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(1711, 'ITI-02346', 144, NULL, 105, 11, 229, 2, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(1712, 'ITI-02347', 56, NULL, 95, 11, 229, 2, 21, 21, 1, 1, 0, 65, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1713, 'ITI-02348', 8, NULL, 52, 11, 229, 2, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1714, 'ITI-02349', 57, NULL, 64, 11, 229, 2, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(1715, 'ITI-02350', 107, NULL, 52, 11, 231, 2, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(1717, 'ITI-02352', 58, NULL, 64, 11, 231, 2, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1718, 'ITI-02353', 1, NULL, 7, 11, 229, 2, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(1719, 'ITI-02354', 101, NULL, 82, 11, 232, 2, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(1720, 'ITI-02355', 83, NULL, 149, 11, 229, 2, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(1721, 'ITI-02356', 106, NULL, 14, 11, 229, 2, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(1723, 'MITI-05009', 188, NULL, 87, 11, 194, 5, 15, 6, 1, 1, 1, 16, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(1724, 'MITI-05010', 28, NULL, 34, 11, 194, 5, 15, 7, 1, 1, 1, 14, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(1727, 'MITI-05012', 171, NULL, 87, 11, 194, 5, 15, 1, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1728, 'ITI-02358', 54, NULL, 102, 11, 232, 2, 10, 4, 1, 1, 0, 13, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1730, 'MITI-05013', 89, NULL, 82, 11, 194, 5, 15, 8, 1, 1, 0, 18, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1732, 'MITI-05014', 70, NULL, 107, 11, 194, 5, 15, 8, 1, 1, 0, 19, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(1734, 'MITI-05015', 160, NULL, 90, 11, 194, 5, 15, 8, 1, 1, 0, 20, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1736, 'MITI-05016', 169, NULL, 12, 11, 194, 5, 15, 7, 1, 1, 0, 21, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(1737, 'ITI-07034', 53, NULL, 95, 11, 202, 7, 1, 1, 1, 1, 0, 22, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1738, 'ITI-02359', 52, NULL, 62, 11, 226, 2, 15, 13, 1, 1, 0, 23, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1739, 'ITI-02360', 124, NULL, 43, 11, 226, 2, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(1741, 'ITI-02361', 39, NULL, 105, 11, 226, 2, 13, 13, 1, 1, 0, 24, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1746, 'ITI-02362', 53, NULL, 62, 11, 226, 2, 6, 5, 1, 1, 0, 28, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1747, 'ITI-07035', 66, NULL, 132, 11, 202, 7, 15, 6, 1, 1, 0, 29, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(1748, 'ITI-02363', 78, NULL, 56, 11, 226, 2, 3, 5, 1, 1, 0, 30, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(1749, 'ITI-02364', 91, NULL, 84, 11, 226, 2, 5, 5, 1, 1, 0, 31, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1751, 'ITI-02365', 91, NULL, 56, 11, 226, 2, 4, 4, 1, 1, 0, 32, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1752, 'ITI-02366', 90, NULL, 52, 11, 226, 2, 3, 3, 1, 1, 0, 33, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1761, 'ITI-02367', 112, NULL, 85, 11, 226, 2, 5, 5, 1, 1, 0, 38, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1775, 'ITI-02368', 86, NULL, 132, 11, 222, 2, 25, 13, 1, 1, 0, 53, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1776, 'ITI-02369', 18, NULL, 85, 11, 215, 2, 30, 33, 1, 1, 0, 46, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1778, 'ITI-02370', 51, NULL, 102, 11, 215, 2, 5, 8, 1, 1, 0, 60, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(1779, 'ITI-02371', 3, NULL, 149, 11, 226, 2, 5, 2, 1, 1, 0, 47, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(1781, 'ITI-02373', 50, NULL, 148, 11, 226, 2, 1, 1, 1, 1, 0, 1, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1782, 'ITI-02374', 66, NULL, 138, 11, 226, 2, 1, 1, 1, 1, 0, 49, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(1790, 'ITI-07037', 54, NULL, 102, 11, 200, 7, 10, 2, 1, 1, 0, 13, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1801, 'ITI-02375', 112, NULL, 85, 11, 215, 2, 15, 10, 1, 1, 0, 56, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1803, 'ITI-02376', 9, NULL, 83, 11, 226, 2, 8, 5, 1, 1, 0, 57, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1808, 'ITI-02377', 108, NULL, 56, 11, 215, 2, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1809, 'ITI-02378', 136, NULL, 125, 11, 215, 2, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1812, 'ITI-02379', 55, NULL, 158, 11, 226, 2, 5, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1813, 'ITI-07038', 55, NULL, 158, 11, 202, 7, 5, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1818, 'ITI-02380', 53, NULL, 158, 11, 226, 2, 5, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1830, 'ITI-07041', 53, NULL, 62, 11, 202, 7, 2, 1, 1, 1, 0, 52, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1840, 'ITI-02381', 53, NULL, 62, 11, 226, 2, 2, 1, 1, 1, 0, 52, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1841, 'ITI-02382', 53, NULL, 22, 11, 215, 2, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1846, 'ITI-02383', 32, NULL, 52, 10, 188, 2, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1847, 'ITI-02384', 33, NULL, 52, 10, 188, 2, 30, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1856, 'ITI-07042', 65, NULL, 144, 12, 237, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1858, 'ITI-07043', 221, NULL, 77, 12, 237, 7, 35, 19, 1, 1, 0, 66, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1859, 'ITI-02385', 103, NULL, 77, 12, 238, 2, 35, 16, 1, 1, 0, 66, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1860, 'ITI-07044', 181, NULL, 105, 12, 237, 7, 35, 11, 1, 1, 0, 67, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(1861, 'ITI-02386', 100, NULL, 105, 12, 238, 2, 35, 13, 1, 1, 0, 67, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(1862, 'ITI-07045', 121, NULL, 118, 12, 237, 7, 35, 18, 1, 1, 0, 117, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(1863, 'ITI-07046', 222, NULL, 56, 12, 237, 7, 35, 10, 1, 1, 0, 68, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(1864, 'ITI-02387', 79, NULL, 56, 12, 238, 2, 35, 4, 1, 1, 0, 68, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(1865, 'ITI-07047', 218, NULL, 52, 12, 237, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(1868, 'ITI-07048', 50, NULL, 95, 12, 240, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1871, 'ITI-07049', 214, NULL, 144, 12, 240, 7, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(1874, 'ITI-07050', 39, NULL, 105, 12, 240, 7, 37, 33, 1, 1, 0, 69, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(1875, 'ITI-02388', 39, NULL, 105, 12, 241, 2, 37, 3, 1, 1, 0, 69, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(1878, 'ITI-07051', 66, NULL, 156, 12, 240, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(1880, 'ITI-07052', 215, NULL, 111, 12, 240, 7, 35, 33, 1, 1, 0, 130, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1883, 'ITI-07053', 216, NULL, 149, 12, 240, 7, 37, 35, 1, 1, 0, 132, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1884, 'ITI-07054', 137, NULL, 118, 12, 240, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1885, 'ITI-07055', 3, NULL, 163, 12, 243, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(1887, 'ITI-07056', 49, NULL, 102, 12, 243, 7, 35, 5, 1, 1, 0, 70, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1897, 'ITI-07057', 221, NULL, 100, 12, 245, 7, 35, 34, 1, 1, 0, 71, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1898, 'ITI-02389', 103, NULL, 100, 12, 247, 2, 35, 1, 1, 1, 0, 71, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1900, 'ITI-07058', 51, NULL, 95, 12, 245, 7, 36, 33, 1, 1, 0, 72, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1901, 'ITI-02390', 51, NULL, 95, 12, 247, 2, 36, 3, 1, 1, 0, 72, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1903, 'ITI-07059', 9, NULL, 144, 12, 245, 7, 37, 31, 1, 1, 0, 73, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1904, 'ITI-02391', 9, NULL, 144, 12, 247, 2, 37, 5, 1, 1, 0, 73, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1909, 'ITI-07060', 222, NULL, 14, 12, 245, 7, 35, 33, 1, 1, 0, 74, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(1910, 'ITI-02392', 79, NULL, 14, 12, 247, 2, 35, 2, 1, 1, 0, 74, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(1912, 'ITI-07061', 121, NULL, 78, 12, 245, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1915, 'ITI-07062', 181, NULL, 7, 12, 245, 7, 35, 31, 1, 1, 0, 75, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-9729</colorFondo></Grupo></Campos>', 0, 1),
(1916, 'ITI-02393', 100, NULL, 7, 12, 247, 2, 35, 3, 1, 1, 0, 75, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-9729</colorFondo></Grupo></Campos>', 0, 1),
(1918, 'ITI-07063', 218, NULL, 149, 12, 245, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(1921, 'ITI-02394', 85, NULL, 52, 12, 252, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(1923, 'ITI-02395', 18, NULL, 23, 12, 252, 2, 36, 11, 1, 1, 0, 76, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1926, 'ITI-02396', 80, NULL, 21, 12, 252, 2, 35, 7, 1, 1, 0, 77, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(1935, 'ITI-07064', 9, NULL, 88, 12, 255, 7, 37, 24, 1, 1, 0, 78, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1936, 'ITI-02397', 9, NULL, 88, 12, 256, 2, 37, 8, 1, 1, 0, 78, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(1939, 'ITI-07065', 221, NULL, 100, 12, 255, 7, 35, 31, 1, 1, 0, 79, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1940, 'ITI-02398', 103, NULL, 100, 12, 256, 2, 35, 4, 1, 1, 0, 79, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(1942, 'ITI-07066', 51, NULL, 95, 12, 255, 7, 35, 29, 1, 1, 0, 80, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1943, 'ITI-02399', 51, NULL, 95, 12, 256, 2, 35, 4, 1, 1, 0, 80, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1944, 'ITI-07067', 222, NULL, 56, 12, 255, 7, 35, 28, 1, 1, 0, 81, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1945, 'ITI-02400', 79, NULL, 56, 12, 256, 2, 35, 7, 1, 1, 0, 81, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(1948, 'ITI-07068', 181, NULL, 7, 12, 255, 7, 35, 24, 1, 1, 0, 82, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-11521</colorFondo></Grupo></Campos>', 0, 1),
(1949, 'ITI-02401', 100, NULL, 7, 12, 256, 2, 35, 7, 1, 1, 0, 82, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-11521</colorFondo></Grupo></Campos>', 0, 1),
(1953, 'ITI-07069', 218, NULL, 52, 12, 255, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(1955, 'ITI-07070', 121, NULL, 118, 12, 255, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(1958, 'ITI-07071', 9, NULL, 164, 12, 259, 7, 35, 14, 1, 1, 0, 83, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1959, 'ITI-02402', 9, NULL, 164, 12, 260, 2, 35, 12, 1, 1, 0, 83, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(1960, 'ITI-02403', 88, NULL, 64, 12, 260, 2, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(1961, 'ITI-02404', 43, NULL, 125, 12, 260, 2, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(1962, 'ITI-02405', 47, NULL, 100, 12, 260, 2, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(1963, 'ITI-02406', 22, NULL, 64, 12, 260, 2, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(1977, 'MITI-05017', 105, NULL, 82, 12, 266, 5, 35, 2, 1, 1, 1, 85, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(1978, 'ITI-02408', 2, NULL, 131, 12, 262, 2, 35, 18, 1, 1, 0, 84, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(1980, 'MITI-05018', 89, NULL, 82, 12, 266, 5, 35, 13, 1, 1, 0, 86, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(1981, 'ITI-02409', 52, NULL, 143, 12, 262, 2, 35, 7, 1, 1, 0, 87, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(1983, 'ITI-02410', 111, NULL, 149, 12, 262, 2, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(1985, 'MITI-05019', 171, NULL, 87, 12, 266, 5, 35, 0, 1, 1, 1, 88, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(1987, 'MITI-05020', 198, NULL, 87, 12, 266, 5, 35, 0, 1, 1, 1, 89, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(1988, 'ITI-02411', 21, NULL, 132, 12, 262, 2, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(1990, 'MITI-05021', 71, NULL, 107, 12, 267, 5, 35, 15, 1, 1, 0, 90, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(1994, 'MITI-05022', 181, NULL, 156, 12, 267, 5, 35, 19, 1, 1, 1, 92, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(1996, 'MITI-05023', 160, NULL, 90, 12, 267, 5, 35, 13, 1, 1, 0, 93, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(1998, 'MITI-05024', 197, NULL, 54, 12, 273, 5, 35, 5, 1, 1, 1, 94, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(1999, 'ITI-02412', 46, NULL, 125, 12, 262, 2, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-274184</colorFondo></Grupo></Campos>', 0, 1),
(2001, 'MITI-05025', 167, NULL, 12, 12, 273, 5, 35, 7, 1, 1, 0, 95, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2003, 'MITI-05026', 30, NULL, 34, 12, 275, 5, 35, 0, 1, 1, 1, 96, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2005, 'MITI-05027', 175, NULL, 34, 12, 275, 5, 35, 0, 1, 1, 1, 97, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(2007, 'MITI-05028', 200, NULL, 103, 12, 277, 5, 35, 5, 1, 1, 1, 98, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(2008, 'ITI-02413', 54, NULL, 62, 12, 278, 2, 35, 10, 1, 1, 0, 99, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2009, 'ITI-07072', 54, NULL, 62, 12, 279, 7, 35, 1, 1, 1, 0, 99, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2011, 'MITI-05029', 195, NULL, 56, 12, 277, 5, 35, 7, 1, 1, 1, 100, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2012, 'ITI-02414', 9, NULL, 123, 12, 278, 2, 35, 28, 1, 1, 0, 101, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(2013, 'ITI-07073', 9, NULL, 123, 12, 279, 7, 35, 1, 1, 1, 0, 101, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2015, 'MITI-05030', 170, NULL, 103, 12, 277, 5, 35, 7, 1, 1, 1, 102, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2016, 'ITI-02415', 13, NULL, 136, 12, 278, 2, 35, 30, 1, 1, 0, 123, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2017, 'ITI-02416', 46, NULL, 7, 12, 278, 2, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-9061633</colorFondo></Grupo></Campos>', 0, 1),
(2018, 'ITI-02417', 88, NULL, 156, 12, 278, 2, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(2019, 'ITI-02418', 43, NULL, 60, 12, 278, 2, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(2020, 'ITI-02419', 92, NULL, 14, 12, 278, 2, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(2024, 'ITI-02421', 8, NULL, 163, 12, 280, 2, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2025, 'ITI-02422', 7, NULL, 132, 12, 280, 2, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2026, 'ITI-02423', 57, NULL, 64, 12, 280, 2, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(2027, 'ITI-02424', 1, NULL, 125, 12, 280, 2, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2028, 'ITI-02425', 135, NULL, 62, 12, 283, 2, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2029, 'ITI-02426', 136, NULL, 125, 12, 283, 2, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2030, 'ITI-02427', 72, NULL, 54, 12, 283, 2, 35, 22, 1, 1, 0, 122, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(2031, 'ITI-02428', 152, NULL, 82, 12, 283, 2, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2032, 'ITI-02429', 101, NULL, 87, 12, 283, 2, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2033, 'ITI-02430', 114, NULL, 163, 12, 283, 2, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2034, 'ITI-02431', 143, NULL, 60, 12, 283, 2, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2037, 'ITI-02433', 62, NULL, 136, 12, 284, 2, 35, 4, 1, 1, 0, 103, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2038, 'ITI-02434', 87, NULL, 132, 12, 286, 2, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2039, 'ITI-02435', 56, NULL, 22, 12, 286, 2, 35, 16, 1, 1, 0, 104, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2040, 'ITI-02436', 55, NULL, 25, 12, 286, 2, 35, 3, 1, 1, 0, 105, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(2041, 'ITI-02437', 54, NULL, 102, 12, 287, 2, 35, 7, 1, 1, 0, 106, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2042, 'ITI-02438', 32, NULL, 52, 12, 288, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2043, 'ITI-02439', 33, NULL, 52, 12, 288, 2, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2044, 'ITI-02440', 124, NULL, 43, 12, 288, 2, 35, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2045, 'ITI-02441', 13, NULL, 118, 12, 289, 2, 35, 25, 1, 1, 0, 109, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2048, 'ITI-02442', 53, NULL, 25, 12, 262, 2, 37, 31, 1, 1, 0, 108, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2049, 'ITI-02443', 106, NULL, 14, 12, 292, 2, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(2053, 'ITI-07074', 52, NULL, 143, 12, 279, 7, 35, 0, 1, 1, 0, 87, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2073, 'ITI-02444', 80, NULL, 21, 12, 262, 2, 39, 4, 1, 1, 0, 116, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(2106, 'ITI-02445', 12, NULL, 75, 12, 241, 2, 36, 2, 1, 1, 0, 119, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(2107, 'ITI-02446', 12, NULL, 75, 12, 241, 2, 35, 3, 1, 1, 0, 120, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(2112, 'ITI-02447', 91, NULL, 111, 12, 278, 2, 35, 2, 1, 1, 0, 130, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2116, 'ITI-02448', 90, NULL, 149, 12, 241, 2, 37, 1, 1, 1, 0, 132, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2118, 'MITI-05031', 191, NULL, 79, 12, 266, 5, 35, 0, 1, 1, 1, 133, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2124, 'ITI-02449', 54, NULL, 62, 12, 247, 2, 35, 2, 1, 1, 0, 135, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2125, 'ITI-07075', 54, NULL, 62, 12, 279, 7, 35, 0, 1, 1, 0, 135, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2137, 'ITI-02450', 52, NULL, 102, 12, 284, 2, 35, 4, 1, 1, 0, 141, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2138, 'ITI-07076', 52, NULL, 102, 12, 279, 7, 35, 0, 1, 1, 0, 141, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2140, 'ITI-02451', 53, NULL, 143, 12, 252, 2, 35, 3, 1, 1, 0, 142, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2141, 'ITI-02452', 39, NULL, 105, 12, 241, 2, 35, 0, 1, 1, 0, 143, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(2142, 'ITI-07077', 39, NULL, 105, 12, 240, 7, 35, 5, 1, 1, 0, 143, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(2146, 'ITI-02453', 56, NULL, 161, 12, 286, 2, 35, 5, 1, 1, 0, 144, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2147, 'ITI-07078', 56, NULL, 161, 12, 279, 7, 35, 1, 1, 1, 0, 144, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2149, 'ITI-02454', 135, NULL, 25, 12, 280, 2, 35, 5, 1, 1, 0, 145, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2152, 'ITI-07079', 135, NULL, 25, 12, 279, 7, 35, 0, 1, 1, 0, 145, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2155, 'ITI-07080', 121, NULL, 23, 12, 237, 7, 35, 0, 1, 1, 0, 147, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2157, 'ITI-02455', 80, NULL, 154, 12, 241, 2, 35, 2, 1, 1, 0, 126, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(2161, 'ITI-02456', 55, NULL, 161, 12, 252, 2, 35, 5, 1, 1, 0, 149, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2162, 'ITI-07081', 55, NULL, 161, 12, 279, 7, 35, 0, 1, 1, 0, 149, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2170, 'ITI-07082', 2, NULL, 131, 12, 259, 7, 35, 0, 1, 1, 0, 84, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2171, 'ITI-07083', 53, NULL, 143, 12, 279, 7, 35, 5, 1, 1, 0, 142, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2178, 'ITI-02457', 18, NULL, 23, 12, 247, 2, 35, 0, 1, 1, 0, 147, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2179, 'ITI-07084', 54, NULL, 102, 12, 279, 7, 35, 1, 1, 1, 0, 106, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2180, 'ITI-02458', 83, NULL, 163, 12, 280, 2, 35, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(2184, 'ITI-02459', 32, NULL, 52, 11, 309, 2, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2185, 'ITI-07085', 156, NULL, 185, 13, 310, 7, 35, 29, 1, 1, 0, 154, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2186, 'ITI-02460', 112, NULL, 185, 13, 311, 2, 35, 2, 1, 1, 0, 154, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2187, 'ITI-07086', 49, NULL, 169, 13, 310, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2188, 'ITI-07087', 40, NULL, 174, 13, 310, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(2189, 'ITI-07088', 65, NULL, 144, 13, 310, 7, 38, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2190, 'ITI-07089', 3, NULL, 160, 13, 310, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2191, 'ITI-07090', 59, NULL, 7, 13, 310, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4473857</colorFondo></Grupo></Campos>', 0, 1),
(2192, 'ITI-07091', 206, NULL, 77, 13, 310, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2193, 'ITI-07092', 49, NULL, 169, 13, 312, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2194, 'ITI-07093', 156, NULL, 185, 13, 312, 7, 40, 34, 1, 1, 0, 155, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2195, 'ITI-02461', 112, NULL, 185, 13, 311, 2, 40, 1, 1, 1, 0, 155, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2196, 'ITI-07094', 65, NULL, 144, 13, 312, 7, 38, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2197, 'ITI-07095', 40, NULL, 174, 13, 312, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2198, 'ITI-07096', 59, NULL, 7, 13, 312, 7, 35, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2199, 'ITI-07097', 206, NULL, 173, 13, 312, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2200, 'ITI-07098', 3, NULL, 160, 13, 312, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-11908457</colorFondo></Grupo></Campos>', 0, 1),
(2201, 'ITI-07099', 59, NULL, 7, 13, 312, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4605441</colorFondo></Grupo></Campos>', 0, 1),
(2202, 'ITI-07100', 65, NULL, 179, 13, 314, 7, 37, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2203, 'ITI-07101', 156, NULL, 185, 13, 314, 7, 35, 25, 1, 1, 0, 156, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2204, 'ITI-02462', 112, NULL, 185, 13, 311, 2, 35, 1, 1, 1, 0, 156, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2205, 'ITI-07102', 49, NULL, 148, 13, 314, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2206, 'ITI-07103', 59, NULL, 7, 13, 314, 7, 38, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5855489</colorFondo></Grupo></Campos>', 0, 1),
(2207, 'ITI-07104', 206, NULL, 173, 13, 314, 7, 38, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2208, 'ITI-07105', 3, NULL, 160, 13, 314, 7, 37, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-7708676</colorFondo></Grupo></Campos>', 0, 1),
(2209, 'ITI-07106', 40, NULL, 174, 13, 314, 7, 38, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2212, 'ITI-07107', 221, NULL, 100, 13, 320, 7, 35, 24, 1, 1, 0, 157, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5000193</colorFondo></Grupo></Campos>', 0, 1),
(2213, 'ITI-02463', 103, NULL, 100, 13, 311, 2, 35, 2, 1, 1, 0, 157, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5000193</colorFondo></Grupo></Campos>', 0, 1),
(2214, 'ITI-07108', 218, NULL, 52, 13, 320, 7, 35, 27, 1, 1, 0, 236, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-18505</colorFondo></Grupo></Campos>', 0, 1),
(2215, 'ITI-07109', 51, NULL, 143, 13, 320, 7, 35, 14, 1, 1, 0, 177, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2216, 'ITI-07110', 181, NULL, 7, 13, 320, 7, 35, 26, 1, 1, 0, 158, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-20084</colorFondo></Grupo></Campos>', 0, 1),
(2217, 'ITI-02464', 100, NULL, 7, 13, 319, 2, 35, 1, 1, 1, 0, 158, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-20084</colorFondo></Grupo></Campos>', 0, 1),
(2218, 'ITI-07111', 222, NULL, 56, 13, 320, 7, 35, 11, 1, 1, 0, 159, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5832794</colorFondo></Grupo></Campos>', 0, 1),
(2219, 'ITI-02465', 79, NULL, 56, 13, 319, 2, 35, 2, 1, 1, 0, 159, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5832794</colorFondo></Grupo></Campos>', 0, 1),
(2220, 'ITI-07112', 9, NULL, 149, 13, 320, 7, 35, 19, 1, 1, 0, 160, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-14145281</colorFondo></Grupo></Campos>', 0, 1),
(2221, 'ITI-02466', 9, NULL, 149, 13, 322, 2, 35, 9, 1, 1, 0, 160, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-14145281</colorFondo></Grupo></Campos>', 0, 1),
(2222, 'ITI-07113', 121, NULL, 118, 13, 320, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-18433</colorFondo></Grupo></Campos>', 0, 1),
(2223, 'ITI-07114', 129, NULL, 23, 13, 323, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-21931</colorFondo></Grupo></Campos>', 0, 1),
(2224, 'ITI-07115', 52, NULL, 143, 13, 323, 7, 35, 17, 1, 1, 0, 161, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(2225, 'ITI-02467', 52, NULL, 143, 13, 319, 2, 35, 2, 1, 1, 0, 161, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(2226, 'ITI-07116', 2, NULL, 21, 13, 323, 7, 35, 18, 1, 1, 0, 162, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2227, 'ITI-07117', 2, NULL, 21, 13, 324, 2, 35, 1, 1, 1, 0, 162, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2228, 'ITI-07117', 224, NULL, 156, 13, 323, 7, 35, 25, 1, 1, 0, 163, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2147800</colorFondo></Grupo></Campos>', 0, 1),
(2229, 'ITI-02118', 21, NULL, 156, 13, 324, 2, 35, 3, 1, 1, 0, 163, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2147800</colorFondo></Grupo></Campos>', 0, 1),
(2230, 'ITI-07118', 225, NULL, 14, 13, 323, 7, 35, 23, 1, 1, 0, 164, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4718593</colorFondo></Grupo></Campos>', 0, 1),
(2231, 'ITI-02119', 92, NULL, 14, 13, 322, 2, 35, 5, 1, 1, 0, 164, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4718593</colorFondo></Grupo></Campos>', 0, 1),
(2232, 'ITI-07119', 223, NULL, 170, 13, 323, 7, 35, 8, 1, 1, 0, 165, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-11141248</colorFondo></Grupo></Campos>', 0, 1),
(2233, 'ITI-02120', 87, NULL, 170, 13, 319, 2, 35, 3, 1, 1, 0, 165, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-11141248</colorFondo></Grupo></Campos>', 0, 1),
(2234, 'ITI-07120', 223, NULL, 170, 13, 325, 7, 35, 29, 1, 1, 0, 166, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(2235, 'ITI-02121', 87, NULL, 170, 13, 319, 2, 35, 1, 1, 1, 0, 166, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(2236, 'ITI-07121', 52, NULL, 143, 13, 325, 7, 35, 21, 1, 1, 0, 167, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2039584</colorFondo></Grupo></Campos>', 0, 1),
(2237, 'ITI-02122', 52, NULL, 143, 13, 319, 2, 35, 1, 1, 1, 0, 167, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2039584</colorFondo></Grupo></Campos>', 0, 1),
(2238, 'ITI-07122', 129, NULL, 23, 13, 325, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2239, 'ITI-07123', 225, NULL, 14, 13, 325, 7, 35, 33, 1, 1, 0, 168, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2240, 'ITI-02123', 92, NULL, 14, 13, 322, 2, 35, 0, 1, 1, 0, 168, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2241, 'ITI-07124', 2, NULL, 144, 13, 325, 7, 35, 32, 1, 1, 0, 169, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2242, 'ITI-02124', 2, NULL, 144, 13, 324, 2, 35, 0, 1, 1, 0, 169, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2243, 'ITI-07125', 224, NULL, 156, 13, 325, 7, 35, 32, 1, 1, 0, 170, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(2244, 'ITI-02125', 21, NULL, 156, 13, 324, 2, 35, 1, 1, 1, 0, 170, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(2245, 'ITI-02126', 23, NULL, 137, 13, 327, 2, 36, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2246, 'ITI-02127', 107, NULL, 105, 13, 327, 2, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2247, 'ITI-02128', 58, NULL, 64, 13, 327, 2, 36, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-15996</colorFondo></Grupo></Campos>', 0, 1),
(2248, 'ITI-02129', 106, NULL, 56, 13, 327, 2, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16734124</colorFondo></Grupo></Campos>', 0, 1),
(2249, 'ITI-02130', 55, NULL, 167, 13, 327, 2, 35, 14, 1, 1, 0, 207, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2105377</colorFondo></Grupo></Campos>', 0, 1),
(2250, 'ITI-02131', 80, NULL, 9, 13, 327, 2, 35, 30, 1, 1, 0, 206, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2251, 'ITI-02132', 72, NULL, 54, 13, 328, 2, 25, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2252, 'ITI-02133', 152, NULL, 82, 13, 328, 2, 20, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2253, 'ITI-07126', 216, NULL, 173, 13, 330, 7, 35, 14, 1, 1, 0, 230, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(2254, 'ITI-07127', 215, NULL, 100, 13, 330, 7, 36, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2255, 'ITI-07128', 39, NULL, 105, 13, 330, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2256, 'ITI-07129', 50, NULL, 161, 13, 330, 7, 35, 7, 1, 1, 0, 233, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2257, 'ITI-07130', 218, NULL, 149, 13, 331, 7, 35, 17, 1, 1, 0, 202, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2258, 'ITI-02134', 111, NULL, 9, 13, 332, 2, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(2259, 'ITI-02135', 88, NULL, 149, 13, 333, 2, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2260, 'ITI-02136', 43, NULL, 60, 13, 333, 2, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2261, 'ITI-02137', 92, NULL, 56, 13, 333, 2, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2262, 'ITI-02138', 9, NULL, 138, 13, 333, 2, 35, 18, 1, 1, 0, 176, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2263, 'ITI-02139', 53, NULL, 161, 13, 333, 2, 35, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2264, 'ITI-02140', 53, NULL, 167, 13, 332, 2, 35, 11, 1, 1, 0, 179, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2265, 'ITI-02141', 22, NULL, 189, 13, 332, 2, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2266, 'ITI-02142', 58, NULL, 64, 13, 334, 2, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2267, 'ITI-02143', 107, NULL, 189, 13, 334, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(2268, 'ITI-02144', 80, NULL, 140, 13, 334, 2, 35, 7, 1, 1, 0, 178, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(2269, 'ITI-02145', 46, NULL, 125, 13, 333, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(2270, 'ITI-02146', 83, NULL, 163, 13, 335, 2, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2271, 'ITI-02147', 144, NULL, 125, 13, 335, 2, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2272, 'ITI-02148', 8, NULL, 52, 13, 335, 2, 35, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(2273, 'ITI-02149', 23, NULL, 138, 13, 334, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2274, 'ITI-02150', 101, NULL, 87, 13, 328, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2275, 'ITI-02151', 135, NULL, 161, 13, 328, 2, 35, 7, 1, 1, 0, 181, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2276, 'ITI-07131', 40, NULL, 125, 13, 337, 7, 70, 19, 1, 1, 0, 171, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(2277, 'ITI-07132', 49, NULL, 62, 13, 337, 7, 70, 19, 1, 1, 0, 172, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 0),
(2278, 'ITI-07133', 65, NULL, 88, 13, 337, 7, 70, 19, 1, 1, 0, 173, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 0),
(2279, 'ITI-07134', 156, NULL, 78, 13, 337, 7, 70, 19, 1, 1, 0, 174, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 0),
(2280, 'ITI-07135', 3, NULL, 52, 13, 337, 7, 70, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 0),
(2281, 'ITI-07136', 59, NULL, 111, 13, 337, 7, 70, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 0),
(2396, 'ITI-02152', 54, NULL, 169, 13, 322, 2, 35, 12, 1, 1, 0, 182, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2397, 'ITI-02153', 56, NULL, 62, 13, 335, 2, 35, 6, 1, 1, 0, 183, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2399, 'ITI-07137', 51, NULL, 62, 13, 331, 7, 35, 7, 1, 1, 0, 184, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2406, 'ITI-07138', 219, NULL, 105, 13, 325, 7, 70, 29, 1, 1, 0, 186, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2407, 'ITI-07139', 219, NULL, 105, 13, 323, 7, 70, 8, 1, 1, 0, 186, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2408, 'ITI-02154', 33, NULL, 105, 13, 327, 2, 70, 43, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2409, 'ITI-02155', 124, NULL, 43, 13, 362, 2, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(2412, 'ITI-02156', 62, NULL, 118, 13, 352, 1, 35, 0, 1, 1, 0, 188, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(2414, 'ITI-02156', 13, NULL, 118, 13, 333, 2, 35, 3, 1, 1, 0, 189, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2420, 'ITI-07140', 9, NULL, 107, 13, 331, 7, 35, 15, 1, 1, 0, 192, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2421, 'ITI-02157', 9, NULL, 107, 13, 333, 2, 35, 4, 1, 1, 0, 192, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2423, 'ITI-02158', 2, NULL, 12, 13, 324, 2, 35, 5, 1, 1, 0, 193, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(2427, 'MITI-05032', 197, NULL, 163, 13, 364, 5, 20, 0, 1, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(2439, 'ITI-02159', 32, NULL, 105, 13, 319, 2, 70, 10, 1, 1, 0, 186, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2441, 'ITI-07141', 54, NULL, 169, 13, 331, 7, 35, 5, 1, 1, 0, 182, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2444, 'ITI-02160', 18, NULL, 191, 13, 332, 2, 35, 3, 1, 1, 0, 197, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2445, 'ITI-02161', 55, NULL, 22, 13, 334, 2, 35, 2, 1, 1, 0, 198, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2447, 'ITI-07142', 52, NULL, 95, 13, 325, 7, 35, 4, 1, 1, 0, 200, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2448, 'ITI-07143', 129, NULL, 23, 13, 325, 7, 35, 0, 1, 1, 0, 201, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2459, 'ITI-07144', 53, NULL, 167, 13, 325, 7, 35, 1, 1, 1, 0, 179, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2465, 'ITI-07145', 51, NULL, 168, 13, 331, 7, 35, 0, 1, 1, 0, 211, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2469, 'ITI-07146', 53, NULL, 168, 13, 331, 7, 35, 4, 1, 1, 0, 212, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2478, 'MITI-05033', 186, NULL, 170, 13, 364, 5, 35, 12, 1, 1, 1, 215, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2480, 'MITI-05034', 192, NULL, 79, 13, 364, 5, 35, 0, 1, 1, 1, 216, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(2482, 'MITI-05035', 172, NULL, 171, 13, 364, 5, 35, 0, 1, 1, 1, 217, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2483, 'MITI-05036', 171, NULL, 87, 13, 364, 5, 35, 0, 1, 1, 1, 218, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2484, 'MITI-05037', 189, NULL, 163, 13, 364, 5, 35, 14, 1, 1, 1, 219, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(2485, 'MITI-05038', 197, NULL, 163, 13, 364, 5, 35, 4, 1, 1, 1, 220, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(2486, 'MITI-05039', 204, NULL, 156, 13, 364, 5, 35, 6, 1, 1, 1, 221, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2487, 'MITI-05040', 28, NULL, 34, 13, 364, 5, 35, 0, 1, 1, 1, 222, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2488, 'MITI-05041', 168, NULL, 12, 13, 364, 5, 35, 7, 1, 1, 0, 223, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(2489, 'MITI-05042', 105, NULL, 82, 13, 364, 5, 35, 10, 1, 1, 1, 224, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2492, 'MITI-05043', 70, NULL, 107, 13, 364, 5, 35, 12, 1, 1, 0, 227, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(2494, 'MITI-05044', 263, NULL, 103, 13, 364, 5, 35, 4, 1, 1, 1, 228, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(2495, 'ITI-07147', 121, NULL, 23, 13, 331, 7, 35, 5, 1, 1, 0, 229, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2496, 'ITI-02162', 90, NULL, 173, 13, 332, 2, 35, 2, 1, 1, 0, 230, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(2499, 'ITI-02163', 135, NULL, 161, 13, 328, 2, 35, 3, 1, 1, 0, 231, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2500, 'ITI-07148', 135, NULL, 161, 13, 331, 7, 35, 0, 1, 1, 0, 231, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2504, 'ITI-02164', 54, NULL, 167, 13, 333, 2, 35, 12, 1, 1, 0, 232, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2505, 'ITI-07149', 54, NULL, 167, 13, 331, 7, 35, 0, 1, 1, 0, 232, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2507, 'ITI-02165', 50, NULL, 161, 13, 322, 2, 35, 0, 1, 1, 0, 233, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2513, 'ITI-02166', 143, NULL, 9, 13, 327, 2, 35, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(2514, 'ITI-02167', 85, NULL, 149, 13, 332, 2, 35, 1, 1, 1, 0, 202, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2515, 'ITI-02168', 72, NULL, 189, 13, 335, 2, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2516, 'ITI-07150', 55, NULL, 167, 13, 330, 7, 35, 12, 1, 1, 0, 207, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2105377</colorFondo></Grupo></Campos>', 0, 1),
(2517, 'ITI-02169', 100, NULL, 7, 13, 334, 2, 35, 1, 1, 1, 0, 235, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2518, 'ITI-07151', 181, NULL, 7, 13, 331, 7, 35, 0, 1, 1, 0, 235, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2520, 'ITI-02170', 85, NULL, 52, 13, 332, 2, 35, 0, 1, 1, 0, 236, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-18505</colorFondo></Grupo></Campos>', 0, 1),
(2522, 'ITI-02171', 51, NULL, 190, 13, 327, 2, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2528, 'ITI-02172', 53, NULL, 168, 13, 324, 2, 35, 2, 1, 1, 0, 212, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2529, 'ITI-02173', 57, NULL, 64, 13, 335, 2, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(2530, 'ITI-02174', 7, NULL, 87, 13, 335, 2, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2531, 'ITI-07191', 156, NULL, 185, 14, 366, 7, 39, 18, 1, 1, 0, 238, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2535, 'ITI-07192', 3, NULL, 100, 14, 366, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2536, 'ITI-07193', 40, NULL, 174, 14, 366, 7, 35, 21, 1, 1, 0, 287, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2537, 'ITI-07194', 65, NULL, 154, 14, 366, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16728320</colorFondo></Grupo></Campos>', 0, 1),
(2538, 'ITI-07195', 59, NULL, 7, 14, 366, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(2539, 'ITI-07196', 206, NULL, 173, 14, 366, 7, 37, 28, 1, 1, 0, 294, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2540, 'ITI-07197', 49, NULL, 102, 14, 366, 7, 37, 18, 1, 1, 0, 239, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2544, 'ITI-07198', 3, NULL, 149, 14, 396, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2545, 'ITI-07199', 50, NULL, 143, 14, 372, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2546, 'ITI-07200', 137, NULL, 196, 14, 372, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2547, 'ITI-07201', 66, NULL, 9, 14, 372, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(2548, 'ITI-07202', 214, NULL, 154, 14, 372, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2549, 'ITI-07203', 39, NULL, 105, 14, 372, 7, 35, 30, 1, 1, 0, 306, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2550, 'ITI-07204', 216, NULL, 173, 14, 372, 7, 35, 31, 1, 1, 0, 291, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2551, 'ITI-07205', 215, NULL, 56, 14, 372, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2552, 'ITI-07206', 214, NULL, 179, 14, 373, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2553, 'ITI-07207', 137, NULL, 185, 14, 373, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2554, 'ITI-07208', 215, NULL, 100, 14, 373, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2555, 'ITI-07209', 66, NULL, 174, 14, 373, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2556, 'ITI-07210', 39, NULL, 105, 14, 373, 7, 35, 35, 1, 1, 0, 307, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2557, 'ITI-07211', 50, NULL, 148, 14, 373, 7, 35, 26, 1, 1, 0, 310, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2558, 'ITI-07212', 216, NULL, 173, 14, 373, 7, 35, 34, 1, 1, 0, 292, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2559, 'ITI-07213', 137, NULL, 196, 14, 374, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2560, 'ITI-07214', 216, NULL, 100, 14, 374, 7, 36, 36, 1, 1, 0, 293, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2561, 'ITI-07215', 214, NULL, 179, 14, 374, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2562, 'ITI-07216', 215, NULL, 56, 14, 374, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(2563, 'ITI-07217', 39, NULL, 105, 14, 374, 7, 35, 30, 1, 1, 0, 308, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2564, 'ITI-07218', 66, NULL, 189, 14, 374, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(2565, 'ITI-07219', 52, NULL, 95, 14, 375, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2568, 'ITI-07220', 223, NULL, 170, 14, 378, 7, 35, 22, 1, 1, 0, 295, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2569, 'ITI-07221', 2, NULL, 160, 14, 378, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2570, 'ITI-07222', 225, NULL, 56, 14, 378, 7, 35, 16, 1, 1, 0, 296, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2571, 'ITI-07223', 224, NULL, 156, 14, 378, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1983414</colorFondo></Grupo></Campos>', 0, 1),
(2572, 'ITI-07224', 129, NULL, 180, 14, 378, 7, 36, 12, 1, 1, 0, 241, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2573, 'ITI-07225', 52, NULL, 148, 14, 378, 7, 36, 16, 1, 1, 0, 242, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2578, 'ITI-07226', 218, NULL, 52, 14, 380, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2579, 'ITI-07227', 222, NULL, 43, 14, 380, 7, 35, 17, 1, 1, 0, 321, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2580, 'ITI-07228', 9, NULL, 149, 14, 380, 7, 38, 11, 1, 1, 0, 243, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(2583, 'ITI-02175', 9, NULL, 149, 14, 421, 2, 38, 8, 1, 1, 0, 243, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(2584, 'ITI-07229', 21, NULL, 156, 14, 382, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2315451</colorFondo></Grupo></Campos>', 0, 1),
(2585, 'ITI-07230', 53, NULL, 62, 14, 382, 7, 35, 17, 1, 1, 0, 286, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2586, 'ITI-07231', 106, NULL, 14, 14, 382, 7, 35, 14, 1, 1, 0, 244, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2587, 'ITI-02176', 106, NULL, 14, 14, 383, 2, 35, 11, 1, 1, 0, 244, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2588, 'ITI-07232', 35, NULL, 189, 14, 382, 7, 35, 7, 1, 1, 0, 289, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2589, 'ITI-07233', 46, NULL, 7, 14, 382, 7, 35, 20, 1, 1, 0, 245, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2590, 'ITI-02177', 46, NULL, 7, 14, 381, 2, 35, 2, 1, 1, 0, 245, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2591, 'ITI-07234', 80, NULL, 9, 14, 382, 7, 36, 17, 1, 1, 0, 246, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(2592, 'ITI-02178', 80, NULL, 9, 14, 383, 2, 36, 16, 1, 1, 0, 246, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(2593, 'ITI-07235', 210, NULL, 118, 14, 382, 7, 35, 22, 1, 1, 0, 318, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2594, 'ITI-07236', 53, NULL, 62, 14, 384, 7, 36, 24, 1, 1, 0, 288, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2595, 'ITI-07237', 35, NULL, 170, 14, 384, 7, 35, 29, 1, 1, 0, 290, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(2596, 'ITI-07238', 46, NULL, 7, 14, 384, 7, 35, 31, 1, 1, 0, 247, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2597, 'ITI-02179', 46, NULL, 7, 14, 381, 2, 35, 2, 1, 1, 0, 247, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2598, 'ITI-07239', 80, NULL, 9, 14, 384, 7, 36, 31, 1, 1, 0, 248, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(2599, 'ITI-02180', 80, NULL, 9, 14, 383, 2, 36, 1, 1, 1, 0, 248, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(2600, 'ITI-07240', 21, NULL, 189, 14, 384, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(2601, 'ITI-07241', 106, NULL, 14, 14, 384, 7, 35, 32, 1, 1, 0, 249, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2602, 'ITI-02181', 106, NULL, 14, 14, 383, 2, 35, 1, 1, 1, 0, 249, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2603, 'ITI-07242', 210, NULL, 118, 14, 384, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2604, 'ITI-02182', 83, NULL, 163, 14, 386, 2, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2605, 'ITI-02183', 1, NULL, 125, 14, 386, 2, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2606, 'ITI-02184', 57, NULL, 64, 14, 386, 2, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2607, 'ITI-02185', 144, NULL, 7, 14, 386, 2, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2608, 'ITI-02186', 8, NULL, 52, 14, 386, 2, 37, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(2609, 'ITI-02187', 7, NULL, 87, 14, 386, 2, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(2610, 'ITI-02188', 56, NULL, 22, 14, 386, 2, 35, 20, 1, 1, 0, 284, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2618, 'ITI-07243', 219, NULL, 105, 14, 378, 7, 70, 21, 1, 1, 0, 303, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-286076</colorFondo></Grupo></Campos>', 0, 1),
(2619, 'ITI-02189', 33, NULL, 105, 14, 383, 2, 70, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-884177</colorFondo></Grupo></Campos>', 0, 1),
(2634, 'ITI-02190', 56, NULL, 169, 14, 386, 2, 35, 4, 1, 1, 0, 250, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2643, 'MITI-05045', 199, NULL, 87, 14, 395, 5, 30, 0, 1, 1, 1, 251, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2645, 'MITI-05046', 198, NULL, 82, 14, 395, 5, 30, 11, 1, 1, 1, 252, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2647, 'MITI-05047', 174, NULL, 170, 14, 395, 5, 30, 12, 1, 1, 1, 253, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2650, 'MITI-05051', 195, NULL, 171, 14, 395, 5, 30, 0, 1, 1, 1, 254, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2652, 'MITI-05052', 30, NULL, 34, 14, 395, 5, 30, 0, 1, 1, 1, 255, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2654, 'MITI-05053', 196, NULL, 90, 14, 395, 5, 30, 0, 1, 1, 1, 256, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2656, 'MITI-05054', 184, NULL, 107, 14, 395, 5, 30, 0, 1, 1, 1, 257, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2658, 'MITI-05055', 173, NULL, 75, 14, 395, 5, 30, 0, 1, 1, 1, 258, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(2660, 'MITI-05056', 167, NULL, 103, 14, 395, 5, 30, 12, 1, 1, 0, 259, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2662, 'MITI-05057', 169, NULL, 12, 14, 395, 5, 30, 7, 1, 1, 0, 260, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2669, 'MITI-05058', 199, NULL, 163, 14, 395, 5, 35, 13, 1, 1, 1, 261, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2670, 'ITI-07244', 49, NULL, 95, 14, 396, 7, 35, 2, 1, 1, 0, 262, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2671, 'ITI-07245', 49, NULL, 95, 14, 396, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2674, 'ITI-07246', 52, NULL, 95, 14, 375, 7, 35, 8, 1, 1, 0, 263, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2677, 'ITI-07247', 51, NULL, 95, 14, 380, 7, 35, 9, 1, 1, 0, 264, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2680, 'ITI-02191', 88, NULL, 206, 14, 381, 2, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(2681, 'ITI-02192', 43, NULL, 206, 14, 381, 2, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2682, 'ITI-02193', 46, NULL, 125, 14, 383, 2, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2039837</colorFondo></Grupo></Campos>', 0, 1),
(2683, 'ITI-02194', 23, NULL, 138, 14, 383, 2, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(2684, 'ITI-02195', 54, NULL, 161, 14, 381, 2, 35, 13, 1, 1, 0, 265, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2687, 'ITI-02196', 2, NULL, 61, 14, 381, 2, 35, 7, 1, 1, 0, 266, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2688, 'ITI-07248', 2, NULL, 61, 14, 378, 7, 35, 1, 1, 1, 0, 266, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2691, 'ITI-02197', 107, NULL, 149, 14, 383, 2, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2692, 'ITI-02198', 83, NULL, 163, 14, 399, 2, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2693, 'ITI-02199', 57, NULL, 64, 14, 399, 2, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2694, 'ITI-02200', 7, NULL, 138, 14, 399, 2, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2695, 'ITI-02201', 55, NULL, 161, 14, 383, 2, 35, 12, 1, 1, 0, 267, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2699, 'ITI-02202', 72, NULL, 138, 14, 400, 2, 35, 11, 1, 1, 0, 268, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2701, 'ITI-02203', 152, NULL, 82, 14, 400, 2, 35, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2702, 'ITI-02204', 80, NULL, 61, 14, 383, 2, 35, 8, 1, 1, 0, 269, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2703, 'ITI-07249', 80, NULL, 61, 14, 382, 7, 35, 1, 1, 1, 0, 269, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2705, 'ITI-02205', 114, NULL, 206, 14, 400, 2, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(2706, 'ITI-02206', 143, NULL, 156, 14, 400, 2, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2707, 'ITI-02207', 135, NULL, 161, 14, 400, 2, 35, 5, 1, 1, 0, 270, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2710, 'ITI-02208', 101, NULL, 160, 14, 400, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2711, 'ITI-02209', 135, NULL, 169, 14, 386, 2, 35, 5, 1, 1, 0, 271, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2712, 'ITI-02210', 135, NULL, 169, 14, 401, 1, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2730, 'ITI-07250', 137, NULL, 118, 14, 408, 7, 35, 14, 1, 1, 0, 273, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2755, 'ITI-02210', 13, NULL, 195, 14, 381, 2, 35, 3, 1, 1, 0, 275, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2764, 'ITI-02211', 18, NULL, 199, 14, 381, 2, 35, 7, 1, 1, 0, 276, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2769, 'ITI-02212', 55, NULL, 168, 14, 383, 2, 30, 2, 1, 1, 0, 278, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2773, 'ITI-02213', 62, NULL, 118, 14, 381, 2, 35, 6, 1, 1, 0, 279, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(2787, 'ITI-07251', 50, NULL, 102, 14, 414, 7, 53, 25, 1, 1, 0, 280, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 0),
(2788, 'ITI-07252', 137, NULL, 78, 14, 414, 7, 53, 23, 1, 1, 0, 281, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 0),
(2790, 'ITI-07253', 66, NULL, 160, 14, 414, 7, 25, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 0),
(2791, 'ITI-07254', 39, NULL, 174, 14, 414, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(2792, 'ITI-07255', 214, NULL, 88, 14, 414, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 0),
(2793, 'ITI-07256', 206, NULL, 49, 14, 414, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 0),
(2794, 'ITI-07257', 215, NULL, 111, 14, 414, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 0),
(2795, 'ITI-07258', 216, NULL, 60, 14, 414, 7, 25, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(2796, 'ITI-07259', 65, NULL, 88, 14, 414, 7, 25, 13, 1, 1, 0, 282, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(2797, 'ITI-07260', 3, NULL, 52, 14, 414, 7, 15, 0, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 0),
(2800, 'ITI-02214', 112, NULL, 185, 14, 381, 2, 39, 2, 1, 1, 0, 238, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2803, 'ITI-07261', 56, NULL, 169, 14, 375, 7, 35, 0, 1, 1, 0, 250, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2804, 'ITI-07262', 56, NULL, 22, 14, 375, 7, 35, 5, 1, 1, 0, 284, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2808, 'ITI-07263', 54, NULL, 161, 14, 384, 7, 35, 0, 1, 1, 0, 265, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2810, 'ITI-02215', 53, NULL, 62, 14, 381, 2, 35, 9, 1, 1, 0, 286, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2811, 'ITI-02216', 53, NULL, 62, 14, 381, 2, 36, 3, 1, 1, 0, 288, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(2812, 'ITI-02217', 35, NULL, 189, 14, 421, 2, 35, 5, 1, 1, 0, 289, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2813, 'ITI-02218', 35, NULL, 170, 14, 381, 2, 35, 3, 1, 1, 0, 290, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(2814, 'ITI-02219', 90, NULL, 173, 14, 421, 2, 35, 1, 1, 1, 0, 291, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2815, 'ITI-02220', 90, NULL, 173, 14, 421, 2, 35, 1, 1, 1, 0, 292, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2816, 'ITI-02221', 90, NULL, 100, 14, 421, 2, 36, 0, 1, 1, 0, 293, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2817, 'ITI-02222', 78, NULL, 173, 14, 421, 2, 37, 6, 1, 1, 0, 294, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2818, 'ITI-02223', 87, NULL, 170, 14, 421, 2, 35, 3, 1, 1, 0, 295, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2820, 'ITI-02224', 92, NULL, 56, 14, 381, 2, 35, 3, 1, 1, 0, 296, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2828, 'ITI-02225', 124, NULL, 43, 14, 400, 2, 70, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(2830, 'ITI-02226', 32, NULL, 105, 14, 421, 2, 70, 5, 1, 1, 0, 303, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-286076</colorFondo></Grupo></Campos>', 0, 1),
(2836, 'ITI-02227', 39, NULL, 105, 14, 421, 2, 35, 0, 1, 1, 0, 306, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2837, 'ITI-02228', 39, NULL, 105, 14, 421, 2, 35, 0, 1, 1, 0, 307, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2838, 'ITI-02229', 39, NULL, 105, 14, 421, 2, 35, 2, 1, 1, 0, 308, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2843, 'ITI-07264', 156, NULL, 78, 14, 414, 7, 2, 2, 1, 1, 0, 311, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 0),
(2846, 'ITI-02230', 33, NULL, 52, 11, 309, 2, 35, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-14803426</colorLetra><colorFondo>-1184275</colorFondo></Grupo></Campos>', 0, 1),
(2850, 'ITI-07265', 9, NULL, 176, 14, 380, 7, 35, 2, 1, 1, 0, 314, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(2858, 'ITI-02231', 22, NULL, 61, 14, 381, 2, 20, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2859, 'ITI-07266', 129, NULL, 23, 14, 375, 7, 35, 5, 1, 1, 0, 316, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(2864, 'MITI-05059', 180, NULL, 156, 14, 395, 5, 35, 2, 1, 1, 1, 317, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(2865, 'ITI-07267', 9, NULL, 149, 14, 380, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2866, 'ITI-02232', 9, NULL, 176, 14, 381, 2, 35, 1, 1, 1, 0, 314, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(2869, 'ITI-07268', 54, NULL, 102, 14, 422, 7, 35, 2, 1, 1, 0, 319, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(2870, 'ITI-02233', 54, NULL, 102, 14, 381, 2, 35, 5, 1, 1, 0, 319, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(2874, 'ITI-07269', 55, NULL, 22, 14, 422, 7, 35, 4, 1, 1, 0, 320, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2875, 'ITI-02234', 55, NULL, 22, 14, 383, 2, 35, 2, 1, 1, 0, 320, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2879, 'ITI-02235', 79, NULL, 43, 14, 421, 2, 35, 0, 1, 1, 0, 321, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2887, 'ITI-07270', 137, NULL, 85, 14, 384, 7, 36, 1, 1, 1, 0, 324, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2888, 'ITI-07271', 56, NULL, 169, 14, 422, 7, 35, 0, 1, 1, 0, 323, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2889, 'ITI-02236', 52, NULL, 22, 14, 421, 2, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(2895, 'ITI-02237', 32, NULL, 52, 9, NULL, 2, 30, 12, 1, 1, 0, 0, 0, 'NULL', 0, 1),
(2896, 'ITI-07272', 66, NULL, 156, 15, 424, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(2897, 'ITI-07273', 214, NULL, 179, 15, 424, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(2898, 'ITI-07274', 137, NULL, 216, 15, 424, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(2899, 'ITI-07275', 216, NULL, 9, 15, 424, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2900, 'ITI-07276', 39, NULL, 105, 15, 424, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(2901, 'ITI-07277', 215, NULL, 56, 15, 424, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(2902, 'ITI-07278', 50, NULL, 148, 15, 424, 7, 35, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2903, 'ITI-07279', 3, NULL, 211, 15, 427, 7, 35, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2904, 'ITI-07280', 9, NULL, 164, 15, 428, 7, 35, 26, 1, 1, 0, 325, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2905, 'ITI-02238', 9, NULL, 164, 15, 429, 2, 35, 3, 1, 1, 0, 325, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2906, 'ITI-07281', 221, NULL, 213, 15, 428, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(2907, 'ITI-07282', 51, NULL, 62, 15, 428, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(2908, 'ITI-07283', 181, NULL, 7, 15, 428, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(2909, 'ITI-07284', 218, NULL, 52, 15, 428, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2910, 'ITI-07285', 121, NULL, 216, 15, 428, 7, 35, 28, 1, 1, 0, 414, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(2911, 'ITI-07286', 222, NULL, 14, 15, 428, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(2912, 'ITI-07287', 9, NULL, 164, 15, 430, 7, 40, 30, 1, 1, 0, 357, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2913, 'ITI-07288', 221, NULL, 100, 15, 430, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2914, 'ITI-07289', 51, NULL, 62, 15, 430, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(2915, 'ITI-07290', 181, NULL, 7, 15, 430, 7, 35, 33, 1, 1, 0, 360, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(2916, 'ITI-07291', 218, NULL, 52, 15, 430, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(2917, 'ITI-07292', 222, NULL, 14, 15, 430, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(2918, 'ITI-07293', 121, NULL, 118, 15, 430, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(2919, 'ITI-07294', 9, NULL, 164, 15, 431, 7, 35, 25, 1, 1, 0, 358, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(2920, 'ITI-07295', 121, NULL, 210, 15, 431, 7, 35, 28, 1, 1, 0, 420, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(2921, 'ITI-07296', 51, NULL, 62, 15, 431, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(2922, 'ITI-07297', 221, NULL, 163, 15, 431, 7, 35, 31, 1, 1, 0, 409, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(2923, 'ITI-07298', 222, NULL, 56, 15, 431, 7, 35, 28, 1, 1, 0, 412, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2924, 'ITI-07299', 181, NULL, 7, 15, 431, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(2925, 'ITI-07300', 218, NULL, 149, 15, 431, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2926, 'ITI-07301', 216, NULL, 9, 15, 427, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(2927, 'ITI-07302', 39, NULL, 105, 15, 427, 7, 35, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2929, 'ITI-07304', 80, NULL, 9, 15, 432, 7, 35, 19, 1, 1, 0, 365, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(2930, 'ITI-07305', 210, NULL, 23, 15, 432, 7, 36, 11, 1, 1, 0, 354, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(2931, 'ITI-07306', 46, NULL, 7, 15, 432, 7, 35, 23, 1, 1, 0, 366, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(2932, 'ITI-07307', 35, NULL, 189, 15, 432, 7, 35, 18, 1, 1, 0, 367, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(2933, 'ITI-07308', 53, NULL, 167, 15, 432, 7, 36, 14, 1, 1, 0, 363, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2934, 'ITI-07309', 21, NULL, 213, 15, 432, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2935, 'ITI-07310', 106, NULL, 14, 15, 432, 7, 35, 19, 1, 1, 0, 368, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2936, 'ITI-07311', 227, NULL, 207, 15, 433, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(2937, 'ITI-07312', 211, NULL, 210, 15, 433, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(2938, 'ITI-07313', 226, NULL, 170, 15, 433, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2939, 'ITI-07314', 253, NULL, 64, 15, 433, 7, 35, 30, 1, 1, 0, 370, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2940, 'ITI-07315', 43, NULL, 211, 15, 433, 7, 35, 31, 1, 1, 0, 372, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(2941, 'ITI-07316', 54, NULL, 167, 15, 433, 7, 35, 24, 1, 1, 0, 376, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(2942, 'ITI-07317', 47, NULL, 173, 15, 433, 7, 35, 29, 1, 1, 0, 374, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(2943, 'ITI-07318', 227, NULL, 23, 15, 434, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(2944, 'ITI-07319', 211, NULL, 210, 15, 434, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(2945, 'ITI-07320', 54, NULL, 22, 15, 434, 7, 35, 14, 1, 1, 0, 377, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(2946, 'ITI-07321', 226, NULL, 170, 15, 434, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(2947, 'ITI-07322', 253, NULL, 189, 15, 434, 7, 35, 16, 1, 1, 0, 371, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(2948, 'ITI-07323', 43, NULL, 211, 15, 434, 7, 35, 13, 1, 1, 0, 373, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(2949, 'ITI-07324', 47, NULL, 173, 15, 434, 7, 35, 10, 1, 1, 0, 375, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(2951, 'MITI-05060', 89, NULL, 170, 15, 436, 5, 35, 0, 1, 1, 0, 326, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2955, 'ITI-02239', 135, NULL, 169, 15, 438, 2, 35, 17, 1, 1, 0, 378, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(2956, 'ITI-02240', 143, NULL, 156, 15, 438, 2, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(2958, 'MITI-05061', 71, NULL, 107, 15, 436, 5, 30, 0, 1, 1, 0, 327, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(2959, 'ITI-02241', 136, NULL, 125, 15, 438, 2, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(2960, 'ITI-02242', 152, NULL, 82, 15, 438, 2, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(2962, 'MITI-05062', 70, NULL, 103, 15, 436, 5, 30, 0, 1, 1, 0, 328, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(2963, 'ITI-02243', 72, NULL, 189, 15, 438, 2, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(2964, 'ITI-02244', 101, NULL, 87, 15, 438, 2, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(2965, 'ITI-02245', 114, NULL, 163, 15, 438, 2, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(2967, 'MITI-05063', 160, NULL, 90, 15, 436, 5, 30, 0, 1, 1, 0, 329, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(2969, 'MITI-05064', 115, NULL, 156, 15, 440, 5, 30, 2, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(2971, 'MITI-05065', 203, NULL, 82, 15, 440, 5, 30, 6, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(2980, 'MITI-05070', 168, NULL, 12, 15, 443, 4, 30, 6, 1, 1, 0, 336, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2981, 'MITI-05071', 168, NULL, 12, 15, 442, 5, 30, 12, 1, 1, 0, 336, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(2983, 'MITI-05072', 170, NULL, 103, 15, 442, 5, 30, 7, 1, 1, 0, 337, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(2985, 'MITI-05073', 197, NULL, 163, 15, 442, 5, 30, 2, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(2987, 'MITI-05074', 198, NULL, 64, 15, 442, 5, 30, 1, 1, 1, 1, 0, 52, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(2989, 'ITI-07325', 50, NULL, 95, 15, 447, 7, 35, 8, 1, 1, 0, 340, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(2992, 'ITI-07326', 137, NULL, 85, 15, 447, 7, 35, 2, 1, 1, 0, 341, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(2999, 'ITI-07327', 50, NULL, 167, 15, 447, 7, 35, 4, 1, 1, 0, 344, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(3004, 'ITI-07328', 223, NULL, 149, 15, 450, 7, 35, 19, 1, 1, 0, 364, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3005, 'ITI-07329', 225, NULL, 56, 15, 450, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3008, 'ITI-02246', 111, NULL, 82, 15, 452, 2, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(3009, 'ITI-02247', 18, NULL, 118, 15, 452, 2, 35, 3, 1, 1, 0, 415, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(3011, 'ITI-02248', 12, NULL, 176, 15, 445, 2, 39, 4, 1, 1, 0, 345, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3012, 'ITI-02249', 1, NULL, 125, 15, 453, 2, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3013, 'ITI-02250', 23, NULL, 100, 15, 453, 2, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(3015, 'ITI-02251', 107, NULL, 149, 15, 453, 2, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3016, 'ITI-02252', 80, NULL, 138, 15, 453, 2, 35, 4, 1, 1, 0, 401, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3017, 'ITI-02253', 58, NULL, 64, 15, 453, 2, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(3018, 'ITI-02254', 55, NULL, 161, 15, 453, 2, 35, 14, 1, 1, 0, 379, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3028, 'ITI-07331', 51, NULL, 143, 15, 447, 7, 35, 1, 1, 1, 0, 349, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(3033, 'ITI-02255', 144, NULL, 125, 15, 456, 2, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3034, 'ITI-02256', 7, NULL, 138, 15, 456, 2, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(3035, 'ITI-02257', 8, NULL, 52, 15, 456, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3038, 'ITI-02258', 135, NULL, 161, 15, 456, 2, 36, 20, 1, 1, 0, 380, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(3039, 'ITI-02259', 56, NULL, 161, 15, 456, 2, 35, 13, 1, 1, 0, 381, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(3044, 'ITI-02260', 112, NULL, 85, 15, 445, 2, 35, 6, 1, 1, 0, 351, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3045, 'ITI-07332', 156, NULL, 85, 15, 447, 7, 35, 4, 1, 1, 0, 351, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3057, 'ITI-02264', 9, NULL, 164, 15, 429, 2, 40, 3, 1, 1, 0, 357, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(3058, 'ITI-02265', 9, NULL, 164, 15, 429, 2, 35, 5, 1, 1, 0, 358, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(3061, 'ITI-02267', 100, NULL, 7, 15, 461, 2, 35, 1, 1, 1, 0, 360, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3067, 'ITI-02270', 87, NULL, 149, 15, 462, 2, 35, 2, 1, 1, 0, 364, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3068, 'ITI-02271', 80, NULL, 9, 15, 453, 2, 35, 4, 1, 1, 0, 365, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(3069, 'ITI-02272', 46, NULL, 7, 15, 429, 2, 35, 1, 1, 1, 0, 366, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(3070, 'ITI-02273', 35, NULL, 189, 15, 452, 2, 35, 1, 1, 1, 0, 367, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3072, 'ITI-02274', 106, NULL, 14, 15, 453, 2, 35, 10, 1, 1, 0, 368, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(3075, 'ITI-02275', 22, NULL, 64, 15, 452, 2, 35, 3, 1, 1, 0, 370, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(3076, 'ITI-02276', 22, NULL, 189, 15, 452, 2, 35, 2, 1, 1, 0, 371, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(3078, 'ITI-02277', 43, NULL, 211, 15, 452, 2, 35, 1, 1, 1, 0, 372, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(3079, 'ITI-02278', 43, NULL, 211, 15, 452, 2, 35, 4, 1, 1, 0, 373, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3080, 'ITI-02279', 47, NULL, 173, 15, 452, 2, 35, 1, 1, 1, 0, 374, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3081, 'ITI-02280', 47, NULL, 173, 15, 452, 2, 35, 2, 1, 1, 0, 375, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3082, 'ITI-02281', 54, NULL, 167, 15, 429, 2, 35, 11, 1, 1, 0, 376, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3083, 'ITI-02282', 54, NULL, 22, 15, 429, 2, 35, 4, 1, 1, 0, 377, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(3122, 'ITI-02284', 13, NULL, 118, 15, 429, 2, 35, 5, 1, 1, 0, 390, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(3123, 'ITI-07337', 121, NULL, 199, 15, 470, 7, 50, 17, 1, 1, 0, 391, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 0),
(3129, 'ITI-07338', 51, NULL, 148, 15, 470, 7, 50, 19, 1, 1, 0, 392, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 0),
(3133, 'ITI-02285', 135, NULL, 169, 15, 445, 2, 35, 1, 1, 1, 0, 393, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(3148, 'ITI-07340', 51, NULL, 148, 15, 450, 7, 35, 1, 1, 1, 0, 396, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3153, 'ITI-07341', 222, NULL, 100, 15, 470, 7, 25, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 0),
(3154, 'ITI-07342', 9, NULL, 179, 15, 470, 7, 25, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(3155, 'ITI-07343', 181, NULL, 105, 15, 470, 7, 25, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 0),
(3156, 'ITI-07344', 218, NULL, 60, 15, 470, 7, 25, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 0),
(3162, 'ITI-07345', 221, NULL, 213, 15, 470, 7, 25, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 0),
(3178, 'ITI-02286', 124, NULL, 43, 15, 479, 2, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3179, 'ITI-02287', 33, NULL, 105, 15, 453, 2, 70, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3180, 'ITI-07346', 219, NULL, 105, 15, 450, 7, 35, 7, 1, 1, 0, 428, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3185, 'ITI-02288', 56, NULL, 161, 15, 453, 2, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(3186, 'ITI-07347', 56, NULL, 161, 15, 447, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(3191, 'ITI-02289', 55, NULL, 161, 15, 453, 2, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3192, 'ITI-07348', 55, NULL, 161, 15, 447, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3223, 'ITI-02298', 52, NULL, 95, 15, 462, 2, 35, 1, 1, 1, 0, 403, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3224, 'ITI-07351', 52, NULL, 95, 15, 450, 7, 35, 1, 1, 1, 0, 403, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3233, 'ITI-02301', 103, NULL, 163, 15, 461, 2, 35, 1, 1, 1, 0, 409, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3236, 'ITI-02304', 79, NULL, 56, 15, 461, 2, 35, 1, 1, 1, 0, 412, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3252, 'ITI-07352', 210, NULL, 118, 15, 450, 7, 35, 9, 1, 1, 0, 415, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(3256, 'MITI-05075', 195, NULL, 176, 15, 440, 5, 35, 1, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3258, 'ITI-02306', 114, NULL, 163, 15, 438, 2, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3265, 'ITI-07353', 53, NULL, 22, 15, 432, 7, 30, 0, 1, 1, 0, 421, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(3273, 'ITI-02307', 136, NULL, 7, 15, 438, 2, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(3274, 'ITI-02308', 106, NULL, 56, 15, 453, 2, 35, 17, 1, 1, 0, 423, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3275, 'ITI-07355', 106, NULL, 56, 15, 432, 7, 35, 3, 1, 1, 0, 423, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3281, 'ITI-02309', 56, NULL, 169, 15, 456, 2, 35, 3, 1, 1, 0, 424, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3282, 'ITI-02310', 101, NULL, 176, 15, 438, 2, 15, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3285, 'ITI-07356', 39, NULL, 105, 15, 427, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3286, 'ITI-07357', 106, NULL, 14, 15, 432, 7, 35, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(3289, 'ITI-02312', 54, NULL, 190, 15, 429, 2, 35, 4, 1, 1, 0, 422, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(3291, 'ITI-02313', 32, NULL, 105, 15, 462, 2, 35, 1, 1, 1, 0, 428, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3292, 'ITI-02314', 107, NULL, 149, 15, 453, 2, 35, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(3295, 'ITI-07358', 215, NULL, 111, 15, 470, 7, 15, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 0),
(3296, 'ITI-07359', 66, NULL, 160, 15, 470, 7, 4, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 0),
(3297, 'ITI-02315', 62, NULL, 118, 15, 462, 2, 10, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(3298, 'ITI-02316', 57, NULL, 64, 15, 456, 2, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3300, 'ITI-07360', 216, NULL, 60, 15, 470, 7, 10, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 0),
(3301, 'ITI-07361', 206, NULL, 49, 15, 470, 7, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(3303, 'ITI-07362', 206, NULL, 176, 16, 485, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(3304, 'ITI-07363', 65, NULL, 179, 16, 485, 7, 37, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3305, 'ITI-07364', 156, NULL, 210, 16, 485, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3306, 'ITI-07365', 59, NULL, 233, 16, 485, 7, 37, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3307, 'ITI-07366', 3, NULL, 222, 16, 485, 7, 37, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(3308, 'ITI-07367', 40, NULL, 174, 16, 485, 7, 37, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(3309, 'ITI-07368', 49, NULL, 143, 16, 486, 7, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3310, 'ITI-07369', 206, NULL, 176, 16, 486, 7, 37, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3311, 'ITI-07370', 3, NULL, 222, 16, 486, 7, 36, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(3312, 'ITI-07371', 65, NULL, 56, 16, 486, 7, 36, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3313, 'ITI-07372', 40, NULL, 174, 16, 486, 7, 37, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3314, 'ITI-07373', 156, NULL, 118, 16, 486, 7, 37, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3315, 'ITI-07374', 59, NULL, 173, 16, 486, 7, 36, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3316, 'ITI-07375', 49, NULL, 143, 16, 487, 7, 36, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3317, 'ITI-07376', 206, NULL, 176, 16, 487, 7, 37, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3318, 'ITI-07377', 65, NULL, 179, 16, 487, 7, 37, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3319, 'ITI-07378', 40, NULL, 174, 16, 487, 7, 37, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3320, 'ITI-07379', 3, NULL, 222, 16, 487, 7, 36, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(3321, 'ITI-07380', 156, NULL, 118, 16, 487, 7, 36, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3322, 'ITI-07381', 59, NULL, 173, 16, 487, 7, 37, 38, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3323, 'ITI-07382', 51, NULL, 62, 16, 488, 7, 28, 22, 1, 1, 0, 429, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3325, 'ITI-07383', 218, NULL, 156, 16, 488, 7, 37, 32, 1, 1, 0, 452, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3326, 'ITI-07384', 121, NULL, 210, 16, 488, 7, 26, 22, 1, 1, 0, 453, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3327, 'ITI-07385', 221, NULL, 163, 16, 488, 7, 35, 24, 1, 1, 0, 507, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(3328, 'ITI-07386', 181, NULL, 105, 16, 488, 7, 28, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(3329, 'ITI-07387', 9, NULL, 209, 16, 488, 7, 26, 21, 1, 1, 0, 450, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3330, 'ITI-07388', 222, NULL, 56, 16, 488, 7, 27, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3331, 'ITI-07389', 224, NULL, 221, 16, 490, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3332, 'ITI-07390', 2, NULL, 187, 16, 490, 7, 25, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3333, 'ITI-07391', 225, NULL, 14, 16, 490, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(3334, 'ITI-07392', 129, NULL, 216, 16, 490, 7, 25, 17, 1, 1, 0, 494, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3335, 'ITI-07393', 223, NULL, 189, 16, 490, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(3336, 'ITI-07394', 52, NULL, 190, 16, 491, 7, 35, 24, 1, 1, 0, 499, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3337, 'ITI-07395', 224, NULL, 221, 16, 491, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3338, 'ITI-07396', 2, NULL, 187, 16, 491, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3339, 'ITI-07397', 223, NULL, 189, 16, 491, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3340, 'ITI-07398', 225, NULL, 14, 16, 491, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3341, 'ITI-07399', 129, NULL, 216, 16, 491, 7, 36, 34, 1, 1, 0, 502, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(3342, 'ITI-07400', 224, NULL, 221, 16, 492, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3343, 'ITI-07401', 52, NULL, 190, 16, 492, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3344, 'ITI-07402', 225, NULL, 14, 16, 492, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3345, 'ITI-07403', 223, NULL, 189, 16, 492, 7, 35, 29, 1, 1, 0, 488, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3346, 'ITI-07404', 2, NULL, 186, 16, 492, 7, 26, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3347, 'ITI-07405', 129, NULL, 216, 16, 492, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3348, 'ITI-07406', 223, NULL, 60, 16, 494, 7, 17, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 0),
(3349, 'ITI-07407', 2, NULL, 154, 16, 494, 7, 17, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 0),
(3350, 'ITI-07408', 225, NULL, 56, 16, 494, 7, 17, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(3351, 'ITI-07409', 129, NULL, 226, 16, 494, 7, 44, 18, 1, 1, 0, 436, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 0),
(3352, 'ITI-07410', 224, NULL, 7, 16, 494, 7, 17, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(3353, 'ITI-07411', 52, NULL, 167, 16, 494, 7, 44, 17, 1, 1, 0, 431, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 0),
(3354, 'ITI-07412', 218, NULL, 160, 16, 494, 7, 11, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 0),
(3355, 'ITI-07413', 211, NULL, 199, 16, 495, 7, 27, 16, 1, 1, 0, 491, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(3356, 'ITI-07414', 226, NULL, 156, 16, 495, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3357, 'ITI-07415', 253, NULL, 60, 16, 495, 7, 30, 21, 1, 1, 0, 447, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3358, 'ITI-07416', 43, NULL, 105, 16, 495, 7, 30, 24, 1, 1, 0, 448, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3359, 'ITI-07417', 54, NULL, 168, 16, 495, 7, 30, 16, 1, 1, 0, 490, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3360, 'ITI-07418', 47, NULL, 173, 16, 495, 7, 30, 17, 1, 1, 0, 449, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3361, 'ITI-07419', 227, NULL, 23, 16, 495, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3362, 'ITI-07420', 229, NULL, 100, 16, 496, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(3363, 'ITI-07421', 230, NULL, 87, 16, 496, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(3365, 'ITI-07423', 87, NULL, 170, 16, 496, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(3366, 'ITI-07424', 231, NULL, 9, 16, 496, 7, 26, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(3367, 'ITI-07425', 228, NULL, 64, 16, 496, 7, 35, 22, 1, 1, 0, 467, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3368, 'ITI-07426', 55, NULL, 167, 16, 496, 7, 26, 20, 1, 1, 0, 479, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(3369, 'ITI-07427', 87, NULL, 170, 16, 498, 7, 30, 14, 1, 1, 0, 445, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(3370, 'ITI-07428', 228, NULL, 105, 16, 498, 7, 30, 9, 1, 1, 0, 468, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3371, 'ITI-07429', 230, NULL, 87, 16, 498, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3372, 'ITI-07430', 231, NULL, 9, 16, 498, 7, 25, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3373, 'ITI-07431', 229, NULL, 43, 16, 498, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(3374, 'ITI-07432', 55, NULL, 219, 16, 498, 7, 30, 14, 1, 1, 0, 444, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3400, 'ITI-02317', 12, NULL, 65, 16, 497, 2, 35, 3, 1, 1, 0, 430, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(3464, 'ITI-02318', 83, NULL, 163, 16, 512, 2, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3465, 'ITI-02319', 57, NULL, 64, 16, 512, 2, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3466, 'ITI-02320', 101, NULL, 138, 16, 512, 2, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3467, 'ITI-02321', 56, NULL, 161, 16, 512, 2, 31, 18, 1, 1, 0, 441, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(3468, 'ITI-02322', 136, NULL, 7, 16, 512, 2, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(3469, 'ITI-02323', 8, NULL, 52, 16, 512, 2, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3505, 'ITI-07433', 49, NULL, 168, 16, 485, 7, 37, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3506, 'ITI-07434', 49, NULL, 217, 16, 515, 7, 67, 26, 1, 1, 0, 432, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(3507, 'ITI-07435', 156, NULL, 199, 16, 515, 7, 67, 26, 1, 1, 0, 433, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(3508, 'ITI-07436', 40, NULL, 7, 16, 515, 7, 66, 26, 1, 1, 0, 434, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(3509, 'ITI-07437', 65, NULL, 88, 16, 515, 7, 67, 26, 1, 1, 0, 435, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(3510, 'ITI-07438', 59, NULL, 7, 16, 515, 7, 0, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(3511, 'ITI-07439', 3, NULL, 52, 16, 515, 7, 0, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(3515, 'ITI-02324', 62, NULL, 118, 16, 497, 2, 25, 1, 1, 1, 0, 439, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3517, 'ITI-02325', 53, NULL, 219, 16, 497, 2, 27, 2, 1, 1, 0, 440, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3518, 'ITI-07440', 53, NULL, 219, 16, 532, 7, 27, 7, 1, 1, 0, 440, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3523, 'ITI-07441', 56, NULL, 161, 16, 496, 7, 31, 1, 1, 1, 0, 441, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(3525, 'ITI-02326', 56, NULL, 161, 16, 511, 6, 31, 1, 1, 1, 0, 441, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(3527, 'ITI-02326', 143, NULL, 60, 16, 525, 2, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3528, 'ITI-02327', 135, NULL, 161, 16, 525, 2, 38, 10, 1, 1, 0, 442, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3533, 'ITI-02328', 7, NULL, 138, 16, 525, 2, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(3534, 'ITI-02329', 135, NULL, 161, 16, 525, 2, 35, 22, 1, 1, 0, 443, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3536, 'ITI-02330', 1, NULL, 100, 16, 526, 2, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3537, 'ITI-02331', 152, NULL, 100, 16, 526, 2, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3546, 'ITI-02332', 55, NULL, 219, 16, 512, 2, 30, 5, 1, 1, 0, 444, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3549, 'ITI-02333', 111, NULL, 170, 16, 497, 2, 30, 1, 1, 1, 0, 445, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(3551, 'ITI-02335', 22, NULL, 60, 16, 497, 2, 30, 1, 1, 1, 0, 447, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3552, 'ITI-02336', 43, NULL, 105, 16, 497, 2, 30, 3, 1, 1, 0, 448, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3553, 'ITI-02337', 47, NULL, 173, 16, 497, 2, 30, 2, 1, 1, 0, 449, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3554, 'ITI-02338', 9, NULL, 209, 16, 497, 2, 26, 3, 1, 1, 0, 450, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3555, 'ITI-07443', 80, NULL, 9, 16, 492, 7, 35, 20, 1, 1, 0, 451, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3558, 'ITI-02330', 80, NULL, 9, 16, 497, 2, 35, 8, 1, 1, 0, 451, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3561, 'ITI-07444', 9, NULL, 235, 16, 488, 7, 36, 27, 1, 1, 0, 454, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3564, 'ITI-02331', 9, NULL, 235, 16, 512, 2, 36, 3, 1, 1, 0, 454, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3566, 'MITI-05076', 169, NULL, 103, 16, 530, 5, 30, 12, 1, 1, 0, 455, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3568, 'MITI-05077', 189, NULL, 163, 16, 530, 5, 30, 8, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3569, 'MITI-05078', 204, NULL, 163, 16, 530, 5, 30, 8, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3572, 'MITI-05079', 186, NULL, 170, 16, 530, 5, 30, 8, 1, 1, 1, 458, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3573, 'MITI-05080', 171, NULL, 87, 16, 530, 5, 30, 8, 1, 1, 1, 459, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3585, 'MITI-05085', 89, NULL, 170, 16, 530, 5, 30, 7, 1, 1, 0, 464, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3590, 'MITI-05087', 71, NULL, 107, 16, 530, 5, 30, 7, 1, 1, 0, 466, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3593, 'ITI-02332', 58, NULL, 64, 16, 497, 2, 35, 5, 1, 1, 0, 467, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3594, 'ITI-02333', 58, NULL, 105, 16, 497, 2, 30, 5, 1, 1, 0, 468, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3606, 'ITI-07445', 219, NULL, 60, 16, 490, 7, 100, 71, 1, 1, 0, 477, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3607, 'ITI-02334', 32, NULL, 60, 16, 497, 2, 100, 1, 1, 1, 0, 477, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3608, 'ITI-07446', 220, NULL, 60, 16, 496, 7, 100, 22, 1, 1, 0, 478, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3609, 'ITI-02335', 33, NULL, 60, 16, 497, 2, 100, 19, 1, 1, 0, 478, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3610, 'ITI-02336', 124, NULL, 43, 16, 534, 2, 50, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3616, 'ITI-02337', 55, NULL, 167, 16, 512, 2, 26, 1, 1, 1, 0, 479, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(3626, 'ITI-02340', 87, NULL, 189, 16, 497, 2, 35, 1, 1, 1, 0, 488, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3629, 'ITI-02341', 54, NULL, 168, 16, 497, 2, 30, 2, 1, 1, 0, 490, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3643, 'ITI-07447', 53, NULL, 220, 16, 532, 7, 35, 2, 1, 1, 0, 497, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(3648, 'ITI-02343', 55, NULL, 22, 16, 497, 2, 30, 3, 1, 1, 0, 498, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(3666, 'ITI-07449', 2, NULL, 234, 16, 492, 7, 30, 1, 1, 1, 0, 501, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3668, 'ITI-07450', 43, NULL, 105, 16, 495, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(3670, 'ITI-07451', 55, NULL, 169, 16, 496, 7, 30, 2, 1, 1, 0, 437, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3671, 'ITI-07452', 121, NULL, 118, 16, 488, 7, 30, 3, 1, 1, 0, 503, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3672, 'ITI-07453', 129, NULL, 216, 16, 491, 7, 33, 2, 1, 1, 0, 504, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(3673, 'ITI-07454', 211, NULL, 199, 16, 495, 7, 29, 2, 1, 1, 0, 505, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(3674, 'ITI-02344', 72, NULL, 138, 16, 525, 2, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(3675, 'ITI-07455', 47, NULL, 173, 16, 495, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3679, 'ITI-02345', 103, NULL, 163, 16, 497, 2, 35, 1, 1, 1, 0, 507, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(3682, 'ITI-07457', 222, NULL, 56, 16, 488, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3683, 'ITI-02346', 55, NULL, 169, 16, 512, 2, 30, 3, 1, 1, 0, 437, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(3684, 'ITI-02347', 80, NULL, 21, 16, 512, 2, 25, 2, 1, 1, 0, 510, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(3685, 'ITI-02348', 58, NULL, 64, 16, 512, 2, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3686, 'ITI-02349', 107, NULL, 189, 16, 512, 2, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3687, 'ITI-02350', 88, NULL, 64, 16, 526, 2, 2, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(3689, 'MITI-05089', 170, NULL, 103, 16, 530, 5, 35, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(3691, 'ITI-07459', 224, NULL, 221, 16, 492, 7, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3692, 'ITI-02351', 104, NULL, 118, 16, 497, 2, 2, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3693, 'ITI-02352', 101, NULL, 176, 16, 525, 2, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1250856</colorFondo></Grupo></Campos>', 0, 1),
(3769, 'ITI-07460', 65, NULL, 241, 17, 547, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(3770, 'ITI-07461', 49, NULL, 95, 17, 547, 7, 30, 11, 1, 1, 0, 555, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3771, 'ITI-07462', 206, NULL, 173, 17, 547, 7, 37, 35, 1, 1, 0, 593, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3772, 'ITI-07463', 3, NULL, 100, 17, 547, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3773, 'ITI-07464', 59, NULL, 189, 17, 547, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(3774, 'ITI-07465', 40, NULL, 243, 17, 547, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3775, 'ITI-07466', 156, NULL, 85, 17, 547, 7, 39, 13, 1, 1, 0, 516, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3776, 'ITI-07467', 216, NULL, 222, 17, 548, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(3777, 'ITI-07468', 215, NULL, 56, 17, 548, 7, 35, 31, 1, 1, 0, 599, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(3778, 'ITI-07469', 214, NULL, 21, 17, 548, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3779, 'ITI-07470', 39, NULL, 105, 17, 548, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3780, 'ITI-07471', 137, NULL, 216, 17, 548, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(3781, 'ITI-07472', 66, NULL, 241, 17, 548, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3782, 'ITI-07473', 214, NULL, 179, 17, 549, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3783, 'ITI-07474', 216, NULL, 222, 17, 549, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3784, 'ITI-07475', 66, NULL, 243, 17, 549, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3785, 'ITI-07476', 39, NULL, 105, 17, 549, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(3786, 'ITI-07477', 215, NULL, 56, 17, 549, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3787, 'ITI-07478', 137, NULL, 216, 17, 549, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(3788, 'ITI-07479', 50, NULL, 218, 17, 549, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(3789, 'ITI-07480', 50, NULL, 249, 17, 550, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3790, 'ITI-07481', 66, NULL, 243, 17, 550, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3791, 'ITI-07482', 137, NULL, 216, 17, 550, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(3792, 'ITI-07483', 216, NULL, 222, 17, 550, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(3793, 'ITI-07484', 214, NULL, 187, 17, 550, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3794, 'ITI-07485', 215, NULL, 242, 17, 550, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3795, 'ITI-07486', 39, NULL, 105, 17, 550, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(3796, 'ITI-07487', 216, NULL, 221, 17, 551, 7, 25, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(3797, 'ITI-07488', 206, NULL, 233, 17, 551, 7, 25, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 0),
(3798, 'ITI-07489', 214, NULL, 88, 17, 551, 7, 25, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 0),
(3799, 'ITI-07490', 66, NULL, 179, 17, 551, 7, 25, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(3800, 'ITI-07491', 137, NULL, 216, 17, 551, 7, 25, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 0),
(3801, 'ITI-07492', 39, NULL, 105, 17, 551, 7, 25, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(3802, 'ITI-07493', 215, NULL, 242, 17, 551, 7, 25, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(3803, 'ITI-07494', 50, NULL, 218, 17, 551, 7, 25, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 0),
(3804, 'ITI-07495', 65, NULL, 88, 17, 551, 7, 25, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 0),
(3807, 'ITI-07496', 52, NULL, 167, 17, 552, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3808, 'ITI-07497', 2, NULL, 131, 17, 552, 7, 35, 27, 1, 1, 0, 517, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3809, 'ITI-07498', 129, NULL, 118, 17, 552, 7, 36, 21, 1, 1, 0, 518, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(3810, 'ITI-07499', 223, NULL, 138, 17, 552, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(3811, 'ITI-07500', 225, NULL, 56, 17, 552, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(3812, 'ITI-07501', 224, NULL, 163, 17, 552, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(3813, 'ITI-07502', 21, NULL, 60, 17, 553, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(3814, 'ITI-07503', 106, NULL, 14, 17, 553, 7, 30, 22, 1, 1, 0, 588, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3815, 'ITI-07504', 210, NULL, 199, 17, 553, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3816, 'ITI-07505', 35, NULL, 221, 17, 553, 7, 30, 21, 1, 1, 0, 554, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3817, 'ITI-07506', 80, NULL, 187, 17, 553, 7, 25, 16, 1, 1, 0, 553, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(3818, 'ITI-07507', 46, NULL, 174, 17, 553, 7, 30, 22, 1, 1, 0, 602, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(3819, 'ITI-07508', 210, NULL, 199, 17, 554, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(3820, 'ITI-07509', 53, NULL, 249, 17, 554, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3821, 'ITI-07510', 21, NULL, 60, 17, 554, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3822, 'ITI-07511', 87, NULL, 156, 17, 558, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3823, 'ITI-07512', 87, NULL, 156, 17, 557, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3824, 'ITI-07513', 230, NULL, 87, 17, 557, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3825, 'ITI-07514', 229, NULL, 43, 17, 557, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3826, 'ITI-07515', 231, NULL, 9, 17, 557, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3827, 'ITI-07516', 228, NULL, 64, 17, 557, 7, 30, 20, 1, 1, 0, 541, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(3828, 'ITI-07517', 55, NULL, 168, 17, 557, 7, 35, 19, 1, 1, 0, 542, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(3829, 'ITI-07518', 234, NULL, 100, 17, 558, 7, 30, 25, 1, 1, 0, 532, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3830, 'ITI-07519', 232, NULL, 156, 17, 558, 7, 30, 22, 1, 1, 0, 533, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(3831, 'ITI-07520', 56, NULL, 62, 17, 558, 7, 30, 20, 1, 1, 0, 534, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3832, 'ITI-07521', 235, NULL, 52, 17, 558, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(3833, 'ITI-07522', 88, NULL, 189, 17, 558, 7, 35, 26, 1, 1, 0, 535, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3834, 'ITI-07523', 233, NULL, 87, 17, 558, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3835, 'ITI-07524', 144, NULL, 7, 17, 558, 7, 30, 22, 1, 1, 0, 536, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(3836, 'ITI-07525', 35, NULL, 221, 17, 556, 7, 17, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(3837, 'ITI-07526', 53, NULL, 220, 17, 556, 7, 20, 13, 1, 1, 0, 513, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(3838, 'ITI-07527', 210, NULL, 207, 17, 556, 7, 20, 14, 1, 1, 0, 514, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(3839, 'ITI-07528', 21, NULL, 60, 17, 556, 7, 17, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 0),
(3840, 'ITI-07529', 80, NULL, 186, 17, 556, 7, 17, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(3841, 'ITI-07530', 106, NULL, 242, 17, 556, 7, 17, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 0),
(3842, 'ITI-07531', 46, NULL, 173, 17, 556, 7, 17, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(3843, 'ITI-07532', 35, NULL, 170, 17, 554, 7, 35, 32, 1, 1, 0, 547, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3844, 'ITI-07533', 80, NULL, 9, 17, 554, 7, 35, 29, 1, 1, 0, 552, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(3845, 'ITI-07534', 46, NULL, 174, 17, 554, 7, 30, 19, 1, 1, 0, 551, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(3846, 'ITI-07535', 106, NULL, 14, 17, 554, 7, 35, 27, 1, 1, 0, 550, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3847, 'ITI-07536', 210, NULL, 199, 17, 555, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(3848, 'ITI-07537', 106, NULL, 14, 17, 555, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3849, 'ITI-07538', 21, NULL, 189, 17, 555, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(3850, 'ITI-07539', 35, NULL, 170, 17, 555, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3851, 'ITI-07540', 53, NULL, 249, 17, 555, 7, 30, 23, 1, 1, 0, 589, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(3852, 'ITI-07541', 80, NULL, 9, 17, 555, 7, 35, 25, 1, 1, 0, 545, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3853, 'ITI-07542', 46, NULL, 173, 17, 555, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(3854, 'ITI-07543', 232, NULL, 163, 17, 559, 7, 30, 13, 1, 1, 0, 515, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3855, 'ITI-07544', 144, NULL, 7, 17, 559, 7, 30, 21, 1, 1, 0, 537, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(3856, 'ITI-07545', 235, NULL, 52, 17, 559, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(3857, 'ITI-07546', 56, NULL, 95, 17, 559, 7, 30, 4, 1, 1, 0, 538, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3858, 'ITI-07547', 234, NULL, 100, 17, 559, 7, 30, 6, 1, 1, 0, 539, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3859, 'ITI-02353', 152, NULL, 241, 17, 561, 2, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3860, 'ITI-02354', 101, NULL, 160, 17, 561, 2, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3861, 'ITI-02355', 72, NULL, 138, 17, 561, 2, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3862, 'ITI-02356', 135, NULL, 219, 17, 561, 2, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(3863, 'ITI-02357', 136, NULL, 100, 17, 561, 2, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(3864, 'ITI-02358', 114, NULL, 163, 17, 561, 2, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3865, 'ITI-02359', 135, NULL, 219, 17, 561, 2, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3866, 'ITI-02360', 135, NULL, 219, 17, 561, 2, 36, 21, 1, 1, 0, 519, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3867, 'ITI-02361', 143, NULL, 163, 17, 561, 2, 30, 10, 1, 1, 0, 515, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3909, 'ITI-07548', 9, NULL, 107, 17, 553, 7, 48, 13, 1, 1, 0, 522, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3951, 'ITI-02362', 135, NULL, 169, 17, 562, 2, 35, 6, 1, 1, 0, 528, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3959, 'ITI-07551', 219, NULL, 60, 17, 552, 7, 50, 27, 1, 1, 0, 531, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3960, 'ITI-07552', 220, NULL, 60, 17, 557, 7, 50, 7, 1, 1, 0, 530, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(3961, 'ITI-02363', 33, NULL, 60, 17, 562, 2, 50, 5, 1, 1, 0, 530, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(3962, 'ITI-02364', 32, NULL, 60, 17, 562, 2, 50, 2, 1, 1, 0, 531, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(3963, 'ITI-02365', 124, NULL, 43, 17, 562, 2, 50, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(3964, 'ITI-02366', 9, NULL, 107, 17, 562, 2, 48, 1, 1, 1, 0, 522, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(3965, 'ITI-02367', 1, NULL, 100, 17, 562, 2, 30, 3, 1, 1, 0, 532, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(3966, 'ITI-02368', 143, NULL, 156, 17, 562, 2, 30, 5, 1, 1, 0, 533, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(3967, 'ITI-02369', 56, NULL, 62, 17, 562, 2, 30, 5, 1, 1, 0, 534, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(3968, 'ITI-02370', 88, NULL, 189, 17, 562, 2, 35, 6, 1, 1, 0, 535, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3969, 'ITI-02371', 144, NULL, 7, 17, 562, 2, 30, 2, 1, 1, 0, 536, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(3970, 'ITI-02372', 144, NULL, 7, 17, 562, 2, 30, 8, 1, 1, 0, 537, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(3971, 'ITI-02373', 56, NULL, 95, 17, 562, 2, 30, 4, 1, 1, 0, 538, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(3972, 'ITI-02374', 1, NULL, 100, 17, 562, 2, 30, 3, 1, 1, 0, 539, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3974, 'ITI-02376', 58, NULL, 64, 17, 562, 2, 30, 6, 1, 1, 0, 541, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(3975, 'ITI-02377', 55, NULL, 168, 17, 562, 2, 35, 9, 1, 1, 0, 542, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(3976, 'ITI-02378', 106, NULL, 14, 17, 562, 2, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(3978, 'ITI-02380', 80, NULL, 9, 17, 562, 2, 35, 5, 1, 1, 0, 545, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3980, 'ITI-07553', 35, NULL, 170, 17, 562, 2, 35, 1, 1, 1, 0, 547, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(3986, 'ITI-02554', 106, NULL, 14, 17, 562, 2, 35, 6, 1, 1, 0, 550, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(3987, 'ITI-02555', 46, NULL, 174, 17, 562, 2, 30, 3, 1, 1, 0, 551, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(3988, 'ITI-02556', 80, NULL, 9, 17, 562, 2, 35, 5, 1, 1, 0, 552, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(3990, 'ITI-02558', 35, NULL, 221, 17, 562, 2, 30, 2, 1, 1, 0, 554, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3993, 'ITI-07554', 210, NULL, 118, 17, 555, 7, 38, 2, 1, 1, 0, 557, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3995, 'ITI-02559', 18, NULL, 118, 17, 562, 2, 38, 1, 1, 1, 0, 557, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(3996, 'ITI-07555', 53, NULL, 219, 17, 548, 7, 30, 15, 1, 1, 0, 558, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4007, 'ITI-07556', 54, NULL, 161, 17, 557, 7, 30, 8, 1, 1, 0, 568, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(4008, 'ITI-07557', 40, NULL, 7, 17, 551, 7, 25, 3, 1, 1, 0, 660, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 0),
(4009, 'ITI-07558', 3, NULL, 52, 17, 551, 7, 25, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(4013, 'ITI-02560', 54, NULL, 161, 17, 562, 2, 30, 1, 1, 1, 0, 568, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(4020, 'ITI-02561', 13, NULL, 118, 17, 562, 2, 30, 1, 1, 1, 0, 571, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(4022, 'MITI-05090', 170, NULL, 229, 17, 578, 5, 35, 12, 1, 1, 0, 572, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4024, 'MITI-05091', 167, NULL, 103, 17, 578, 5, 35, 8, 1, 1, 0, 573, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4026, 'MITI-05092', 105, NULL, 170, 17, 578, 5, 35, 3, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4028, 'MITI-05093', 199, NULL, 163, 17, 578, 5, 35, 8, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4030, 'MITI-05094', 188, NULL, 87, 17, 578, 5, 35, 5, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(4032, 'MITI-05095', 180, NULL, 229, 17, 578, 5, 35, 5, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(4034, 'MITI-05096', 191, NULL, 79, 17, 578, 5, 35, 0, 0, 0, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4050, 'MITI-05104', 70, NULL, 103, 17, 578, 5, 35, 7, 1, 1, 1, 586, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(4052, 'MITI-05105', 160, NULL, 90, 17, 578, 5, 35, 7, 1, 1, 0, 587, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4054, 'ITI-02562', 106, NULL, 14, 17, 562, 2, 30, 3, 1, 1, 0, 588, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(4062, 'ITI-02563', 78, NULL, 173, 17, 562, 2, 37, 2, 1, 1, 0, 593, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4064, 'ITI-07559', 2, NULL, 186, 17, 552, 7, 30, 3, 1, 1, 0, 594, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4068, 'ITI-02564', 112, NULL, 85, 17, 562, 2, 39, 1, 1, 1, 0, 516, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4075, 'ITI-02567', 91, NULL, 56, 17, 562, 2, 35, 1, 1, 1, 0, 599, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(4077, 'ITI-02568', 135, NULL, 22, 17, 562, 2, 30, 6, 1, 1, 0, 600, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(4082, 'ITI-02569', 2, NULL, 131, 17, 562, 2, 35, 1, 1, 1, 0, 517, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4083, 'ITI-02570', 46, NULL, 174, 17, 562, 2, 30, 1, 1, 1, 0, 602, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4086, 'ITI-02571', 57, NULL, 64, 17, 562, 2, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4087, 'ITI-07560', 229, NULL, 43, 17, 557, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(4092, 'ITI-02572', 100, NULL, 105, 17, 562, 2, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4095, 'ITI-07561', 53, NULL, 168, 17, 554, 7, 35, 1, 1, 1, 0, 592, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(4096, 'ITI-07562', 224, NULL, 163, 17, 552, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4097, 'ITI-07563', 39, NULL, 105, 17, 548, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4101, 'ITI-07564', 210, NULL, 247, 17, 554, 7, 10, 1, 1, 1, 0, 608, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4102, 'ITI-07565', 56, NULL, 219, 17, 559, 7, 30, 2, 1, 1, 0, 520, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(4110, 'ITI-07566', 40, NULL, 243, 17, 547, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(4113, 'MITI-05106', 168, NULL, 229, 18, 581, 5, 30, 9, 1, 1, 0, 609, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4177, 'ITI-07567', 124, NULL, 43, 18, 606, 7, 30, 0, 0, 0, 0, 611, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(4178, 'ITI-07568', 220, NULL, 60, 18, 608, 7, 30, 1, 1, 1, 0, 610, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4179, 'ITI-02573', 33, NULL, 60, 18, 605, 2, 30, 15, 1, 1, 0, 610, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4180, 'ITI-02574', 124, NULL, 43, 18, 605, 2, 30, 13, 1, 1, 0, 611, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(4181, 'ITI-07569', 219, NULL, 60, 18, 607, 7, 30, 13, 1, 1, 0, 612, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4182, 'ITI-02575', 32, NULL, 60, 18, 605, 2, 30, 1, 1, 1, 0, 612, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4183, 'ITI-07570', 50, NULL, 218, 18, 594, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(4184, 'ITI-07571', 66, NULL, 9, 18, 594, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4185, 'ITI-07572', 216, NULL, 173, 18, 594, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4186, 'ITI-07573', 215, NULL, 100, 18, 594, 7, 30, 18, 1, 1, 0, 682, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4187, 'ITI-07574', 214, NULL, 241, 18, 594, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4188, 'ITI-07575', 39, NULL, 105, 18, 594, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(4189, 'ITI-07576', 137, NULL, 85, 18, 594, 7, 40, 13, 1, 1, 0, 615, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4190, 'ITI-07577', 221, NULL, 100, 18, 595, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4191, 'ITI-07578', 9, NULL, 179, 18, 595, 7, 35, 21, 1, 1, 0, 678, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4192, 'ITI-07579', 181, NULL, 221, 18, 595, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4193, 'ITI-07580', 121, NULL, 216, 18, 595, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4194, 'ITI-07581', 222, NULL, 14, 18, 595, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4195, 'ITI-07582', 218, NULL, 163, 18, 595, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(4196, 'ITI-07583', 9, NULL, 179, 18, 596, 7, 35, 31, 1, 1, 0, 659, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(4197, 'ITI-07584', 218, NULL, 243, 18, 596, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4198, 'ITI-07585', 181, NULL, 221, 18, 596, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(4199, 'ITI-07586', 222, NULL, 14, 18, 596, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4200, 'ITI-07587', 221, NULL, 56, 18, 596, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4201, 'ITI-07588', 121, NULL, 216, 18, 596, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(4202, 'ITI-07589', 51, NULL, 167, 18, 596, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(4203, 'ITI-07590', 9, NULL, 123, 18, 597, 7, 35, 25, 1, 1, 0, 637, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(4204, 'ITI-07591', 221, NULL, 56, 18, 597, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(4205, 'ITI-07592', 181, NULL, 221, 18, 597, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(4206, 'ITI-07593', 222, NULL, 14, 18, 597, 7, 35, 24, 1, 1, 0, 638, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4207, 'ITI-07594', 121, NULL, 216, 18, 597, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4208, 'ITI-07595', 51, NULL, 167, 18, 597, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(4209, 'ITI-07596', 218, NULL, 253, 18, 597, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4210, 'ITI-07597', 181, NULL, 221, 18, 598, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 0),
(4211, 'ITI-07598', 221, NULL, 100, 18, 598, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(4212, 'ITI-07599', 9, NULL, 88, 18, 598, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(4213, 'ITI-07600', 218, NULL, 243, 18, 598, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(4214, 'ITI-07601', 121, NULL, 216, 18, 598, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(4215, 'ITI-07602', 51, NULL, 168, 18, 598, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(4216, 'ITI-07603', 222, NULL, 242, 18, 598, 7, 30, 9, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 0),
(4217, 'ITI-07604', 210, NULL, 118, 18, 599, 7, 36, 31, 1, 1, 0, 668, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4218, 'ITI-07605', 106, NULL, 242, 18, 599, 7, 35, 31, 0, 1, 0, 635, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(4219, 'ITI-07606', 46, NULL, 173, 18, 599, 7, 35, 34, 1, 1, 0, 636, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4220, 'ITI-07607', 80, NULL, 140, 18, 599, 7, 35, 26, 1, 1, 0, 653, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4221, 'ITI-07608', 35, NULL, 138, 18, 599, 7, 35, 32, 1, 1, 0, 654, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4222, 'ITI-07609', 53, NULL, 219, 18, 599, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(4223, 'ITI-07610', 21, NULL, 163, 18, 599, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4224, 'ITI-07611', 211, NULL, 199, 18, 600, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(4225, 'ITI-07612', 226, NULL, 222, 18, 600, 7, 35, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4226, 'ITI-07613', 227, NULL, 23, 18, 600, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(4227, 'ITI-07614', 253, NULL, 189, 18, 600, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4228, 'ITI-07615', 43, NULL, 60, 18, 600, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(4229, 'ITI-07616', 47, NULL, 174, 18, 600, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4230, 'ITI-07617', 43, NULL, 60, 18, 601, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4231, 'ITI-07618', 54, NULL, 62, 18, 601, 7, 35, 25, 1, 1, 0, 681, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4232, 'ITI-07619', 47, NULL, 174, 18, 601, 7, 36, 36, 1, 1, 0, 633, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4233, 'ITI-07620', 226, NULL, 170, 18, 601, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4234, 'ITI-07621', 253, NULL, 64, 18, 601, 7, 35, 32, 1, 1, 0, 634, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4235, 'ITI-07622', 211, NULL, 118, 18, 601, 7, 35, 23, 1, 1, 0, 684, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(4236, 'ITI-07623', 227, NULL, 23, 18, 601, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4237, 'ITI-07624', 54, NULL, 62, 18, 602, 7, 35, 20, 1, 1, 0, 623, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4238, 'ITI-07625', 226, NULL, 170, 18, 602, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(4239, 'ITI-07626', 211, NULL, 118, 18, 602, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(4240, 'ITI-07627', 47, NULL, 173, 18, 602, 7, 35, 33, 1, 1, 0, 631, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(4241, 'ITI-07628', 253, NULL, 64, 18, 602, 7, 35, 23, 1, 1, 0, 632, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4242, 'ITI-07629', 227, NULL, 23, 18, 602, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(4243, 'ITI-07630', 43, NULL, 60, 18, 602, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(4244, 'ITI-07631', 226, NULL, 222, 18, 609, 7, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(4245, 'ITI-07632', 54, NULL, 220, 18, 609, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4246, 'ITI-07633', 54, NULL, 220, 18, 609, 7, 30, 12, 1, 1, 0, 613, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 0),
(4247, 'ITI-07634', 211, NULL, 247, 18, 609, 7, 30, 13, 1, 1, 0, 614, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 0),
(4248, 'ITI-07635', 253, NULL, 189, 18, 609, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(4249, 'ITI-07636', 47, NULL, 7, 18, 609, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(4250, 'ITI-07637', 43, NULL, 60, 18, 609, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 0),
(4251, 'ITI-07638', 227, NULL, 248, 18, 609, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 0),
(4252, 'ITI-07639', 238, NULL, 248, 18, 604, 7, 30, 20, 1, 1, 0, 691, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4253, 'ITI-07640', 136, NULL, 7, 18, 604, 7, 30, 21, 1, 1, 0, 624, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(4254, 'ITI-07641', 237, NULL, 87, 18, 604, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4255, 'ITI-07642', 239, NULL, 52, 18, 604, 7, 35, 21, 1, 1, 0, 625, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(4256, 'ITI-07643', 236, NULL, 163, 18, 604, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4257, 'ITI-07644', 256, NULL, 105, 18, 604, 7, 35, 21, 1, 1, 0, 626, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4258, 'ITI-07645', 135, NULL, 219, 18, 604, 7, 35, 24, 1, 1, 0, 621, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(4259, 'ITI-07646', 88, NULL, 222, 18, 603, 7, 35, 19, 1, 1, 0, 627, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(4260, 'ITI-07647', 233, NULL, 87, 18, 603, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(4261, 'ITI-07648', 234, NULL, 242, 18, 603, 7, 30, 25, 0, 1, 0, 628, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4262, 'ITI-07649', 235, NULL, 52, 18, 603, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(4263, 'ITI-07650', 232, NULL, 9, 18, 603, 7, 30, 6, 1, 1, 0, 629, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4264, 'ITI-07651', 144, NULL, 189, 18, 603, 7, 30, 11, 1, 1, 0, 630, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4265, 'ITI-07652', 56, NULL, 219, 18, 603, 7, 30, 10, 1, 1, 0, 622, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4266, 'ITI-02576', 152, NULL, 241, 18, 631, 2, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(4267, 'ITI-02577', 23, NULL, 138, 18, 632, 2, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4268, 'ITI-02578', 57, NULL, 105, 18, 630, 2, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4269, 'ITI-02579', 72, NULL, 43, 18, 631, 2, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4339, 'ITI-07653', 52, NULL, 167, 18, 622, 7, 35, 6, 1, 1, 0, 618, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(4348, 'ITI-02580', 135, NULL, 219, 18, 629, 2, 35, 9, 1, 1, 0, 621, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(4349, 'ITI-02581', 56, NULL, 219, 18, 629, 2, 30, 5, 1, 1, 0, 622, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4350, 'ITI-02582', 54, NULL, 62, 18, 629, 2, 35, 0, 0, 0, 0, 623, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4351, 'ITI-02583', 136, NULL, 7, 18, 631, 2, 30, 0, 0, 0, 0, 624, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(4352, 'ITI-02584', 8, NULL, 52, 18, 630, 2, 35, 7, 1, 1, 0, 625, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(4353, 'ITI-02585', 107, NULL, 105, 18, 632, 2, 35, 3, 1, 1, 0, 626, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4354, 'ITI-02586', 88, NULL, 222, 18, 634, 2, 35, 4, 1, 1, 0, 627, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(4355, 'ITI-02587', 1, NULL, 242, 18, 630, 2, 30, 3, 0, 1, 0, 628, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4356, 'ITI-02588', 143, NULL, 9, 18, 631, 2, 30, 5, 1, 1, 0, 629, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4357, 'ITI-02589', 144, NULL, 189, 18, 630, 2, 30, 5, 1, 1, 0, 630, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4358, 'ITI-02590', 47, NULL, 173, 18, 633, 2, 35, 0, 0, 0, 0, 631, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(4359, 'ITI-02591', 22, NULL, 64, 18, 633, 2, 35, 1, 1, 1, 0, 632, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4360, 'ITI-02592', 47, NULL, 174, 18, 633, 2, 36, 0, 0, 0, 0, 633, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4361, 'ITI-02593', 22, NULL, 64, 18, 633, 2, 35, 1, 1, 1, 0, 634, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4362, 'ITI-02594', 106, NULL, 242, 18, 632, 2, 35, 4, 0, 1, 0, 635, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(4363, 'ITI-02595', 46, NULL, 173, 18, 634, 2, 35, 0, 0, 0, 0, 636, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4364, 'ITI-02596', 9, NULL, 123, 18, 634, 2, 35, 1, 1, 1, 0, 637, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(4365, 'ITI-02597', 79, NULL, 14, 18, 633, 2, 35, 0, 1, 0, 0, 638, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4380, 'ITI-02598', 80, NULL, 140, 18, 632, 2, 35, 1, 1, 1, 0, 653, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4381, 'ITI-02599', 35, NULL, 138, 18, 633, 2, 35, 1, 1, 1, 0, 654, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4382, 'ITI-07654', 53, NULL, 168, 18, 622, 7, 35, 10, 1, 1, 0, 655, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4383, 'ITI-07655', 54, NULL, 62, 18, 622, 7, 35, 5, 1, 1, 0, 656, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4384, 'ITI-07656', 54, NULL, 161, 18, 622, 7, 35, 6, 1, 1, 0, 639, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4385, 'ITI-07657', 80, NULL, 21, 18, 623, 7, 35, 3, 1, 1, 0, 657, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(4386, 'ITI-02600', 80, NULL, 21, 18, 632, 2, 35, 1, 1, 1, 0, 657, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(4387, 'ITI-07658', 80, NULL, 21, 18, 623, 7, 35, 0, 1, 0, 0, 658, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(4388, 'ITI-02601', 80, NULL, 21, 18, 632, 2, 35, 2, 1, 1, 0, 658, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(4397, 'ITI-07659', 55, NULL, 161, 18, 608, 7, 39, 7, 1, 1, 0, 662, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4398, 'ITI-02602', 55, NULL, 161, 18, 632, 2, 39, 6, 1, 1, 0, 662, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4410, 'ITI-02603', 18, NULL, 118, 18, 633, 2, 36, 2, 1, 1, 0, 668, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4411, 'ITI-02604', 43, NULL, 60, 18, 634, 2, 30, 0, 0, 0, 0, 669, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(4412, 'ITI-02605', 43, NULL, 60, 18, 634, 2, 30, 2, 1, 1, 0, 670, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4413, 'ITI-02606', 43, NULL, 60, 18, 634, 2, 30, 0, 0, 0, 0, 671, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(4417, 'ITI-07660', 135, NULL, 169, 18, 622, 7, 32, 0, 0, 0, 0, 651, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4418, 'ITI-02607', 135, NULL, 169, 18, 629, 2, 32, 4, 1, 1, 0, 651, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4427, 'MITI-05107', 263, NULL, 229, 18, 581, 5, 25, 12, 1, 1, 0, 679, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4431, 'ITI-02608', 83, NULL, 163, 18, 630, 2, 10, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4435, 'ITI-02609', 56, NULL, 22, 18, 630, 2, 30, 0, 0, 0, 0, 646, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4436, 'ITI-07661', 56, NULL, 22, 18, 622, 7, 30, 1, 1, 1, 0, 646, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4438, 'ITI-02610', 91, NULL, 100, 18, 605, 2, 30, 1, 1, 1, 0, 682, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4441, 'ITI-02611', 55, NULL, 220, 18, 632, 2, 35, 1, 1, 1, 0, 683, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4442, 'ITI-07662', 55, NULL, 220, 18, 608, 7, 35, 4, 1, 1, 0, 683, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4447, 'ITI-02612', 101, NULL, 87, 18, 631, 2, 10, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4449, 'ITI-07663', 215, NULL, 14, 18, 598, 7, 10, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(4450, 'ITI-07664', 39, NULL, 105, 18, 598, 7, 10, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 0),
(4451, 'ITI-07665', 223, NULL, 189, 18, 609, 7, 10, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(4452, 'ITI-07666', 218, NULL, 7, 18, 598, 7, 10, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 0),
(4453, 'ITI-07667', 35, NULL, 52, 18, 609, 7, 10, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(4454, 'ITI-07668', 216, NULL, 173, 18, 627, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4455, 'ITI-07669', 46, NULL, 173, 18, 627, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4459, 'ITI-07670', 21, NULL, 163, 18, 627, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4466, 'ITI-07671', 21, NULL, 60, 18, 627, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4470, 'ITI-02613', 9, NULL, 179, 18, 634, 2, 35, 1, 1, 1, 0, 678, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4476, 'ITI-02614', 13, NULL, 248, 18, 605, 2, 30, 1, 1, 1, 0, 691, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4477, 'ITI-02615', 152, NULL, 241, 18, 631, 2, 10, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4478, 'ITI-02616', 135, NULL, 161, 18, 631, 2, 30, 5, 1, 1, 0, 617, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(4480, 'ITI-07672', 144, NULL, 189, 18, 627, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(4482, 'ITI-07673', 54, NULL, 161, 18, 629, 2, 35, 1, 1, 1, 0, 639, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4484, 'ITI-07673', 181, NULL, 221, 18, 627, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4487, 'ITI-07674', 66, NULL, 9, 18, 627, 7, 6, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4489, 'ITI-07675', 210, NULL, 78, 18, 609, 7, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(4490, 'ITI-07676', 35, NULL, 52, 18, 609, 7, 5, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(4492, 'MITI-05108', 71, NULL, 90, 19, 643, 5, 30, 2, 1, 1, 0, 694, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4494, 'MITI-05109', 45, NULL, 79, 19, 643, 5, 30, 0, 0, 0, 1, 695, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4496, 'MITI-05110', 89, NULL, 170, 19, 645, 5, 30, 2, 1, 1, 0, 696, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4498, 'MITI-05111', 70, NULL, 103, 19, 645, 5, 30, 2, 1, 1, 0, 697, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4500, 'MITI-05112', 181, NULL, 87, 19, 645, 5, 30, 2, 1, 1, 1, 698, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4502, 'MITI-05113', 182, NULL, 107, 19, 647, 5, 30, 0, 0, 0, 1, 699, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4504, 'MITI-05114', 169, NULL, 172, 19, 647, 5, 30, 7, 1, 1, 0, 700, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4506, 'MITI-05115', 191, NULL, 79, 19, 643, 5, 30, 0, 0, 0, 1, 701, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4508, 'MITI-05116', 196, NULL, 90, 19, 643, 5, 30, 0, 0, 0, 1, 702, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4511, 'MITI-05117', 194, NULL, 87, 19, 645, 5, 30, 0, 0, 0, 1, 703, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4513, 'MITI-05118', 204, NULL, 54, 19, 645, 5, 30, 0, 0, 0, 1, 704, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4515, 'MITI-05119', 263, NULL, 229, 19, 645, 5, 30, 0, 0, 0, 1, 705, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(4554, 'ITI-07677', 65, NULL, 263, 19, 652, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4555, 'ITI-07678', 49, NULL, 143, 19, 652, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(4556, 'ITI-07679', 3, NULL, 243, 19, 652, 7, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4558, 'ITI-07680', 206, NULL, 56, 19, 652, 7, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4559, 'ITI-07681', 59, NULL, 242, 19, 652, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4562, 'ITI-07682', 40, NULL, 286, 19, 652, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(4565, 'ITI-07683', 156, NULL, 118, 19, 652, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4574, 'ITI-07684', 40, NULL, 263, 19, 653, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(4576, 'ITI-07685', 206, NULL, 265, 19, 653, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(4577, 'ITI-07686', 65, NULL, 179, 19, 653, 7, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(4579, 'ITI-07687', 3, NULL, 243, 19, 653, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(4582, 'ITI-07688', 59, NULL, 242, 19, 653, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4585, 'ITI-07689', 156, NULL, 226, 19, 653, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(4589, 'ITI-07690', 65, NULL, 179, 19, 654, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(4603, 'ITI-07691', 40, NULL, 243, 19, 654, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(4607, 'ITI-07692', 156, NULL, 85, 19, 654, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 0),
(4608, 'ITI-07693', 3, NULL, 52, 19, 654, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 0),
(4609, 'ITI-07694', 49, NULL, 218, 19, 654, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(4610, 'ITI-07695', 59, NULL, 242, 19, 654, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 0),
(4611, 'ITI-07696', 206, NULL, 56, 19, 654, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(4612, 'ITI-07697', 49, NULL, 218, 19, 654, 7, 40, 18, 1, 1, 0, 706, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 0),
(4613, 'ITI-07698', 49, NULL, 272, 19, 655, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(4614, 'ITI-07699', 206, NULL, 173, 19, 655, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4615, 'ITI-07700', 3, NULL, 253, 19, 655, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4616, 'ITI-07701', 156, NULL, 260, 19, 655, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(4618, 'ITI-07702', 65, NULL, 264, 19, 655, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4620, 'ITI-07703', 59, NULL, 283, 19, 655, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(4623, 'ITI-07704', 40, NULL, 263, 19, 655, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(4638, 'ITI-07705', 9, NULL, 43, 19, 656, 7, 30, 25, 1, 1, 0, 736, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(4640, 'ITI-07706', 221, NULL, 138, 19, 656, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4641, 'ITI-07707', 218, NULL, 253, 19, 656, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4643, 'ITI-07708', 222, NULL, 56, 19, 656, 7, 30, 20, 1, 1, 0, 770, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4644, 'ITI-07709', 121, NULL, 85, 19, 656, 7, 36, 12, 1, 1, 0, 724, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4645, 'ITI-07710', 181, NULL, 60, 19, 656, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4646, 'ITI-07711', 51, NULL, 95, 19, 656, 7, 38, 18, 1, 1, 0, 725, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(4649, 'ITI-07712', 2, NULL, 131, 19, 657, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(4651, 'ITI-07713', 224, NULL, 221, 19, 657, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4652, 'ITI-07714', 52, NULL, 169, 19, 657, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(4655, 'ITI-07715', 223, NULL, 282, 19, 657, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(4659, 'ITI-07716', 225, NULL, 14, 19, 657, 7, 35, 30, 1, 1, 0, 735, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(4660, 'ITI-07717', 129, NULL, 118, 19, 657, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4661, 'ITI-07718', 219, NULL, 60, 19, 657, 7, 90, 81, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(4663, 'ITI-07719', 224, NULL, 221, 19, 658, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(4664, 'ITI-07720', 2, NULL, 131, 19, 658, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4665, 'ITI-07721', 223, NULL, 282, 19, 658, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4666, 'ITI-07722', 225, NULL, 14, 19, 658, 7, 35, 29, 1, 1, 0, 734, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4667, 'ITI-07723', 129, NULL, 118, 19, 658, 7, 35, 32, 1, 1, 0, 778, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4670, 'ITI-07724', 52, NULL, 168, 19, 658, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4676, 'ITI-07725', 224, NULL, 221, 19, 659, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(4677, 'ITI-07726', 225, NULL, 14, 19, 659, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(4678, 'ITI-07727', 2, NULL, 131, 19, 659, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(4679, 'ITI-07728', 223, NULL, 189, 19, 659, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(4680, 'ITI-07729', 52, NULL, 218, 19, 659, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 0),
(4681, 'ITI-07730', 129, NULL, 226, 19, 659, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 0),
(4682, 'ITI-07731', 225, NULL, 242, 19, 660, 7, 30, 11, 1, 1, 0, 733, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4683, 'ITI-07732', 224, NULL, 60, 19, 660, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4684, 'ITI-07733', 223, NULL, 189, 19, 660, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4685, 'ITI-07734', 2, NULL, 138, 19, 660, 7, 30, 17, 1, 1, 0, 775, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4686, 'ITI-07735', 52, NULL, 95, 19, 660, 7, 30, 3, 1, 1, 0, 707, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4687, 'ITI-07736', 129, NULL, 199, 19, 660, 7, 35, 7, 1, 1, 0, 708, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(4690, 'ITI-07737', 226, NULL, 282, 19, 661, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(4691, 'ITI-07738', 43, NULL, 60, 19, 661, 7, 36, 35, 1, 1, 0, 730, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4692, 'ITI-07739', 253, NULL, 189, 19, 661, 7, 30, 22, 1, 1, 0, 731, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4693, 'ITI-07740', 47, NULL, 173, 19, 661, 7, 30, 23, 1, 1, 0, 732, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4694, 'ITI-07741', 54, NULL, 25, 19, 661, 7, 30, 16, 1, 1, 0, 739, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4695, 'ITI-07742', 211, NULL, 199, 19, 661, 7, 36, 15, 1, 1, 0, 740, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4696, 'ITI-07743', 227, NULL, 23, 19, 661, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4697, 'ITI-07744', 229, NULL, 100, 19, 664, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4698, 'ITI-07745', 55, NULL, 169, 19, 664, 7, 35, 33, 1, 1, 0, 738, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4699, 'ITI-07746', 231, NULL, 9, 19, 664, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(4700, 'ITI-07747', 87, NULL, 163, 19, 664, 7, 35, 35, 1, 1, 0, 729, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4701, 'ITI-07748', 230, NULL, 170, 19, 664, 7, 36, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4702, 'ITI-07749', 228, NULL, 64, 19, 664, 7, 35, 35, 1, 1, 0, 727, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(4703, 'ITI-07750', 220, NULL, 60, 19, 664, 7, 90, 70, 1, 1, 0, 728, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4704, 'ITI-07751', 229, NULL, 100, 19, 666, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 0),
(4705, 'ITI-07752', 231, NULL, 9, 19, 666, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(4706, 'ITI-07753', 87, NULL, 163, 19, 666, 7, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(4707, 'ITI-07754', 228, NULL, 105, 19, 666, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 0),
(4708, 'ITI-07755', 230, NULL, 170, 19, 666, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(4709, 'ITI-07756', 55, NULL, 218, 19, 666, 7, 30, 10, 1, 1, 0, 709, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 0),
(4710, 'ITI-07757', 228, NULL, 64, 19, 667, 7, 35, 28, 1, 1, 0, 723, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(4711, 'ITI-07758', 55, NULL, 25, 19, 667, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4712, 'ITI-07759', 231, NULL, 173, 19, 667, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4713, 'ITI-07760', 87, NULL, 138, 19, 667, 7, 35, 32, 1, 1, 0, 726, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4714, 'ITI-07761', 229, NULL, 100, 19, 667, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(4715, 'ITI-07762', 230, NULL, 170, 19, 667, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(4716, 'ITI-07763', 55, NULL, 25, 19, 667, 7, 35, 24, 1, 1, 0, 710, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(4717, 'ITI-07764', 239, NULL, 52, 19, 668, 7, 35, 28, 1, 1, 0, 717, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(4718, 'ITI-07765', 256, NULL, 105, 19, 668, 7, 30, 10, 1, 1, 0, 718, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4719, 'ITI-07766', 135, NULL, 25, 19, 668, 7, 35, 6, 1, 1, 0, 737, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4720, 'ITI-07767', 238, NULL, 248, 19, 668, 7, 36, 36, 1, 1, 0, 719, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4721, 'ITI-07768', 136, NULL, 265, 19, 668, 7, 30, 27, 1, 1, 0, 720, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4722, 'ITI-07769', 237, NULL, 87, 19, 668, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(4723, 'ITI-07770', 236, NULL, 163, 19, 668, 7, 35, 32, 1, 1, 0, 721, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(4740, 'ITI-07771', 124, NULL, 43, 19, 707, 7, 35, 17, 1, 1, 0, 716, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4741, 'ITI-02674', 124, NULL, 43, 19, 708, 2, 35, 9, 1, 1, 0, 716, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(4742, 'ITI-02675', 8, NULL, 52, 19, 673, 2, 35, 2, 1, 1, 0, 717, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(4743, 'ITI-02676', 107, NULL, 105, 19, 672, 2, 30, 6, 1, 1, 0, 718, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4744, 'ITI-02677', 13, NULL, 248, 19, 671, 2, 36, 0, 0, 0, 0, 719, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(4745, 'ITI-02678', 136, NULL, 265, 19, 674, 2, 30, 1, 1, 1, 0, 720, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(4746, 'ITI-02679', 114, NULL, 163, 19, 674, 2, 35, 1, 1, 1, 0, 721, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(4754, 'ITI-07772', 49, NULL, 143, 19, 653, 7, 35, 8, 1, 1, 0, 722, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4769, 'ITI-02680', 58, NULL, 64, 19, 672, 2, 35, 6, 1, 1, 0, 723, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(4784, 'ITI-02681', 111, NULL, 138, 19, 670, 2, 35, 0, 0, 0, 0, 726, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4785, 'ITI-02682', 58, NULL, 64, 19, 672, 2, 35, 0, 1, 0, 0, 727, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(4786, 'ITI-02683', 33, NULL, 60, 19, 672, 2, 90, 4, 1, 1, 0, 728, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4787, 'ITI-02684', 111, NULL, 163, 19, 670, 2, 35, 0, 1, 0, 0, 729, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4788, 'ITI-02685', 43, NULL, 60, 19, 671, 2, 36, 0, 1, 0, 0, 730, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4789, 'ITI-02686', 22, NULL, 189, 19, 670, 2, 30, 0, 0, 0, 0, 731, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(4790, 'ITI-02687', 47, NULL, 173, 19, 670, 2, 30, 2, 1, 1, 0, 732, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(4791, 'ITI-02688', 92, NULL, 242, 19, 671, 2, 30, 1, 1, 1, 0, 733, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4792, 'ITI-02689', 92, NULL, 14, 19, 671, 2, 35, 0, 1, 0, 0, 734, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4793, 'ITI-02690', 92, NULL, 14, 19, 671, 2, 35, 0, 1, 0, 0, 735, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(4794, 'ITI-02691', 9, NULL, 43, 19, 671, 2, 30, 0, 0, 0, 0, 736, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(4795, 'ITI-02692', 135, NULL, 25, 19, 674, 2, 35, 8, 1, 1, 0, 737, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4796, 'ITI-02693', 55, NULL, 25, 19, 672, 2, 35, 0, 1, 0, 0, 710, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(4797, 'ITI-02694', 55, NULL, 169, 19, 672, 2, 35, 0, 1, 0, 0, 738, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4798, 'ITI-02695', 54, NULL, 25, 19, 671, 2, 30, 1, 1, 1, 0, 739, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(4799, 'ITI-02696', 101, NULL, 160, 19, 674, 2, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(4800, 'ITI-02697', 57, NULL, 105, 19, 673, 2, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4847, 'ITI-02698', 7, NULL, 163, 19, 673, 2, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4864, 'ITI-07773', 135, NULL, 219, 19, 676, 7, 39, 2, 1, 1, 0, 746, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4865, 'ITI-02699', 135, NULL, 219, 19, 709, 2, 39, 4, 1, 1, 0, 746, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4871, 'ITI-07774', 55, NULL, 161, 19, 676, 7, 30, 7, 1, 1, 0, 758, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4872, 'ITI-02700', 55, NULL, 161, 19, 709, 2, 30, 2, 1, 1, 0, 758, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(4877, 'ITI-07775', 80, NULL, 140, 19, 656, 7, 35, 3, 1, 1, 0, 760, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(4879, 'ITI-02701', 80, NULL, 140, 19, 671, 2, 35, 1, 1, 1, 0, 760, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(4889, 'ITI-02702', 56, NULL, 22, 19, 673, 2, 27, 5, 1, 1, 0, 766, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(4890, 'ITI-07776', 56, NULL, 22, 19, 676, 7, 27, 2, 1, 1, 0, 766, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(4899, 'ITI-02703', 53, NULL, 62, 19, 670, 2, 30, 0, 0, 0, 0, 769, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(4900, 'ITI-07777', 53, NULL, 62, 19, 676, 7, 30, 17, 1, 1, 0, 769, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(4903, 'ITI-02704', 79, NULL, 56, 19, 670, 2, 30, 1, 1, 1, 0, 770, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(4907, 'ITI-07778', 106, NULL, 14, 19, 660, 7, 10, 0, 1, 0, 0, 772, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(4908, 'ITI-02705', 106, NULL, 14, 19, 672, 2, 10, 3, 1, 1, 0, 772, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(4909, 'ITI-07779', 46, NULL, 7, 19, 661, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(4916, 'ITI-02706', 104, NULL, 85, 19, 670, 2, 2, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(4918, 'ITI-07780', 47, NULL, 173, 19, 661, 7, 10, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(4928, 'ITI-02707', 143, NULL, 60, 19, 670, 2, 30, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(4929, 'ITI-02708', 143, NULL, 163, 19, 674, 2, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(4932, 'ITI-02709', 72, NULL, 235, 19, 674, 2, 10, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(4934, 'ITI-07781', 216, NULL, 253, 19, 656, 7, 15, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(4936, 'ITI-07782', 43, NULL, 189, 19, 654, 7, 20, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4937, 'ITI-07783', 43, NULL, 189, 19, 666, 7, 20, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(4938, 'ITI-07784', 181, NULL, 52, 19, 654, 7, 10, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(4939, 'ITI-07785', 181, NULL, 52, 19, 659, 7, 20, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(4940, 'ITI-07786', 222, NULL, 14, 19, 659, 7, 10, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(4997, 'ITI-02710', 114, NULL, 262, 20, 737, 2, 12, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5002, 'ITI-07787', 65, NULL, 262, 20, 723, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5004, 'ITI-07788', 206, NULL, 173, 20, 723, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5005, 'ITI-07789', 59, NULL, 327, 20, 723, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5007, 'ITI-07790', 3, NULL, 253, 20, 723, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(5008, 'ITI-07791', 49, NULL, 95, 20, 723, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5016, 'ITI-07792', 40, NULL, 285, 20, 723, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(5019, 'ITI-07793', 156, NULL, 226, 20, 723, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5021, 'ITI-07794', 49, NULL, 95, 20, 723, 7, 30, 13, 1, 1, 0, 782, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5024, 'ITI-07795', 216, NULL, 221, 20, 724, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5026, 'ITI-07796', 214, NULL, 179, 20, 724, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5027, 'ITI-07797', 66, NULL, 326, 20, 724, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5029, 'ITI-07798', 215, NULL, 56, 20, 724, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(5031, 'ITI-07799', 39, NULL, 105, 20, 724, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(5033, 'ITI-07800', 137, NULL, 118, 20, 724, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(5035, 'ITI-07801', 214, NULL, 131, 20, 725, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5036, 'ITI-07802', 137, NULL, 118, 20, 725, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5037, 'ITI-07803', 216, NULL, 243, 20, 725, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5038, 'ITI-07804', 39, NULL, 105, 20, 725, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5039, 'ITI-07805', 50, NULL, 62, 20, 725, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5040, 'ITI-07806', 66, NULL, 9, 20, 725, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(5041, 'ITI-07807', 215, NULL, 56, 20, 725, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(5042, 'ITI-07808', 39, NULL, 105, 20, 726, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5043, 'ITI-07809', 216, NULL, 173, 20, 726, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(5044, 'ITI-07810', 214, NULL, 262, 20, 726, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(5045, 'ITI-07811', 215, NULL, 242, 20, 726, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5046, 'ITI-07812', 137, NULL, 260, 20, 726, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(5047, 'ITI-07813', 66, NULL, 327, 20, 726, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5048, 'ITI-07814', 50, NULL, 168, 20, 726, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5049, 'ITI-07815', 216, NULL, 243, 20, 727, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 0),
(5050, 'ITI-07816', 50, NULL, 62, 20, 727, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 0),
(5051, 'ITI-07817', 137, NULL, 85, 20, 727, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(5052, 'ITI-07818', 214, NULL, 179, 20, 727, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(5053, 'ITI-07819', 66, NULL, 163, 20, 727, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 0),
(5054, 'ITI-07820', 39, NULL, 105, 20, 727, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 0),
(5055, 'ITI-07821', 215, NULL, 56, 20, 727, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(5056, 'ITI-07822', 223, NULL, 282, 20, 728, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5057, 'ITI-07823', 52, NULL, 168, 20, 728, 7, 30, 22, 1, 1, 0, 846, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5058, 'ITI-07824', 129, NULL, 260, 20, 728, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5059, 'ITI-07825', 2, NULL, 253, 20, 728, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5060, 'ITI-07826', 225, NULL, 242, 20, 728, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(5061, 'ITI-07827', 224, NULL, 285, 20, 728, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5062, 'ITI-07828', 80, NULL, 131, 20, 729, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5063, 'ITI-07829', 46, NULL, 221, 20, 729, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5064, 'ITI-07830', 35, NULL, 282, 20, 729, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5065, 'ITI-07831', 21, NULL, 60, 20, 729, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5066, 'ITI-07832', 106, NULL, 14, 20, 729, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5067, 'ITI-07833', 210, NULL, 248, 20, 729, 7, 35, 33, 1, 1, 0, 839, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(5152, 'ITI-07834', 21, NULL, 326, 20, 730, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5153, 'ITI-07835', 46, NULL, 265, 20, 730, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5154, 'ITI-07836', 53, NULL, 169, 20, 730, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5155, 'ITI-07837', 106, NULL, 14, 20, 730, 7, 35, 30, 1, 1, 0, 820, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5156, 'ITI-07838', 35, NULL, 138, 20, 730, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5157, 'ITI-07839', 80, NULL, 9, 20, 730, 7, 35, 34, 1, 1, 0, 824, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(5158, 'ITI-07840', 210, NULL, 266, 20, 730, 7, 36, 32, 1, 1, 0, 825, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5159, 'ITI-07841', 53, NULL, 25, 20, 731, 7, 30, 14, 1, 1, 0, 849, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5160, 'ITI-07842', 21, NULL, 60, 20, 731, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(5161, 'ITI-07843', 35, NULL, 282, 20, 731, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(5162, 'ITI-07844', 106, NULL, 242, 20, 731, 7, 30, 18, 1, 1, 0, 819, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5163, 'ITI-07845', 80, NULL, 327, 20, 731, 7, 30, 3, 1, 1, 0, 847, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(5164, 'ITI-07846', 210, NULL, 199, 20, 731, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(5165, 'ITI-07847', 46, NULL, 326, 20, 731, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5166, 'ITI-07848', 53, NULL, 143, 20, 732, 7, 35, 11, 1, 1, 0, 786, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(5167, 'ITI-07849', 210, NULL, 275, 20, 732, 7, 36, 12, 1, 1, 0, 787, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 0),
(5168, 'ITI-07850', 80, NULL, 131, 20, 732, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 0),
(5169, 'ITI-07851', 46, NULL, 221, 20, 732, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 0),
(5170, 'ITI-07852', 21, NULL, 60, 20, 732, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 0),
(5171, 'ITI-07853', 35, NULL, 138, 20, 732, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 0),
(5172, 'ITI-07854', 106, NULL, 14, 20, 732, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 0),
(5173, 'ITI-07855', 229, NULL, 43, 20, 733, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(5174, 'ITI-07856', 87, NULL, 282, 20, 733, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(5175, 'ITI-07857', 231, NULL, 173, 20, 733, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5176, 'ITI-07858', 230, NULL, 170, 20, 733, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5177, 'ITI-07859', 55, NULL, 25, 20, 733, 7, 30, 17, 1, 1, 0, 841, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(5178, 'ITI-07860', 228, NULL, 282, 20, 733, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5179, 'ITI-07861', 234, NULL, 100, 20, 734, 7, 35, 35, 1, 1, 0, 796, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(5180, 'ITI-07862', 88, NULL, 325, 20, 734, 7, 35, 35, 1, 1, 0, 797, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5181, 'ITI-07863', 144, NULL, 243, 20, 734, 7, 35, 34, 1, 1, 0, 798, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5182, 'ITI-07864', 232, NULL, 163, 20, 734, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(5183, 'ITI-07865', 56, NULL, 143, 20, 734, 7, 35, 33, 1, 1, 0, 795, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5184, 'ITI-07866', 235, NULL, 52, 20, 734, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(5185, 'ITI-07867', 233, NULL, 87, 20, 734, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5186, 'ITI-07868', 232, NULL, 163, 20, 735, 7, 36, 34, 1, 1, 0, 794, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(5187, 'ITI-07869', 56, NULL, 25, 20, 735, 7, 36, 27, 1, 1, 0, 793, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5188, 'ITI-07870', 144, NULL, 265, 20, 735, 7, 35, 34, 1, 1, 0, 792, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5189, 'ITI-07871', 233, NULL, 87, 20, 735, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(5190, 'ITI-07872', 235, NULL, 52, 20, 735, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(5191, 'ITI-07873', 234, NULL, 100, 20, 735, 7, 35, 33, 1, 1, 0, 791, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5192, 'ITI-07874', 88, NULL, 325, 20, 735, 7, 35, 32, 1, 1, 0, 790, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(5193, 'ITI-07875', 220, NULL, 60, 20, 733, 7, 80, 26, 1, 1, 0, 800, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5194, 'ITI-07876', 219, NULL, 60, 20, 728, 7, 80, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(5195, 'ITI-07877', 144, NULL, 265, 20, 736, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 0),
(5196, 'ITI-07878', 88, NULL, 325, 20, 736, 7, 35, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(5197, 'ITI-07879', 234, NULL, 100, 20, 736, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 0),
(5198, 'ITI-07880', 233, NULL, 170, 20, 736, 7, 35, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 0),
(5199, 'ITI-07881', 235, NULL, 52, 20, 736, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 0),
(5200, 'ITI-07882', 232, NULL, 163, 20, 736, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(5201, 'ITI-07883', 56, NULL, 143, 20, 736, 7, 35, 8, 1, 1, 0, 788, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(5202, 'ITI-07884', 124, NULL, 43, 20, 740, 7, 50, 13, 1, 1, 0, 789, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5203, 'ITI-02711', 124, NULL, 43, 20, 741, 2, 50, 7, 1, 1, 0, 789, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5204, 'ITI-02712', 101, NULL, 160, 20, 739, 2, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(5205, 'ITI-02713', 152, NULL, 100, 20, 739, 2, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5206, 'ITI-02714', 88, NULL, 325, 20, 737, 2, 35, 1, 1, 1, 0, 790, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(5207, 'ITI-02715', 1, NULL, 100, 20, 738, 2, 35, 1, 1, 1, 0, 791, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5208, 'ITI-02716', 144, NULL, 265, 20, 738, 2, 35, 1, 1, 1, 0, 792, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5209, 'ITI-02717', 56, NULL, 25, 20, 738, 2, 36, 6, 1, 1, 0, 793, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5210, 'ITI-02718', 143, NULL, 163, 20, 739, 2, 36, 2, 1, 1, 0, 794, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(5211, 'ITI-02719', 56, NULL, 143, 20, 738, 2, 35, 0, 0, 0, 0, 795, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5212, 'ITI-02720', 1, NULL, 100, 20, 738, 2, 35, 0, 0, 0, 0, 796, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(5213, 'ITI-02721', 88, NULL, 325, 20, 741, 2, 35, 0, 0, 0, 0, 797, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5214, 'ITI-02722', 144, NULL, 243, 20, 738, 2, 35, 0, 0, 0, 0, 798, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5215, 'ITI-07885', 143, NULL, 163, 20, 739, 2, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(5216, 'ITI-02886', 33, NULL, 60, 20, 737, 2, 80, 3, 1, 1, 0, 800, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5257, 'ITI-07885', 156, NULL, 328, 20, 723, 7, 30, 12, 1, 1, 0, 781, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5259, 'ITI-07886', 129, NULL, 23, 20, 728, 7, 30, 17, 1, 1, 0, 836, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5264, 'MITI-05120', 160, NULL, 163, 20, 781, 5, 30, 2, 1, 1, 0, 803, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5266, 'MITI-05121', 204, NULL, 87, 20, 781, 5, 30, 2, 1, 1, 1, 804, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5268, 'MITI-05122', 174, NULL, 170, 20, 781, 5, 30, 2, 1, 1, 1, 805, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5270, 'MITI-05123', 177, NULL, 230, 20, 781, 5, 35, 1, 1, 1, 1, 806, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5272, 'MITI-05124', 200, NULL, 8, 20, 784, 5, 30, 0, 0, 0, 1, 807, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5274, 'MITI-05125', 28, NULL, 171, 20, 781, 5, 30, 0, 0, 0, 1, 808, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5276, 'MITI-05126', 172, NULL, 103, 20, 781, 5, 30, 3, 1, 1, 1, 809, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5278, 'MITI-05127', 170, NULL, 103, 20, 785, 5, 30, 7, 1, 1, 0, 810, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5279, 'ITI-07887', 9, NULL, 138, 20, 726, 7, 35, 5, 1, 1, 0, 811, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(5282, 'ITI-07888', 135, NULL, 169, 20, 743, 7, 35, 4, 1, 1, 0, 785, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5283, 'ITI-07889', 135, NULL, 161, 20, 743, 7, 36, 8, 1, 1, 0, 813, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(5284, 'ITI-02887', 135, NULL, 161, 20, 744, 2, 36, 2, 1, 1, 0, 813, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(5285, 'ITI-02888', 135, NULL, 169, 20, 744, 2, 35, 4, 1, 1, 0, 785, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5292, 'ITI-02889', 106, NULL, 242, 20, 739, 2, 30, 2, 1, 1, 0, 819, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5293, 'ITI-02890', 106, NULL, 14, 20, 739, 2, 35, 1, 1, 1, 0, 820, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5298, 'ITI-02891', 135, NULL, 22, 20, 741, 2, 30, 3, 1, 1, 0, 822, 0, '<Campos><Grupo><colorLetra>-65536</colorLetra><colorFondo>-1</colorFondo></Grupo></Campos>', 1, 1),
(5299, 'ITI-07890', 135, NULL, 22, 20, 740, 7, 30, 1, 1, 1, 0, 822, 0, '<Campos><Grupo><colorLetra>-65536</colorLetra><colorFondo>-1</colorFondo></Grupo></Campos>', 1, 1),
(5304, 'ITI-07891', 137, NULL, 260, 20, 726, 7, 30, 0, 0, 0, 0, 826, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5309, 'ITI-02892', 135, NULL, 219, 20, 739, 2, 30, 1, 1, 1, 0, 827, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5310, 'ITI-07892', 135, NULL, 219, 20, 743, 7, 30, 1, 1, 1, 0, 827, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5314, 'ITI-07893', 51, NULL, 317, 20, 743, 7, 30, 13, 1, 1, 0, 828, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5318, 'ITI-07894', 54, NULL, 289, 20, 743, 7, 30, 16, 1, 1, 0, 829, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5321, 'ITI-07895', 230, NULL, 170, 20, 733, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(5326, 'ITI-07896', 55, NULL, 161, 20, 743, 7, 30, 5, 1, 1, 0, 833, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5347, 'ITI-07897', 52, NULL, 168, 20, 728, 7, 30, 1, 1, 1, 0, 840, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5348, 'ITI-07898', 52, NULL, 168, 20, 728, 7, 30, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 1, 1),
(5349, 'ITI-07899', 223, NULL, 282, 20, 728, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 1, 1),
(5351, 'ITI-07900', 50, NULL, 272, 20, 725, 7, 30, 2, 1, 1, 0, 842, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(5354, 'ITI-07901', 56, NULL, 169, 20, 743, 7, 35, 1, 1, 1, 0, 821, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5356, 'ITI-07902', 56, NULL, 161, 20, 743, 7, 37, 6, 1, 1, 0, 812, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5358, 'ITI-02893', 56, NULL, 169, 20, 744, 2, 35, 2, 1, 1, 0, 821, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5364, 'ITI-02894', 56, NULL, 219, 20, 744, 2, 35, 1, 1, 1, 0, 783, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5365, 'ITI-07903', 52, NULL, 168, 20, 779, 8, 30, 1, 1, 1, 0, 846, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5367, 'ITI-02895', 72, NULL, 235, 20, 739, 2, 15, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5368, 'ITI-07903', 224, NULL, 285, 20, 728, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 1, 1),
(5371, 'ITI-07904', 39, NULL, 105, 20, 726, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 1, 1),
(5373, 'ITI-02896', 57, NULL, 105, 20, 738, 2, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5374, 'ITI-02897', 88, NULL, 64, 20, 737, 2, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5387, 'ITI-02898', 83, NULL, 87, 20, 738, 2, 3, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5393, 'ITI-07905', 225, NULL, 14, 20, 732, 7, 10, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 0),
(5394, 'ITI-07906', 65, NULL, 262, 20, 807, 7, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 1, 1),
(5396, 'ITI-07907', 226, NULL, 7, 20, 736, 7, 15, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 0),
(5397, 'ITI-02899', 107, NULL, 105, 20, 737, 2, 2, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5450, 'ITI-07908', 39, NULL, 105, 21, 838, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5451, 'ITI-07909', 214, NULL, 209, 21, 838, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5452, 'ITI-07910', 216, NULL, 173, 21, 838, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5453, 'ITI-07911', 215, NULL, 242, 21, 838, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5454, 'ITI-07912', 66, NULL, 9, 21, 838, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5455, 'ITI-07913', 137, NULL, 353, 21, 838, 7, 35, 13, 1, 1, 0, 851, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5457, 'ITI-07914', 50, NULL, 95, 21, 838, 7, 36, 18, 1, 1, 0, 852, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5459, 'ITI-07915', 9, NULL, 179, 21, 839, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5460, 'ITI-07916', 51, NULL, 143, 21, 839, 7, 35, 31, 1, 1, 0, 918, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(5461, 'ITI-07917', 181, NULL, 337, 21, 839, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(5462, 'ITI-07918', 221, NULL, 56, 21, 839, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5463, 'ITI-07919', 218, NULL, 325, 21, 839, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5464, 'ITI-07920', 222, NULL, 14, 21, 839, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5465, 'ITI-07921', 121, NULL, 118, 21, 839, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5466, 'ITI-07922', 9, NULL, 179, 21, 840, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(5467, 'ITI-07923', 181, NULL, 337, 21, 840, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5468, 'ITI-07924', 221, NULL, 56, 21, 840, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(5469, 'ITI-07925', 222, NULL, 14, 21, 840, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5470, 'ITI-07926', 218, NULL, 325, 21, 840, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(5471, 'ITI-07927', 121, NULL, 118, 21, 840, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5472, 'ITI-07928', 51, NULL, 272, 21, 841, 7, 30, 21, 1, 1, 0, 916, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(5473, 'ITI-07929', 221, NULL, 100, 21, 842, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(5474, 'ITI-07930', 121, NULL, 85, 21, 842, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 0),
(5475, 'ITI-07931', 222, NULL, 14, 21, 842, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(5476, 'ITI-07932', 51, NULL, 143, 21, 842, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 0),
(5477, 'ITI-07933', 181, NULL, 105, 21, 842, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 0),
(5478, 'ITI-07934', 218, NULL, 163, 21, 842, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 0),
(5479, 'ITI-07935', 9, NULL, 338, 21, 842, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(5480, 'ITI-07936', 9, NULL, 338, 21, 841, 7, 32, 16, 1, 1, 0, 870, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(5481, 'ITI-07937', 51, NULL, 168, 21, 841, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(5482, 'ITI-07938', 218, NULL, 327, 21, 841, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5483, 'ITI-07939', 222, NULL, 242, 21, 841, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5484, 'ITI-07940', 121, NULL, 260, 21, 841, 7, 30, 11, 1, 1, 0, 928, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5485, 'ITI-07941', 181, NULL, 326, 21, 841, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(5486, 'ITI-07942', 221, NULL, 100, 21, 841, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5487, 'ITI-07943', 46, NULL, 173, 21, 843, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5488, 'ITI-07944', 53, NULL, 167, 21, 843, 7, 35, 24, 1, 1, 0, 915, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5489, 'ITI-07945', 106, NULL, 242, 21, 843, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(5490, 'ITI-07946', 21, NULL, 138, 21, 843, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5491, 'ITI-07947', 35, NULL, 327, 21, 843, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(5492, 'ITI-07948', 80, NULL, 9, 21, 843, 7, 30, 15, 1, 1, 0, 929, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(5495, 'ITI-07950', 47, NULL, 326, 21, 844, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5496, 'ITI-07951', 227, NULL, 234, 21, 844, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5497, 'ITI-07952', 54, NULL, 335, 21, 844, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5498, 'ITI-07953', 43, NULL, 60, 21, 844, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(5499, 'ITI-07954', 226, NULL, 282, 21, 844, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(5500, 'ITI-07955', 211, NULL, 286, 21, 844, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5501, 'ITI-07956', 253, NULL, 64, 21, 844, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5502, 'ITI-07957', 47, NULL, 326, 21, 845, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(5503, 'ITI-07958', 211, NULL, 257, 21, 845, 7, 35, 30, 1, 1, 0, 923, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5504, 'ITI-07959', 54, NULL, 168, 21, 845, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(5505, 'ITI-07960', 226, NULL, 282, 21, 845, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(5506, 'ITI-07961', 227, NULL, 234, 21, 845, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5507, 'ITI-07962', 43, NULL, 60, 21, 845, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(5508, 'ITI-07963', 253, NULL, 64, 21, 845, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5509, 'ITI-07964', 54, NULL, 143, 21, 846, 7, 30, 10, 1, 1, 0, 854, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 0),
(5511, 'ITI-07965', 43, NULL, 60, 21, 846, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 0),
(5512, 'ITI-07966', 226, NULL, 282, 21, 846, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 0),
(5513, 'ITI-07967', 47, NULL, 163, 21, 846, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 0),
(5515, 'ITI-07968', 227, NULL, 286, 21, 846, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 0),
(5517, 'ITI-07969', 211, NULL, 330, 21, 846, 7, 37, 14, 1, 1, 0, 855, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(5520, 'ITI-07970', 253, NULL, 325, 21, 846, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(5521, 'ITI-07971', 106, NULL, 56, 21, 846, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 0),
(5524, 'ITI-07972', 232, NULL, 327, 21, 847, 7, 35, 25, 1, 1, 0, 895, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5526, 'ITI-07973', 56, NULL, 25, 21, 847, 7, 36, 23, 1, 1, 0, 911, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5527, 'ITI-07974', 144, NULL, 138, 21, 847, 7, 35, 28, 1, 1, 0, 896, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5528, 'ITI-07975', 88, NULL, 64, 21, 847, 7, 35, 35, 1, 1, 0, 897, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(5529, 'ITI-07976', 234, NULL, 100, 21, 847, 7, 35, 33, 1, 1, 0, 898, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5532, 'ITI-07977', 233, NULL, 170, 21, 847, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5534, 'ITI-07978', 235, NULL, 52, 21, 847, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5536, 'ITI-07979', 136, NULL, 265, 21, 848, 7, 35, 27, 1, 1, 0, 890, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5537, 'ITI-07980', 238, NULL, 23, 21, 848, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(5539, 'ITI-07981', 135, NULL, 62, 21, 848, 7, 35, 29, 1, 1, 0, 891, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5540, 'ITI-07982', 236, NULL, 337, 21, 848, 7, 35, 28, 1, 1, 0, 892, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(5542, 'ITI-07983', 237, NULL, 87, 21, 848, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5543, 'ITI-07984', 239, NULL, 52, 21, 848, 7, 35, 34, 1, 1, 0, 893, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(5545, 'ITI-07985', 256, NULL, 105, 21, 848, 7, 35, 18, 1, 1, 0, 894, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(5549, 'ITI-07986', 135, NULL, 25, 21, 849, 7, 35, 20, 1, 1, 0, 885, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5550, 'ITI-07987', 236, NULL, 163, 21, 849, 7, 35, 34, 1, 1, 0, 886, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5552, 'ITI-07988', 256, NULL, 138, 21, 849, 7, 35, 33, 1, 1, 0, 887, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5553, 'ITI-07989', 136, NULL, 265, 21, 849, 7, 35, 35, 1, 1, 0, 888, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5554, 'ITI-07990', 239, NULL, 52, 21, 849, 7, 35, 20, 1, 1, 0, 889, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5556, 'ITI-07991', 237, NULL, 87, 21, 849, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5558, 'ITI-07992', 238, NULL, 23, 21, 849, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5559, 'ITI-07993', 236, NULL, 337, 21, 850, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(5562, 'ITI-07994', 135, NULL, 335, 21, 850, 7, 30, 6, 1, 1, 0, 856, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 0),
(5564, 'ITI-07995', 136, NULL, 7, 21, 850, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 0),
(5566, 'ITI-07996', 239, NULL, 52, 21, 850, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(5567, 'ITI-07997', 237, NULL, 170, 21, 850, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 0),
(5568, 'ITI-07998', 256, NULL, 105, 21, 850, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 0),
(5569, 'ITI-07999', 238, NULL, 118, 21, 850, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 0),
(5572, 'ITI-07001', 87, NULL, 160, 21, 850, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(5574, 'ITI-07002', 124, NULL, 43, 21, 851, 7, 30, 1, 1, 1, 0, 857, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5576, 'ITI-02900', 124, NULL, 43, 21, 833, 2, 30, 10, 1, 1, 0, 857, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5582, 'ITI-07003', 236, NULL, 117, 21, 850, 7, 10, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5642, 'ITI-07004', 210, NULL, 23, 21, 843, 7, 30, 19, 1, 1, 0, 908, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(5643, 'ITI-07005', 231, NULL, 173, 21, 853, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(5644, 'ITI-07006', 233, NULL, 170, 21, 847, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(5645, 'ITI-07007', 220, NULL, 56, 21, 853, 7, 50, 6, 1, 1, 0, 882, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5646, 'ITI-07008', 219, NULL, 56, 21, 852, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5713, 'MITI-05128', 167, NULL, 172, 21, 890, 5, 30, 2, 1, 1, 0, 871, 0, '<Campos><Grupo><colorLetra>-32640</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5715, 'MITI-05129', 30, NULL, 34, 21, 890, 5, 30, 0, 0, 0, 1, 872, 0, '<Campos><Grupo><colorLetra>-16744193</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5717, 'MITI-05130', 184, NULL, 8, 21, 890, 5, 30, 0, 0, 0, 1, 873, 0, '<Campos><Grupo><colorLetra>-65281</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5719, 'MITI-05131', 178, NULL, 79, 21, 890, 5, 30, 0, 0, 0, 1, 874, 0, '<Campos><Grupo><colorLetra>-256</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(5721, 'MITI-05132', 173, NULL, 75, 21, 890, 5, 30, 0, 0, 0, 1, 875, 0, '<Campos><Grupo><colorLetra>-32768</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5723, 'MITI-05133', 171, NULL, 87, 21, 890, 5, 30, 1, 1, 1, 1, 876, 0, '<Campos><Grupo><colorLetra>-16776961</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5725, 'MITI-05134', 197, NULL, 54, 21, 890, 5, 30, 1, 1, 1, 1, 877, 0, '<Campos><Grupo><colorLetra>-8388353</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5727, 'MITI-05135', 189, NULL, 170, 21, 890, 5, 30, 1, 1, 1, 1, 878, 0, '<Campos><Grupo><colorLetra>-65281</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(5729, 'MITI-05136', 263, NULL, 103, 21, 890, 5, 30, 7, 1, 1, 0, 879, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(5732, 'ITI-07009', 52, NULL, 25, 21, 854, 7, 35, 10, 1, 1, 0, 880, 0, '<Campos><Grupo><colorLetra>-16760704</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(5738, 'MITI-05137', 199, NULL, 163, 21, 890, 5, 30, 2, 1, 1, 1, 881, 0, '<Campos><Grupo><colorLetra>-65281</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(5739, 'ITI-02901', 33, NULL, 56, 21, 836, 2, 50, 1, 1, 1, 0, 882, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5741, 'ITI-02903', 136, NULL, 7, 21, 829, 2, 30, 0, 0, 0, 0, 884, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(5742, 'ITI-02904', 135, NULL, 25, 21, 829, 2, 35, 3, 1, 1, 0, 885, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5743, 'ITI-02905', 114, NULL, 163, 21, 829, 2, 35, 0, 0, 0, 0, 886, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5744, 'ITI-02906', 107, NULL, 138, 21, 828, 2, 35, 2, 1, 1, 0, 887, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5745, 'ITI-02907', 136, NULL, 265, 21, 829, 2, 35, 0, 0, 0, 0, 888, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5746, 'ITI-02908', 8, NULL, 52, 21, 828, 2, 35, 1, 1, 1, 0, 889, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5747, 'ITI-02909', 136, NULL, 265, 21, 829, 2, 35, 0, 0, 0, 0, 890, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5748, 'ITI-02910', 135, NULL, 62, 21, 829, 2, 35, 1, 1, 1, 0, 891, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5749, 'ITI-02911', 114, NULL, 337, 21, 829, 2, 35, 1, 1, 1, 0, 892, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(5750, 'ITI-02912', 8, NULL, 52, 21, 828, 2, 35, 0, 0, 0, 0, 893, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(5751, 'ITI-02913', 107, NULL, 105, 21, 836, 2, 35, 0, 0, 0, 0, 894, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(5752, 'ITI-02914', 143, NULL, 327, 21, 828, 2, 35, 1, 1, 1, 0, 895, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5753, 'ITI-02915', 144, NULL, 138, 21, 828, 2, 35, 0, 0, 0, 0, 896, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5754, 'ITI-02916', 88, NULL, 64, 21, 836, 2, 35, 0, 0, 0, 0, 897, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(5755, 'ITI-02917', 1, NULL, 100, 21, 828, 2, 35, 1, 1, 1, 0, 898, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5756, 'ITI-02918', 72, NULL, 43, 21, 829, 2, 10, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5764, 'ITI-07010', 135, NULL, 22, 21, 854, 7, 30, 2, 1, 1, 0, 901, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5765, 'ITI-07011', 135, NULL, 219, 21, 854, 7, 35, 0, 0, 0, 0, 858, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(5767, 'ITI-07012', 50, NULL, 167, 21, 838, 7, 36, 1, 1, 1, 0, 903, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5769, 'ITI-07013', 51, NULL, 272, 21, 854, 7, 35, 1, 1, 1, 0, 904, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5775, 'ITI-07014', 135, NULL, 219, 21, 854, 7, 30, 1, 1, 1, 0, 902, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5776, 'ITI-02919', 135, NULL, 219, 21, 837, 2, 30, 2, 1, 1, 0, 902, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5780, 'ITI-02920', 106, NULL, 14, 21, 828, 2, 5, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(5785, 'ITI-07015', 55, NULL, 95, 21, 895, 7, 30, 3, 1, 1, 0, 912, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5796, 'ITI-07016', 88, NULL, 64, 21, 847, 7, 35, 13, 1, 1, 0, 930, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5816, 'ITI-07017', 80, NULL, 21, 21, 852, 7, 35, 2, 1, 1, 0, 922, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(5821, 'ITI-07018', 121, NULL, 23, 21, 852, 7, 30, 1, 1, 1, 0, 925, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5822, 'ITI-07019', 56, NULL, 161, 21, 854, 7, 35, 3, 1, 1, 0, 865, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(5826, 'ITI-07020', 211, NULL, 23, 21, 840, 7, 33, 1, 1, 1, 0, 920, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5827, 'ITI-07021', 106, NULL, 242, 21, 843, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 1, 1),
(5830, 'ITI-07022', 121, NULL, 85, 21, 852, 7, 35, 1, 1, 1, 0, 927, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5831, 'ITI-07023', 229, NULL, 43, 21, 853, 7, 35, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5832, 'ITI-02921', 57, NULL, 105, 21, 828, 2, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(5834, 'ITI-02922', 101, NULL, 87, 21, 829, 2, 30, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5837, 'ITI-07024', 234, NULL, 100, 21, 847, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 1, 1),
(5841, 'ITI-02923', 88, NULL, 64, 21, 836, 2, 35, 1, 1, 1, 0, 930, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5843, 'ITI-07025', 233, NULL, 170, 21, 847, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 1, 1),
(5844, 'ITI-07026', 21, NULL, 60, 21, 846, 7, 7, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 0),
(5845, 'ITI-02924', 23, NULL, 163, 21, 836, 2, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5852, 'MITI-05138', 181, NULL, 87, 22, 903, 5, 20, 6, 1, 1, 1, 963, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(5854, 'MITI-05139', 89, NULL, 176, 22, 903, 5, 20, 7, 1, 1, 0, 961, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5857, 'MITI-05140', 198, NULL, 163, 22, 903, 5, 20, 2, 1, 1, 1, 962, 0, '<Campos><Grupo><colorLetra>-8388353</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5859, 'MITI-05141', 28, NULL, 171, 22, 903, 5, 30, 2, 1, 1, 1, 933, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(5860, 'MITI-05142', 71, NULL, 90, 22, 903, 5, 20, 7, 1, 1, 0, 934, 0, '<Campos><Grupo><colorLetra>-16744193</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5861, 'MITI-05143', 70, NULL, 107, 22, 903, 5, 20, 7, 1, 1, 0, 935, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5862, 'MITI-05144', 200, NULL, 21, 22, 903, 5, 20, 0, 0, 0, 1, 936, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5863, 'MITI-05145', 195, NULL, 281, 22, 903, 5, 20, 0, 1, 0, 1, 937, 0, '<Campos><Grupo><colorLetra>-8388608</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5864, 'MITI-05146', 168, NULL, 385, 22, 903, 5, 20, 2, 1, 1, 0, 938, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(5951, 'ITI-07027', 40, NULL, 206, 22, 919, 7, 37, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(5952, 'ITI-07028', 59, NULL, 100, 22, 919, 7, 37, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5953, 'ITI-07029', 49, NULL, 386, 22, 919, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(5955, 'ITI-07030', 156, NULL, 199, 22, 919, 7, 37, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(5956, 'ITI-07031', 206, NULL, 56, 22, 919, 7, 37, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(5957, 'ITI-07032', 65, NULL, 373, 22, 919, 7, 37, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5958, 'ITI-07033', 3, NULL, 52, 22, 919, 7, 37, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(5959, 'ITI-07034', 49, NULL, 62, 22, 920, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(5961, 'ITI-07035', 40, NULL, 100, 22, 920, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(5962, 'ITI-07036', 206, NULL, 56, 22, 920, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(5963, 'ITI-07037', 3, NULL, 9, 22, 920, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5964, 'ITI-07038', 59, NULL, 52, 22, 920, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(5965, 'ITI-07039', 65, NULL, 373, 22, 920, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5967, 'ITI-07040', 156, NULL, 372, 22, 920, 7, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(5968, 'ITI-07041', 206, NULL, 265, 22, 923, 7, 23, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(5970, 'ITI-07042', 49, NULL, 386, 22, 923, 7, 23, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(5971, 'ITI-07043', 40, NULL, 7, 22, 923, 7, 23, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5972, 'ITI-07044', 65, NULL, 56, 22, 923, 7, 25, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(5974, 'ITI-07045', 3, NULL, 163, 22, 923, 7, 24, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(5975, 'ITI-07046', 59, NULL, 373, 22, 923, 7, 24, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(5976, 'ITI-07047', 156, NULL, 260, 22, 923, 7, 23, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(5978, 'ITI-07048', 156, NULL, 372, 22, 922, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(5979, 'ITI-07049', 206, NULL, 173, 22, 922, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(5980, 'ITI-07050', 3, NULL, 327, 22, 922, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(5981, 'ITI-07051', 59, NULL, 138, 22, 922, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(5982, 'ITI-07052', 49, NULL, 220, 22, 922, 7, 33, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5983, 'ITI-07053', 65, NULL, 285, 22, 922, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5984, 'ITI-07054', 40, NULL, 242, 22, 922, 7, 36, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(5985, 'ITI-07055', 51, NULL, 167, 22, 924, 7, 36, 15, 1, 1, 0, 940, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(5987, 'ITI-07056', 181, NULL, 105, 22, 924, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(5988, 'ITI-07057', 218, NULL, 60, 22, 924, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(5989, 'ITI-07058', 221, NULL, 163, 22, 924, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(5990, 'ITI-07059', 9, NULL, 138, 22, 924, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(5991, 'ITI-07060', 121, NULL, 23, 22, 924, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(5992, 'ITI-07061', 222, NULL, 242, 22, 924, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(5993, 'ITI-07062', 2, NULL, 179, 22, 926, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(5994, 'ITI-07063', 223, NULL, 325, 22, 926, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5995, 'ITI-07064', 52, NULL, 169, 22, 926, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(5996, 'ITI-07065', 129, NULL, 372, 22, 926, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(5997, 'ITI-07066', 225, NULL, 14, 22, 926, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(5998, 'ITI-07067', 224, NULL, 60, 22, 926, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(5999, 'ITI-07068', 219, NULL, 56, 22, 926, 7, 90, 65, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6000, 'ITI-07069', 223, NULL, 325, 22, 927, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(6001, 'ITI-07070', 224, NULL, 60, 22, 927, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(6002, 'ITI-07071', 2, NULL, 179, 22, 927, 7, 35, 34, 1, 1, 0, 969, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6003, 'ITI-07072', 129, NULL, 372, 22, 927, 7, 35, 33, 1, 1, 0, 970, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6004, 'ITI-07073', 225, NULL, 14, 22, 927, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6006, 'ITI-07074', 52, NULL, 168, 22, 928, 7, 30, 12, 1, 1, 0, 976, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6007, 'ITI-07075', 223, NULL, 327, 22, 928, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(6008, 'ITI-07076', 224, NULL, 160, 22, 928, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(6009, 'ITI-07077', 225, NULL, 242, 22, 928, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6010, 'ITI-07078', 2, NULL, 285, 22, 928, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6011, 'ITI-07079', 129, NULL, 23, 22, 928, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(6012, 'ITI-07080', 2, NULL, 179, 22, 929, 7, 35, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(6013, 'ITI-07081', 129, NULL, 372, 22, 929, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6014, 'ITI-07082', 223, NULL, 325, 22, 929, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6015, 'ITI-07083', 224, NULL, 60, 22, 929, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6016, 'ITI-07084', 225, NULL, 14, 22, 929, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(6017, 'ITI-07085', 47, NULL, 173, 22, 930, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6018, 'ITI-07086', 54, NULL, 167, 22, 930, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(6020, 'ITI-07087', 211, NULL, 85, 22, 930, 7, 38, 24, 1, 1, 0, 941, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6021, 'ITI-07088', 211, NULL, 85, 22, 963, 6, 38, 14, 1, 1, 0, 941, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6027, 'ITI-07089', 52, NULL, 143, 22, 929, 7, 45, 10, 1, 1, 0, 943, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6029, 'ITI-07090', 253, NULL, 64, 22, 930, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6030, 'ITI-07091', 227, NULL, 23, 22, 930, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(6031, 'ITI-07092', 226, NULL, 327, 22, 930, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(6032, 'ITI-07093', 43, NULL, 206, 22, 930, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(6033, 'ITI-07094', 87, NULL, 337, 22, 933, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6034, 'ITI-07095', 230, NULL, 176, 22, 933, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6035, 'ITI-07096', 229, NULL, 100, 22, 933, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(6036, 'ITI-07097', 55, NULL, 22, 22, 933, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6037, 'ITI-07098', 231, NULL, 9, 22, 933, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(6038, 'ITI-07099', 228, NULL, 64, 22, 933, 7, 36, 33, 1, 1, 0, 989, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6039, 'ITI-07100', 220, NULL, 56, 22, 933, 7, 75, 62, 1, 1, 0, 967, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(6040, 'ITI-07101', 229, NULL, 100, 22, 935, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6041, 'ITI-07102', 87, NULL, 337, 22, 935, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(6042, 'ITI-07103', 55, NULL, 143, 22, 935, 7, 35, 11, 1, 1, 0, 944, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6043, 'ITI-07104', 230, NULL, 163, 22, 935, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(6044, 'ITI-07105', 228, NULL, 105, 22, 935, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(6045, 'ITI-07106', 231, NULL, 9, 22, 935, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6046, 'ITI-07107', 229, NULL, 43, 22, 934, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(6047, 'ITI-07108', 228, NULL, 64, 22, 934, 7, 35, 28, 1, 1, 0, 977, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6048, 'ITI-07109', 231, NULL, 173, 22, 934, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6049, 'ITI-07110', 55, NULL, 161, 22, 934, 7, 35, 5, 1, 1, 0, 959, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6050, 'ITI-07111', 230, NULL, 138, 22, 934, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(6051, 'ITI-07112', 87, NULL, 337, 22, 934, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(6052, 'ITI-07113', 236, NULL, 206, 22, 936, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6053, 'ITI-07114', 136, NULL, 265, 22, 936, 7, 36, 33, 1, 1, 0, 966, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(6054, 'ITI-07115', 135, NULL, 62, 22, 936, 7, 37, 31, 1, 1, 0, 946, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(6055, 'ITI-07116', 256, NULL, 105, 22, 936, 7, 35, 30, 1, 1, 0, 964, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(6056, 'ITI-07117', 237, NULL, 87, 22, 936, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(6057, 'ITI-07118', 239, NULL, 52, 22, 936, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(6058, 'ITI-07119', 238, NULL, 376, 22, 936, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6059, 'ITI-07120', 256, NULL, 105, 22, 937, 7, 35, 20, 1, 1, 0, 965, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(6060, 'ITI-07121', 237, NULL, 87, 22, 937, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(6061, 'ITI-07122', 124, NULL, 43, 22, 938, 7, 50, 46, 1, 1, 0, 945, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(6062, 'ITI-02925', 124, NULL, 43, 22, 940, 2, 50, 0, 0, 0, 0, 945, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(6063, 'ITI-02926', 135, NULL, 62, 22, 941, 2, 37, 0, 0, 0, 0, 946, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(6220, 'ITI-07123', 49, NULL, 62, 22, 920, 7, 35, 15, 1, 1, 0, 942, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6236, 'ITI-07124', 54, NULL, 168, 22, 930, 7, 38, 25, 1, 1, 0, 953, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6246, 'ITI-07125', 135, NULL, 25, 22, 933, 7, 38, 9, 1, 1, 0, 960, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(6251, 'ITI-02927', 107, NULL, 105, 22, 942, 2, 35, 0, 1, 0, 0, 964, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(6252, 'ITI-02928', 107, NULL, 105, 22, 942, 2, 35, 1, 1, 1, 0, 965, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(6253, 'ITI-02929', 136, NULL, 265, 22, 941, 2, 36, 1, 1, 1, 0, 966, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(6254, 'ITI-02930', 33, NULL, 56, 22, 942, 2, 75, 2, 1, 1, 0, 967, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(6255, 'ITI-02931', 80, NULL, 140, 22, 942, 2, 36, 1, 1, 1, 0, 968, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6256, 'ITI-07126', 80, NULL, 140, 22, 937, 7, 36, 1, 1, 1, 0, 968, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6274, 'ITI-07127', 135, NULL, 220, 22, 938, 7, 36, 9, 1, 1, 0, 973, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6275, 'ITI-02932', 135, NULL, 220, 22, 954, 8, 36, 11, 1, 1, 0, 973, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6282, 'ITI-02932', 57, NULL, 64, 22, 942, 2, 5, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(6283, 'ITI-02933', 57, NULL, 64, 22, 942, 2, 35, 1, 1, 1, 0, 977, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6284, 'ITI-07128', 106, NULL, 14, 22, 974, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(6289, 'ITI-07129', 53, NULL, 25, 22, 977, 7, 35, 6, 1, 1, 0, 978, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6294, 'ITI-07130', 54, NULL, 161, 22, 977, 7, 35, 1, 1, 1, 0, 979, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6298, 'ITI-07131', 51, NULL, 167, 22, 977, 7, 35, 3, 1, 1, 0, 980, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6301, 'ITI-07132', 46, NULL, 325, 22, 974, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6302, 'ITI-07133', 238, NULL, 376, 22, 937, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6306, 'ITI-07134', 9, NULL, 88, 22, 924, 7, 35, 1, 1, 1, 0, 982, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6308, 'ITI-07135', 52, NULL, 169, 22, 926, 7, 30, 1, 1, 1, 0, 984, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6309, 'ITI-07136', 129, NULL, 118, 22, 926, 7, 35, 2, 1, 1, 0, 985, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(6310, 'ITI-07137', 55, NULL, 168, 22, 934, 7, 30, 1, 1, 1, 0, 981, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(6311, 'ITI-07138', 237, NULL, 87, 22, 981, 7, 5, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 1, 1),
(6313, 'ITI-07139', 52, NULL, 335, 22, 939, 7, 30, 1, 1, 1, 0, 987, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(6315, 'ITI-07140', 229, NULL, 43, 22, 981, 7, 5, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 1, 1),
(6317, 'ITI-07141', 106, NULL, 14, 22, 981, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 1, 1),
(6318, 'ITI-07142', 43, NULL, 206, 22, 981, 7, 5, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 1, 1),
(6319, 'ITI-07143', 226, NULL, 327, 22, 981, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 1, 1),
(6323, 'ITI-07144', 56, NULL, 388, 22, 977, 7, 35, 0, 1, 0, 0, 988, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6326, 'ITI-07145', 88, NULL, 337, 22, 937, 7, 5, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6327, 'ITI-02934', 57, NULL, 64, 22, 942, 2, 36, 1, 1, 1, 0, 989, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6328, 'ITI-07146', 51, NULL, 366, 22, 939, 7, 30, 1, 1, 1, 0, 990, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6338, 'ITI-07147', 53, NULL, 272, 22, 977, 7, 35, 0, 0, 0, 0, 992, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(6451, 'ITI-07148', 214, NULL, 179, 23, 1000, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6452, 'ITI-07149', 137, NULL, 372, 23, 1000, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(6453, 'ITI-07150', 39, NULL, 105, 23, 1000, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(6454, 'ITI-07151', 66, NULL, 373, 23, 1000, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(6455, 'ITI-07152', 216, NULL, 60, 23, 1000, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6456, 'ITI-07153', 215, NULL, 56, 23, 1000, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6457, 'ITI-07154', 50, NULL, 386, 23, 1000, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(6458, 'ITI-07155', 156, NULL, 374, 23, 1001, 7, 30, 10, 1, 1, 0, 997, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6459, 'ITI-07156', 59, NULL, 173, 23, 1001, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6460, 'ITI-07157', 49, NULL, 388, 23, 1001, 7, 30, 11, 1, 1, 0, 1012, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6461, 'ITI-07158', 206, NULL, 265, 23, 1001, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6462, 'ITI-07159', 40, NULL, 394, 23, 1001, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6463, 'ITI-07160', 3, NULL, 100, 23, 1001, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6464, 'ITI-07161', 65, NULL, 140, 23, 1001, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(6465, 'ITI-07162', 137, NULL, 372, 23, 1002, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6466, 'ITI-07163', 50, NULL, 386, 23, 1002, 7, 30, 13, 1, 1, 0, 1016, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6467, 'ITI-07164', 215, NULL, 56, 23, 1002, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6468, 'ITI-07165', 39, NULL, 105, 23, 1002, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6469, 'ITI-07166', 66, NULL, 373, 23, 1002, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6470, 'ITI-07167', 216, NULL, 52, 23, 1002, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6471, 'ITI-07168', 214, NULL, 209, 23, 1002, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(6472, 'ITI-07169', 50, NULL, 409, 23, 1003, 7, 35, 23, 1, 1, 0, 1049, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6473, 'ITI-07170', 66, NULL, 173, 23, 1003, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6474, 'ITI-07171', 39, NULL, 394, 23, 1003, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6475, 'ITI-07172', 215, NULL, 242, 23, 1003, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6476, 'ITI-07173', 214, NULL, 138, 23, 1003, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6477, 'ITI-07174', 137, NULL, 23, 23, 1003, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6478, 'ITI-07175', 216, NULL, 100, 23, 1003, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(6479, 'ITI-07176', 137, NULL, 372, 23, 1004, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(6480, 'ITI-07177', 214, NULL, 179, 23, 1004, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(6481, 'ITI-07178', 66, NULL, 373, 23, 1004, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 0),
(6482, 'ITI-07179', 216, NULL, 383, 23, 1004, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(6483, 'ITI-07180', 50, NULL, 409, 23, 1004, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 0),
(6484, 'ITI-07181', 39, NULL, 105, 23, 1004, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 0),
(6485, 'ITI-07182', 215, NULL, 56, 23, 1004, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 0),
(6486, 'ITI-07183', 224, NULL, 160, 23, 1006, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(6487, 'ITI-07184', 225, NULL, 242, 23, 1006, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(6488, 'ITI-07185', 129, NULL, 23, 23, 1006, 7, 30, 13, 1, 1, 0, 1037, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(6489, 'ITI-07186', 223, NULL, 285, 23, 1006, 7, 37, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6490, 'ITI-07187', 2, NULL, 140, 23, 1006, 7, 30, 12, 1, 1, 0, 1011, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(6491, 'ITI-07188', 35, NULL, 241, 23, 1007, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(6492, 'ITI-07189', 46, NULL, 265, 23, 1007, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(6493, 'ITI-07190', 21, NULL, 389, 23, 1007, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(6494, 'ITI-07191', 80, NULL, 9, 23, 1007, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6495, 'ITI-07192', 106, NULL, 14, 23, 1007, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(6496, 'ITI-07193', 210, NULL, 374, 23, 1007, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6497, 'ITI-07194', 53, NULL, 409, 23, 1007, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(6498, 'ITI-07195', 35, NULL, 241, 23, 1009, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6499, 'ITI-07196', 21, NULL, 60, 23, 1009, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(6500, 'ITI-07197', 210, NULL, 372, 23, 1009, 7, 35, 28, 1, 1, 0, 1015, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(6501, 'ITI-07198', 106, NULL, 14, 23, 1009, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6502, 'ITI-07199', 46, NULL, 163, 23, 1009, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(6503, 'ITI-07200', 80, NULL, 9, 23, 1009, 7, 35, 29, 1, 1, 0, 1009, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(6504, 'ITI-07201', 52, NULL, 272, 23, 1006, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(6505, 'ITI-07202', 53, NULL, 168, 23, 1010, 7, 35, 21, 1, 1, 0, 1021, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6506, 'ITI-07203', 21, NULL, 60, 23, 1010, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(6507, 'ITI-07204', 46, NULL, 173, 23, 1010, 7, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(6508, 'ITI-07205', 80, NULL, 338, 23, 1010, 7, 30, 7, 1, 1, 0, 995, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(6509, 'ITI-07206', 106, NULL, 242, 23, 1010, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(6511, 'ITI-07207', 35, NULL, 285, 23, 1010, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(6512, 'ITI-07208', 210, NULL, 23, 23, 1010, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(6513, 'ITI-07209', 53, NULL, 388, 23, 1014, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 0),
(6514, 'ITI-07210', 46, NULL, 7, 23, 1014, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 0),
(6515, 'ITI-07211', 106, NULL, 14, 23, 1014, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(6516, 'ITI-07212', 80, NULL, 9, 23, 1014, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 0),
(6517, 'ITI-07213', 210, NULL, 372, 23, 1014, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 0),
(6518, 'ITI-07214', 21, NULL, 60, 23, 1014, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 0),
(6519, 'ITI-07215', 35, NULL, 383, 23, 1014, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(6521, 'ITI-07216', 229, NULL, 43, 23, 1015, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6522, 'ITI-07217', 230, NULL, 176, 23, 1015, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(6523, 'ITI-07218', 231, NULL, 163, 23, 1015, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(6524, 'ITI-07219', 55, NULL, 161, 23, 1015, 7, 35, 16, 1, 1, 0, 1018, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(6525, 'ITI-07220', 228, NULL, 394, 23, 1015, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6526, 'ITI-07221', 87, NULL, 138, 23, 1015, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(6527, 'ITI-07222', 56, NULL, 365, 23, 1016, 7, 35, 31, 1, 1, 0, 1046, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(6528, 'ITI-07223', 234, NULL, 7, 23, 1016, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(6529, 'ITI-07224', 232, NULL, 398, 23, 1016, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6530, 'ITI-07225', 233, NULL, 163, 23, 1016, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(6531, 'ITI-07226', 144, NULL, 105, 23, 1016, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(6532, 'ITI-07227', 235, NULL, 52, 23, 1016, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(6535, 'ITI-07228', 88, NULL, 160, 23, 1016, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(6537, 'ITI-07229', 56, NULL, 168, 23, 1017, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6538, 'ITI-07230', 88, NULL, 160, 23, 1017, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(6539, 'ITI-07231', 233, NULL, 138, 23, 1017, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(6542, 'MITI-05147', 204, NULL, 87, 23, 1012, 5, 20, 5, 1, 1, 1, 1003, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6543, 'ITI-07232', 232, NULL, 398, 23, 1017, 7, 35, 24, 1, 1, 0, 994, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6544, 'ITI-07233', 144, NULL, 285, 23, 1017, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(6545, 'ITI-07234', 235, NULL, 52, 23, 1017, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(6546, 'ITI-07235', 234, NULL, 100, 23, 1017, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6547, 'ITI-07236', 88, NULL, 389, 23, 1018, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 0),
(6548, 'MITI-05148', 199, NULL, 176, 23, 1012, 5, 20, 5, 1, 1, 1, 1004, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6550, 'ITI-07237', 56, NULL, 365, 23, 1018, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 0),
(6551, 'ITI-07238', 234, NULL, 179, 23, 1018, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 0),
(6552, 'ITI-07239', 235, NULL, 52, 23, 1018, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 0),
(6553, 'ITI-07240', 233, NULL, 163, 23, 1018, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 0),
(6554, 'ITI-07241', 144, NULL, 105, 23, 1018, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 0),
(6555, 'ITI-07242', 232, NULL, 398, 23, 1018, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 0),
(6556, 'MITI-05149', 200, NULL, 8, 23, 1012, 5, 20, 0, 0, 0, 1, 1005, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(6557, 'ITI-02935', 124, NULL, 43, 23, 1019, 2, 40, 2, 1, 1, 0, 993, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(6558, 'ITI-07243', 124, NULL, 43, 23, 1020, 7, 40, 31, 1, 1, 0, 993, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(6559, 'ITI-07244', 220, NULL, 56, 23, 1015, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(6560, 'ITI-07245', 219, NULL, 56, 23, 1006, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(6561, 'ITI-02936', 143, NULL, 398, 23, 1019, 2, 35, 2, 1, 1, 0, 994, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6562, 'ITI-02937', 80, NULL, 338, 23, 1019, 2, 30, 0, 0, 0, 0, 995, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(6686, 'ITI-07246', 135, NULL, 25, 23, 1021, 7, 41, 6, 1, 1, 0, 996, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(6730, 'MITI-05150', 169, NULL, 172, 23, 1012, 5, 30, 2, 1, 1, 0, 998, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6731, 'ITI-07247', 237, NULL, 383, 23, 1020, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(6749, 'MITI-05151', 173, NULL, 54, 23, 1012, 5, 20, 6, 1, 1, 1, 1002, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6754, 'MITI-05152', 30, NULL, 171, 23, 1012, 5, 20, 2, 1, 1, 1, 1006, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6755, 'MITI-05153', 177, NULL, 230, 23, 1012, 5, 20, 0, 0, 0, 1, 1007, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(6756, 'MITI-05154', 172, NULL, 90, 23, 1012, 5, 20, 1, 1, 1, 1, 1008, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(6757, 'ITI-02938', 80, NULL, 9, 23, 1019, 2, 35, 1, 1, 1, 0, 1009, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(6758, 'ITI-07248', 256, NULL, 253, 23, 1020, 7, 35, 20, 1, 1, 0, 1010, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(6759, 'ITI-02939', 107, NULL, 253, 23, 1019, 2, 35, 0, 0, 0, 0, 1010, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(6774, 'ITI-07249', 55, NULL, 272, 23, 1021, 7, 30, 8, 1, 1, 0, 1020, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(6796, 'ITI-07250', 51, NULL, 161, 23, 1021, 7, 30, 0, 0, 0, 0, 1032, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6801, 'ITI-07251', 54, NULL, 317, 23, 1021, 7, 30, 10, 1, 1, 0, 1033, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6807, 'ITI-07252', 54, NULL, 404, 23, 1021, 7, 30, 5, 1, 1, 0, 1034, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6822, 'ITI-07253', 43, NULL, 398, 23, 1014, 7, 10, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(6823, 'ITI-07254', 56, NULL, 22, 23, 1021, 7, 30, 2, 1, 1, 0, 1036, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(6834, 'ITI-07255', 52, NULL, 220, 23, 1021, 7, 30, 3, 1, 1, 0, 1027, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(6835, 'ITI-07256', 229, NULL, 43, 23, 1015, 7, 10, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 1, 1),
(6836, 'ITI-07257', 53, NULL, 365, 23, 1021, 7, 30, 2, 1, 1, 0, 1043, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(6837, 'ITI-07258', 56, NULL, 25, 23, 1021, 7, 31, 1, 1, 1, 0, 1044, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(6839, 'ITI-07259', 231, NULL, 163, 23, 1015, 7, 10, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 1, 1),
(6840, 'ITI-07260', 54, NULL, 95, 23, 1021, 7, 30, 1, 1, 1, 0, 1001, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6852, 'ITI-07261', 53, NULL, 404, 23, 1021, 7, 30, 1, 1, 1, 0, 1050, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(6853, 'ITI-07262', 9, NULL, 88, 23, 1021, 7, 35, 1, 1, 1, 0, 1017, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(6854, 'ITI-07263', 65, NULL, 140, 23, 1001, 7, 10, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 1, 1),
(6856, 'ITI-07264', 51, NULL, 272, 23, 1021, 7, 30, 4, 1, 1, 0, 1051, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(6867, 'ITI-07265', 210, NULL, 118, 23, 1009, 7, 34, 1, 1, 1, 0, 1054, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1</colorFondo></Grupo></Campos>', 0, 1),
(6869, 'ITI-07266', 124, NULL, 43, 24, 1084, 7, 50, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(6870, 'ITI-07267', 219, NULL, 56, 24, 1087, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(6871, 'ITI-07268', 220, NULL, 56, 24, 1087, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(6954, 'ITI-07269', 137, NULL, 374, 24, 1075, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(6955, 'ITI-07270', 216, NULL, 60, 24, 1075, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6956, 'ITI-07271', 215, NULL, 242, 24, 1075, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(6957, 'ITI-07272', 50, NULL, 317, 24, 1075, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(6958, 'ITI-07273', 214, NULL, 241, 24, 1075, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6959, 'ITI-07274', 39, NULL, 394, 24, 1075, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(6960, 'ITI-07275', 66, NULL, 285, 24, 1075, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(6961, 'ITI-07276', 51, NULL, 386, 24, 1071, 7, 35, 23, 1, 1, 0, 1082, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(6962, 'ITI-07277', 121, NULL, 85, 24, 1071, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6963, 'ITI-07278', 221, NULL, 100, 24, 1071, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(6964, 'ITI-07279', 222, NULL, 14, 24, 1071, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(6965, 'ITI-07280', 218, NULL, 160, 24, 1071, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1</colorFondo></Grupo></Campos>', 0, 1),
(6966, 'ITI-07281', 9, NULL, 43, 24, 1071, 7, 36, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6967, 'ITI-07282', 181, NULL, 373, 24, 1071, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(6968, 'ITI-07283', 9, NULL, 179, 24, 1072, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(6969, 'ITI-07284', 51, NULL, 220, 24, 1072, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(6970, 'ITI-07285', 121, NULL, 372, 24, 1072, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(6971, 'ITI-07286', 181, NULL, 373, 24, 1072, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(6972, 'ITI-07287', 222, NULL, 14, 24, 1072, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(6973, 'ITI-07288', 218, NULL, 60, 24, 1072, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6974, 'ITI-07289', 221, NULL, 77, 24, 1072, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(6975, 'ITI-07290', 9, NULL, 88, 24, 1073, 7, 35, 18, 1, 1, 0, 1100, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6976, 'ITI-07291', 221, NULL, 56, 24, 1073, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(6977, 'ITI-07292', 51, NULL, 95, 24, 1073, 7, 32, 18, 1, 1, 0, 1055, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6978, 'ITI-07293', 222, NULL, 242, 24, 1073, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(6979, 'ITI-07294', 181, NULL, 394, 24, 1073, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(6980, 'ITI-07295', 218, NULL, 241, 24, 1073, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(6981, 'ITI-07296', 121, NULL, 23, 24, 1073, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(6982, 'ITI-07297', 51, NULL, 220, 24, 1074, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(6983, 'ITI-07298', 221, NULL, 100, 24, 1074, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(6984, 'ITI-07299', 9, NULL, 179, 24, 1074, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(6985, 'ITI-07300', 121, NULL, 372, 24, 1074, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(6986, 'ITI-07301', 222, NULL, 14, 24, 1074, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(6987, 'ITI-07302', 181, NULL, 373, 24, 1074, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(6988, 'ITI-07303', 218, NULL, 416, 24, 1074, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(6989, 'ITI-07304', 53, NULL, 270, 24, 1074, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(6990, 'ITI-07305', 53, NULL, 25, 24, 1076, 7, 35, 12, 1, 1, 0, 1102, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(6991, 'ITI-07306', 80, NULL, 9, 24, 1076, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(6992, 'ITI-07307', 46, NULL, 173, 24, 1076, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(6993, 'ITI-07308', 35, NULL, 138, 24, 1076, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(6994, 'ITI-07309', 106, NULL, 242, 24, 1076, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(6995, 'ITI-07310', 21, NULL, 285, 24, 1076, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(6996, 'ITI-07311', 210, NULL, 23, 24, 1076, 7, 35, 14, 1, 1, 0, 1081, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(6997, 'ITI-07312', 144, NULL, 173, 24, 1080, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(6998, 'ITI-07313', 233, NULL, 163, 24, 1080, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(6999, 'ITI-07314', 232, NULL, 138, 24, 1080, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(7000, 'ITI-07315', 56, NULL, 161, 24, 1080, 7, 35, 23, 1, 1, 0, 1080, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(7001, 'ITI-07316', 88, NULL, 285, 24, 1080, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7002, 'ITI-07317', 234, NULL, 100, 24, 1080, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7003, 'ITI-07318', 235, NULL, 394, 24, 1080, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7004, 'ITI-07319', 136, NULL, 265, 24, 1081, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(7005, 'ITI-07320', 237, NULL, 87, 24, 1081, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(7006, 'ITI-07321', 236, NULL, 56, 24, 1081, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7007, 'ITI-07322', 239, NULL, 52, 24, 1081, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(7008, 'ITI-07323', 256, NULL, 105, 24, 1081, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(7009, 'ITI-07324', 238, NULL, 118, 24, 1081, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(7010, 'ITI-07325', 256, NULL, 105, 24, 1082, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(7011, 'ITI-07326', 135, NULL, 25, 24, 1082, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7012, 'ITI-07327', 136, NULL, 265, 24, 1082, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(7013, 'ITI-07328', 236, NULL, 111, 24, 1082, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(7014, 'ITI-07329', 237, NULL, 138, 24, 1082, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(7015, 'ITI-07330', 238, NULL, 23, 24, 1082, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(7016, 'ITI-07331', 239, NULL, 163, 24, 1082, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(7017, 'ITI-07332', 135, NULL, 220, 24, 1083, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(7018, 'ITI-07333', 236, NULL, 56, 24, 1083, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(7019, 'ITI-07334', 239, NULL, 52, 24, 1083, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(7020, 'ITI-07335', 256, NULL, 253, 24, 1083, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(7021, 'ITI-07336', 238, NULL, 118, 24, 1083, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(7022, 'ITI-07337', 136, NULL, 373, 24, 1083, 7, 35, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(7023, 'ITI-07338', 237, NULL, 416, 24, 1083, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(7025, 'ITI-07339', 47, NULL, 7, 24, 1079, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(7026, 'ITI-07340', 227, NULL, 286, 24, 1079, 7, 35, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(7027, 'ITI-07341', 211, NULL, 372, 24, 1079, 7, 35, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7028, 'ITI-07342', 43, NULL, 253, 24, 1079, 7, 35, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(7029, 'ITI-07343', 253, NULL, 416, 24, 1079, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(7030, 'ITI-07344', 226, NULL, 398, 24, 1079, 7, 35, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(7031, 'ITI-07345', 54, NULL, 388, 24, 1079, 7, 35, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(7032, 'ITI-07346', 135, NULL, 168, 24, 1081, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7033, 'ITI-07347', 211, NULL, 372, 24, 1077, 7, 35, 25, 1, 1, 0, 1090, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7034, 'ITI-07348', 253, NULL, 206, 24, 1077, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(7035, 'ITI-07349', 54, NULL, 365, 24, 1077, 7, 35, 26, 1, 1, 0, 1096, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(7036, 'ITI-07350', 47, NULL, 7, 24, 1077, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7037, 'ITI-07351', 227, NULL, 174, 24, 1077, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(7038, 'ITI-07352', 43, NULL, 253, 24, 1077, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(7039, 'ITI-07353', 226, NULL, 398, 24, 1077, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(7040, 'ITI-07354', 54, NULL, 365, 24, 1078, 7, 35, 18, 1, 1, 0, 1097, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(7041, 'ITI-07355', 43, NULL, 60, 24, 1078, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(7042, 'ITI-07356', 253, NULL, 206, 24, 1078, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(7043, 'ITI-07357', 226, NULL, 398, 24, 1078, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(7044, 'ITI-07358', 47, NULL, 163, 24, 1078, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(7045, 'ITI-07359', 227, NULL, 286, 24, 1078, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(7046, 'ITI-07360', 211, NULL, 260, 24, 1078, 7, 35, 29, 1, 1, 0, 1094, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(7047, 'ITI-07361', 50, NULL, 95, 24, 1075, 7, 40, 13, 1, 1, 0, 1056, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(7048, 'ITI-07362', 39, NULL, 411, 24, 1088, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(7049, 'ITI-07363', 80, NULL, 411, 24, 1088, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(7050, 'ITI-07364', 39, NULL, 411, 24, 1074, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7057, 'MITI-05155', 197, NULL, 9, 24, 1105, 5, 20, 2, 1, 1, 1, 1072, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7058, 'MITI-05156', 195, NULL, 56, 24, 1105, 5, 20, 0, 0, 0, 1, 1073, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(7059, 'MITI-05157', 189, NULL, 87, 24, 1105, 5, 20, 2, 1, 1, 1, 1075, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7060, 'MITI-05158', 170, NULL, 398, 24, 1105, 5, 20, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(7201, 'MITI-05159', 167, NULL, 103, 24, 1105, 5, 20, 5, 1, 1, 0, 1076, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(7209, 'ITI-07365', 229, NULL, 43, 24, 1085, 7, 10, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 1, 1),
(7224, 'MITI-05160', 170, NULL, 258, 24, 1105, 5, 20, 1, 1, 1, 1, 1077, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(7226, 'MITI-05161', 171, NULL, 281, 24, 1105, 5, 21, 4, 1, 1, 1, 1062, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7227, 'MITI-05162', 202, NULL, 172, 24, 1105, 5, 20, 0, 0, 0, 1, 1063, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(7229, 'MITI-05163', 191, NULL, 176, 24, 1105, 5, 20, 0, 0, 0, 1, 1065, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7230, 'MITI-05164', 160, NULL, 90, 24, 1105, 5, 20, 5, 1, 1, 0, 1066, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(7231, 'MITI-05165', 28, NULL, 376, 24, 1105, 5, 20, 1, 1, 1, 1, 1067, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(7232, 'MITI-05166', 182, NULL, 8, 24, 1105, 5, 20, 0, 0, 0, 1, 1068, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(7233, 'MITI-05167', 183, NULL, 107, 24, 1105, 5, 20, 0, 0, 0, 1, 1069, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7234, 'MITI-05168', 178, NULL, 171, 24, 1105, 5, 20, 1, 1, 1, 1, 1070, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7235, 'MITI-05169', 193, NULL, 171, 24, 1105, 5, 20, 1, 1, 1, 1, 1071, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7243, 'MITI-05170', 196, NULL, 230, 24, 1105, 5, 20, 1, 1, 1, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7264, 'ITI-07366', 55, NULL, 404, 24, 1134, 7, 35, 5, 1, 1, 0, 1091, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7268, 'ITI-07367', 55, NULL, 270, 24, 1134, 7, 35, 5, 1, 1, 0, 1092, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7277, 'ITI-07368', 51, NULL, 161, 24, 1134, 7, 35, 1, 1, 1, 0, 1093, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7288, 'ITI-07369', 54, NULL, 168, 24, 1086, 7, 35, 8, 1, 1, 0, 1099, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(7303, 'ITI-07370', 210, NULL, 118, 24, 1086, 7, 35, 1, 1, 1, 0, 1089, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(7317, 'ITI-07371', 52, NULL, 95, 24, 1134, 7, 35, 4, 1, 1, 0, 1107, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7324, 'ITI-07372', 80, NULL, 21, 24, 1086, 7, 35, 2, 1, 1, 0, 1110, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(7326, 'ITI-07373', 54, NULL, 409, 24, 1134, 7, 35, 0, 0, 0, 0, 1111, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(7328, 'ITI-07374', 54, NULL, 404, 24, 1086, 7, 30, 2, 1, 1, 0, 1113, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7330, 'ITI-07375', 39, NULL, 394, 24, 1085, 7, 5, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 1, 1),
(7333, 'ITI-07376', 135, NULL, 168, 24, 1134, 7, 31, 1, 1, 1, 0, 1087, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7336, 'ITI-07377', 135, NULL, 161, 24, 1086, 7, 30, 1, 1, 1, 0, 1116, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7427, 'ITI-07378', 65, NULL, 179, 25, 1157, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7428, 'ITI-07379', 3, NULL, 160, 25, 1157, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7429, 'ITI-07380', 206, NULL, 56, 25, 1157, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(7430, 'ITI-07381', 156, NULL, 372, 25, 1157, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7431, 'ITI-07382', 59, NULL, 373, 25, 1157, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(7432, 'ITI-07383', 40, NULL, 416, 25, 1157, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(7433, 'ITI-07384', 40, NULL, 7, 25, 1158, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(7434, 'ITI-07385', 59, NULL, 179, 25, 1158, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(7435, 'ITI-07386', 49, NULL, 388, 25, 1157, 7, 35, 6, 1, 1, 0, 1118, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(7436, 'ITI-07387', 206, NULL, 265, 25, 1158, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(7437, 'ITI-07388', 49, NULL, 220, 25, 1158, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7438, 'ITI-07389', 156, NULL, 372, 25, 1158, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(7439, 'ITI-07390', 3, NULL, 52, 25, 1158, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7440, 'ITI-07391', 65, NULL, 416, 25, 1158, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(7441, 'ITI-07392', 49, NULL, 388, 25, 1159, 7, 35, 15, 1, 1, 0, 1119, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(7442, 'ITI-07393', 206, NULL, 173, 25, 1159, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(7443, 'ITI-07394', 3, NULL, 132, 25, 1159, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(7444, 'ITI-07395', 156, NULL, 374, 25, 1159, 7, 35, 19, 1, 1, 0, 1120, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(7445, 'ITI-07396', 40, NULL, 394, 25, 1159, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(7446, 'ITI-07397', 65, NULL, 285, 25, 1159, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(7447, 'ITI-07398', 59, NULL, 100, 25, 1159, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(7448, 'ITI-07399', 9, NULL, 43, 25, 1160, 7, 35, 33, 1, 1, 0, 1148, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(7449, 'ITI-07400', 51, NULL, 219, 25, 1160, 7, 36, 20, 1, 1, 0, 1136, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(7450, 'ITI-07401', 222, NULL, 242, 25, 1160, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(7451, 'ITI-07402', 181, NULL, 394, 25, 1160, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(7452, 'ITI-07403', 218, NULL, 241, 25, 1160, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(7453, 'ITI-07404', 221, NULL, 100, 25, 1160, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(7454, 'ITI-07405', 121, NULL, 23, 25, 1160, 7, 37, 22, 1, 1, 0, 1121, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(7455, 'ITI-07406', 225, NULL, 14, 25, 1161, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(7456, 'ITI-07407', 2, NULL, 179, 25, 1161, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(7457, 'ITI-07408', 223, NULL, 398, 25, 1161, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(7458, 'ITI-07409', 224, NULL, 60, 25, 1161, 7, 40, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(7459, 'ITI-07410', 129, NULL, 118, 25, 1161, 7, 35, 26, 1, 1, 0, 1159, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(7460, 'ITI-07411', 219, NULL, 56, 25, 1161, 7, 70, 55, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(7461, 'ITI-07412', 52, NULL, 22, 25, 1161, 7, 35, 22, 1, 1, 0, 1133, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(7462, 'ITI-07413', 224, NULL, 206, 25, 1162, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(7463, 'ITI-07414', 225, NULL, 14, 25, 1162, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(7464, 'ITI-07415', 129, NULL, 372, 25, 1162, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7465, 'ITI-07416', 2, NULL, 373, 25, 1162, 7, 35, 30, 1, 1, 0, 1165, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7466, 'ITI-07417', 223, NULL, 398, 25, 1162, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7467, 'ITI-07418', 52, NULL, 220, 25, 1164, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(7468, 'ITI-07419', 225, NULL, 14, 25, 1164, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7469, 'ITI-07420', 224, NULL, 206, 25, 1164, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(7470, 'ITI-07421', 223, NULL, 398, 25, 1164, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(7471, 'ITI-07422', 2, NULL, 373, 25, 1164, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(7472, 'ITI-07423', 129, NULL, 372, 25, 1164, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(7473, 'ITI-07424', 52, NULL, 168, 25, 1163, 7, 37, 31, 1, 1, 0, 1132, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(7474, 'ITI-07425', 129, NULL, 118, 25, 1163, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(7475, 'ITI-07426', 223, NULL, 138, 25, 1163, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(7476, 'ITI-07427', 225, NULL, 242, 25, 1163, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(7477, 'ITI-07428', 224, NULL, 132, 25, 1163, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(7478, 'ITI-07429', 2, NULL, 241, 25, 1163, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(7479, 'ITI-07430', 47, NULL, 173, 25, 1165, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(7480, 'ITI-07431', 54, NULL, 95, 25, 1165, 7, 35, 13, 1, 1, 0, 1146, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(7481, 'ITI-07432', 253, NULL, 132, 25, 1165, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(7482, 'ITI-07433', 226, NULL, 138, 25, 1165, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(7483, 'ITI-07434', 211, NULL, 419, 25, 1165, 7, 35, 14, 1, 1, 0, 1155, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(7484, 'ITI-07435', 43, NULL, 285, 25, 1165, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(7485, 'ITI-07436', 227, NULL, 23, 25, 1165, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(7486, 'ITI-07437', 87, NULL, 420, 25, 1166, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(7487, 'ITI-07438', 229, NULL, 100, 25, 1166, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(7488, 'ITI-07439', 55, NULL, 365, 25, 1166, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(7489, 'ITI-07440', 230, NULL, 163, 25, 1166, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(7490, 'ITI-07441', 231, NULL, 9, 25, 1166, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7491, 'ITI-07442', 228, NULL, 105, 25, 1166, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7492, 'ITI-07443', 220, NULL, 56, 25, 1166, 7, 60, 53, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7493, 'ITI-07444', 87, NULL, 420, 25, 1167, 7, 35, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(7494, 'ITI-07445', 230, NULL, 163, 25, 1167, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(7495, 'ITI-07446', 231, NULL, 173, 25, 1167, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(7496, 'ITI-07447', 55, NULL, 219, 25, 1167, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(7497, 'ITI-07448', 229, NULL, 242, 25, 1167, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7498, 'ITI-07449', 228, NULL, 394, 25, 1167, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(7499, 'ITI-07450', 87, NULL, 420, 25, 1168, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7500, 'ITI-07451', 55, NULL, 423, 25, 1168, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(7501, 'ITI-07452', 230, NULL, 163, 25, 1168, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(7502, 'ITI-07453', 231, NULL, 9, 25, 1168, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(7503, 'ITI-07454', 228, NULL, 411, 25, 1168, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(7504, 'ITI-07455', 229, NULL, 416, 25, 1168, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(7505, 'ITI-07456', 135, NULL, 25, 25, 1169, 7, 35, 26, 1, 1, 0, 1151, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(7506, 'ITI-07457', 236, NULL, 56, 25, 1169, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(7507, 'ITI-07458', 136, NULL, 265, 25, 1169, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(7508, 'ITI-07459', 237, NULL, 87, 25, 1169, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(7509, 'ITI-07460', 238, NULL, 23, 25, 1169, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(7510, 'ITI-07461', 256, NULL, 138, 25, 1169, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(7511, 'ITI-07462', 239, NULL, 52, 25, 1169, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(7512, 'ITI-07463', 124, NULL, 43, 25, 1170, 7, 55, 52, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(7513, 'ITI-07464', 232, NULL, 383, 25, 1171, 7, 35, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(7686, 'MITI-05171', 203, NULL, 171, 25, 1207, 5, 20, 1, 1, 1, 1, 1122, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7687, 'MITI-05172', 192, NULL, 230, 25, 1207, 5, 20, 1, 1, 1, 1, 1123, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7688, 'MITI-05173', 195, NULL, 376, 25, 1207, 5, 15, 1, 1, 1, 1, 1124, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7689, 'MITI-05174', 168, NULL, 258, 25, 1207, 5, 20, 5, 1, 1, 0, 1125, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(7690, 'MITI-05175', 115, NULL, 103, 25, 1207, 5, 20, 0, 0, 0, 1, 1126, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(7691, 'MITI-05176', 198, NULL, 54, 25, 1207, 5, 20, 1, 1, 1, 1, 1128, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(7712, 'MITI-05177', 105, NULL, 87, 25, 1207, 5, 20, 1, 1, 1, 1, 1129, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7718, 'ITI-07465', 52, NULL, 168, 25, 1171, 7, 30, 3, 1, 1, 0, 1131, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(7725, 'ITI-07466', 135, NULL, 167, 25, 1213, 7, 35, 4, 1, 1, 0, 1135, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7733, 'ITI-07467', 55, NULL, 386, 25, 1213, 7, 30, 2, 1, 1, 0, 1140, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7743, 'ITI-07468', 56, NULL, 386, 25, 1213, 7, 30, 7, 1, 1, 0, 1142, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7771, 'ITI-07469', 211, NULL, 431, 25, 1165, 7, 30, 0, 0, 0, 0, 1147, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7772, 'ITI-07470', 9, NULL, 370, 25, 1160, 7, 30, 1, 1, 1, 0, 1154, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(7787, 'ITI-07471', 9, NULL, 88, 25, 1160, 7, 30, 5, 1, 1, 0, 1163, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(7792, 'ITI-07472', 53, NULL, 386, 25, 1213, 7, 30, 1, 1, 1, 0, 1164, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7799, 'ITI-07473', 54, NULL, 168, 25, 1213, 7, 30, 7, 1, 1, 0, 1167, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(7800, 'ITI-07474', 2, NULL, 209, 25, 1163, 7, 30, 2, 1, 1, 0, 1143, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(7801, 'ITI-07475', 52, NULL, 219, 25, 1213, 7, 30, 1, 1, 1, 0, 1127, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(7802, 'ITI-07476', 135, NULL, 25, 25, 1213, 7, 30, 1, 1, 1, 0, 1138, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(7803, 'ITI-07477', 2, NULL, 280, 25, 1163, 7, 30, 1, 1, 1, 0, 1168, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(7804, 'ITI-07478', 253, NULL, 132, 25, 1199, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 1, 1),
(7805, 'ITI-07479', 129, NULL, 85, 25, 1163, 7, 30, 1, 1, 1, 0, 1157, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(7806, 'ITI-07480', 49, NULL, 388, 25, 1213, 7, 35, 1, 1, 1, 0, 1169, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(7808, 'ITI-07482', 52, NULL, 167, 25, 1167, 7, 30, 2, 1, 1, 0, 1170, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(7811, 'ITI-07483', 54, NULL, 270, 25, 1213, 7, 30, 0, 0, 0, 0, 1144, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(7813, 'ITI-07484', 3, NULL, 160, 25, 1222, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(7814, 'ITI-07485', 237, NULL, 105, 25, 1169, 7, 10, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(7815, 'ITI-07486', 256, NULL, 105, 25, 1169, 7, 10, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(7816, 'ITI-07487', 239, NULL, 416, 25, 1169, 7, 10, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(7817, 'ITI-07488', 223, NULL, 285, 25, 1161, 7, 10, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(7818, 'ITI-07489', 232, NULL, 60, 25, 1171, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8064, 'ITI-07490', 206, NULL, 56, 26, 1269, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8065, 'ITI-07491', 65, NULL, 265, 26, 1269, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(8066, 'ITI-07492', 59, NULL, 173, 26, 1269, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(8067, 'ITI-07493', 49, NULL, 219, 26, 1269, 7, 35, 13, 1, 1, 0, 1172, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8068, 'ITI-07494', 156, NULL, 23, 26, 1269, 7, 35, 11, 1, 1, 0, 1208, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(8069, 'ITI-07495', 3, NULL, 440, 26, 1269, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8070, 'ITI-07496', 40, NULL, 394, 26, 1269, 7, 35, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8071, 'ITI-07497', 214, NULL, 179, 26, 1270, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8072, 'ITI-07498', 216, NULL, 446, 26, 1270, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(8073, 'ITI-07499', 50, NULL, 423, 26, 1270, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8074, 'ITI-07500', 137, NULL, 372, 26, 1270, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8075, 'ITI-07501', 66, NULL, 373, 26, 1270, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8076, 'ITI-07502', 39, NULL, 105, 26, 1270, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(8077, 'ITI-07503', 215, NULL, 56, 26, 1270, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(8078, 'ITI-07504', 50, NULL, 409, 26, 1271, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(8079, 'ITI-07505', 214, NULL, 179, 26, 1271, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(8080, 'ITI-07506', 137, NULL, 372, 26, 1271, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(8081, 'ITI-07507', 216, NULL, 439, 26, 1271, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(8082, 'ITI-07508', 215, NULL, 56, 26, 1271, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(8083, 'ITI-07509', 66, NULL, 373, 26, 1271, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8084, 'ITI-07510', 39, NULL, 411, 26, 1271, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(8085, 'ITI-07511', 50, NULL, 22, 26, 1272, 7, 35, 4, 1, 1, 0, 1173, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(8086, 'ITI-07512', 214, NULL, 285, 26, 1272, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(8087, 'ITI-07513', 137, NULL, 85, 26, 1272, 7, 35, 8, 1, 1, 0, 1174, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(8088, 'ITI-07514', 216, NULL, 160, 26, 1272, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(8089, 'ITI-07515', 215, NULL, 242, 26, 1272, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(8090, 'ITI-07516', 39, NULL, 394, 26, 1272, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8091, 'ITI-07517', 66, NULL, 241, 26, 1272, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(8092, 'ITI-07518', 129, NULL, 374, 26, 1273, 7, 36, 21, 1, 1, 0, 1175, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8093, 'ITI-07519', 52, NULL, 270, 26, 1273, 7, 37, 15, 1, 1, 0, 1176, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8094, 'ITI-07520', 2, NULL, 285, 26, 1273, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(8095, 'ITI-07521', 224, NULL, 132, 26, 1273, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(8096, 'ITI-07522', 223, NULL, 241, 26, 1273, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8097, 'ITI-07523', 225, NULL, 242, 26, 1273, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(8098, 'ITI-07524', 219, NULL, 56, 26, 1273, 7, 50, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8099, 'ITI-07525', 35, NULL, 420, 26, 1274, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(8100, 'ITI-07526', 53, NULL, 423, 26, 1274, 7, 30, 21, 1, 1, 0, 1225, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8102, 'ITI-07527', 21, NULL, 206, 26, 1274, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8103, 'ITI-07528', 80, NULL, 416, 26, 1274, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(8104, 'MITI-05178', 169, NULL, 103, 26, 1284, 5, 20, 5, 1, 1, 0, 1177, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(8106, 'ITI-07529', 210, NULL, 372, 26, 1274, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(8107, 'ITI-07530', 106, NULL, 14, 26, 1274, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8108, 'ITI-07531', 46, NULL, 285, 26, 1274, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8115, 'ITI-07532', 53, NULL, 423, 26, 1275, 7, 35, 23, 1, 1, 0, 1194, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8116, 'ITI-07533', 46, NULL, 265, 26, 1275, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(8117, 'ITI-07534', 210, NULL, 372, 26, 1275, 7, 35, 25, 1, 1, 0, 1211, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(8118, 'ITI-07535', 106, NULL, 14, 26, 1275, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(8119, 'ITI-07536', 35, NULL, 163, 26, 1275, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(8120, 'ITI-07537', 21, NULL, 439, 26, 1275, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8121, 'ITI-07538', 80, NULL, 9, 26, 1275, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(8123, 'ITI-07539', 46, NULL, 7, 26, 1276, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(8124, 'ITI-07540', 35, NULL, 206, 26, 1276, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(8125, 'ITI-07541', 53, NULL, 409, 26, 1276, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8126, 'ITI-07542', 210, NULL, 372, 26, 1276, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(8127, 'ITI-07543', 80, NULL, 439, 26, 1276, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(8128, 'ITI-07544', 21, NULL, 416, 26, 1276, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(8129, 'ITI-07545', 106, NULL, 14, 26, 1276, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8130, 'ITI-07546', 46, NULL, 173, 26, 1277, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(8131, 'ITI-07547', 21, NULL, 60, 26, 1277, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(8132, 'ITI-07548', 35, NULL, 138, 26, 1277, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8133, 'ITI-07549', 80, NULL, 330, 26, 1277, 7, 30, 15, 1, 1, 0, 1221, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8134, 'ITI-07550', 53, NULL, 317, 26, 1277, 7, 30, 12, 1, 1, 0, 1212, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(8135, 'ITI-07551', 106, NULL, 242, 26, 1277, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(8136, 'ITI-07552', 210, NULL, 23, 26, 1277, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8137, 'ITI-07553', 55, NULL, 168, 26, 1278, 7, 36, 17, 1, 1, 0, 1178, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(8138, 'ITI-07554', 229, NULL, 100, 26, 1278, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8139, 'ITI-07555', 230, NULL, 138, 26, 1278, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(8140, 'ITI-07556', 231, NULL, 173, 26, 1278, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8141, 'ITI-07557', 228, NULL, 394, 26, 1278, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8142, 'ITI-07558', 87, NULL, 440, 26, 1278, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8143, 'ITI-07559', 220, NULL, 56, 26, 1278, 7, 50, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(8144, 'ITI-07560', 56, NULL, 409, 26, 1279, 7, 35, 18, 1, 1, 0, 1187, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8145, 'ITI-07561', 234, NULL, 446, 26, 1279, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(8146, 'ITI-07562', 88, NULL, 420, 26, 1279, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8147, 'ITI-07563', 144, NULL, 373, 26, 1279, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8148, 'ITI-07564', 235, NULL, 52, 26, 1279, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8149, 'ITI-07565', 232, NULL, 398, 26, 1279, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8150, 'ITI-07566', 233, NULL, 87, 26, 1279, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(8151, 'ITI-07567', 144, NULL, 7, 26, 1280, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8152, 'ITI-07568', 234, NULL, 179, 26, 1280, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8153, 'ITI-07569', 56, NULL, 25, 26, 1280, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(8154, 'ITI-07570', 235, NULL, 52, 26, 1280, 7, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(8155, 'ITI-07571', 88, NULL, 416, 26, 1280, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(8156, 'ITI-07572', 232, NULL, 398, 26, 1280, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8157, 'ITI-07573', 233, NULL, 163, 26, 1280, 7, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(8158, 'ITI-07574', 233, NULL, 163, 26, 1281, 7, 36, 36, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8159, 'ITI-07575', 235, NULL, 52, 26, 1281, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8160, 'ITI-07576', 144, NULL, 173, 26, 1281, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(8161, 'ITI-07577', 56, NULL, 161, 26, 1281, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(8162, 'ITI-07578', 232, NULL, 138, 26, 1281, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8163, 'ITI-07579', 88, NULL, 132, 26, 1281, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(8164, 'ITI-07580', 234, NULL, 440, 26, 1281, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8165, 'ITI-07581', 124, NULL, 43, 26, 1282, 7, 50, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8185, 'MITI-05179', 105, NULL, 87, 25, 1207, 5, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8193, 'ITI-07582', 135, NULL, 219, 26, 1282, 7, 30, 4, 1, 1, 0, 1179, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8206, 'ITI-07583', 55, NULL, 404, 26, 1295, 7, 30, 4, 1, 1, 0, 1184, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8211, 'ITI-07584', 135, NULL, 219, 26, 1295, 7, 35, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8216, 'ITI-07585', 135, NULL, 365, 26, 1295, 7, 30, 1, 1, 1, 0, 1186, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8221, 'ITI-07586', 2, NULL, 209, 26, 1290, 7, 35, 4, 1, 1, 0, 1188, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8239, 'ITI-07587', 56, NULL, 167, 26, 1295, 7, 30, 3, 1, 1, 0, 1201, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8241, 'ITI-07588', 52, NULL, 95, 26, 1295, 7, 30, 0, 1, 0, 0, 1198, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8248, 'ITI-07589', 237, NULL, 132, 26, 1282, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(8251, 'ITI-07590', 55, NULL, 365, 26, 1295, 7, 30, 4, 1, 1, 0, 1182, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8264, 'ITI-07591', 52, NULL, 447, 26, 1295, 7, 35, 12, 1, 1, 0, 1218, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8269, 'ITI-07592', 51, NULL, 447, 26, 1295, 7, 30, 2, 1, 1, 0, 1219, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8274, 'ITI-07593', 54, NULL, 447, 26, 1295, 7, 30, 1, 1, 1, 0, 1220, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8284, 'ITI-07594', 53, NULL, 272, 26, 1295, 7, 30, 2, 1, 1, 0, 1224, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8287, 'ITI-07595', 53, NULL, 220, 26, 1295, 7, 30, 1, 1, 1, 0, 1199, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8288, 'ITI-07596', 9, NULL, 433, 26, 1290, 7, 35, 3, 1, 1, 0, 1196, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8291, 'ITI-07597', 50, NULL, 220, 26, 1295, 7, 30, 1, 1, 1, 0, 1226, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8292, 'ITI-07598', 137, NULL, 260, 26, 1290, 7, 35, 1, 1, 1, 0, 1227, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(8296, 'MITI-05180', 203, NULL, 270, 22, 903, 5, 10, 0, 0, 0, 1, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8297, 'ITI-07599', 229, NULL, 105, 26, 1282, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8298, 'ITI-07600', 232, NULL, 60, 26, 1282, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(8299, 'ITI-07601', 231, NULL, 105, 26, 1282, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8487, 'ITI-07602', 50, NULL, 22, 27, 1331, 7, 30, 10, 1, 1, 0, 1234, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8488, 'ITI-07603', 66, NULL, 9, 27, 1331, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8489, 'ITI-07604', 215, NULL, 242, 27, 1331, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8490, 'ITI-07605', 216, NULL, 440, 27, 1331, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8491, 'ITI-07606', 39, NULL, 394, 27, 1331, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8492, 'ITI-07607', 137, NULL, 23, 27, 1331, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(8493, 'ITI-07608', 214, NULL, 241, 27, 1331, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8494, 'ITI-07609', 9, NULL, 179, 27, 1332, 7, 30, 25, 1, 1, 0, 1259, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(8495, 'ITI-07610', 222, NULL, 14, 27, 1332, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(8496, 'ITI-07611', 51, NULL, 365, 27, 1332, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(8497, 'ITI-07612', 121, NULL, 372, 27, 1332, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(8498, 'ITI-07613', 218, NULL, 60, 27, 1332, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(8499, 'ITI-07614', 181, NULL, 373, 27, 1332, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(8500, 'ITI-07615', 221, NULL, 56, 27, 1332, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(8501, 'ITI-07616', 51, NULL, 423, 27, 1333, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(8502, 'ITI-07617', 121, NULL, 372, 27, 1333, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(8503, 'ITI-07618', 9, NULL, 179, 27, 1333, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(8504, 'ITI-07619', 181, NULL, 373, 27, 1333, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(8505, 'ITI-07620', 221, NULL, 56, 27, 1333, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(8506, 'ITI-07621', 222, NULL, 14, 27, 1333, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(8507, 'ITI-07622', 218, NULL, 52, 27, 1333, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(8508, 'ITI-07623', 9, NULL, 43, 27, 1334, 7, 30, 19, 1, 1, 0, 1233, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(8509, 'ITI-07624', 221, NULL, 100, 27, 1334, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8510, 'ITI-07625', 222, NULL, 14, 27, 1334, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(8511, 'ITI-07626', 51, NULL, 161, 27, 1334, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(8512, 'ITI-07627', 218, NULL, 241, 27, 1334, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8513, 'ITI-07628', 181, NULL, 394, 27, 1334, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(8514, 'ITI-07629', 121, NULL, 23, 27, 1334, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8515, 'ITI-07630', 80, NULL, 9, 27, 1335, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8516, 'ITI-07631', 46, NULL, 160, 27, 1335, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8517, 'ITI-07632', 35, NULL, 138, 27, 1335, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(8518, 'ITI-07633', 53, NULL, 161, 27, 1335, 7, 30, 17, 1, 1, 0, 1230, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(8519, 'ITI-07634', 106, NULL, 242, 27, 1335, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(8520, 'ITI-07635', 210, NULL, 419, 27, 1335, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8521, 'ITI-07636', 21, NULL, 132, 27, 1335, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8522, 'ITI-07637', 226, NULL, 420, 27, 1336, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(8523, 'ITI-07638', 54, NULL, 423, 27, 1336, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(8524, 'ITI-07639', 253, NULL, 206, 27, 1336, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8525, 'ITI-07640', 43, NULL, 439, 27, 1336, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8526, 'ITI-07641', 211, NULL, 372, 27, 1336, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8527, 'ITI-07642', 47, NULL, 411, 27, 1336, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8528, 'ITI-07643', 227, NULL, 118, 27, 1336, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(8529, 'ITI-07644', 227, NULL, 446, 27, 1337, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8530, 'ITI-07645', 253, NULL, 206, 27, 1337, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(8531, 'ITI-07646', 47, NULL, 416, 27, 1337, 7, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(8532, 'ITI-07647', 43, NULL, 439, 27, 1337, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(8533, 'ITI-07648', 54, NULL, 388, 27, 1337, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(8534, 'ITI-07649', 226, NULL, 420, 27, 1337, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(8535, 'ITI-07650', 211, NULL, 372, 27, 1337, 7, 30, 22, 1, 1, 0, 1265, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8536, 'ITI-07651', 47, NULL, 285, 27, 1338, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8537, 'ITI-07652', 227, NULL, 118, 27, 1338, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(8538, 'ITI-07653', 253, NULL, 132, 27, 1338, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(8539, 'ITI-07654', 226, NULL, 398, 27, 1338, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(8540, 'ITI-07655', 211, NULL, 23, 27, 1338, 7, 30, 23, 1, 1, 0, 1257, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(8541, 'ITI-07656', 43, NULL, 440, 27, 1338, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(8542, 'ITI-07657', 227, NULL, 446, 27, 1339, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8543, 'ITI-07658', 211, NULL, 372, 27, 1339, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(8544, 'ITI-07659', 54, NULL, 220, 27, 1339, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388544</colorFondo></Grupo></Campos>', 0, 1),
(8545, 'ITI-07660', 253, NULL, 285, 27, 1339, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8546, 'ITI-07661', 43, NULL, 439, 27, 1339, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8547, 'ITI-07662', 226, NULL, 398, 27, 1339, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8548, 'ITI-07663', 47, NULL, 383, 27, 1339, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(8549, 'ITI-07664', 56, NULL, 272, 27, 1340, 7, 30, 20, 1, 1, 0, 1240, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(8550, 'ITI-07665', 233, NULL, 163, 27, 1340, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(8551, 'ITI-07666', 234, NULL, 100, 27, 1340, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(8552, 'ITI-07667', 144, NULL, 52, 27, 1340, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(8553, 'ITI-07668', 232, NULL, 138, 27, 1340, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(8554, 'ITI-07669', 235, NULL, 394, 27, 1340, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8555, 'ITI-07670', 88, NULL, 440, 27, 1340, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(8556, 'ITI-07671', 135, NULL, 404, 27, 1341, 7, 35, 18, 1, 1, 0, 1231, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8557, 'ITI-07672', 136, NULL, 265, 27, 1341, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8558, 'ITI-07673', 256, NULL, 105, 27, 1341, 7, 30, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8559, 'ITI-07674', 237, NULL, 87, 27, 1341, 7, 30, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8560, 'ITI-07675', 239, NULL, 9, 27, 1341, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8561, 'ITI-07676', 238, NULL, 118, 27, 1341, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8562, 'ITI-07677', 236, NULL, 56, 27, 1341, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(8563, 'ITI-07678', 136, NULL, 7, 27, 1342, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(8564, 'ITI-07679', 238, NULL, 118, 27, 1342, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8565, 'ITI-07680', 239, NULL, 163, 27, 1342, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(8566, 'ITI-07681', 236, NULL, 242, 27, 1342, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(8567, 'ITI-07682', 256, NULL, 132, 27, 1342, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777088</colorFondo></Grupo></Campos>', 0, 1),
(8568, 'ITI-07683', 237, NULL, 138, 27, 1342, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8569, 'ITI-07684', 256, NULL, 285, 27, 1343, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8570, 'ITI-07685', 237, NULL, 416, 27, 1343, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(8571, 'ITI-07686', 136, NULL, 7, 27, 1343, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8572, 'ITI-07687', 135, NULL, 423, 27, 1343, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(8573, 'ITI-07688', 236, NULL, 373, 27, 1343, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(8574, 'ITI-07689', 239, NULL, 383, 27, 1343, 7, 30, 8, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8575, 'ITI-07690', 238, NULL, 118, 27, 1343, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(8576, 'ITI-07691', 219, NULL, 14, 27, 1344, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8577, 'ITI-07692', 220, NULL, 14, 27, 1344, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1</colorFondo></Grupo></Campos>', 0, 1),
(8578, 'ITI-07693', 124, NULL, 43, 27, 1344, 7, 30, 11, 1, 1, 0, 1269, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(8579, 'ITI-07694', 54, NULL, 272, 27, 1338, 7, 30, 14, 1, 1, 0, 1228, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(8595, 'ITI-07695', 135, NULL, 167, 27, 1342, 7, 35, 30, 1, 1, 0, 1251, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8662, 'ITI-07696', 51, NULL, 22, 27, 1346, 7, 1, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(8663, 'ITI-07697', 234, NULL, 329, 27, 1346, 7, 0, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8669, 'MITI-05181', 170, NULL, 172, 27, 1360, 5, 30, 5, 1, 1, 0, 1229, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8693, 'ITI-07698', 55, NULL, 25, 27, 1346, 7, 30, 9, 1, 1, 0, 1236, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8699, 'ITI-07699', 55, NULL, 95, 27, 1346, 7, 30, 3, 1, 1, 0, 1238, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8704, 'ITI-07700', 80, NULL, 9, 27, 1345, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 1, 1),
(8732, 'ITI-07701', 21, NULL, 60, 27, 1345, 7, 10, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 1, 1),
(8733, 'ITI-07702', 46, NULL, 7, 27, 1345, 7, 5, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8734, 'ITI-07703', 51, NULL, 388, 27, 1346, 7, 30, 2, 1, 1, 0, 1254, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8735, 'ITI-07704', 50, NULL, 95, 27, 1346, 7, 35, 2, 1, 1, 0, 1244, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(8737, 'MITI-05182', 115, NULL, 12, 27, 1360, 5, 15, 2, 1, 1, 1, 1255, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8746, 'ITI-07705', 56, NULL, 270, 27, 1346, 7, 30, 2, 1, 1, 0, 1235, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8759, 'ITI-07706', 53, NULL, 25, 27, 1346, 7, 30, 5, 1, 1, 0, 1266, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8763, 'ITI-07707', 53, NULL, 161, 27, 1346, 7, 35, 2, 1, 1, 0, 1237, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(8766, 'ITI-07708', 53, NULL, 95, 27, 1346, 7, 35, 1, 1, 1, 0, 1245, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(8767, 'ITI-07709', 80, NULL, 21, 27, 1346, 7, 30, 1, 1, 1, 0, 1268, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(8768, 'ITI-07710', 137, NULL, 23, 27, 1345, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 1, 1),
(8769, 'ITI-02940', 124, NULL, 43, 27, 1373, 2, 30, 1, 1, 1, 0, 1269, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(8772, 'ITI-07711', 53, NULL, 168, 27, 1346, 7, 30, 1, 1, 1, 0, 1270, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8774, 'ITI-07712', 237, NULL, 87, 27, 1346, 7, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8775, 'ITI-07713', 210, NULL, 85, 27, 1335, 7, 35, 21, 1, 1, 0, 1246, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8863, 'ITI-07714', 49, NULL, 365, 28, 1389, 7, 40, 10, 1, 1, 0, 1272, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8864, 'ITI-07715', 156, NULL, 372, 28, 1389, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8865, 'ITI-07716', 3, NULL, 64, 28, 1389, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8866, 'ITI-07717', 40, NULL, 206, 28, 1389, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(8867, 'ITI-07718', 59, NULL, 179, 28, 1389, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8868, 'ITI-07719', 206, NULL, 56, 28, 1389, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8869, 'ITI-07720', 65, NULL, 373, 28, 1389, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8870, 'ITI-07721', 49, NULL, 365, 28, 1390, 7, 35, 23, 1, 1, 0, 0, 387, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8871, 'ITI-07722', 156, NULL, 372, 28, 1390, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8872, 'ITI-07723', 3, NULL, 64, 28, 1390, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8873, 'ITI-07724', 40, NULL, 7, 28, 1390, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(8874, 'ITI-07725', 59, NULL, 373, 28, 1390, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8875, 'ITI-07726', 206, NULL, 56, 28, 1390, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8876, 'ITI-07727', 65, NULL, 179, 28, 1390, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8877, 'ITI-07728', 49, NULL, 95, 28, 1392, 7, 35, 28, 1, 1, 0, 0, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8878, 'ITI-07729', 156, NULL, 23, 28, 1392, 7, 37, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8879, 'ITI-07730', 3, NULL, 241, 28, 1392, 7, 40, 37, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8880, 'ITI-07731', 40, NULL, 394, 28, 1392, 7, 37, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(8881, 'ITI-07732', 59, NULL, 132, 28, 1392, 7, 37, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8882, 'ITI-07733', 206, NULL, 138, 28, 1392, 7, 37, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8883, 'ITI-07734', 65, NULL, 285, 28, 1392, 7, 37, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8884, 'ITI-07735', 51, NULL, 161, 28, 1394, 7, 33, 11, 1, 1, 0, 1274, 387, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8885, 'ITI-07736', 121, NULL, 23, 28, 1394, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8886, 'ITI-07737', 218, NULL, 132, 28, 1394, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8887, 'ITI-07738', 221, NULL, 100, 28, 1394, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(8888, 'ITI-07739', 222, NULL, 242, 28, 1394, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8889, 'ITI-07740', 181, NULL, 64, 28, 1394, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8890, 'ITI-07741', 9, NULL, 241, 28, 1394, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8891, 'ITI-07742', 52, NULL, 95, 28, 1395, 7, 30, 22, 1, 1, 0, 1312, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8892, 'ITI-07743', 129, NULL, 372, 28, 1395, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8893, 'ITI-07744', 223, NULL, 398, 28, 1395, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(8894, 'ITI-07745', 224, NULL, 60, 28, 1395, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8895, 'ITI-07746', 225, NULL, 14, 28, 1395, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8896, 'ITI-07747', 2, NULL, 373, 28, 1395, 7, 30, 22, 1, 1, 0, 1301, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8897, 'ITI-07748', 52, NULL, 365, 28, 1396, 7, 30, 18, 1, 1, 0, 0, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8898, 'ITI-07749', 129, NULL, 372, 28, 1396, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8899, 'ITI-07750', 219, NULL, 7, 28, 1395, 7, 80, 57, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(8900, 'ITI-07751', 223, NULL, 439, 28, 1396, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8901, 'ITI-07752', 224, NULL, 60, 28, 1396, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(8902, 'ITI-07753', 225, NULL, 14, 28, 1396, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(8903, 'ITI-07754', 2, NULL, 179, 28, 1396, 7, 30, 24, 1, 1, 0, 1303, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8904, 'ITI-07755', 52, NULL, 447, 28, 1398, 7, 30, 6, 1, 1, 0, 1273, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8905, 'ITI-07756', 129, NULL, 23, 28, 1398, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8906, 'ITI-07757', 223, NULL, 440, 28, 1398, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8907, 'ITI-07758', 224, NULL, 60, 28, 1398, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(8908, 'ITI-07759', 225, NULL, 242, 28, 1398, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8909, 'ITI-07760', 2, NULL, 285, 28, 1398, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8910, 'ITI-07761', 54, NULL, 95, 28, 1399, 7, 35, 25, 1, 1, 0, 1277, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8911, 'ITI-07762', 211, NULL, 216, 28, 1399, 7, 35, 16, 1, 1, 0, 1307, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8912, 'ITI-07763', 226, NULL, 138, 28, 1399, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8913, 'ITI-07764', 43, NULL, 132, 28, 1399, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(8914, 'ITI-07765', 227, NULL, 23, 28, 1399, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8915, 'ITI-07766', 253, NULL, 440, 28, 1399, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8916, 'ITI-07767', 47, NULL, 7, 28, 1399, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(8917, 'ITI-07768', 55, NULL, 167, 28, 1400, 7, 35, 30, 1, 1, 0, 0, 387, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(8918, 'ITI-07769', 228, NULL, 105, 28, 1400, 7, 35, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8919, 'ITI-07770', 87, NULL, 420, 28, 1400, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(8920, 'ITI-07771', 229, NULL, 14, 28, 1400, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(8921, 'ITI-07772', 230, NULL, 163, 28, 1400, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(8922, 'ITI-07773', 231, NULL, 9, 28, 1400, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16776961</colorFondo></Grupo></Campos>', 0, 1),
(8923, 'ITI-07774', 220, NULL, 7, 28, 1400, 7, 80, 56, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8948, 'ITI-07775', 55, NULL, 167, 28, 1401, 7, 30, 25, 1, 1, 0, 0, 357, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(8949, 'ITI-07776', 228, NULL, 394, 28, 1401, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(8950, 'ITI-07777', 87, NULL, 439, 28, 1401, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(8951, 'ITI-07778', 229, NULL, 100, 28, 1401, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(8952, 'ITI-07779', 230, NULL, 138, 28, 1401, 7, 30, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760832</colorFondo></Grupo></Campos>', 0, 1),
(8953, 'ITI-07780', 231, NULL, 52, 28, 1401, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(8954, 'ITI-07781', 55, NULL, 167, 28, 1408, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(8955, 'ITI-07782', 228, NULL, 105, 28, 1408, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582784</colorFondo></Grupo></Campos>', 0, 1),
(8956, 'ITI-07783', 87, NULL, 206, 28, 1408, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777216</colorFondo></Grupo></Campos>', 0, 1),
(8957, 'ITI-07784', 229, NULL, 56, 28, 1408, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(8958, 'ITI-07785', 230, NULL, 163, 28, 1408, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(8959, 'ITI-07786', 231, NULL, 9, 28, 1408, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(8960, 'ITI-07787', 135, NULL, 447, 28, 1409, 7, 35, 34, 1, 1, 0, 0, 387, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(8961, 'ITI-07788', 236, NULL, 242, 28, 1409, 7, 35, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(8962, 'ITI-07789', 256, NULL, 105, 28, 1409, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(8963, 'ITI-07790', 136, NULL, 394, 28, 1409, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(8964, 'ITI-07791', 237, NULL, 87, 28, 1409, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(8988, 'ITI-07792', 238, NULL, 118, 28, 1409, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(8989, 'ITI-07793', 239, NULL, 52, 28, 1409, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(8990, 'ITI-07794', 124, NULL, 52, 28, 1415, 7, 55, 46, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(9201, 'ITI-07795', 135, NULL, 423, 28, 1453, 7, 30, 2, 1, 1, 0, 1291, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9206, 'ITI-07796', 51, NULL, 409, 28, 1453, 7, 30, 0, 0, 0, 0, 1292, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9211, 'ITI-07797', 50, NULL, 220, 28, 1453, 7, 30, 0, 0, 0, 0, 1293, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9216, 'ITI-07798', 56, NULL, 22, 28, 1453, 7, 30, 2, 1, 1, 0, 1294, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9241, 'ITI-07799', 121, NULL, 260, 28, 1394, 7, 30, 2, 1, 1, 0, 1306, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(9243, 'ITI-07800', 129, NULL, 260, 28, 1456, 7, 30, 1, 1, 1, 0, 1298, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(9244, 'ITI-07801', 55, NULL, 168, 28, 1453, 7, 30, 3, 1, 1, 0, 1308, 387, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(9245, 'ITI-07802', 54, NULL, 317, 28, 1453, 7, 35, 1, 1, 1, 0, 1309, 387, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582912</colorFondo></Grupo></Campos>', 0, 1),
(9246, 'ITI-07803', 211, NULL, 472, 28, 1456, 7, 30, 1, 1, 1, 0, 1279, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(9247, 'ITI-07804', 80, NULL, 435, 28, 1456, 7, 35, 3, 1, 1, 0, 1310, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(9251, 'ITI-07805', 53, NULL, 476, 28, 1453, 7, 35, 0, 0, 0, 0, 1311, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9258, 'MITI-05183', 162, NULL, 172, 28, 1458, 4, 1, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9262, 'ITI-07806', 135, NULL, 476, 28, 1453, 7, 30, 4, 1, 1, 0, 1313, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9266, 'ITI-07807', 237, NULL, 420, 28, 1409, 7, 2, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(9352, 'ITI-07808', 3, NULL, 432, 29, 1478, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(9354, 'ITI-07809', 65, NULL, 432, 29, 1478, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(9355, 'ITI-07810', 206, NULL, 432, 29, 1478, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(9356, 'ITI-07811', 49, NULL, 432, 29, 1478, 7, 38, 10, 1, 1, 0, 1315, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(9357, 'ITI-07812', 59, NULL, 100, 29, 1478, 7, 35, 11, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(9358, 'ITI-07813', 40, NULL, 394, 29, 1478, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(9359, 'ITI-07814', 156, NULL, 23, 29, 1478, 7, 35, 9, 1, 1, 0, 1346, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-19533</colorFondo></Grupo></Campos>', 0, 1),
(9360, 'ITI-07815', 214, NULL, 179, 29, 1479, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-23480</colorFondo></Grupo></Campos>', 0, 1),
(9361, 'ITI-07816', 215, NULL, 100, 29, 1479, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-9327614</colorFondo></Grupo></Campos>', 0, 1),
(9362, 'ITI-07817', 50, NULL, 22, 29, 1479, 7, 30, 13, 1, 1, 0, 0, 404, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(9363, 'ITI-07818', 39, NULL, 105, 29, 1479, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4689409</colorFondo></Grupo></Campos>', 0, 1),
(9364, 'ITI-07819', 137, NULL, 372, 29, 1479, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-28161</colorFondo></Grupo></Campos>', 0, 1),
(9365, 'ITI-07820', 66, NULL, 373, 29, 1479, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-209</colorFondo></Grupo></Campos>', 0, 1),
(9366, 'ITI-07821', 216, NULL, 9, 29, 1479, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372224</colorFondo></Grupo></Campos>', 0, 1),
(9367, 'ITI-07822', 50, NULL, 365, 29, 1480, 7, 35, 21, 1, 1, 0, 1314, 317, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4473925</colorFondo></Grupo></Campos>', 0, 1),
(9368, 'ITI-07823', 214, NULL, 179, 29, 1480, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-19094</colorFondo></Grupo></Campos>', 0, 1),
(9369, 'ITI-07824', 137, NULL, 372, 29, 1480, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-21761</colorFondo></Grupo></Campos>', 0, 1),
(9370, 'ITI-07825', 216, NULL, 9, 29, 1480, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2002688</colorFondo></Grupo></Campos>', 0, 1),
(9371, 'ITI-07826', 215, NULL, 56, 29, 1480, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-6842624</colorFondo></Grupo></Campos>', 0, 1),
(9372, 'ITI-07827', 66, NULL, 373, 29, 1480, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(9373, 'ITI-07828', 39, NULL, 105, 29, 1480, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-3800890</colorFondo></Grupo></Campos>', 0, 1),
(9374, 'ITI-07829', 66, NULL, 439, 29, 1483, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(9375, 'ITI-07830', 50, NULL, 95, 29, 1483, 7, 30, 16, 1, 1, 0, 1339, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(9376, 'ITI-07831', 214, NULL, 285, 29, 1483, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-24510</colorFondo></Grupo></Campos>', 0, 1),
(9377, 'ITI-07832', 215, NULL, 242, 29, 1483, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(9378, 'ITI-07833', 39, NULL, 394, 29, 1483, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8076801</colorFondo></Grupo></Campos>', 0, 1),
(9379, 'ITI-07834', 216, NULL, 100, 29, 1483, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2987776</colorFondo></Grupo></Campos>', 0, 1),
(9380, 'ITI-07835', 137, NULL, 23, 29, 1483, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-17921</colorFondo></Grupo></Campos>', 0, 1),
(9381, 'ITI-07836', 52, NULL, 95, 29, 1484, 7, 38, 12, 1, 1, 0, 1316, 387, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(9382, 'ITI-07837', 129, NULL, 118, 29, 1484, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-25187</colorFondo></Grupo></Campos>', 0, 1),
(9383, 'ITI-07838', 224, NULL, 132, 29, 1484, 7, 35, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(9384, 'ITI-07839', 2, NULL, 285, 29, 1484, 7, 35, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-723968</colorFondo></Grupo></Campos>', 0, 1),
(9385, 'ITI-07840', 223, NULL, 440, 29, 1484, 7, 35, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-37633</colorFondo></Grupo></Campos>', 0, 1),
(9386, 'ITI-07841', 225, NULL, 242, 29, 1484, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5592576</colorFondo></Grupo></Campos>', 0, 1),
(9387, 'ITI-07842', 46, NULL, 7, 29, 1485, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16738409</colorFondo></Grupo></Campos>', 0, 1),
(9388, 'ITI-07843', 53, NULL, 365, 29, 1485, 7, 35, 26, 1, 1, 0, 0, 317, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(9389, 'ITI-07844', 21, NULL, 60, 29, 1485, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(9390, 'ITI-07845', 35, NULL, 479, 29, 1485, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-14570123</colorFondo></Grupo></Campos>', 0, 1),
(9391, 'ITI-07846', 210, NULL, 372, 29, 1485, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12901</colorFondo></Grupo></Campos>', 0, 1),
(9392, 'ITI-07847', 80, NULL, 439, 29, 1485, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-48574</colorFondo></Grupo></Campos>', 0, 1),
(9393, 'ITI-07848', 106, NULL, 56, 29, 1485, 7, 35, 35, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-6513586</colorFondo></Grupo></Campos>', 0, 1),
(9394, 'ITI-07849', 21, NULL, 60, 29, 1487, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(9395, 'ITI-07850', 46, NULL, 7, 29, 1487, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16736353</colorFondo></Grupo></Campos>', 0, 1),
(9396, 'ITI-07851', 35, NULL, 420, 29, 1487, 7, 35, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16733696</colorFondo></Grupo></Campos>', 0, 1),
(9399, 'ITI-07852', 53, NULL, 409, 29, 1487, 7, 35, 23, 1, 1, 0, 0, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(9400, 'ITI-07853', 210, NULL, 372, 29, 1487, 7, 35, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-10322</colorFondo></Grupo></Campos>', 0, 1),
(9407, 'ITI-07854', 80, NULL, 439, 29, 1487, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-5242880</colorFondo></Grupo></Campos>', 0, 1),
(9409, 'ITI-07855', 106, NULL, 56, 29, 1487, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5987328</colorFondo></Grupo></Campos>', 0, 1),
(9410, 'ITI-07856', 55, NULL, 25, 29, 1488, 7, 35, 31, 1, 1, 0, 1349, 387, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(9412, 'ITI-07857', 228, NULL, 64, 29, 1488, 7, 35, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16721447</colorFondo></Grupo></Campos>', 0, 1),
(9413, 'ITI-07858', 231, NULL, 479, 29, 1488, 7, 35, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16752030</colorFondo></Grupo></Campos>', 0, 1),
(9414, 'ITI-07859', 230, NULL, 138, 29, 1488, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16604061</colorFondo></Grupo></Campos>', 0, 1),
(9415, 'ITI-07860', 87, NULL, 440, 29, 1488, 7, 35, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-1482765</colorFondo></Grupo></Campos>', 0, 1),
(9416, 'ITI-07861', 229, NULL, 242, 29, 1488, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-5724160</colorFondo></Grupo></Campos>', 0, 1),
(9417, 'ITI-07862', 88, NULL, 479, 29, 1489, 7, 35, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(9418, 'ITI-07863', 56, NULL, 409, 29, 1489, 7, 35, 21, 1, 1, 0, 0, 317, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(9419, 'ITI-07864', 234, NULL, 206, 29, 1489, 7, 35, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16729601</colorFondo></Grupo></Campos>', 0, 1),
(9420, 'ITI-07865', 233, NULL, 87, 29, 1489, 7, 35, 10, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16731303</colorFondo></Grupo></Campos>', 0, 1),
(9421, 'ITI-07866', 235, NULL, 52, 29, 1489, 7, 35, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-47458</colorFondo></Grupo></Campos>', 0, 1),
(9422, 'ITI-07867', 144, NULL, 105, 29, 1489, 7, 35, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-5144996</colorFondo></Grupo></Campos>', 0, 1),
(9423, 'ITI-07868', 232, NULL, 398, 29, 1489, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16738409</colorFondo></Grupo></Campos>', 0, 1),
(9424, 'ITI-07869', 235, NULL, 52, 29, 1491, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(9427, 'ITI-07870', 256, NULL, 105, 29, 1491, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4259649</colorFondo></Grupo></Campos>', 0, 1),
(9429, 'ITI-07871', 233, NULL, 163, 29, 1491, 7, 35, 33, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16735150</colorFondo></Grupo></Campos>', 0, 1),
(9430, 'ITI-07872', 232, NULL, 138, 29, 1491, 7, 35, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16724274</colorFondo></Grupo></Campos>', 0, 1),
(9431, 'ITI-07873', 88, NULL, 132, 29, 1491, 7, 35, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2528256</colorFondo></Grupo></Campos>', 0, 1),
(9432, 'ITI-07874', 234, NULL, 440, 29, 1491, 7, 35, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(9433, 'ITI-07875', 236, NULL, 242, 29, 1491, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4671374</colorFondo></Grupo></Campos>', 0, 1),
(9434, 'ITI-07876', 144, NULL, 394, 29, 1491, 7, 35, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-338685</colorFondo></Grupo></Campos>', 0, 1),
(9436, 'ITI-07877', 56, NULL, 409, 29, 1492, 7, 30, 3, 1, 1, 0, 0, 317, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 0),
(9438, 'ITI-07878', 88, NULL, 206, 29, 1492, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 0),
(9442, 'ITI-07879', 234, NULL, 179, 29, 1492, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-7682561</colorFondo></Grupo></Campos>', 0, 0),
(9444, 'ITI-07880', 232, NULL, 60, 29, 1492, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16741236</colorFondo></Grupo></Campos>', 0, 0),
(9446, 'ITI-07881', 144, NULL, 105, 29, 1492, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2971905</colorFondo></Grupo></Campos>', 0, 0),
(9447, 'ITI-07882', 233, NULL, 163, 29, 1492, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-13002389</colorFondo></Grupo></Campos>', 0, 0),
(9448, 'ITI-07883', 235, NULL, 52, 29, 1492, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-378818</colorFondo></Grupo></Campos>', 0, 0),
(9538, 'ITI-07884', 124, NULL, 52, 28, 1415, 7, 10, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(9539, 'ITI-07885', 124, NULL, 52, 28, 1415, 7, 10, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(9542, 'ITI-07886', 124, NULL, 52, 29, 1516, 7, 50, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(9543, 'ITI-07887', 219, NULL, 7, 29, 1484, 7, 50, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(9544, 'ITI-07888', 220, NULL, 7, 29, 1488, 7, 50, 13, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(9558, 'ITI-07889', 56, NULL, 167, 29, 1491, 7, 35, 24, 1, 1, 0, 1331, 357, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744384</colorFondo></Grupo></Campos>', 0, 1),
(9635, 'ITI-07890', 129, NULL, 118, 29, 1484, 7, 35, 13, 1, 1, 0, 1320, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16737</colorFondo></Grupo></Campos>', 0, 1),
(9651, 'ITI-07891', 237, NULL, 488, 29, 1531, 7, 35, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(9652, 'ITI-07892', 256, NULL, 488, 29, 1531, 7, 35, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(9672, 'ITI-07893', 135, NULL, 25, 29, 1517, 7, 35, 3, 1, 1, 0, 1321, 357, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760768</colorFondo></Grupo></Campos>', 0, 1),
(9681, 'ITI-07894', 51, NULL, 423, 29, 1517, 7, 30, 0, 0, 0, 0, 1324, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9685, 'ITI-07895', 55, NULL, 272, 29, 1517, 7, 30, 1, 1, 1, 0, 1325, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9690, 'ITI-07896', 54, NULL, 404, 29, 1517, 7, 30, 0, 0, 0, 0, 1326, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9695, 'ITI-07897', 49, NULL, 95, 29, 1517, 7, 30, 1, 1, 1, 0, 1327, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(9710, 'ITI-07898', 56, NULL, 161, 29, 1517, 7, 30, 4, 1, 1, 0, 1335, 357, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(9718, 'ITI-07899', 135, NULL, 167, 29, 1517, 7, 30, 3, 1, 1, 0, 1323, 317, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-12582848</colorFondo></Grupo></Campos>', 0, 1),
(9740, 'ITI-07900', 210, NULL, 472, 29, 1485, 7, 30, 1, 1, 1, 0, 1350, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777152</colorFondo></Grupo></Campos>', 0, 1),
(9746, 'ITI-07901', 239, NULL, 9, 29, 1542, 7, 5, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 1, 1),
(9755, 'ITI-07902', 237, NULL, 105, 29, 1531, 7, 5, 2, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(9758, 'ITI-07903', 56, NULL, 485, 29, 1517, 7, 30, 3, 1, 1, 0, 1337, 317, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(9767, 'ITI-07904', 80, NULL, 457, 29, 1531, 7, 30, 1, 1, 1, 0, 1363, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(9768, 'ITI-07905', 223, NULL, 420, 29, 1492, 7, 10, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(9770, 'ITI-07906', 52, NULL, 476, 29, 1517, 7, 28, 1, 1, 1, 0, 1340, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(9771, 'ITI-07907', 129, NULL, 260, 29, 1531, 7, 31, 1, 1, 1, 0, 1332, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(9974, 'ITI-07908', 50, NULL, 476, 30, 1577, 7, 35, 14, 1, 1, 0, 1364, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(9975, 'ITI-07909', 137, NULL, 432, 30, 1577, 7, 30, 11, 1, 1, 0, 1366, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(9977, 'ITI-07910', 216, NULL, 100, 30, 1577, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(9979, 'ITI-07911', 39, NULL, 432, 30, 1577, 7, 33, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(9981, 'ITI-07912', 215, NULL, 105, 30, 1577, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8388353</colorFondo></Grupo></Campos>', 0, 1),
(9982, 'ITI-07913', 214, NULL, 179, 30, 1577, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(9984, 'ITI-07914', 66, NULL, 132, 30, 1577, 7, 31, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-3414513</colorFondo></Grupo></Campos>', 0, 1),
(10033, 'ITI-07915', 51, NULL, 220, 30, 1589, 7, 30, 19, 1, 1, 0, 1419, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10034, 'ITI-07916', 121, NULL, 372, 30, 1589, 7, 30, 21, 1, 1, 0, 1408, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(10035, 'ITI-07917', 218, NULL, 432, 30, 1589, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10036, 'ITI-07918', 221, NULL, 285, 30, 1589, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4605696</colorFondo></Grupo></Campos>', 0, 1),
(10037, 'ITI-07919', 222, NULL, 56, 30, 1589, 7, 33, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(10038, 'ITI-07920', 181, NULL, 64, 30, 1589, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10039, 'ITI-07921', 9, NULL, 88, 30, 1589, 7, 30, 18, 1, 1, 0, 1401, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(10046, 'ITI-07922', 51, NULL, 220, 30, 1590, 7, 30, 12, 1, 1, 0, 1380, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10048, 'ITI-07923', 121, NULL, 372, 30, 1590, 7, 30, 26, 1, 1, 0, 1418, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(10051, 'ITI-07924', 218, NULL, 432, 30, 1590, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10052, 'ITI-07925', 221, NULL, 163, 30, 1590, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-3750400</colorFondo></Grupo></Campos>', 0, 1),
(10054, 'ITI-07926', 222, NULL, 56, 30, 1590, 7, 31, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(10055, 'ITI-07927', 181, NULL, 64, 30, 1590, 7, 30, 27, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10057, 'ITI-07928', 9, NULL, 131, 30, 1590, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(10070, 'ITI-07929', 50, NULL, 388, 30, 1594, 7, 30, 0, 0, 0, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10071, 'ITI-07930', 51, NULL, 388, 30, 1594, 7, 30, 16, 1, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10072, 'ITI-07931', 121, NULL, 374, 30, 1594, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(10073, 'ITI-07932', 218, NULL, 440, 30, 1594, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(10074, 'ITI-07933', 221, NULL, 100, 30, 1594, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4079360</colorFondo></Grupo></Campos>', 0, 1),
(10075, 'ITI-07934', 222, NULL, 242, 30, 1594, 7, 30, 17, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(10076, 'ITI-07935', 181, NULL, 394, 30, 1594, 7, 30, 22, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(10077, 'ITI-07936', 9, NULL, 179, 30, 1594, 7, 30, 28, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(10078, 'ITI-07937', 53, NULL, 167, 30, 1602, 7, 37, 10, 1, 1, 0, 1368, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10079, 'ITI-07938', 210, NULL, 374, 30, 1602, 7, 30, 9, 1, 1, 0, 1369, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(10080, 'ITI-07939', 35, NULL, 440, 30, 1602, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(10081, 'ITI-07940', 21, NULL, 439, 30, 1602, 7, 30, 24, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10082, 'ITI-07941', 106, NULL, 242, 30, 1602, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(10083, 'ITI-07942', 80, NULL, 9, 30, 1602, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10084, 'ITI-07943', 46, NULL, 394, 30, 1602, 7, 35, 34, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(10085, 'ITI-07944', 54, NULL, 365, 30, 1603, 7, 30, 24, 1, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10086, 'ITI-07945', 211, NULL, 372, 30, 1603, 7, 32, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(10087, 'ITI-07946', 226, NULL, 439, 30, 1603, 7, 31, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(10088, 'ITI-07947', 43, NULL, 60, 30, 1603, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10089, 'ITI-07948', 227, NULL, 118, 30, 1603, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-2631936</colorFondo></Grupo></Campos>', 0, 1),
(10090, 'ITI-07949', 253, NULL, 432, 30, 1603, 7, 32, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(10091, 'ITI-07950', 47, NULL, 7, 30, 1603, 7, 32, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10092, 'ITI-07951', 54, NULL, 476, 30, 1604, 7, 30, 17, 1, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10093, 'ITI-07952', 211, NULL, 118, 30, 1604, 7, 30, 12, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(10094, 'ITI-07953', 226, NULL, 398, 30, 1604, 7, 30, 14, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(10095, 'ITI-07954', 43, NULL, 60, 30, 1604, 7, 30, 16, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10096, 'ITI-07955', 227, NULL, 23, 30, 1604, 7, 30, 18, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-3750400</colorFondo></Grupo></Campos>', 0, 1),
(10097, 'ITI-07956', 253, NULL, 206, 30, 1604, 7, 30, 19, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(10098, 'ITI-07957', 47, NULL, 100, 30, 1604, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10099, 'ITI-07958', 56, NULL, 167, 30, 1605, 7, 32, 31, 1, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10100, 'ITI-07959', 144, NULL, 132, 30, 1605, 7, 33, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10101, 'ITI-07960', 88, NULL, 285, 30, 1605, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10102, 'ITI-07961', 232, NULL, 479, 30, 1605, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(10103, 'ITI-07962', 233, NULL, 138, 30, 1605, 7, 30, 26, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(10104, 'ITI-07963', 234, NULL, 383, 30, 1605, 7, 30, 25, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(10105, 'ITI-07964', 235, NULL, 52, 30, 1605, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(10106, 'ITI-07965', 135, NULL, 365, 30, 1606, 7, 30, 10, 1, 1, 0, 1389, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10107, 'ITI-07966', 236, NULL, 56, 30, 1606, 7, 31, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(10108, 'ITI-07967', 256, NULL, 105, 30, 1606, 7, 30, 6, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(10109, 'ITI-07968', 136, NULL, 373, 30, 1606, 7, 30, 21, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711872</colorFondo></Grupo></Campos>', 0, 1),
(10110, 'ITI-07969', 237, NULL, 87, 30, 1606, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10111, 'ITI-07970', 238, NULL, 118, 30, 1606, 7, 32, 32, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-3487232</colorFondo></Grupo></Campos>', 0, 1),
(10112, 'ITI-07971', 239, NULL, 420, 30, 1606, 7, 30, 9, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(10113, 'ITI-07972', 135, NULL, 25, 30, 1607, 7, 31, 30, 1, 1, 0, 1402, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10114, 'ITI-07973', 236, NULL, 242, 30, 1607, 7, 30, 23, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(10115, 'ITI-07974', 256, NULL, 206, 30, 1607, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(10116, 'ITI-07975', 136, NULL, 373, 30, 1607, 7, 30, 30, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711808</colorFondo></Grupo></Campos>', 0, 1),
(10117, 'ITI-07976', 237, NULL, 138, 30, 1607, 7, 31, 31, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(10118, 'ITI-07977', 238, NULL, 499, 30, 1607, 7, 30, 20, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-3355648</colorFondo></Grupo></Campos>', 0, 1),
(10119, 'ITI-07978', 239, NULL, 9, 30, 1607, 7, 30, 29, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10120, 'ITI-07979', 135, NULL, 365, 30, 1608, 7, 30, 5, 1, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10121, 'ITI-07980', 236, NULL, 56, 30, 1608, 7, 30, 7, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744256</colorFondo></Grupo></Campos>', 0, 1),
(10122, 'ITI-07981', 256, NULL, 285, 30, 1608, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(10123, 'ITI-07982', 136, NULL, 373, 30, 1608, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(10124, 'ITI-07983', 237, NULL, 479, 30, 1608, 7, 30, 5, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10125, 'ITI-07984', 238, NULL, 118, 30, 1608, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(10126, 'ITI-07985', 239, NULL, 52, 30, 1608, 7, 30, 4, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10127, 'ITI-07986', 47, NULL, 7, 30, 1609, 7, 30, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10128, 'ITI-07987', 35, NULL, 479, 30, 1609, 7, 3, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(10153, 'ITI-07988', 124, NULL, 52, 30, 1616, 7, 30, 15, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10154, 'ITI-07989', 219, NULL, 7, 30, 1617, 7, 30, 8, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10155, 'ITI-07990', 220, NULL, 7, 30, 1617, 7, 30, 9, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10166, 'ITI-07991', 52, NULL, 388, 30, 1621, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10172, 'ITI-07992', 55, NULL, 220, 30, 1621, 7, 30, 0, 1, 0, 0, 1371, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10177, 'ITI-07993', 56, NULL, 168, 30, 1621, 7, 30, 0, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10182, 'ITI-07994', 51, NULL, 168, 30, 1621, 7, 30, 1, 1, 1, 0, 1373, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10188, 'ITI-07995', 226, NULL, 7, 30, 1609, 7, 30, 3, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(10218, 'ITI-07996', 53, NULL, 25, 30, 1621, 7, 35, 3, 1, 1, 0, 1377, 392, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-12550016</colorFondo></Grupo></Campos>', 0, 1),
(10220, 'ITI-07997', 56, NULL, 95, 30, 1621, 7, 30, 8, 1, 1, 0, 1393, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10225, 'ITI-07998', 50, NULL, 493, 30, 1621, 7, 30, 4, 1, 1, 0, 1394, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10246, 'ITI-07999', 135, NULL, 447, 30, 1621, 7, 30, 4, 1, 1, 0, 1396, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(10255, 'ITI-07002', 144, NULL, 105, 30, 1630, 7, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 1, 1),
(10261, 'ITI-07003', 80, NULL, 213, 30, 1617, 7, 30, 6, 1, 1, 0, 1382, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10262, 'ITI-07004', 80, NULL, 213, 30, 1617, 7, 33, 0, 0, 0, 0, 1383, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10264, 'ITI-07005', 80, NULL, 213, 30, 1617, 7, 34, 1, 1, 1, 0, 1406, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10269, 'ITI-07006', 211, NULL, 472, 30, 1631, 7, 30, 1, 1, 1, 0, 1410, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-128</colorFondo></Grupo></Campos>', 0, 1),
(10271, 'ITI-07007', 214, NULL, 179, 30, 1630, 7, 1, 1, 1, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 1, 1),
(10273, 'ITI-07008', 211, NULL, 450, 30, 1604, 7, 18, 1, 1, 1, 0, 1413, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10276, 'ITI-07009', 52, NULL, 317, 30, 1621, 7, 30, 0, 0, 0, 0, 1415, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10282, 'ITI-07010', 211, NULL, 118, 30, 1631, 7, 30, 0, 1, 0, 0, 1417, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(10287, 'ITI-07011', 53, NULL, 388, 30, 1602, 7, 30, 5, 1, 1, 0, 1420, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10295, 'ITI-07012', 211, NULL, 450, 30, 1631, 7, 21, 3, 1, 1, 0, 1422, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10297, 'ITI-07013', 49, NULL, 485, 30, 1621, 7, 25, 0, 0, 0, 0, 1423, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10516, 'ITI-07014', 156, NULL, 432, 31, 1683, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(10517, 'ITI-07015', 3, NULL, 432, 31, 1683, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(10519, 'ITI-07016', 40, NULL, 432, 31, 1683, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(10521, 'ITI-07017', 59, NULL, 432, 31, 1683, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10522, 'ITI-07018', 206, NULL, 479, 31, 1683, 7, 34, 34, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(10524, 'ITI-07019', 65, NULL, 9, 31, 1683, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(10526, 'ITI-07020', 49, NULL, 168, 31, 1684, 7, 34, 31, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(10527, 'ITI-07021', 156, NULL, 374, 31, 1684, 7, 33, 32, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10528, 'ITI-07022', 3, NULL, 52, 31, 1684, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10529, 'ITI-07023', 40, NULL, 7, 31, 1684, 7, 33, 32, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(10531, 'ITI-07024', 59, NULL, 383, 31, 1684, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(10532, 'ITI-07025', 206, NULL, 163, 31, 1684, 7, 33, 32, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(10534, 'ITI-07026', 65, NULL, 285, 31, 1684, 7, 33, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(10535, 'ITI-07027', 49, NULL, 272, 31, 1685, 7, 35, 17, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10537, 'ITI-07028', 156, NULL, 118, 31, 1685, 7, 35, 28, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(10538, 'ITI-07029', 3, NULL, 64, 31, 1685, 7, 35, 31, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10539, 'ITI-07030', 40, NULL, 394, 31, 1685, 7, 35, 28, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(10541, 'ITI-07031', 59, NULL, 420, 31, 1685, 7, 35, 29, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-4144960</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(10543, 'ITI-07032', 206, NULL, 138, 31, 1685, 7, 35, 28, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(10544, 'ITI-07033', 65, NULL, 179, 31, 1685, 7, 35, 29, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10547, 'ITI-07034', 51, NULL, 388, 31, 1686, 7, 30, 15, 0, 1, 0, 1425, 357, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10550, 'ITI-07035', 121, NULL, 23, 31, 1686, 7, 30, 11, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16760704</colorFondo></Grupo></Campos>', 0, 1),
(10555, 'ITI-07036', 218, NULL, 479, 31, 1686, 7, 30, 24, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10557, 'ITI-07037', 221, NULL, 213, 31, 1686, 7, 30, 15, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(10558, 'ITI-07038', 222, NULL, 242, 31, 1686, 7, 30, 10, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10559, 'ITI-07039', 181, NULL, 64, 31, 1686, 7, 30, 17, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(10561, 'ITI-07040', 9, NULL, 138, 31, 1686, 7, 30, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(10565, 'ITI-07041', 129, NULL, 372, 31, 1687, 7, 28, 21, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1),
(10567, 'ITI-07042', 223, NULL, 398, 31, 1687, 7, 28, 18, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-16777056</colorFondo></Grupo></Campos>', 0, 1),
(10568, 'ITI-07043', 224, NULL, 60, 31, 1687, 7, 28, 21, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32768</colorFondo></Grupo></Campos>', 0, 1),
(10572, 'ITI-07044', 225, NULL, 56, 31, 1687, 7, 28, 24, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711936</colorFondo></Grupo></Campos>', 0, 1),
(10573, 'ITI-07045', 2, NULL, 131, 31, 1687, 7, 28, 21, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(10575, 'ITI-07046', 52, NULL, 220, 31, 1688, 7, 28, 16, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(10577, 'ITI-07047', 129, NULL, 372, 31, 1688, 7, 28, 23, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(10578, 'ITI-07048', 223, NULL, 383, 31, 1688, 7, 28, 16, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744193</colorFondo></Grupo></Campos>', 0, 1),
(10579, 'ITI-07049', 224, NULL, 60, 31, 1688, 7, 28, 21, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10581, 'ITI-07050', 225, NULL, 56, 31, 1688, 7, 28, 22, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323200</colorFondo></Grupo></Campos>', 0, 1),
(10582, 'ITI-07051', 2, NULL, 131, 31, 1688, 7, 28, 20, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323073</colorFondo></Grupo></Campos>', 0, 1),
(10584, 'ITI-07052', 52, NULL, 476, 31, 1689, 7, 28, 16, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(10586, 'ITI-07053', 129, NULL, 374, 31, 1689, 7, 28, 10, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32576</colorFondo></Grupo></Campos>', 0, 1),
(10587, 'ITI-07054', 223, NULL, 440, 31, 1689, 7, 28, 10, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10588, 'ITI-07055', 224, NULL, 439, 31, 1689, 7, 28, 10, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355648</colorFondo></Grupo></Campos>', 0, 1),
(10590, 'ITI-07056', 225, NULL, 100, 31, 1689, 7, 28, 11, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388480</colorFondo></Grupo></Campos>', 0, 1);
INSERT INTO `escolaresgrupo` (`idgrupo`, `clave`, `idmateria`, `idMateriaReferencia`, `idempleado`, `idcuatrimestre`, `idcarga`, `idplan_estudios`, `capacidad`, `totalAlumnos`, `calificado`, `activo`, `esOptativa`, `claveGrupoMixto`, `idProfesorAdjunto`, `Configuracion`, `Recursamiento`, `Modalidad`) VALUES
(10591, 'ITI-07057', 2, NULL, 179, 31, 1689, 7, 28, 10, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(10593, 'ITI-07058', 54, NULL, 168, 31, 1690, 7, 28, 6, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(10595, 'ITI-07059', 211, NULL, 118, 31, 1690, 7, 28, 13, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(10596, 'ITI-07060', 226, NULL, 163, 31, 1690, 7, 28, 27, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8388608</colorFondo></Grupo></Campos>', 0, 1),
(10597, 'ITI-07061', 43, NULL, 132, 31, 1690, 7, 28, 22, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-256</colorFondo></Grupo></Campos>', 0, 1),
(10599, 'ITI-07062', 227, NULL, 497, 31, 1690, 7, 28, 12, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-4144960</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(10600, 'ITI-07063', 253, NULL, 206, 31, 1690, 7, 28, 25, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10602, 'ITI-07064', 47, NULL, 383, 31, 1690, 7, 28, 24, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744320</colorFondo></Grupo></Campos>', 0, 1),
(10604, 'ITI-07065', 55, NULL, 220, 31, 1692, 7, 28, 24, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(10606, 'ITI-07066', 228, NULL, 105, 31, 1692, 7, 28, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(10608, 'ITI-07067', 87, NULL, 439, 31, 1692, 7, 28, 15, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10609, 'ITI-07068', 229, NULL, 100, 31, 1692, 7, 28, 28, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10610, 'ITI-07069', 230, NULL, 87, 31, 1692, 7, 28, 21, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10611, 'ITI-07070', 231, NULL, 213, 31, 1692, 7, 28, 27, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-4144960</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(10614, 'ITI-07071', 228, NULL, 105, 31, 1693, 7, 28, 19, 0, 0, 0, 0, 0, '<Campos><Grupo><colorLetra>-4144960</colorLetra><colorFondo>-65281</colorFondo></Grupo></Campos>', 0, 1),
(10615, 'ITI-07072', 55, NULL, 485, 31, 1693, 7, 28, 19, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355776</colorFondo></Grupo></Campos>', 0, 1),
(10617, 'ITI-07073', 228, NULL, 105, 31, 1693, 7, 28, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(10619, 'ITI-07074', 87, NULL, 440, 31, 1693, 7, 28, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(10621, 'ITI-07075', 229, NULL, 242, 31, 1693, 7, 28, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10622, 'ITI-07076', 230, NULL, 87, 31, 1693, 7, 28, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-65536</colorFondo></Grupo></Campos>', 0, 1),
(10623, 'ITI-07077', 231, NULL, 479, 31, 1693, 7, 28, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-1</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(10624, 'ITI-07078', 135, NULL, 168, 31, 1696, 7, 30, 27, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355840</colorFondo></Grupo></Campos>', 0, 1),
(10625, 'ITI-07079', 236, NULL, 242, 31, 1696, 7, 30, 23, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355585</colorFondo></Grupo></Campos>', 0, 1),
(10626, 'ITI-07080', 256, NULL, 206, 31, 1696, 7, 30, 28, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10627, 'ITI-07081', 136, NULL, 394, 31, 1696, 7, 30, 19, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10628, 'ITI-07082', 237, NULL, 138, 31, 1696, 7, 30, 28, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16744448</colorFondo></Grupo></Campos>', 0, 1),
(10629, 'ITI-07083', 238, NULL, 497, 31, 1696, 7, 30, 24, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-8355712</colorLetra><colorFondo>-65408</colorFondo></Grupo></Campos>', 0, 1),
(10630, 'ITI-07084', 239, NULL, 52, 31, 1696, 7, 30, 30, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32640</colorFondo></Grupo></Campos>', 0, 1),
(10631, 'ITI-07085', 219, NULL, 439, 31, 1697, 7, 47, 47, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-16711681</colorFondo></Grupo></Campos>', 0, 1),
(10632, 'ITI-07086', 220, NULL, 7, 31, 1697, 7, 60, 32, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(10633, 'ITI-07087', 124, NULL, 52, 31, 1697, 7, 40, 33, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32704</colorFondo></Grupo></Campos>', 0, 1),
(10663, 'ITI-07088', 135, NULL, 365, 31, 1705, 7, 0, 0, 0, 1, 0, 0, 493, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8355712</colorFondo></Grupo></Campos>', 0, 1),
(10664, 'ITI-07089', 232, NULL, 7, 31, 1705, 7, 0, 0, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8372160</colorFondo></Grupo></Campos>', 0, 1),
(10665, 'ITI-07090', 237, NULL, 105, 31, 1705, 7, 0, 0, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(10666, 'ITI-07091', 87, NULL, 60, 31, 1705, 7, 0, 0, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-8323328</colorFondo></Grupo></Campos>', 0, 1),
(10675, 'ITI-07092', 219, NULL, 7, 31, 1697, 7, 20, 1, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-32513</colorFondo></Grupo></Campos>', 0, 1),
(10677, 'ITI-07093', 51, NULL, 95, 31, 1686, 7, 30, 2, 0, 1, 0, 1426, 392, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-4144960</colorFondo></Grupo></Campos>', 0, 1),
(11683, 'ITI-07094', 55, NULL, 365, 33, 3709, 7, 10, 0, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(11684, 'ITI-07095', 228, NULL, 105, 33, 3709, 7, 10, 0, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(11685, 'ITI-07096', 87, NULL, 394, 33, 3709, 7, 12, 0, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(11686, 'ITI-07097', 231, NULL, 9, 33, 3709, 7, 15, 0, 0, 1, 0, 0, 0, '<Campos><Grupo><colorLetra>-16777216</colorLetra><colorFondo>-986896</colorFondo></Grupo></Campos>', 0, 1),
(11687, 'ITI-07098', 219, NULL, 7, 35, 3710, 7, 5, 2, 0, 1, 0, 0, 0, 'NULL', 0, 1),
(11688, 'ITI-07099', 220, NULL, 7, 35, 3710, 7, 5, 1, 0, 1, 0, 0, 0, 'NULL', 0, 1),
(11689, 'ITI-07100', 124, NULL, 7, 35, 3710, 7, 5, 1, 0, 1, 0, 0, 0, 'NULL', 0, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresgrupo_alumno`
--

CREATE TABLE `escolaresgrupo_alumno` (
  `idgrupo` int(11) NOT NULL,
  `idalumno` int(11) NOT NULL,
  `idmateria` int(11) NOT NULL,
  `baja` tinyint(4) NOT NULL,
  `corte1` tinyint(3) UNSIGNED DEFAULT NULL,
  `tipo1` tinyint(3) UNSIGNED DEFAULT NULL,
  `corte2` tinyint(3) UNSIGNED DEFAULT NULL,
  `tipo2` tinyint(3) UNSIGNED DEFAULT NULL,
  `global` tinyint(3) UNSIGNED DEFAULT NULL,
  `final` tinyint(3) UNSIGNED DEFAULT NULL,
  `tipo_final` tinyint(3) UNSIGNED DEFAULT NULL,
  `idMateriaReferencia` int(11) DEFAULT NULL,
  `asistencia` tinyint(3) UNSIGNED DEFAULT NULL,
  `fechaMovimiento` datetime DEFAULT NULL,
  `idUsuario` int(11) DEFAULT NULL,
  `PromedioClase` decimal(18,2) DEFAULT NULL,
  `codigoAsistencia` varchar(20) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresgrupo_alumno`
--

INSERT INTO `escolaresgrupo_alumno` (`idgrupo`, `idalumno`, `idmateria`, `baja`, `corte1`, `tipo1`, `corte2`, `tipo2`, `global`, `final`, `tipo_final`, `idMateriaReferencia`, `asistencia`, `fechaMovimiento`, `idUsuario`, `PromedioClase`, `codigoAsistencia`) VALUES
(10614, 69, 228, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 00:40:34', 1, NULL, NULL),
(10614, 84, 228, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 20:11:30', 1, NULL, NULL),
(10615, 69, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 00:40:34', 1, NULL, NULL),
(10615, 84, 55, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 20:11:30', 1, NULL, NULL),
(10617, 69, 228, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 00:40:34', 1, NULL, NULL),
(10617, 84, 228, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 20:11:30', 1, NULL, NULL),
(10619, 69, 87, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 00:40:34', 1, NULL, NULL),
(10619, 84, 87, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 20:11:30', 1, NULL, NULL),
(10621, 69, 229, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 00:40:35', 1, NULL, NULL),
(10621, 84, 229, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 20:11:30', 1, NULL, NULL),
(10622, 69, 230, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 00:40:35', 1, NULL, NULL),
(10622, 84, 230, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 20:11:30', 1, NULL, NULL),
(10623, 69, 231, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 00:40:35', 1, NULL, NULL),
(10623, 84, 231, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2020-04-07 20:11:30', 1, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresgrupo_alumno_calificaciones`
--

CREATE TABLE `escolaresgrupo_alumno_calificaciones` (
  `idGrupoAlumnoCalificacion` int(11) NOT NULL,
  `idGrupo` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `Unidad` tinyint(3) UNSIGNED NOT NULL,
  `Calificacion` tinyint(3) UNSIGNED NOT NULL,
  `baja` tinyint(4) NOT NULL,
  `fechaActualizacion` date NOT NULL,
  `idPlanDeEstudios` int(11) NOT NULL,
  `idMateria` int(11) NOT NULL,
  `idCuatrimestre` int(11) NOT NULL,
  `idMateriaReferencia` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresgrupo_alumno_calificaciones`
--

INSERT INTO `escolaresgrupo_alumno_calificaciones` (`idGrupoAlumnoCalificacion`, `idGrupo`, `idAlumno`, `Unidad`, `Calificacion`, `baja`, `fechaActualizacion`, `idPlanDeEstudios`, `idMateria`, `idCuatrimestre`, `idMateriaReferencia`) VALUES
(1021, 10614, 69, 1, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1022, 10614, 69, 2, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1023, 10614, 69, 3, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1024, 10614, 69, 4, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1025, 10614, 69, 5, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1026, 10615, 69, 1, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1027, 10615, 69, 2, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1028, 10615, 69, 3, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1029, 10615, 69, 4, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1030, 10617, 69, 1, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1031, 10617, 69, 2, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1032, 10617, 69, 3, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1033, 10617, 69, 4, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1034, 10617, 69, 5, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1035, 10619, 69, 1, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1036, 10619, 69, 2, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1037, 10619, 69, 3, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1038, 10619, 69, 4, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1039, 10621, 69, 1, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1040, 10621, 69, 2, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1041, 10621, 69, 3, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1042, 10621, 69, 4, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1043, 10621, 69, 5, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1044, 10622, 69, 1, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1045, 10622, 69, 2, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1046, 10622, 69, 3, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1047, 10622, 69, 4, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1048, 10622, 69, 5, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1049, 10622, 69, 6, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1050, 10623, 69, 1, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1051, 10623, 69, 2, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1052, 10623, 69, 3, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1053, 10623, 69, 4, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1054, 10623, 69, 5, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1055, 10614, 84, 1, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1056, 10614, 84, 2, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1057, 10614, 84, 3, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1058, 10614, 84, 4, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1059, 10614, 84, 5, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1060, 10615, 84, 1, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1061, 10615, 84, 2, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1062, 10615, 84, 3, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1063, 10615, 84, 4, 0, 0, '2020-04-07', 7, 55, 31, NULL),
(1064, 10617, 84, 1, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1065, 10617, 84, 2, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1066, 10617, 84, 3, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1067, 10617, 84, 4, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1068, 10617, 84, 5, 0, 0, '2020-04-07', 7, 228, 31, NULL),
(1069, 10619, 84, 1, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1070, 10619, 84, 2, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1071, 10619, 84, 3, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1072, 10619, 84, 4, 0, 0, '2020-04-07', 7, 87, 31, NULL),
(1073, 10621, 84, 1, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1074, 10621, 84, 2, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1075, 10621, 84, 3, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1076, 10621, 84, 4, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1077, 10621, 84, 5, 0, 0, '2020-04-07', 7, 229, 31, NULL),
(1078, 10622, 84, 1, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1079, 10622, 84, 2, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1080, 10622, 84, 3, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1081, 10622, 84, 4, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1082, 10622, 84, 5, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1083, 10622, 84, 6, 0, 0, '2020-04-07', 7, 230, 31, NULL),
(1084, 10623, 84, 1, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1085, 10623, 84, 2, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1086, 10623, 84, 3, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1087, 10623, 84, 4, 0, 0, '2020-04-07', 7, 231, 31, NULL),
(1088, 10623, 84, 5, 0, 0, '2020-04-07', 7, 231, 31, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolareshorario`
--

CREATE TABLE `escolareshorario` (
  `idhorario` int(11) NOT NULL,
  `dia` tinyint(3) UNSIGNED NOT NULL,
  `inicio` time NOT NULL,
  `fin` time NOT NULL,
  `idgrupo` int(11) NOT NULL,
  `idaula` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresimagen`
--

CREATE TABLE `escolaresimagen` (
  `id` int(11) NOT NULL,
  `img` longblob DEFAULT NULL,
  `idPersona` int(11) DEFAULT NULL,
  `Activa` tinyint(4) DEFAULT NULL,
  `idCuatrimestre` int(11) DEFAULT NULL,
  `idPlanDeEsctudios` int(11) DEFAULT NULL,
  `ContentType` varchar(50) DEFAULT NULL,
  `Name` varchar(50) DEFAULT NULL,
  `IdAlumno` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresimgrep`
--

CREATE TABLE `escolaresimgrep` (
  `idArchivo` int(11) NOT NULL,
  `Nombre` varchar(150) DEFAULT NULL,
  `TipoDeArchivo` varchar(250) DEFAULT NULL,
  `Dato` longblob DEFAULT NULL,
  `idPersona` int(11) DEFAULT NULL,
  `idCuatrimestre` int(11) DEFAULT NULL,
  `idPlanDeEstudios` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresinfresultadosptc`
--

CREATE TABLE `escolaresinfresultadosptc` (
  `IdProfActividades` int(11) NOT NULL,
  `Numasesorias` int(11) DEFAULT NULL,
  `NumTesinas` int(11) DEFAULT NULL,
  `NumEstancias` int(11) DEFAULT NULL,
  `NumArticulos` int(11) DEFAULT NULL,
  `NumPetentes` int(11) DEFAULT NULL,
  `NumPrototipos` int(11) DEFAULT NULL,
  `DesGestionAcademica` longtext DEFAULT NULL,
  `DesInvestigacion` longtext DEFAULT NULL,
  `DesAsesorias` longtext DEFAULT NULL,
  `DesTutorias` longtext DEFAULT NULL,
  `DesVinculacion` longtext DEFAULT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdCuatrimerstre` int(11) NOT NULL,
  `IdEmpleado` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresinscripcion`
--

CREATE TABLE `escolaresinscripcion` (
  `id` int(11) NOT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `idalumno` int(11) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `financiera` tinyint(4) NOT NULL,
  `academica` tinyint(4) NOT NULL,
  `valida` tinyint(4) NOT NULL,
  `fecha` datetime DEFAULT NULL,
  `fechaAcademica` datetime DEFAULT NULL,
  `reporteBase` tinyint(3) UNSIGNED DEFAULT NULL,
  `EquivalenteA` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresinscripcion`
--

INSERT INTO `escolaresinscripcion` (`id`, `idplan_estudios`, `idalumno`, `idcuatrimestre`, `financiera`, `academica`, `valida`, `fecha`, `fechaAcademica`, `reporteBase`, `EquivalenteA`) VALUES
(27, 30, 68, 35, 1, 1, 1, '2020-03-13 00:00:00', NULL, NULL, 0),
(28, 1, 71, 1, 1, 0, 1, '2020-03-21 00:00:00', NULL, NULL, 0),
(29, 1, 71, 2, 1, 0, 1, '2020-03-23 19:39:56', NULL, NULL, 0),
(30, 1, 71, 3, 1, 0, 1, '2020-03-23 19:46:10', NULL, NULL, 0),
(31, 2, 67, 1, 1, 0, 1, '2020-03-23 19:53:58', NULL, NULL, 0),
(32, 2, 67, 2, 1, 0, 1, '2020-03-23 19:55:46', NULL, NULL, 0),
(33, 1, 71, 4, 1, 0, 1, '2020-03-23 19:59:50', NULL, NULL, 0),
(34, 22, 68, 1, 1, 0, 1, '2020-03-23 20:11:20', NULL, NULL, 0),
(35, 22, 68, 2, 1, 0, 1, '2020-03-23 20:11:28', NULL, NULL, 0),
(40, 1, 71, 5, 1, 0, 1, '2020-03-29 02:11:40', NULL, NULL, 0),
(41, 1, 71, 6, 1, 0, 1, '2020-03-29 02:11:50', NULL, NULL, 0),
(42, 1, 71, 7, 1, 0, 1, '2020-03-29 02:11:56', NULL, NULL, 0),
(43, 1, 71, 8, 1, 0, 1, '2020-03-29 02:12:01', NULL, NULL, 0),
(44, 1, 71, 9, 1, 0, 1, '2020-03-29 02:12:06', NULL, NULL, 0),
(45, 1, 71, 10, 1, 0, 1, '2020-03-29 02:12:11', NULL, NULL, 0),
(46, 1, 71, 11, 1, 0, 1, '2020-03-29 02:12:15', NULL, NULL, 0),
(47, 1, 71, 12, 1, 0, 1, '2020-03-29 02:12:20', NULL, NULL, 0),
(48, 1, 71, 13, 1, 0, 1, '2020-03-29 02:12:25', NULL, NULL, 0),
(49, 1, 71, 15, 1, 0, 1, '2020-03-29 02:12:31', NULL, NULL, 0),
(50, 1, 71, 16, 1, 0, 1, '2020-03-29 02:12:41', NULL, NULL, 0),
(51, 1, 71, 17, 1, 0, 1, '2020-03-29 02:12:47', NULL, NULL, 0),
(52, 1, 71, 18, 1, 0, 1, '2020-03-29 02:12:52', NULL, NULL, 0),
(53, 1, 71, 20, 1, 0, 1, '2020-03-29 02:12:57', NULL, NULL, 0),
(56, 2, 67, 3, 1, 0, 1, '2020-03-29 02:13:29', NULL, NULL, 0),
(57, 2, 67, 4, 1, 0, 1, '2020-03-29 02:13:37', NULL, NULL, 0),
(58, 2, 67, 5, 1, 0, 1, '2020-03-29 02:13:42', NULL, NULL, 0),
(59, 2, 67, 8, 1, 0, 1, '2020-03-29 02:13:48', NULL, NULL, 0),
(60, 2, 67, 9, 1, 0, 1, '2020-03-29 02:14:01', NULL, NULL, 0),
(62, 2, 67, 10, 1, 0, 1, '2020-03-29 02:14:11', NULL, NULL, 0),
(63, 2, 67, 11, 1, 0, 1, '2020-03-29 02:14:16', NULL, NULL, 0),
(64, 1, 80, 1, 1, 0, 1, '2020-03-29 04:29:50', NULL, NULL, 0),
(65, 1, 80, 2, 1, 0, 1, '2020-03-29 04:29:54', NULL, NULL, 0),
(66, 1, 80, 3, 1, 0, 1, '2020-03-29 04:29:59', NULL, NULL, 0),
(67, 2, 82, 1, 1, 0, 1, '2020-03-29 04:30:14', NULL, NULL, 0),
(68, 2, 82, 2, 1, 0, 1, '2020-03-29 04:30:19', NULL, NULL, 0),
(69, 2, 82, 3, 1, 0, 1, '2020-03-29 04:30:24', NULL, NULL, 0),
(70, 2, 82, 4, 1, 0, 1, '2020-03-29 04:30:30', NULL, NULL, 0),
(71, 3, 69, 1, 1, 0, 1, '2020-03-29 05:23:02', NULL, NULL, 0),
(72, 3, 69, 2, 1, 0, 1, '2020-03-29 05:23:06', NULL, NULL, 0),
(73, 3, 69, 3, 1, 0, 1, '2020-03-29 05:23:11', NULL, NULL, 0),
(74, 2, 79, 1, 1, 0, 1, '2020-03-29 22:23:06', NULL, NULL, 0),
(75, 2, 79, 2, 1, 0, 1, '2020-03-29 22:23:11', NULL, NULL, 0),
(76, 2, 79, 3, 1, 0, 1, '2020-03-29 22:23:17', NULL, NULL, 0),
(78, 2, 82, 5, 1, 0, 1, '2020-03-29 22:23:52', NULL, NULL, 0),
(79, 2, 82, 6, 1, 0, 1, '2020-03-29 22:24:01', NULL, NULL, 0),
(80, 2, 82, 7, 1, 0, 1, '2020-03-29 22:24:07', NULL, NULL, 0),
(81, 2, 82, 8, 1, 0, 1, '2020-03-29 22:24:22', NULL, NULL, 0),
(82, 2, 82, 9, 1, 0, 1, '2020-03-29 22:24:47', NULL, NULL, 0),
(83, 2, 79, 4, 1, 0, 1, '2020-03-29 22:26:18', NULL, NULL, 0),
(84, 2, 79, 5, 1, 0, 1, '2020-03-29 22:26:26', NULL, NULL, 0),
(85, 2, 79, 6, 1, 0, 1, '2020-03-29 22:26:34', NULL, NULL, 0),
(86, 2, 79, 7, 1, 0, 1, '2020-03-29 22:26:40', NULL, NULL, 0),
(87, 2, 79, 8, 1, 0, 1, '2020-03-29 22:26:46', NULL, NULL, 0),
(88, 2, 79, 9, 1, 0, 1, '2020-03-29 22:27:00', NULL, NULL, 0),
(89, 7, 69, 10, 1, 0, 1, '2020-04-02 17:03:37', NULL, NULL, 0),
(90, 7, 69, 11, 1, 0, 1, '2020-04-02 17:03:45', NULL, NULL, 0),
(91, 7, 69, 28, 1, 0, 1, '2020-04-02 17:14:55', NULL, NULL, 0),
(92, 7, 84, 9, 1, 0, 1, '2020-04-03 22:51:42', NULL, NULL, 0),
(93, 7, 84, 10, 1, 0, 1, '2020-04-03 22:51:49', NULL, NULL, 0),
(94, 7, 84, 11, 1, 0, 1, '2020-04-03 22:51:56', NULL, NULL, 0),
(95, 7, 84, 12, 1, 0, 1, '2020-04-03 22:52:08', NULL, NULL, 0),
(96, 7, 69, 12, 1, 0, 1, '2020-04-03 22:52:36', NULL, NULL, 0),
(97, 7, 84, 13, 1, 0, 1, '2020-04-03 22:58:57', NULL, NULL, 0),
(98, 7, 69, 13, 1, 0, 1, '2020-04-03 22:59:25', NULL, NULL, 0),
(100, 7, 69, 29, 1, 0, 1, '2020-04-03 23:03:13', NULL, NULL, 0),
(101, 7, 84, 29, 1, 0, 1, '2020-04-03 23:04:20', NULL, NULL, 0),
(102, 7, 69, 31, 1, 1, 1, '2020-04-04 02:10:38', NULL, NULL, 0),
(103, 7, 84, 31, 1, 1, 1, '2020-04-04 02:11:30', NULL, NULL, 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresmateria`
--

CREATE TABLE `escolaresmateria` (
  `idmateria` int(11) NOT NULL,
  `nombre` varchar(80) CHARACTER SET utf8 NOT NULL,
  `nombre_abrv` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `idCatalogo` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresmateria`
--

INSERT INTO `escolaresmateria` (`idmateria`, `nombre`, `nombre_abrv`, `idCatalogo`) VALUES
(1, 'ADMINISTRACIÓN DE PROYECTOS DE INFORMACIÓN', '', 6),
(2, 'ÁLGEBRA LINEAL', '', 1),
(3, 'ALGORITMOS', '', 6),
(4, 'ALGORITMOS Y PROGRAMACIÓN', '', 5),
(5, 'ANÁLISIS DE CIRCUITOS ELÉCTRICOS', '', 5),
(6, 'ANÁLISIS DE MECANISMOS', '', 5),
(7, 'ARQUITECTURA DE PROCESADORES', '', 6),
(8, 'ARQUITECTURA PARA LA INTEGRACIÓN DE TECNOLOGÍA', '', 6),
(9, 'CÁLCULO DIFERENCIAL E INTEGRAL', '', 1),
(10, 'CÁLCULO VECTORIAL', '', 1),
(11, 'CIENCIA E INGENIERÍA DE LOS MATERIALES', '', 4),
(12, 'CIRCUITOS LÓGICOS', '', 6),
(13, 'COMPETITIVIDAD Y DESARROLLO DE EMPRENDEDORES', '', 2),
(14, 'COMUNICACIÓN Y RELACIONES HUMANAS', '', 2),
(15, 'CONTROL CLÁSICO', '', 5),
(16, 'CONTROL DIGITAL', '', 5),
(17, 'CONTROL SECUENCIAL', '', 5),
(18, 'DESARROLLO ORGANIZACIONAL', '', 2),
(19, 'DIBUJO PARA INGENIERÍA', '', 5),
(20, 'DINÁMICA', '', 1),
(21, 'DISEÑO DE BASES DE DATOS', '', 6),
(22, 'DISEÑO DE SISTEMAS DE INFORMACIÓN', '', 6),
(23, 'DISEÑO DE SISTEMAS OPERATIVOS', '', 6),
(24, 'DISEÑO MECÁNICO', '', 5),
(25, 'DISEÑO MECATRÓNICO I', '', 5),
(26, 'ECUACIONES DIFERENCIALES', '', 1),
(27, 'ELECTRICIDAD Y MAGNETISMO', '', 1),
(28, 'ELECTRÓNICA', '', NULL),
(29, 'ELECTRÓNICA ANALÓGICA', '', 5),
(30, 'ELECTRÓNICA DE POTENCIA', '', 5),
(31, 'ELECTRÓNICA DIGITAL', '', 5),
(32, 'ESTANCIA Y/O PROYECTO I', '', NULL),
(33, 'ESTANCIA Y/O PROYECTO II', '', NULL),
(34, 'ESTÁTICA', '', 1),
(35, 'ESTRUCTURA DE DATOS', '', 6),
(36, 'FUNDAMENTOS DE ELECTRICIDAD', '', 4),
(37, 'FUNDAMENTOS DE ELECTRÓNICA', '', 4),
(38, 'FUNDAMENTOS DE QUÍMICA', '', 1),
(39, 'HERRAMIENTAS MULTIMEDIA', '', 6),
(40, 'HERRAMIENTAS OFIMÁTICAS', '', 6),
(41, 'HERRAMIENTAS OFIMÁTICAS AVANZADAS', '', NULL),
(42, 'HERRAMIENTAS WEB', '', 6),
(43, 'IMPLEMENTACIÓN DE BASES DE DATOS', '', 6),
(44, 'INGENIERÍA ASISTIDA POR COMPUTADORA', '', 5),
(45, 'INGENIERÍA DE CONTROL', '', NULL),
(46, 'INGENIERÍA DE REQUERIMIENTOS', '', 6),
(47, 'INGENIERÍA DE SOFTWARE', '', 6),
(48, 'INGENIERÍA DE MANTENIMIENTO', '', 5),
(49, 'INGLÉS I', '', 3),
(50, 'INGLÉS II', '', 3),
(51, 'INGLÉS III', '', 3),
(52, 'INGLÉS IV', '', 3),
(53, 'INGLÉS V', '', 3),
(54, 'INGLÉS VI', '', 3),
(55, 'INGLÉS VII', '', 3),
(56, 'INGLÉS VIII', '', 3),
(57, 'INTERACCIÓN HOMBRE - MAQUINA', '', 6),
(58, 'INTERFACES', '', 6),
(59, 'INTRODUCCIÓN A LA INGENIERÍA EN TECNOLOGÍAS DE LA INFORMACIÓN', '', 6),
(60, 'INTRODUCCIÓN A LA INGENIERÍA EN MANUFACTURA', '', 4),
(61, 'INTRODUCCIÓN A LA INGENIERÍA MECATRÓNICA', '', 5),
(62, 'LIDERAZGO', '', 2),
(63, 'MANTENIMIENTO Y SEGURIDAD INDUSTRIAL', '', 5),
(64, 'MÁQUINAS ELÉCTRICAS', '', 5),
(65, 'MATEMÁTICAS BÁSICAS', '', 1),
(66, 'MATEMÁTICAS DISCRETAS', '', 1),
(67, 'MECÁNICA', '', 4),
(68, 'MECÁNICA DE FLUIDOS', '', 5),
(69, 'MEDICIONES ELÉCTRICAS Y DIMENSIONALES', '', 5),
(70, 'METODOLOGÍA DE LA INVESTIGACIÓN', '', 7),
(71, 'MÉTODOS MATEMÁTICOS', '', NULL),
(72, 'MÉTODOS NUMÉRICOS', '', 1),
(73, 'METROLOGÍA', '', 5),
(74, 'MICROCONTROLADORES', '', 5),
(75, 'MODELADO DE SISTEMAS FÍSICOS', '', NULL),
(76, 'MODELADO Y SIMULACIÓN DE SISTEMAS', '', 5),
(77, 'NORMATIVIDAD Y CALIDAD TECNOLÓGICA', '', 5),
(78, 'ORGANIZACIÓN DE COMPUTADORAS', '', 6),
(79, 'PRINCIPIOS DE RUTEO', '', 6),
(80, 'PROBABILIDAD Y ESTADÍSTICA', '', 1),
(81, 'PROBABILIDAD Y ESTADÍSTICA INFERENCIAL', '', 4),
(82, 'PROCESAMIENTO DIGITAL DE SEÑALES', '', 5),
(83, 'PROCESAMIENTO PARALELO Y DISTRIBUIDO', '', 6),
(84, 'PROCESOS INDUSTRIALES', '', 5),
(85, 'PROGRAMACIÓN AVANZADA', '', 6),
(86, 'PROGRAMACIÓN BÁSICA', '', 6),
(87, 'PROGRAMACIÓN ORIENTADA A OBJETOS', '', 6),
(88, 'PROGRAMACIÓN WEB', '', 6),
(89, 'PROGRAMACIÓN Y DISEÑO DE ALGORITMOS', '', NULL),
(90, 'RAZONAMIENTO LÓGICO', '', 6),
(91, 'REDES', '', 6),
(92, 'REDES AVANZADAS', '', 6),
(93, 'REDES INDUSTRIALES', '', 5),
(94, 'RESISTENCIA DE MATERIALES', '', 5),
(95, 'RESISTENCIA Y TECNOLOGÍA DE MATERIALES', '', 5),
(96, 'ROBÓTICA I', '', 5),
(97, 'SEGURIDAD E HIGIENE INDUSTRIAL', '', 4),
(98, 'SENSORES Y ACTUADORES', '', 5),
(99, 'SISTEMAS CAM Y CNC', '', 5),
(100, 'SISTEMAS DE INFORMACIÓN', '', 6),
(101, 'SISTEMAS EMBEBIDOS', '', 6),
(102, 'SISTEMAS HIDRÁULICOS Y NEUMÁTICOS ', '', 5),
(103, 'SISTEMAS OPERATIVOS', '', 6),
(104, 'TALLER DE LECTURA Y REDACCIÓN', '', 2),
(105, 'TECNOLOGÍA ORIENTADA A OBJETOS', '', NULL),
(106, 'TECNOLOGÍAS WAN', '', 6),
(107, 'TECNOLOGÍAS Y APLICACIONES WEB', '', 6),
(108, 'TELEMÁTICA', '', 6),
(109, 'TEORÍA DE LAS COMUNICACIONES', '', 5),
(110, 'TERMODINÁMICA Y TRANSFERENCIA DE CALOR', '', 5),
(111, 'TÓPICOS AVANZADOS DE PROGRAMACIÓN ORIENTADA A OBJETOS', '', 6),
(112, 'VALORES Y DESARROLLO SUSTENTABLE', '', 2),
(113, 'ADMINISTRACIÓN', 'NULL', 4),
(114, 'ADMINISTRACIÓN DE CENTROS DE DATOS', '', 6),
(115, 'ADMINISTRACIÓN DE PROYECTOS', '', 4),
(116, 'ADMINISTRACIÓN E INGENIERÍA DE PROYECTOS', '', 5),
(117, 'AUTOMATIZACIÓN', '', 4),
(118, 'CALIDAD', '', 4),
(119, 'CONTABILIDAD Y COSTOS DE PRODUCCIÓN', '', 4),
(120, 'CONTROL INTELIGENTE', '', 5),
(121, 'DESARROLLO INTERPERSONAL', '', 2),
(122, 'DISEÑO PARA MANUFACTURA Y ENSAMBLE', '', 4),
(123, 'DISEÑO MECATRÓNICO II', '', 5),
(124, 'ESTADÍA', 'ESTD', NULL),
(126, 'FORMULACIÓN Y EVALUACIÓN DE PROYECTOS', '', 4),
(127, 'GESTIÓN DE LA CALIDAD', '', 4),
(128, 'GESTIÓN DEL MANTENIMIENTO', '', 4),
(129, 'HABILIDADES DEL PENSAMIENTO', '', 2),
(131, 'HERRAMIENTAS DE MEJORA', '', 4),
(132, 'INGENIERÍA DE MÉTODOS', '', 4),
(133, 'INGENIERÍA DE PLANTA', '', 4),
(134, 'INGENIERÍA DE PLÁSTICOS', '', 4),
(135, 'INGLÉS IX', '', 3),
(136, 'INTELIGENCIA DE NEGOCIOS', '', 6),
(137, 'INTELIGENCIA EMOCIONAL', '', 2),
(138, 'INVESTIGACIÓN DE OPERACIONES', '', 4),
(139, 'LÓGICA DE PROGRAMACIÓN NUMÉRICA', '', 4),
(140, 'MANUFACTURA ESBELTA', '', 4),
(141, 'MECATRÓNICA', '', 4),
(142, 'METODOLOGÍAS DE DISEÑO', '', 4),
(143, 'MINERÍA DE DATOS', '', 6),
(144, 'NEGOCIOS ELECTRÓNICOS', '', 6),
(145, 'PLANEACIÓN Y CONTROL DE LA PRODUCCIÓN', '', 4),
(146, 'PROCESOS DE ENSAMBLE', '', 4),
(147, 'PROCESOS ESPECIALES DE MANUFACTURA', '', 4),
(148, 'PROCESOS PRIMARIOS DE MANUFACTURA', '', 4),
(149, 'PROCESOS SECUNDARIOS DE MANUFACTURA', '', 4),
(150, 'PRONÓSTICOS E INVENTARIOS', '', 4),
(151, 'ROBÓTICA II', '', 5),
(152, 'SEGURIDAD INFORMÁTICA Y DE REDES', '', 6),
(153, 'SIMULACIÓN DE PROCESOS DISCRETOS', '', 4),
(154, 'TECNOLOGÍAS DE SOPORTE EN DISEÑO Y MANUFACTURA', '', 4),
(155, 'TERMODINÁMICA', '', 1),
(156, 'VALORES DEL SER', '', 2),
(157, 'VIBRACIONES MECÁNICAS', '', 5),
(158, 'OPTATIVA I', 'NULL', NULL),
(159, 'OPTATIVA II', 'NULL', NULL),
(160, 'PROCESOS ESTOCÁSTICOS', 'NULL', NULL),
(161, 'OPTATIVA III', 'NULL', NULL),
(162, 'OPTATIVA IV', 'NULL', NULL),
(163, 'OPTATIVA V', 'NULL', NULL),
(164, 'OPTATIVA VI', 'NULL', NULL),
(165, 'OPTATIVA VII', 'NULL', NULL),
(166, 'OPTATIVA VIII', 'NULL', NULL),
(167, 'SEMINARIO I', 'NULL', NULL),
(168, 'SEMINARIO II', 'NULL', NULL),
(169, 'SEMINARIO III', 'NULL', NULL),
(170, 'SEMINARIO IV', 'NULL', NULL),
(171, 'PROCESADORES DIGITALES', 'NULL', NULL),
(172, 'ANÁLISIS DE SEÑALES Y SISTEMAS', '', NULL),
(173, 'ANÁLISIS MATEMÁTICO', '', NULL),
(174, 'BASE DE DATOS', '', NULL),
(175, 'CALIDAD DE LA ENERGÍA ELÉCTRICA', '', NULL),
(176, 'COMUNICACIONES ÓPTICAS', '', NULL),
(177, 'CONTROL DE SISTEMAS LÍNEALES', '', NULL),
(178, 'CONTROL DE SISTEMAS NO LÍNEALES', '', NULL),
(179, 'CONVERTIDORES CD-CA', '', NULL),
(180, 'ESTRATEGIAS DE COMPETITIVIDAD TECNOLÓGICA', '', NULL),
(181, 'FUNDAMENTOS DE SISTEMAS DE INFORMACIÓN', '', 6),
(182, 'INGENIERÍA DE PROCESOS', '', NULL),
(183, 'MECÁNICA ANALÍTICA', '', NULL),
(184, 'MECÁNICA DE MATERIALES', '', NULL),
(185, 'MODELADO, OPTIMIZACIÓN Y SIMULACIÓN DE PROCESOS', '', NULL),
(186, 'OPTIMIZACIÓN', '', NULL),
(187, 'PRINCIPIOS DE COMUNICACIÓN', '', 6),
(188, 'PROCESADORES DIGITALES Y CONTROL SECUENCIAL', '', NULL),
(189, 'PROCESAMIENTO DISTRIBUIDO', '', NULL),
(190, 'REDES DE COMPUTADORAS', '', NULL),
(191, 'ROBÓTICA', '', NULL),
(192, 'ROBÓTICA AVANZADA', '', NULL),
(193, 'SISTEMAS DINÁMICOS', '', NULL),
(194, 'TECNOLOGÍAS MIDDLEWARE', '', NULL),
(195, 'TÓPICOS SELECTOS DE COMUNICACIÓN', '', NULL),
(196, 'TÓPICOS SELECTOS DE CONTROL', '', NULL),
(197, 'TÓPICOS SELECTOS DE IMAGENOLOGÍA', '', NULL),
(198, 'TÓPICOS SELECTOS DE INGENIERÍA EN SISTEMAS', '', NULL),
(199, 'TÓPICOS SELECTOS DE INTELIGENCIA ARTIFICIAL', '', NULL),
(200, 'TÓPICOS SELECTOS DE MANUFACTURA', '', NULL),
(201, 'TÓPICOS SELECTOS DE MECÁNICA', '', NULL),
(202, 'TÓPICOS SELECTOS DE ÓPTICA', '', NULL),
(203, 'TÓPICOS SELECTOS DE SEGURIDAD', '', NULL),
(204, 'VISIÓN POR COMPUTADORA', '', NULL),
(205, 'NÚCLEO REGIONAL I', 'NULL', NULL),
(206, 'ARQUITECTURA DE COMPUTADORAS', 'NULL', 6),
(207, 'TRIGONOMETRÍA Y GEOMETRÍA ANALÍTICA', 'NULL', NULL),
(208, 'ARITMÉTICA Y ÁLGEBRA', 'NULL', NULL),
(209, 'PENSAMIENTO CRÍTICO', 'NULL', NULL),
(210, 'HABILIDADES ORGANIZACIONALES', 'NULL', 2),
(211, 'ÉTICA PROFESIONAL', 'NULL', 2),
(213, 'SISTEMAS NEUMÁTICOS E HIDRÁULICOS', 'NULL', 4),
(214, 'FUNDAMENTOS DE FÍSICA', 'NULL', 1),
(215, 'FUNDAMENTOS DE REDES', 'NULL', 6),
(216, 'LÓGICA COMPUTACIONAL', 'NULL', 6),
(217, 'NORMATIVIDAD Y SEGURIDAD INDUSTRIAL', 'NULL', 5),
(218, 'PROGRAMACIÓN ESTRUCTURADA', 'NULL', 5),
(219, 'ESTANCIA I', 'EST1', NULL),
(220, 'ESTANCIA II', 'EST2', NULL),
(221, 'ADMINISTRACIÓN DE SISTEMAS OPERATIVOS', 'NULL', 6),
(222, 'RUTEO', 'NULL', 6),
(223, 'INTRODUCCIÓN A LA PROGRAMACIÓN ORIENTADA A OBJETOS', 'NULL', 6),
(224, 'INTRODUCCIÓN A LAS BASES DE DATOS', 'NULL', 6),
(225, 'SWITCHEO Y WIRELESS', 'NULL', 6),
(226, 'ANÁLISIS Y DISEÑO ORIENTADO A OBJETOS', 'NULL', 6),
(227, 'PROCESO ADMINISTRATIVO', 'NULL', 6),
(228, 'DISEÑO DE INTERFACES', 'NULL', 6),
(229, 'SEGURIDAD INFORMÁTICA', 'NULL', 6),
(230, 'INTRODUCCIÓN A LA GRAFICACIÓN POR COMPUTADORA', 'NULL', 6),
(231, 'SEMINARIO DE INVESTIGACIÓN', 'NULL', 6),
(232, 'MINERÍA DE DATOS APLICADA', 'NULL', 6),
(233, 'GRAFICACIÓN POR COMPUTADORA AVANZADA', 'NULL', 6),
(234, 'PROYECTOS DE TECNOLOGÍAS DE LA INFORMACIÓN', 'NULL', 6),
(235, 'ADMINISTRACIÓN DE SISTEMAS INTEGRALES', 'NULL', 6),
(236, 'ADMINISTRACIÓN DE CENTROS DE CÓMPUTO', 'NULL', 6),
(237, 'CÓMPUTO EN DISPOSITIVOS MÓVILES', 'NULL', 6),
(238, 'DESARROLLO DE EMPRENDEDORES', 'NULL', 6),
(239, 'INTEGRACIÓN DE TECNOLOGÍAS DE LA INFORMACIÓN', 'NULL', 6),
(240, 'PROGRAMACIÓN DE PERIFÉRICOS', 'NULL', 5),
(241, 'SENSORES Y ACONDICIONAMIENTO DE SEÑALES', 'NULL', 5),
(242, 'AUTOMATIZACIÓN INDUSTRIAL', 'NULL', 5),
(243, 'PROCESOS DE MANUFACTURA', 'NULL', 5),
(244, 'ADQUISICIÓN Y PROCESAMIENTO DE SEÑALES', 'NULL', 5),
(245, 'INGENIERÍA ECONÓMICA', 'NULL', 5),
(246, 'TEORÍA DE CONTROL', 'NULL', 5),
(247, 'CINEMÁTICA DE ROBOTS', 'NULL', 5),
(248, 'TRANSFERENCIA DE CALOR', 'NULL', 5),
(249, 'INTEGRACIÓN DE SISTEMAS MECATRÓNICOS', 'NULL', 5),
(250, 'DINÁMICA Y CONTROL DE ROBOTS', 'NULL', 5),
(251, 'CALIDAD E INNOVACIÓN TECNOLÓGICA', 'NULL', 5),
(252, 'ANÁLISIS Y DISEÑO DE SISTEMAS DE INFORMACIÓN', 'NULL', NULL),
(253, 'ANÁLISIS Y DISEÑO DE SISTEMAS', 'NULL', 6),
(254, 'DISEÑO MECATRÓNICO', 'NULL', 5),
(255, 'INGENIERÍA DEL MANTENIMIENTO', 'NULL', 5),
(256, 'TECNOLOGÍA Y APLICACIONES WEB', 'NULL', 6),
(257, 'METODOLOGÍAS DE LA INVESTIGACIÓN', 'NULL', 4),
(258, 'INTRODUCCIÓN A LAS MATEMÁTICAS', 'NULL', 1),
(259, 'INTRODUCCIÓN A LA ADMINISTRACIÓN', 'NULL', 7),
(260, 'FUNDAMENTOS DE CONTABILIDAD', 'NULL', 7),
(261, 'HERRAMIENTAS DE OFIMÁTICA', 'NULL', 7),
(262, 'EXPRESIÓN ORAL Y ESCRITA', 'NULL', 1),
(263, 'TRABAJO DE TESIS', 'NULL', NULL),
(264, 'MATEMÁTICAS APLICADAS A LA ADMINISTRACIÓN', 'NULL', 7),
(265, 'ASPECTOS LEGALES DE LA ORGANIZACIÓN', 'NULL', 7),
(266, 'CONTABILIDAD FINANCIERA', 'NULL', 7),
(267, 'ADMINISTRACIÓN DE SISTEMAS DE INFORMACIÓN', 'NULL', 7),
(268, 'CONTABILIDAD DE COSTOS', 'NULL', 7),
(269, 'MICROECONOMÍA', 'NULL', 7),
(270, 'PLANEACIÓN ESTRATÉGICA', 'NULL', 7),
(271, 'MACROECONOMÍA', 'NULL', 7),
(272, 'ADMINISTRACIÓN DEL CAPITAL HUMANO', 'NULL', 7),
(273, 'CONTABILIDAD ADMINISTRATIVA', 'NULL', 7),
(274, 'FUNDAMENTOS DE MERCADOTECNIA', 'NULL', 7),
(275, 'MATEMÁTICAS FINANCIERAS', 'NULL', 7),
(276, 'COMPORTAMIENTO Y DESARROLLO ORGANIZACIONAL', 'NULL', 7),
(277, 'NEGOCIACIÓN EMPRESARIAL', 'NULL', 7),
(278, 'INVESTIGACIÓN DE MERCADOS', 'NULL', 7),
(279, 'DERECHO LABORAL', 'NULL', 7),
(280, 'MÉTODOS CUANTITATIVOS Y PRONÓSTICOS', 'NULL', 7),
(281, 'ADMINISTRACIÓN DE SUELDOS Y SALARIOS', 'NULL', 7),
(282, 'ANÁLISIS FINANCIERO', 'NULL', 7),
(283, 'MERCADOTECNIA ESTRATÉGICA', 'NULL', 7),
(284, 'TECNOLOGÍAS DE INFORMACIÓN APLICADA A LOS NEGOCIOS', 'NULL', 7),
(285, 'ADMINISTRACIÓN DE LA PRODUCCIÓN', 'NULL', 7),
(286, 'COMERCIO INTERNACIONAL', 'NULL', 7),
(287, 'AUDITORIA ADMINISTRATIVA', 'NULL', 7),
(288, 'ADMINISTRACIÓN FINANCIERA', 'NULL', 7),
(289, 'COMERCIO ELECTRÓNICO', 'NULL', 7),
(290, 'CONTRIBUCIONES FISCALES', 'NULL', 7),
(291, 'SEMINARIO DE HABILIDADES GERENCIALES', 'NULL', 7),
(292, 'FORMULACIÓN Y EVALUACIÓN DE PROYECTOS DE INVERSIÓN', 'NULL', 7),
(293, 'DESARROLLO EMPRENDEDOR', 'NULL', 7),
(294, 'LOGISTICA ADMINISTRATIVA', 'NULL', 7),
(295, 'CONSULTORÍA', 'NULL', 7),
(296, 'DESARROLLO SUSTENTABLE', 'NULL', 7),
(297, 'DISEÑO DE ALGORITMOS', 'NULL', NULL),
(298, 'MATEMÁTICAS', 'NULL', NULL),
(299, 'CONTABILIDAD', 'NULL', NULL),
(300, 'INGLÉS', 'NULL', NULL),
(301, 'FRANCÉS I', 'NULL', NULL),
(302, 'FRANCÉS II', 'NULL', NULL),
(303, 'ADMINISTRACIÓN DE EMPRESAS FAMILIARES', 'NULL', 7),
(304, 'COMERCIO EXTERIOR Y ADUANAS', 'NULL', 7),
(305, 'FRANQUICIAS', 'NULL', 7),
(306, 'PLANEACIÓN Y DISEÑO DE SISTEMAS Y ESTRATEGIAS DE NEGOCIOS', 'NULL', 7),
(307, 'METROLOGÍA AUTOMOTRIZ', 'NULL', NULL),
(308, 'HABILIDADES PARA APRENDER A APRENDER', 'NULL', NULL),
(309, 'DIBUJO POR COMPUTADORA', 'NULL', NULL),
(310, 'MATERIALES AUTOMOTRICES', 'NULL', NULL),
(311, 'ELECTRICIDAD AUTOMOTRIZ', 'NULL', NULL),
(312, 'AUTOTRÓNICA', 'NULL', NULL),
(313, 'ANÁLISIS ESTRUCTURAL AUTOMOTRIZ', 'NULL', NULL),
(314, 'ELECTRÓNICA AUTOMOTRIZ', 'NULL', NULL),
(315, 'MOTORES AUTOMOTRICES', 'NULL', NULL),
(316, 'MÁQUINAS ELÉCTRICAS AUTOMOTRICES', 'NULL', NULL),
(317, 'MECANISMOS AUTOMOTRICES', 'NULL', NULL),
(318, 'SISTEMAS AUTOMOTRICES', 'NULL', NULL),
(319, 'ERGONOMÍA', 'NULL', NULL),
(320, 'SISTEMAS DE CALIDAD', 'NULL', NULL),
(321, 'SISTEMAS DE PLANEACIÓN', 'NULL', NULL),
(322, 'CONTROL DE LA PRODUCCIÓN', 'NULL', NULL),
(323, 'MANUFACTURA AUTOMOTRIZ CAM Y CNC', 'NULL', NULL),
(324, 'CONTROL ESTADÍSTICO DE LA CALIDAD', 'NULL', NULL),
(325, 'MANUFACTURA AUTOMOTRIZ CAE', 'NULL', NULL),
(326, 'TECNOLOGÍA DEL PLASTICO', 'NULL', NULL),
(327, 'SISTEMAS DE IMPULSIÓN', 'NULL', NULL),
(328, 'SISTEMA DE DIRECCIÓN Y FRENOS', 'NULL', NULL),
(329, 'SISTEMA DE CÓMPUTO AUTOMOTRIZ', 'NULL', NULL),
(330, 'MOTORES AUTOMOTRICES ALTERNATIVOS', 'NULL', NULL),
(331, 'SISTEMAS INTELIGENTES DEL AUTOMÓVIL', 'NULL', NULL),
(332, 'ANÁLISIS MULTIFÍSICO', 'NULL', NULL),
(333, 'SISTEMAS DE COMERCIALIZACIÓN', 'NULL', NULL),
(334, 'DISEÑO AUTOMOTRIZ', 'NULL', NULL),
(335, 'PROYECTO DE INVESTIGACIÓN', 'NULL', NULL),
(336, 'PRINCIPIOS DE MARKETING', 'NULL', NULL),
(337, 'HERRAMIENTAS COMPUTACIONALES', 'NULL', NULL),
(338, 'PROCESAMIENTO DE POLVOS', 'NULL', NULL),
(339, 'TECNOLOGÍA DE LOS MATERIALES', 'NULL', NULL),
(340, 'TÉCNICAS DE DISEÑO APLICADO', 'NULL', NULL),
(341, 'SIMULACIÓN DE ESFUERZOS Y APLICACIÓN DE MATERIALES', 'NULL', NULL),
(342, 'DISEÑO DE PROTOCOLO DE INVESTIGACIÓN', 'NULL', NULL),
(343, 'ENERGÍAS RENOVABLES Y MEDIO AMBIENTE', 'NULL', NULL),
(344, 'FÍSICA DE SEMICONDUCTORES', 'NULL', NULL),
(345, 'AHORRO ENERGÉTICO EN SISTEMAS SUSTENTABLES', 'NULL', NULL),
(346, 'OPTATIVA GENERAL I', 'NULL', NULL),
(347, 'OPTATIVA GENERAL II', 'NULL', NULL),
(348, 'TÉCNICAS EXPERIMENTALES', 'NULL', NULL),
(349, 'DISEÑO DE EXPERIMENTOS E INSTRUMENTACIÓN', 'NULL', NULL),
(350, 'ANÁLISIS DE DATOS', 'NULL', NULL),
(351, 'OPTATIVA GENERAL III', 'NULL', NULL),
(352, 'TRABAJO EXPERIMENTAL ', 'NULL', NULL),
(353, 'REDACCIÓN DE TEXTOS CIENTÍFICOS', 'NULL', NULL),
(354, 'TRABAJO DE INVESTIGACIÓN', 'NULL', NULL),
(355, 'TÉCNICAS DE CARACTERIZACIÓN DE MATERIALES', 'NULL', NULL),
(356, 'LABORATORIO DE SIMULACIÓN', 'NULL', NULL),
(357, 'INSTRUMENTACIÓN DE SISTEMAS HÍBRIDOS', 'NULL', NULL),
(358, 'ELEMENTOS DE DISEÑO DE INSTALACIONES ELÉCTRICAS', 'NULL', NULL),
(359, 'SISTEMAS TÉRMICOS', 'NULL', NULL),
(360, 'SISTEMAS DINÁMICOS NO LINEALES', 'NULL', NULL),
(361, 'AERODINÁMICA', 'NULL', NULL),
(362, 'SISTEMAS ELECTROMECÁNICOS', 'NULL', NULL),
(363, 'PLANIFICACIÓN DE CAMPOS EÓLICOS', 'NULL', NULL),
(364, 'MECÁNICA DE MEDIOS CONTINUOS', 'NULL', NULL),
(365, 'COMPORTAMIENTO MECÁNICO DE LOS MATERIALES', 'NULL', NULL),
(366, 'TERMOQUÍMICA', 'NULL', NULL),
(367, 'QUÍMICA DE LA BIOMASA', 'NULL', NULL),
(368, 'TECNOLOGÍA DE LOS BIOCOMBUSTIBLES', 'NULL', NULL),
(369, 'CATÁLISIS HETEROGÉNEA COMPUTACIONAL', 'NULL', NULL),
(370, 'INGENIERÍA DE BIOPROCESOS', 'NULL', NULL),
(371, 'ANÁLISIS DE CICLOS DE VIDA', 'NULL', NULL),
(372, 'MICROBIOLOGÍA AVANZADA', 'NULL', NULL),
(373, 'FÍSICOQUÍMICA AVANZADA ', 'NULL', NULL),
(374, 'QUÍMICA BÁSICA', 'NULL', 1),
(375, 'FUNCIONES MATEMÁTICAS', 'NULL', 1),
(376, 'INTRODUCCIÓN A LA INGENIERÍA MECATRÓNICA Y ROBÓTICA', 'NULL', 5),
(377, 'INTELIGENCIA EMOCIONAL Y MANEJO DE CONFLICTOS', 'NULL', 2),
(378, 'CÁLCULO DIFERENCIAL', 'NULL', 1),
(379, 'FÍSICA', 'NULL', 1),
(380, 'MANTENIMIENTO DE SISTEMAS MECATRÓNICOS Y ROBÓTICOS', 'NULL', 5),
(381, 'HABILIDADES COGNITIVAS Y CREATIVIDAD', 'NULL', 2),
(382, 'CÁLCULO INTEGRAL', 'NULL', 1),
(383, 'MECÁNICA DE CUERPO RÍGIDO', 'NULL', 5),
(384, 'ADMINISTRACIÓN DE MANTENIMIENTO', 'NULL', 5),
(385, 'CIRCUITOS ELÉCTRICOS Y ELECTRÓNICOS', 'NULL', 5),
(386, 'SEGURIDAD Y MEDIO AMBIENTE', 'NULL', 5),
(387, 'ESTRUCTURA Y PROPIEDADES DE LOS MATERIALES', 'NULL', 1),
(388, 'SISTEMAS DIGITALES', 'NULL', 5),
(389, 'EXPRESIÓN ORAL Y ESCRITA I', 'NULL', 1),
(390, 'EXPRESIÓN ORAL Y ESCRITA II', 'NULL', 1),
(391, 'SISTEMAS ELECTRÓNICOS DE INTERFAZ', 'NULL', 5),
(392, 'HABILIDADES GERENCIALES', 'NULL', 2),
(393, 'MATEMÁTICAS PARA INGENIERÍA I', 'NULL', 1),
(394, 'MATEMÁTICAS PARA INGENIERÍA II', 'NULL', 1),
(395, 'FÍSICA PARA INGENIERÍA', 'NULL', 1),
(396, 'CINEMÁTICA DE MECANISMOS', 'NULL', 5),
(397, 'CONTROLADORES LÓGICOS PROGRAMABLES', 'NULL', 5),
(398, 'LIDERAZGO DE EQUIPOS DE ALTO DESEMPEÑO', 'NULL', 2),
(399, 'PROGRAMACIÓN DE ROBOTS INDUSTRIALES', 'NULL', 5),
(400, 'CONTROL DE MOTORES ELÉCTRICOS', 'NULL', 5),
(401, 'DISEÑO Y SELECCIÓN DE ELEMENTOS MECÁNICOS', 'NULL', 5),
(402, 'ADMINISTRACIÓN DE PROYECTOS DE INGENIERÍA', 'NULL', 5),
(403, 'DISEÑO DE SISTEMAS MECATRÓNICOS', 'NULL', 5),
(404, 'DINÁMICA DE ROBOTS', 'NULL', 5),
(405, 'SISTEMAS DE VISIÓN ARTIFICIAL', 'NULL', 5),
(406, 'ADQUISICIÓN Y PROCESAMIENTO DIGITAL DE SEÑALES', 'NULL', 5),
(407, 'PROGRAMACIÓN DE SISTEMAS EMBEBIDOS', 'NULL', 5),
(408, 'INTEGRACIÓN DE SISTEMAS MECATRÓNICOS Y ROBÓTICOS', 'NULL', 5),
(409, 'CONTROL AVANZADO', 'NULL', 5),
(410, 'SISTEMAS AVANZADOS DE MANUFACTURA', 'NULL', 5),
(411, 'CONTROL DE ROBOTS', 'NULL', 5),
(412, 'SISTEMAS DE PRODUCCIÓN INDUSTRIAL', 'NULL', 5),
(413, 'DESARROLLO HUMANO Y VALORES', 'NULL', 2),
(414, 'INTRODUCCIÓN A LA CONTABILIDAD', 'NULL', NULL),
(415, 'PRINCIPIOS DE ADMINISTRACIÓN', 'NULL', NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresmateriasoptativas`
--

CREATE TABLE `escolaresmateriasoptativas` (
  `idPlanEstudios` int(11) NOT NULL,
  `idMateriaOptativa` int(11) NOT NULL,
  `idMateria` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresnivelesdominioescala`
--

CREATE TABLE `escolaresnivelesdominioescala` (
  `idNivelDominioEscala` int(11) NOT NULL,
  `clave` varchar(10) CHARACTER SET utf8 NOT NULL,
  `Nivel` varchar(50) CHARACTER SET utf8 NOT NULL,
  `califMinima` decimal(18,2) NOT NULL,
  `califMaxima` decimal(18,2) NOT NULL,
  `CalifGeneral` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarespendientes`
--

CREATE TABLE `escolarespendientes` (
  `IdPendiente` int(11) NOT NULL,
  `Pendiente` varchar(250) CHARACTER SET utf8 NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresperiodoinscripciones`
--

CREATE TABLE `escolaresperiodoinscripciones` (
  `idPeriodoInscripcion` int(11) NOT NULL,
  `idCuatrimestre` int(11) NOT NULL,
  `idCatalogo` smallint(6) NOT NULL,
  `fechaInicio` date NOT NULL,
  `fechaFin` date NOT NULL,
  `Nota` varchar(200) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresperiodos`
--

CREATE TABLE `escolaresperiodos` (
  `IdPeriodo` int(11) NOT NULL,
  `IdCiclo` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresplan_estudios`
--

CREATE TABLE `escolaresplan_estudios` (
  `idplan_estudios` int(11) NOT NULL,
  `clave` varchar(50) CHARACTER SET utf8 NOT NULL,
  `version` varchar(50) CHARACTER SET utf8 NOT NULL,
  `idcarrera` int(11) NOT NULL,
  `fecha_autorizacion` date DEFAULT NULL,
  `fecha_inicio` date DEFAULT NULL,
  `fecha_fin` date DEFAULT NULL,
  `num_cuatrimestres` tinyint(3) UNSIGNED NOT NULL,
  `califMinimaAprobatoria` tinyint(3) UNSIGNED NOT NULL,
  `Tipo` tinyint(3) UNSIGNED NOT NULL,
  `creditos` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresplan_estudios`
--

INSERT INTO `escolaresplan_estudios` (`idplan_estudios`, `clave`, `version`, `idcarrera`, `fecha_autorizacion`, `fecha_inicio`, `fecha_fin`, `num_cuatrimestres`, `califMinimaAprobatoria`, `Tipo`, `creditos`) VALUES
(1, 'IM-2007', '1', 1, '0000-00-00', '2007-09-01', '2010-08-29', 10, 70, 59, 398),
(2, 'ITI-2007', '1', 2, '0000-00-00', '2007-09-01', '2010-08-29', 10, 70, 59, 398),
(3, 'ITM-2009', '1', 3, '0000-00-00', '2009-09-01', '2010-08-29', 10, 70, 59, 384),
(4, 'MIM-2009', '1', 4, '0000-00-00', '2009-09-01', '0000-00-00', 6, 70, 60, 106),
(5, 'MITI-2009', '1', 5, '0000-00-00', '2009-09-01', '0000-00-00', 6, 70, 60, 106),
(6, 'IM-2010', '1', 1, '0000-00-00', '2010-08-30', '0000-00-00', 10, 70, 59, 375),
(7, 'ITI-2010', '1', 2, '0000-00-00', '2010-08-30', '0000-00-00', 10, 70, 59, 376),
(8, 'ITM-2010', '1', 3, '0000-00-00', '2010-08-30', '0000-00-00', 10, 70, 59, 375),
(9, 'C-2010', '1', 6, '0000-00-00', '2010-08-30', '0000-00-00', 1, 70, 61, 4),
(10, 'PYMES-2011', '2011', 7, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 112, 390),
(14, 'ITI-ED-2011', '1.0', 2, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 59, NULL),
(16, 'I-EXTERNOS', '2013', 9, '0000-00-00', '0000-00-00', '0000-00-00', 9, 70, 61, NULL),
(17, 'PROP-MI2013', '1', 10, '0000-00-00', '0000-00-00', '0000-00-00', 1, 70, 60, NULL),
(18, 'F-EXTERNOS', '1', 9, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 61, NULL),
(19, 'ISA-2014', '2014', 11, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 59, 375),
(20, 'MI-2015', '1', 12, '0000-00-00', '0000-00-00', '0000-00-00', 6, 80, 60, 106),
(22, 'MER-2016', '2016', 13, '0000-00-00', '0000-00-00', '0000-00-00', 6, 80, 60, 110),
(23, 'IM-2017', '2017', 1, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 59, 359),
(27, 'PA ING IND', '2010', 14, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 59, 224),
(28, 'ITM-2018', '1', 3, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 59, 397),
(29, 'ITI-2018', '1', 2, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 59, 398),
(30, 'LAyGE-2018', '1', 15, '0000-00-00', '0000-00-00', '0000-00-00', 10, 70, 112, 110);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresplan_estudios_materia`
--

CREATE TABLE `escolaresplan_estudios_materia` (
  `idplan_estudios` int(11) NOT NULL,
  `idmateria` int(11) NOT NULL,
  `cuatrimestre` tinyint(3) UNSIGNED NOT NULL,
  `clave` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `ciclo` tinyint(3) UNSIGNED NOT NULL,
  `hrs_semana` tinyint(3) UNSIGNED DEFAULT NULL,
  `hrs_teorica_pres` tinyint(3) UNSIGNED DEFAULT NULL,
  `hrs_teorica_nopres` tinyint(3) UNSIGNED DEFAULT NULL,
  `hrs_prac_pres` tinyint(3) UNSIGNED DEFAULT NULL,
  `hrs_prac_nopres` int(11) DEFAULT NULL,
  `total_hrs` int(11) DEFAULT NULL,
  `creditos` tinyint(3) UNSIGNED DEFAULT NULL,
  `tipo` tinyint(3) UNSIGNED DEFAULT NULL,
  `orden` tinyint(3) UNSIGNED NOT NULL,
  `unidades` tinyint(3) UNSIGNED NOT NULL,
  `idCatalogo` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolaresplan_estudios_materia`
--

INSERT INTO `escolaresplan_estudios_materia` (`idplan_estudios`, `idmateria`, `cuatrimestre`, `clave`, `ciclo`, `hrs_semana`, `hrs_teorica_pres`, `hrs_teorica_nopres`, `hrs_prac_pres`, `hrs_prac_nopres`, `total_hrs`, `creditos`, `tipo`, `orden`, `unidades`, `idCatalogo`) VALUES
(1, 2, 1, 'ALL23-02 CV', 1, 8, 5, 1, 1, 1, 120, 8, 55, 2, 6, 0),
(1, 4, 1, 'ALG23-04  CV', 1, 6, 1, 0, 4, 1, 90, 6, 56, 4, 4, 0),
(1, 5, 3, 'ACE23-17 ES', 1, 7, 4, 1, 1, 1, 105, 7, 56, 2, 4, 0),
(1, 6, 4, 'ANM23-27  ES', 2, 6, 35, 7, 30, 3, 90, 6, 56, 5, 5, 0),
(1, 9, 1, 'CDI23-06 CV', 1, 8, 6, 1, 1, 0, 120, 8, 55, 6, 4, 0),
(1, 10, 2, 'CVC23-14 CV', 1, 7, 3, 0, 3, 1, 105, 7, 55, 6, 6, 0),
(1, 13, 8, 'CDE23-57  TR', 3, 3, 3, 0, 0, 0, 45, 3, 54, 7, 3, 0),
(1, 14, 1, 'CRH123-08 TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 8, 3, 0),
(1, 15, 7, 'COC23-45  ES', 3, 6, 4, 1, 1, 0, 90, 6, 56, 2, 5, 0),
(1, 16, 8, 'COD23-52  ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 2, 5, 0),
(1, 17, 6, 'COS23-40  ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 4, 5, 0),
(1, 18, 7, 'DSO23-49  TR', 3, 3, 3, 0, 0, 0, 45, 3, 54, 6, 3, 0),
(1, 19, 2, 'DPI23-11 ES', 1, 6, 0, 0, 5, 1, 90, 6, 56, 3, 5, 0),
(1, 20, 3, 'DIN23-20 ES', 1, 6, 4, 1, 0, 0, 90, 6, 56, 5, 6, 0),
(1, 24, 6, 'DIM23-39  ES', 2, 7, 5, 0, 1, 1, 105, 7, 56, 3, 5, 0),
(1, 25, 8, 'DIM23-55  ES', 3, 8, 2, 0, 6, 0, 120, 8, 56, 5, 5, 0),
(1, 26, 3, 'ECD23-21 CV', 1, 6, 4, 1, 1, 0, 90, 6, 55, 6, 6, 0),
(1, 27, 2, 'ELM23-10  ES', 1, 5, 3, 0, 1, 1, 75, 5, 56, 2, 4, 0),
(1, 29, 4, 'ELA23-24 ES', 2, 8, 63, 14, 30, 13, 120, 8, 56, 2, 4, 0),
(1, 30, 5, 'ELP23-31 ES', 2, 7, 4, 0, 2, 1, 105, 7, 56, 2, 4, 0),
(1, 31, 2, 'ELD23-12 ES', 1, 7, 4, 0, 2, 1, 105, 7, 56, 4, 4, 0),
(1, 32, 4, 'ESP23-29  ES', 2, 8, 0, 0, 0, 120, 120, 8, 56, 7, 1, 0),
(1, 33, 7, 'ESP23-50  ES', 3, 8, 0, 0, 0, 120, 120, 8, 56, 7, 1, 0),
(1, 34, 2, 'EST23-13 CV', 1, 7, 4, 1, 1, 1, 105, 7, 56, 5, 7, 0),
(1, 40, 1, 'HEO23-03 TR', 1, 3, 1, 0, 1, 1, 45, 3, 54, 3, 4, 0),
(1, 44, 7, 'IAC23-46  ES', 3, 6, 3, 0, 3, 0, 90, 6, 56, 3, 4, 0),
(1, 48, 7, 'INM23-47 ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 4, 5, 0),
(1, 49, 1, 'ING23-01-TR', 1, 5, 3, 0, 2, 0, 75, 5, 54, 1, 4, 0),
(1, 50, 2, 'ING23-09-TR', 1, 5, 3, 0, 2, 0, 75, 5, 54, 1, 3, 0),
(1, 51, 3, 'ING23-16-TR', 1, 5, 3, 0, 2, 0, 75, 5, 54, 1, 4, 0),
(1, 52, 4, 'ING-23-23-TR', 2, 5, 45, 0, 30, 0, 75, 5, 54, 1, 3, 0),
(1, 53, 5, 'ING23-30-TR', 2, 5, 3, 0, 2, 0, 75, 5, 54, 1, 4, 0),
(1, 54, 6, 'ING-23-37 TR', 2, 5, 3, 0, 2, 0, 75, 5, 54, 1, 4, 0),
(1, 55, 7, 'ING23-44TR', 3, 5, 3, 0, 2, 0, 75, 5, 54, 1, 3, 0),
(1, 56, 8, 'ING23-51-TR', 3, 5, 3, 0, 2, 0, 75, 5, 54, 1, 4, 0),
(1, 61, 1, 'IIM-23-05 ES', 1, 3, 2, 0, 1, 0, 45, 3, 56, 5, 3, 0),
(1, 62, 6, 'LID23-43  TR', 2, 3, 3, 0, 0, 0, 45, 3, 54, 7, 3, 0),
(1, 63, 3, 'MSI23-19 ES', 1, 5, 3, 0, 2, 1, 75, 5, 56, 4, 5, 0),
(1, 64, 5, 'MAE23-36 ES', 2, 5, 3, 0, 5, 1, 75, 5, 56, 7, 4, 0),
(1, 68, 5, 'MEF23-34 ES', 2, 5, 4, 0, 1, 0, 75, 5, 56, 5, 5, 0),
(1, 69, 1, 'MED23-07 ES', 1, 4, 1, 0, 2, 1, 60, 4, 56, 7, 5, 0),
(1, 72, 4, 'MEN23-28  ES', 2, 4, 30, 0, 15, 15, 60, 4, 55, 6, 5, 0),
(1, 74, 5, 'MIC23-33  ES', 2, 6, 3, 0, 2, 1, 90, 6, 56, 4, 4, 0),
(1, 76, 5, 'MSS23-35  ES', 2, 7, 4, 0, 2, 1, 105, 7, 56, 6, 4, 0),
(1, 77, 9, 'NCT23-63  ES', 3, 5, 3, 1, 0, 1, 75, 5, 56, 6, 4, 0),
(1, 80, 4, 'PRE23-26 CV', 2, 4, 60, 0, 0, 0, 60, 4, 55, 4, 5, 0),
(1, 82, 7, 'PDS23-48  ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 5, 4, 0),
(1, 84, 6, 'PRI23-38  ES', 2, 6, 3, 0, 3, 0, 90, 6, 56, 2, 4, 0),
(1, 93, 8, 'RDI23-56  ES', 3, 6, 1, 0, 2, 1, 90, 6, 56, 6, 5, 0),
(1, 95, 3, 'RTM23-18 ES', 1, 8, 6, 0, 1, 1, 120, 8, 56, 3, 4, 0),
(1, 96, 8, 'ROB23-54  ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 4, 5, 0),
(1, 98, 4, 'SEA23-25  ES', 2, 5, 30, 5, 30, 10, 75, 5, 56, 3, 5, 0),
(1, 99, 8, 'SCC23-53  ES', 3, 6, 2, 0, 4, 0, 90, 6, 56, 3, 4, 0),
(1, 102, 6, 'SHN23-42  ES', 2, 7, 4, 0, 2, 1, 105, 7, 56, 6, 4, 0),
(1, 104, 2, 'TLR23-15 TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 7, 3, 0),
(1, 109, 5, 'TEC23-32  ES', 2, 5, 3, 0, 1, 1, 75, 5, 56, 3, 4, 0),
(1, 110, 6, 'TIC23-41  ES', 2, 6, 4, 1, 1, 0, 90, 6, 56, 5, 5, 0),
(1, 112, 3, 'VDS23-22 TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 7, 3, 0),
(1, 116, 9, 'AIP23-54  ES', 3, 4, 3, 0, 1, 0, 60, 4, 56, 7, 4, 0),
(1, 120, 9, 'COI23-59  ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 2, 4, 0),
(1, 123, 9, 'DIM23-60  ES', 3, 8, 0, 0, 30, 90, 120, 8, 56, 3, 5, 0),
(1, 124, 10, 'EST23-65 ES', 4, 40, 0, 0, 30, 570, 600, 38, 56, 1, 1, 0),
(1, 135, 9, 'ING23-51 TR', 3, 5, 3, 0, 2, 0, 75, 5, 54, 1, 4, 0),
(1, 151, 9, 'ROB23-61  ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 4, 4, 0),
(1, 157, 9, 'VIM23-62  ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 5, 5, 0),
(2, 1, 8, 'API16-54 ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 5, 4, 0),
(2, 2, 5, 'ALL16-33 CV', 2, 8, 4, 0, 2, 2, 120, 8, 55, 5, 5, 0),
(2, 3, 1, 'ALG16-02 ES', 1, 8, 2, 0, 3, 3, 120, 8, 56, 2, 4, 0),
(2, 7, 8, 'ADP16-51 ES', 3, 5, 2, 0, 3, 0, 75, 5, 56, 2, 6, 0),
(2, 8, 8, 'AIT16-53 ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 4, 4, 0),
(2, 9, 6, 'CDI16-39 CV', 2, 8, 4, 0, 2, 2, 120, 8, 55, 4, 4, 0),
(2, 12, 2, 'CIL16-08 ES', 1, 6, 3, 0, 2, 1, 90, 6, 56, 1, 4, 0),
(2, 13, 6, 'CDE16-41 TR', 2, 3, 3, 0, 0, 0, 45, 3, 54, 6, 4, 0),
(2, 14, 1, 'CRH16-06 TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 6, 4, 0),
(2, 18, 5, 'DEO16-34 TR', 2, 3, 3, 0, 0, 0, 45, 3, 54, 6, 3, 0),
(2, 21, 5, 'DBD16-31 ES', 2, 5, 2, 0, 3, 0, 75, 5, 56, 3, 4, 0),
(2, 22, 5, 'DSI16-32 ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 4, 4, 0),
(2, 23, 7, 'DSO16-39 ES', 3, 5, 2, 0, 3, 0, 75, 5, 56, 5, 6, 0),
(2, 32, 4, 'EYP16-26 ES', 2, 8, 0, 0, 0, 8, 120, 8, 56, 5, 1, 0),
(2, 33, 7, 'EYP16-48 ES', 3, 8, 0, 0, 0, 8, 120, 8, 56, 6, 1, 0),
(2, 35, 4, 'EDD16-24 ES', 2, 6, 2, 0, 4, 0, 90, 6, 56, 3, 4, 0),
(2, 39, 3, 'HEM16-17 ES', 1, 6, 0, 0, 4, 2, 90, 6, 56, 3, 2, 0),
(2, 40, 1, 'HEO16-03 ES', 1, 6, 0, 0, 4, 2, 90, 6, 54, 3, 4, 0),
(2, 42, 2, 'HWB16-10 ES', 1, 5, 0, 0, 4, 1, 75, 5, 56, 3, 4, 0),
(2, 43, 6, 'IBD16-40 ES', 2, 5, 3, 0, 2, 0, 75, 5, 56, 5, 3, 0),
(2, 46, 6, 'IDR16-38 ES', 2, 5, 3, 0, 2, 0, 75, 5, 56, 3, 4, 0),
(2, 47, 5, 'ING16-29 ES', 2, 6, 3, 0, 2, 1, 90, 6, 56, 1, 4, 0),
(2, 49, 1, 'ING16-07 TR', 1, 5, 3, 0, 2, 0, 75, 5, 54, 7, 4, 0),
(2, 50, 2, 'ING16-14 TR', 1, 5, 3, 0, 2, 0, 75, 5, 54, 7, 4, 0),
(2, 51, 3, 'ING16-21 TR', 1, 5, 3, 0, 2, 0, 75, 5, 54, 7, 4, 0),
(2, 52, 4, 'ING16-28 TR', 2, 5, 3, 0, 2, 0, 75, 5, 54, 7, 3, 0),
(2, 53, 5, 'ING16-35 TR', 2, 5, 3, 0, 2, 0, 75, 5, 54, 7, 4, 0),
(2, 54, 6, 'ING16-42 TR', 2, 5, 3, 0, 2, 0, 75, 5, 54, 7, 4, 0),
(2, 55, 7, 'ING16-49 TR', 3, 5, 3, 0, 2, 0, 75, 5, 54, 7, 3, 0),
(2, 56, 8, 'ING16-56 TR', 3, 5, 3, 0, 2, 0, 75, 5, 56, 7, 4, 0),
(2, 57, 8, 'IHM16-55 ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 6, 4, 0),
(2, 58, 7, 'INT16-44 ES', 3, 5, 3, 0, 2, 0, 75, 5, 56, 2, 4, 0),
(2, 59, 1, 'ITI16-O5 ES', 1, 5, 5, 0, 0, 0, 75, 5, 56, 5, 4, 0),
(2, 62, 4, 'LID16-27 TR', 2, 3, 3, 0, 0, 0, 45, 3, 54, 6, 3, 0),
(2, 65, 1, 'MAB16-04 CV', 1, 7, 1, 0, 4, 2, 105, 7, 55, 4, 4, 0),
(2, 66, 2, 'MAD16-12 CV', 1, 7, 2, 0, 3, 2, 105, 7, 55, 5, 4, 0),
(2, 72, 9, 'MTN16-61 CV', 3, 7, 2, 0, 3, 2, 105, 7, 55, 5, 5, 0),
(2, 78, 3, 'ODC16-18 ES', 1, 6, 2, 0, 3, 1, 90, 6, 56, 4, 4, 0),
(2, 79, 4, 'PRR16-22 ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 1, 4, 0),
(2, 80, 7, 'POE16-46 CV', 3, 7, 3, 0, 2, 2, 105, 7, 55, 4, 5, 0),
(2, 83, 8, 'PPD16-50 ES', 3, 7, 2, 0, 3, 2, 105, 7, 56, 1, 2, 0),
(2, 85, 3, 'PRA16-16 ES', 1, 8, 2, 0, 4, 2, 120, 8, 56, 2, 5, 0),
(2, 86, 2, 'PRB16-09 ES', 1, 7, 1, 0, 4, 2, 105, 7, 56, 2, 4, 0),
(2, 87, 4, 'POO16-23 ES', 2, 7, 2, 0, 3, 2, 105, 7, 56, 2, 3, 0),
(2, 88, 6, 'PWE16-37 ES', 2, 8, 2, 0, 4, 2, 120, 8, 56, 2, 5, 0),
(2, 90, 2, 'RAL16-11 ES', 1, 7, 2, 0, 3, 2, 105, 7, 56, 4, 5, 0),
(2, 91, 3, 'RED16-15 ES', 1, 6, 2, 0, 3, 1, 90, 6, 56, 1, 5, 0),
(2, 92, 6, 'RDA16-36 ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 1, 5, 0),
(2, 100, 4, 'SII16-25 ES', 2, 5, 3, 0, 1, 1, 75, 5, 56, 4, 4, 0),
(2, 101, 9, 'SIE16-58 ES', 3, 7, 2, 0, 3, 2, 105, 7, 56, 2, 6, 0),
(2, 103, 3, 'SOP16-19 ES', 1, 6, 2, 0, 3, 1, 90, 6, 56, 5, 4, 0),
(2, 104, 2, 'TLR16-13 TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 6, 4, 0),
(2, 106, 7, 'TEW16-43 ES', 3, 5, 2, 0, 3, 0, 75, 5, 56, 1, 5, 0),
(2, 107, 7, 'TWE16-45 ES', 3, 5, 2, 0, 3, 0, 75, 5, 56, 3, 4, 0),
(2, 108, 1, 'TEL16-01 ES', 1, 6, 2, 0, 3, 1, 90, 6, 56, 1, 4, 0),
(2, 111, 5, 'TAP16-30 ES', 2, 7, 2, 0, 3, 2, 105, 7, 56, 2, 3, 0),
(2, 112, 3, 'VDS16-20 TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 6, 3, 0),
(2, 114, 9, 'ACD16-60 ES', 3, 5, 2, 0, 3, 0, 75, 5, 56, 4, 4, 0),
(2, 124, 10, 'EYP16-64 ES', 4, 40, 0, 0, 0, 40, 600, 38, 56, 1, 1, 0),
(2, 135, 9, 'ING16-63 TR', 3, 5, 3, 0, 2, 0, 75, 5, 54, 7, 4, 0),
(2, 136, 9, 'IDN16-59 ES', 3, 5, 2, 0, 3, 0, 75, 5, 56, 3, 4, 0),
(2, 143, 9, 'MDD16-62 ES', 3, 5, 2, 0, 3, 0, 75, 5, 56, 6, 4, 0),
(2, 144, 8, 'NGE16-52 ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 3, 3, 0),
(2, 152, 9, 'SEG16-57 ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 1, 6, 0),
(3, 2, 1, 'ALL-CV', 1, 6, 3, 0, 2, 0, 90, 6, 55, 3, 4, 0),
(3, 9, 1, 'CDI-CV', 1, 8, 2, 0, 4, 0, 120, 8, 55, 4, 4, 0),
(3, 10, 2, 'CAV-CV', 1, 6, 3, 0, 2, 0, 90, 6, 55, 4, 4, 0),
(3, 11, 3, 'CIM-CV', 1, 7, 4, 1, 2, 1, 105, 7, 55, 3, 4, 0),
(3, 13, 6, 'CDE-TR', 2, 3, 2, 0, 1, 0, 45, 3, 54, 1, 4, 0),
(3, 14, 1, 'CRH-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 4, 0),
(3, 19, 2, 'DII-CV', 1, 6, 2, 0, 3, 0, 90, 5, 55, 5, 4, 0),
(3, 26, 3, 'ECD-CV', 1, 8, 3, 0, 3, 0, 120, 7, 55, 5, 4, 0),
(3, 32, 4, 'ES1-ES', 2, 4, 0, 0, 0, 0, 60, 4, 56, 1, 4, 0),
(3, 33, 7, 'ES2-ES', 3, 5, 0, 0, 0, 0, 75, 5, 54, 1, 4, 0),
(3, 36, 5, 'FUE-CV', 2, 6, 3, 1, 2, 1, 90, 5, 55, 1, 4, 0),
(3, 37, 6, 'FEL-CV', 2, 6, 3, 0, 2, 0, 90, 6, 55, 1, 4, 0),
(3, 38, 2, 'FUQ-CV', 1, 6, 3, 1, 2, 1, 90, 6, 55, 3, 4, 0),
(3, 40, 1, 'HEO-TR', 1, 6, 0, 0, 4, 0, 90, 5, 54, 7, 4, 0),
(3, 49, 1, 'INGI-TR', 1, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 50, 2, 'INGII-TR', 1, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 51, 3, 'INGIII-TR', 1, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 52, 4, 'INGIV-TR', 2, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 53, 5, 'INGV-TR', 2, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 54, 6, 'INGVI-TR', 2, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 55, 7, 'INGVII-TR', 3, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 56, 8, 'INGVIII-TR', 3, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 60, 1, 'IIM-ES', 1, 5, 2, 1, 2, 1, 75, 5, 56, 5, 4, 0),
(3, 62, 4, 'LID-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 1, 4, 0),
(3, 67, 4, 'MEC-ES', 2, 7, 3, 0, 3, 0, 105, 7, 56, 1, 4, 0),
(3, 68, 5, 'MEF-ES', 2, 6, 2, 1, 2, 1, 90, 5, 56, 1, 5, 0),
(3, 70, 7, 'MEI-CV', 3, 5, 3, 0, 1, 0, 75, 5, 55, 1, 4, 0),
(3, 73, 2, 'MET-CV', 1, 6, 2, 1, 2, 1, 90, 5, 55, 7, 4, 0),
(3, 81, 2, 'PEI-CV', 1, 7, 4, 0, 2, 0, 105, 7, 55, 6, 4, 0),
(3, 84, 5, 'PPM-ES', 2, 7, 3, 2, 2, 2, 105, 7, 56, 1, 4, 0),
(3, 94, 7, 'REM-CV', 3, 6, 3, 0, 2, 0, 90, 5, 54, 1, 4, 0),
(3, 97, 1, 'SHI-CV', 1, 6, 2, 2, 2, 2, 90, 5, 55, 6, 4, 0),
(3, 102, 7, 'SNH-ES', 3, 7, 3, 0, 3, 0, 105, 7, 56, 1, 4, 0),
(3, 104, 2, 'TLR-TR', 1, 3, 2, 0, 1, 0, 45, 3, 54, 2, 4, 0),
(3, 112, 3, 'VDS-TR', 1, 3, 2, 0, 1, 0, 45, 3, 54, 2, 4, 0),
(3, 113, 6, 'ADM-ES', 2, 6, 4, 2, 0, 2, 90, 6, 56, 1, 4, 0),
(3, 115, 9, 'ADP-ES', 3, 5, 2, 0, 2, 0, 75, 5, 56, 1, 4, 0),
(3, 117, 8, 'AUT-ES', 3, 5, 2, 0, 2, 0, 75, 5, 56, 1, 4, 0),
(3, 118, 3, 'CAL-CV', 1, 6, 3, 1, 2, 1, 90, 5, 55, 6, 4, 0),
(3, 119, 8, 'CCP-ES', 3, 5, 2, 0, 2, 0, 75, 5, 56, 1, 4, 0),
(3, 122, 9, 'DME-ES', 3, 5, 2, 0, 2, 0, 75, 5, 56, 1, 4, 0),
(3, 124, 10, 'ESD-ES', 3, 38, 0, 0, 0, 0, 600, 38, 56, 1, 4, 0),
(3, 126, 8, 'FEP-ES', 3, 6, 3, 0, 2, 0, 90, 6, 56, 1, 4, 0),
(3, 127, 5, 'GEC-ES', 2, 7, 4, 0, 2, 0, 105, 7, 56, 1, 4, 0),
(3, 128, 6, 'GEM-ES', 2, 6, 3, 1, 1, 1, 90, 6, 56, 1, 4, 0),
(3, 129, 4, 'SD', 2, NULL, NULL, NULL, NULL, NULL, 45, 3, 54, 1, 4, 0),
(3, 131, 4, 'HEM-ES', 2, 8, 4, 0, 3, 0, 120, 8, 56, 1, 4, 0),
(3, 132, 4, 'INM-ES', 2, 6, 2, 1, 2, 1, 90, 5, 56, 1, 4, 0),
(3, 133, 6, 'INP-ES', 2, 6, 3, 0, 1, 0, 90, 6, 56, 1, 4, 0),
(3, 134, 7, 'INP-ES', 3, 6, 2, 1, 3, 1, 90, 5, 56, 1, 4, 0),
(3, 135, 9, 'INGIX-TR', 3, 6, 3, 1, 2, 1, 90, 5, 54, 1, 4, 0),
(3, 138, 9, 'INO-ES', 3, 5, 2, 0, 2, 0, 75, 5, 56, 1, 4, 0),
(3, 139, 3, 'LPN-CV', 1, 5, 2, 0, 2, 0, 75, 5, 55, 7, 4, 0),
(3, 140, 7, 'MAE-ES', 3, 5, 2, 0, 2, 0, 75, 5, 56, 1, 4, 0),
(3, 141, 9, 'MEC-ES', 3, 7, 3, 0, 2, 0, 105, 6, 56, 1, 4, 0),
(3, 142, 8, 'MED-ES', 3, 5, 3, 0, 1, 0, 75, 5, 56, 1, 4, 0),
(3, 145, 5, 'PCP-ES', 2, 5, 3, 0, 1, 0, 75, 5, 56, 1, 4, 0),
(3, 146, 8, 'PRE-ES', 3, 6, 2, 1, 3, 1, 90, 6, 56, 1, 4, 0),
(3, 147, 9, 'PEM-ES', 3, 6, 2, 1, 3, 1, 90, 6, 56, 1, 4, 0),
(3, 148, 5, 'PPM-ES', 2, 5, NULL, NULL, NULL, NULL, 105, 7, 56, 5, 4, 0),
(3, 149, 6, 'PSM-ES', 2, 7, 4, 1, 2, 1, 105, 6, 56, 1, 4, 0),
(3, 150, 4, 'PRI-ES', 2, 6, 2, 1, 2, 1, 90, 5, 56, 1, 4, 0),
(3, 153, 9, 'SPD-ES', 3, 6, 2, 0, 3, 0, 90, 6, 56, 1, 4, 0),
(3, 154, 8, 'TSD-ES', 3, 7, 3, 0, 2, 0, 105, 6, 56, 1, 4, 0),
(3, 155, 3, 'TER-CV', 1, 5, 3, 0, 1, 0, 75, 5, 56, 4, 4, 0),
(3, 210, 5, 'HAO-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 1, 4, 0),
(4, 70, 3, 'MEI09-09', 1, 6, 4, 2, 0, 0, 90, 6, 54, 1, 4, 0),
(4, 71, 1, 'MEM09-02', 1, 8, 4, 2, 0, 2, 120, 8, 54, 2, 4, 0),
(4, 89, 1, 'PDA09-01', 1, 8, 3, 1, 2, 2, 120, 8, 54, 1, 4, 0),
(4, 158, 1, 'OP109-03', 1, 8, 4, 2, 0, 2, 120, 8, 57, 3, 3, 0),
(4, 159, 1, 'OP209-04', 1, 8, 4, 2, 0, 2, 120, 8, 57, 4, 3, 0),
(4, 160, 2, 'PRE09-05', 1, 8, 4, 2, 0, 2, 120, 8, 54, 1, 4, 0),
(4, 161, 2, 'OP309-06', 1, 8, 4, 2, 0, 2, 120, 8, 57, 2, 3, 0),
(4, 162, 2, 'OP409-07', 1, 8, 4, 2, 0, 2, 120, 8, 57, 3, 3, 0),
(4, 163, 2, 'OP509-08', 1, 8, 4, 2, 0, 2, 120, 8, 57, 4, 3, 0),
(4, 164, 3, 'OP609-10', 1, 8, 4, 2, 0, 2, 120, 8, 57, 2, 3, 0),
(4, 165, 3, 'OP709-11', 1, 8, 4, 2, 0, 2, 120, 8, 57, 3, 3, 0),
(4, 166, 4, 'OP809-13', 1, 8, 4, 2, 0, 2, 120, 8, 57, 1, 3, 0),
(4, 167, 3, 'SEM09-12', 1, 3, 2, 1, 0, 0, 45, 3, 58, 4, 4, 0),
(4, 168, 4, 'SEM09-14', 1, 3, 2, 1, 0, 0, 45, 3, 58, 2, 4, 0),
(4, 169, 5, 'SEM09-15', 1, 3, 2, 1, 0, 0, 45, 3, 58, 1, 4, 0),
(4, 170, 6, 'SEM09-16', 1, 3, 2, 1, 0, 0, 45, 3, 58, 1, 4, 0),
(4, 263, 7, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(5, 70, 3, 'MEI09-09', 1, 6, 4, 2, 0, 0, 90, 6, 54, 1, 4, 0),
(5, 71, 1, 'MEM09-02', 1, 8, 4, 2, 0, 2, 120, 8, 54, 2, 4, 0),
(5, 89, 1, 'PDA09-01', 1, 8, 3, 1, 2, 2, 120, 8, 54, 1, 4, 0),
(5, 158, 1, 'OP109-03', 1, 8, 4, 2, 0, 2, 120, 8, 57, 3, 3, 0),
(5, 159, 1, 'OP209-04', 1, 8, 4, 2, 0, 2, 120, 8, 57, 4, 3, 0),
(5, 160, 2, 'PRE09-05', 1, 8, 4, 2, 0, 2, 120, 8, 54, 1, 4, 0),
(5, 161, 2, 'OP309-06', 1, 8, 4, 2, 0, 2, 120, 8, 57, 2, 3, 0),
(5, 162, 2, 'OP409-07', 1, 8, 4, 2, 0, 2, 120, 8, 57, 3, 3, 0),
(5, 163, 2, 'OP509-08', 1, 8, 4, 2, 0, 2, 120, 8, 57, 4, 3, 0),
(5, 164, 3, 'OP609-10', 1, 8, 4, 2, 0, 2, 120, 8, 57, 2, 3, 0),
(5, 165, 3, 'OP709-11', 1, 8, 4, 2, 0, 2, 120, 8, 57, 3, 3, 0),
(5, 166, 4, 'OP809-13', 1, 8, 4, 2, 0, 2, 120, 8, 57, 1, 3, 0),
(5, 167, 3, 'SEM09-12', 1, 3, 2, 1, 0, 0, 45, 3, 58, 4, 4, 0),
(5, 168, 4, 'SEM09-14', 1, 3, 2, 1, 0, 0, 45, 3, 58, 2, 4, 0),
(5, 169, 5, 'SEM09-15', 1, 3, 2, 1, 0, 0, 45, 3, 58, 1, 4, 0),
(5, 170, 6, 'SEM09-16', 1, 3, 2, 1, 0, 0, 45, 3, 58, 1, 4, 0),
(5, 263, 7, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(6, 2, 1, 'ALL-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 7, 5, 0),
(6, 5, 2, 'ACE-ES', 1, 8, 4, 1, 2, 1, 120, 7, 56, 4, 4, 0),
(6, 6, 5, 'ANM-ES', 2, 6, 3, 0, 2, 1, 90, 6, 56, 3, 5, 0),
(6, 9, 1, 'CDI-CV', 1, 8, 2, 1, 4, 1, 120, 7, 55, 6, 4, 0),
(6, 10, 2, 'CAV-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 6, 6, 0),
(6, 16, 8, 'COD-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 6, 4, 0),
(6, 19, 1, 'DPI-ES', 1, 5, 1, 0, 3, 1, 75, 5, 56, 5, 5, 0),
(6, 20, 3, 'DIN-CV', 1, 5, 1, 0, 3, 1, 75, 5, 55, 3, 6, 0),
(6, 24, 6, 'DIM-ES', 2, 7, 3, 0, 3, 1, 105, 6, 56, 3, 5, 0),
(6, 26, 4, 'ECD-CV', 2, 8, 3, 1, 3, 1, 120, 7, 55, 6, 6, 0),
(6, 27, 1, 'ELM-CV', 1, 6, 3, 1, 2, 0, 90, 6, 55, 4, 4, 0),
(6, 29, 3, 'ELA-ES', 1, 7, 4, 0, 1, 1, 105, 7, 56, 4, 4, 0),
(6, 30, 4, 'ELP-ES', 2, 5, 2, 0, 1, 1, 75, 5, 56, 4, 4, 0),
(6, 31, 3, 'ELD-ES', 1, 7, 3, 0, 3, 1, 105, 6, 56, 5, 4, 0),
(6, 34, 2, 'EST-CV', 1, 6, 3, 0, 2, 1, 90, 6, 55, 3, 7, 0),
(6, 44, 7, 'IAC-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 3, 4, 0),
(6, 49, 1, 'INGI-TR', 1, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(6, 50, 2, 'INGII-TR', 1, 6, 3, 0, 2, 1, 90, 5, 54, 1, 3, 0),
(6, 51, 3, 'INGIII-TR', 1, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(6, 52, 4, 'INGIV-TR', 2, 6, 3, 0, 2, 1, 90, 5, 54, 1, 3, 0),
(6, 53, 5, 'INGV-TR', 2, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(6, 54, 6, 'INGVI-TR', 2, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(6, 55, 7, 'INGVII-TR', 3, 6, 3, 0, 2, 1, 90, 5, 54, 1, 3, 0),
(6, 56, 8, 'INGVIII-TR', 3, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(6, 64, 6, 'MAE-ES', 2, 5, 2, 0, 2, 1, 75, 5, 56, 5, 4, 0),
(6, 68, 5, 'MDF-ES', 2, 5, 2, 0, 2, 1, 75, 5, 56, 7, 4, 0),
(6, 73, 1, 'MET-ES', 1, 6, 2, 1, 3, 0, 90, 6, 56, 3, 5, 0),
(6, 74, 5, 'MIC-ES', 2, 8, 3, 1, 3, 1, 120, 7, 56, 5, 4, 0),
(6, 76, 5, 'MSS-ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 6, 4, 0),
(6, 80, 3, 'PRE-CV', 1, 6, 3, 0, 2, 1, 90, 6, 55, 6, 5, 0),
(6, 93, 9, 'REI-ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 3, 5, 0),
(6, 94, 4, 'REM-ES', 2, 5, 2, 0, 1, 1, 75, 5, 56, 3, 4, 0),
(6, 99, 8, 'SCC-ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 3, 4, 0),
(6, 102, 6, 'SHN-ES', 2, 6, 3, 0, 2, 1, 90, 6, 56, 7, 4, 0),
(6, 116, 7, 'AIP-ES', 3, 4, 3, 0, 3, 0, 60, 4, 56, 4, 4, 0),
(6, 120, 9, 'COI-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 6, 4, 0),
(6, 121, 3, 'DEI-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(6, 124, 10, 'EST-ES', 3, 40, 0, 0, 0, 8, 600, 37, 56, 1, 1, 0),
(6, 129, 4, 'HAP-TR', 2, 3, 2, 0, 1, 0, 45, 3, 54, 2, 3, 0),
(6, 135, 9, 'INGIX-TR', 3, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(6, 137, 2, 'INE-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(6, 155, 8, 'TER-CV', 3, 6, 3, 0, 2, 1, 90, 5, 55, 2, 5, 0),
(6, 156, 1, 'VAS-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(6, 157, 8, 'VIM-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 7, 5, 0),
(6, 210, 5, 'HAO-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(6, 211, 6, 'ETP-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(6, 217, 2, 'NSI-ES', 1, 5, 3, 1, 1, 0, 75, 5, 56, 7, 5, 0),
(6, 218, 2, 'PRE-ES', 1, 6, 2, 0, 3, 1, 90, 5, 56, 5, 4, 0),
(6, 219, 4, 'ETNI-ES', 2, 8, 0, 0, 0, 8, 120, 7, 56, 7, 1, 0),
(6, 220, 7, 'ETNII-ES', 3, 8, 0, 0, 0, 8, 120, 7, 56, 7, 1, 0),
(6, 240, 4, 'PRP-ES', 2, 5, 2, 0, 1, 1, 75, 5, 56, 5, 3, 0),
(6, 241, 5, 'SAS-ES', 2, 6, 2, 1, 3, 0, 90, 5, 56, 4, 5, 0),
(6, 242, 6, 'AUI-ES', 2, 7, 3, 0, 3, 1, 105, 7, 56, 4, 5, 0),
(6, 243, 6, 'PRM-ES', 2, 6, 3, 0, 2, 1, 90, 5, 56, 6, 4, 0),
(6, 244, 7, 'APS-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 2, 4, 0),
(6, 245, 7, 'INE-ES', 3, 4, 2, 0, 1, 1, 60, 4, 56, 5, 4, 0),
(6, 246, 7, 'TEC-ES', 3, 6, 3, 1, 2, 0, 90, 6, 56, 6, 5, 0),
(6, 247, 8, 'CIR-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 5, 5, 0),
(6, 248, 9, 'TRC-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 2, 5, 0),
(6, 249, 9, 'ISM-ES', 3, 7, 3, 0, 3, 1, 105, 7, 56, 4, 5, 0),
(6, 250, 9, 'DCR-ES', 3, 7, 3, 0, 3, 1, 105, 6, 56, 5, 4, 0),
(6, 251, 9, 'CIT-ES', 3, 3, 1, 0, 1, 1, 45, 3, 56, 7, 4, 0),
(6, 254, 8, 'DIM-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 4, 5, 0),
(6, 255, 3, 'INM-ES', 1, 6, 3, 1, 2, 0, 90, 6, 56, 7, 5, 0),
(7, 2, 4, 'ALL-CV', 2, 6, 2, 0, 3, 1, 90, 6, 55, 6, 5, 0),
(7, 3, 1, 'ALG-ES', 1, 8, 3, 1, 2, 2, 120, 7, 56, 3, 5, 0),
(7, 9, 3, 'CDI-CV', 1, 8, 4, 1, 2, 1, 120, 7, 55, 7, 4, 0),
(7, 21, 5, 'DBD-ES', 2, 7, 2, 1, 3, 1, 105, 6, 56, 4, 5, 0),
(7, 35, 5, 'ESD-ES', 2, 6, 3, 0, 2, 1, 90, 6, 56, 3, 4, 0),
(7, 39, 2, 'HM-ES', 1, 5, 1, 0, 3, 1, 75, 5, 56, 4, 2, 0),
(7, 40, 1, 'HEO-ES', 1, 5, 0, 0, 4, 1, 75, 5, 56, 4, 5, 0),
(7, 43, 6, 'MBD-ES', 2, 6, 1, 1, 4, 0, 90, 6, 56, 4, 3, 0),
(7, 46, 5, 'INR-ES', 2, 6, 3, 0, 1, 2, 90, 6, 56, 7, 4, 0),
(7, 47, 6, 'ISW-ES', 2, 7, 2, 1, 3, 1, 105, 6, 56, 7, 4, 0),
(7, 49, 1, 'INGI-TR', 1, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(7, 50, 2, 'INGII-TR', 1, 6, 3, 1, 2, 0, 90, 5, 54, 1, 3, 0),
(7, 51, 3, 'INGIII-TR', 1, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(7, 52, 4, 'INGIV-TR', 2, 6, 3, 1, 2, 0, 90, 5, 54, 1, 3, 0),
(7, 53, 5, 'INGV-TR', 2, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(7, 54, 6, 'INGVI-TR', 2, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(7, 55, 7, 'INGVII-TR', 3, 6, 3, 1, 2, 0, 90, 5, 54, 1, 3, 0),
(7, 56, 8, 'INGVIII-TR', 3, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(7, 59, 1, 'IIT-ES', 1, 4, 3, 1, 0, 0, 60, 4, 56, 5, 4, 0),
(7, 65, 1, 'MAB-CV', 1, 7, 6, 1, 0, 0, 105, 7, 55, 7, 3, 0),
(7, 66, 2, 'MAD-CV', 1, 6, 2, 0, 3, 1, 90, 5, 55, 7, 6, 0),
(7, 80, 5, 'PRE-CV', 2, 6, 3, 0, 2, 1, 90, 6, 55, 6, 5, 0),
(7, 87, 7, 'POO-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 3, 3, 0),
(7, 88, 8, 'PWE-ES', 3, 8, 3, 1, 2, 2, 120, 7, 56, 3, 5, 0),
(7, 106, 5, 'TEW-ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 5, 5, 0),
(7, 121, 3, 'DEI-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(7, 124, 10, 'EST-ES', 3, 40, 0, 0, 0, 40, 600, 38, 56, 1, 1, 0),
(7, 129, 4, 'HAP-TR', 2, 3, 2, 0, 1, 0, 45, 3, 54, 2, 3, 0),
(7, 135, 9, 'INGIX-TR', 3, 6, 5, 1, 0, 0, 90, 5, 54, 1, 4, 0),
(7, 136, 9, 'INE-ES', 3, 6, 3, 1, 2, 0, 90, 6, 56, 4, 4, 0),
(7, 137, 2, 'INE-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(7, 144, 8, 'NEL-ES', 3, 4, 2, 0, 1, 1, 60, 4, 56, 2, 3, 0),
(7, 156, 1, 'VAS-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(7, 181, 3, 'FSI-ES', 1, 4, 2, 0, 1, 1, 60, 4, 56, 6, 4, 0),
(7, 206, 1, 'ARC-ES', 1, 7, 2, 2, 3, 0, 105, 7, 56, 6, 4, 0),
(7, 210, 5, 'HAO-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(7, 211, 6, 'ETP-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(7, 214, 2, 'FUF-CV', 1, 8, 3, 1, 3, 1, 120, 7, 55, 6, 5, 0),
(7, 215, 2, 'FR-ES', 1, 6, 2, 0, 3, 1, 90, 6, 56, 5, 5, 0),
(7, 216, 2, 'LC-ES', 1, 6, 2, 0, 3, 1, 90, 6, 56, 3, 5, 0),
(7, 218, 3, 'PES-ES', 1, 6, 3, 0, 2, 1, 90, 6, 56, 3, 5, 0),
(7, 219, 4, 'ETNI-ES', 2, 8, 0, 0, 0, 8, 120, 7, 56, 7, 1, 0),
(7, 220, 7, 'ETNII-ES', 3, 8, 0, 0, 0, 8, 120, 7, 56, 7, 1, 0),
(7, 221, 3, 'ASO-ES', 1, 7, 2, 0, 3, 2, 105, 6, 56, 4, 4, 0),
(7, 222, 3, 'RUT-ES', 1, 6, 3, 0, 2, 1, 90, 6, 56, 5, 4, 0),
(7, 223, 4, 'IPO-ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 3, 3, 0),
(7, 224, 4, 'IBD-ES', 2, 5, 3, 0, 1, 1, 75, 5, 56, 4, 4, 0),
(7, 225, 4, 'SWI-ES', 2, 6, 2, 0, 3, 1, 90, 6, 56, 5, 5, 0),
(7, 226, 6, 'ADO-ES', 2, 7, 2, 1, 3, 1, 105, 7, 56, 3, 4, 0),
(7, 227, 6, 'PAD-ES', 2, 4, 3, 1, 0, 0, 60, 4, 56, 5, 3, 0),
(7, 228, 7, 'DIN-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 2, 4, 0),
(7, 229, 7, 'SEI-ES', 3, 5, 3, 1, 1, 0, 75, 5, 56, 4, 4, 0),
(7, 230, 7, 'IGC-ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 5, 5, 0),
(7, 231, 7, 'SIN-ES', 3, 4, 3, 1, 0, 0, 60, 4, 56, 6, 4, 0),
(7, 232, 8, 'MDA-ES', 3, 8, 3, 1, 2, 2, 120, 7, 56, 4, 4, 0),
(7, 233, 8, 'GCA-ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 5, 5, 0),
(7, 234, 8, 'PTI-ES', 3, 4, 2, 0, 1, 1, 60, 4, 56, 6, 4, 0),
(7, 235, 8, 'ASI-ES', 3, 4, 3, 0, 0, 1, 60, 4, 56, 7, 3, 0),
(7, 236, 9, 'ACC-ES', 3, 5, 4, 1, 0, 0, 75, 4, 56, 2, 4, 0),
(7, 237, 9, 'CDM-ES', 3, 6, 2, 1, 3, 0, 90, 6, 56, 5, 5, 0),
(7, 238, 9, 'DEM-ES', 3, 5, 2, 0, 0, 3, 75, 5, 56, 6, 4, 0),
(7, 239, 9, 'ITI-ES', 3, 6, 2, 1, 3, 0, 90, 6, 56, 7, 4, 0),
(7, 253, 6, 'ADS-ES', 2, 4, 3, 1, 0, 0, 60, 6, 56, 6, 4, 0),
(7, 256, 9, 'TAW-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 3, 4, 0),
(8, 2, 1, 'ALL-CV', 1, 6, 3, 0, 2, 1, 90, 6, 55, 3, 5, 0),
(8, 9, 1, 'CDI-CV', 1, 8, 2, 0, 4, 2, 120, 8, 55, 4, 4, 0),
(8, 10, 2, 'CAV-CV', 1, 6, 3, 0, 2, 1, 90, 6, 55, 4, 6, 0),
(8, 11, 3, 'CIM-CV', 1, 7, 4, 1, 2, 0, 105, 7, 54, 3, 4, 0),
(8, 19, 2, 'DII-CV', 1, 6, 2, 0, 3, 1, 90, 5, 55, 5, 5, 0),
(8, 26, 3, 'ECD-CV', 1, 8, 3, 0, 3, 2, 120, 7, 55, 5, 6, 0),
(8, 36, 5, 'FUE-CV', 2, 6, 3, 1, 2, 0, 90, 5, 55, 3, 5, 0),
(8, 37, 6, 'FEL-CV', 2, 6, 3, 0, 2, 1, 90, 6, 55, 3, 5, 0),
(8, 38, 2, 'FUQ-CV', 1, 6, 3, 1, 2, 0, 90, 6, 55, 3, 5, 0),
(8, 40, 1, 'HEO-TR', 1, 6, 0, 0, 4, 2, 90, 5, 54, 7, 6, 0),
(8, 49, 1, 'INGI-TR', 1, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(8, 50, 2, 'INGII-TR', 1, 6, 3, 1, 2, 0, 90, 5, 54, 1, 3, 0),
(8, 51, 3, 'INGIII-TR', 1, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(8, 52, 4, 'INGIV-TR', 2, 6, 3, 1, 2, 0, 90, 5, 54, 1, 3, 0),
(8, 53, 5, 'INGV-TR', 2, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(8, 54, 6, 'INGVI-TR', 2, 3, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(8, 55, 7, 'INGVII-TR', 3, 6, 3, 1, 2, 0, 90, 5, 54, 1, 3, 0),
(8, 56, 8, 'INGVIII-TR', 3, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(8, 60, 1, 'IIM-ES', 1, 5, 2, 1, 2, 0, 75, 5, 56, 5, 4, 0),
(8, 67, 4, 'MEC-ES', 2, 7, 3, 0, 3, 1, 105, 7, 56, 3, 5, 0),
(8, 68, 5, 'MEF-ES', 2, 6, 2, 1, 2, 1, 90, 5, 56, 7, 4, 0),
(8, 73, 2, 'MET-CV', 1, 6, 2, 1, 2, 1, 90, 5, 55, 7, 3, 0),
(8, 81, 2, 'PEI-CV', 1, 7, 4, 0, 2, 1, 105, 7, 55, 6, 5, 0),
(8, 94, 7, 'REM-CV', 3, 6, 3, 0, 2, 1, 90, 5, 55, 4, 4, 0),
(8, 97, 1, 'SHI-CV', 1, 6, 2, 2, 2, 0, 90, 5, 55, 6, 5, 0),
(8, 113, 6, 'ADM-ES', 2, 6, 4, 2, 0, 0, 90, 6, 56, 6, 4, 0),
(8, 115, 9, 'ADP-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 5, 4, 0),
(8, 117, 8, 'AUT-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 3, 4, 0),
(8, 118, 3, 'CAL-CV', 1, 6, 3, 1, 2, 0, 90, 6, 55, 6, 5, 0),
(8, 119, 8, 'CCP-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 2, 4, 0),
(8, 121, 3, 'DEI-TR', 1, 3, 2, 0, 1, 0, 45, 3, 54, 2, 3, 0),
(8, 122, 9, 'DME-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 2, 5, 0),
(8, 124, 10, 'EST-TR', 4, 38, 0, 0, 0, 40, 600, 38, 55, 1, 4, 0),
(8, 126, 8, 'FEP-ES', 3, 6, 3, 0, 2, 1, 90, 6, 56, 5, 5, 0),
(8, 127, 5, 'GEC-ES', 2, 7, 4, 0, 2, 1, 105, 7, 56, 6, 4, 0),
(8, 128, 6, 'GEMS-ES', 2, 6, 3, 1, 1, 1, 90, 6, 56, 7, 5, 0),
(8, 129, 4, 'HAP-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(8, 131, 4, 'HEM-ES', 2, 8, 4, 0, 3, 1, 120, 8, 56, 6, 5, 0),
(8, 132, 4, 'INM-ES', 2, 6, 2, 1, 2, 1, 90, 5, 56, 5, 5, 0),
(8, 133, 6, 'INP-ES', 2, 6, 3, 0, 1, 2, 90, 6, 56, 4, 4, 0),
(8, 134, 7, 'INP-ES', 3, 6, 2, 1, 3, 0, 90, 5, 56, 6, 5, 0),
(8, 135, 9, 'INGIX-TR', 3, 6, 3, 1, 2, 0, 90, 5, 54, 1, 4, 0),
(8, 137, 2, 'INE-TR', 1, 3, 2, 0, 1, 0, 45, 3, 54, 2, 3, 0),
(8, 138, 9, 'INO-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 4, 4, 0),
(8, 139, 3, 'LPN-CV', 1, 5, 2, 0, 2, 1, 75, 5, 55, 7, 3, 0),
(8, 140, 7, 'MAE-ES', 3, 5, 2, 0, 2, 1, 75, 5, 56, 2, 5, 0),
(8, 141, 9, 'MEC-ES', 3, 7, 3, 0, 2, 2, 105, 6, 56, 3, 4, 0),
(8, 142, 8, 'MED-ES', 3, 5, 3, 0, 1, 1, 75, 5, 56, 4, 5, 0),
(8, 145, 5, 'PCP-ES', 2, 5, 3, 0, 1, 1, 75, 5, 56, 4, 4, 0),
(8, 146, 8, 'PRE-ES', 3, 6, 2, 1, 3, 0, 90, 6, 56, 6, 4, 0),
(8, 147, 9, 'PEM-ES', 3, 6, 2, 1, 3, 0, 90, 6, 56, 6, 4, 0),
(8, 148, 5, 'PPM-ES', 2, 7, 3, 2, 2, 0, 105, 7, 56, 5, 3, 0),
(8, 149, 6, 'PSM-ES', 2, 7, 4, 1, 2, 0, 105, 6, 56, 5, 3, 0),
(8, 150, 4, 'PRI-ES', 2, 6, 2, 1, 2, 1, 90, 5, 56, 4, 4, 0),
(8, 153, 9, 'SPD-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 7, 4, 0),
(8, 154, 8, 'TSD-ES', 3, 7, 3, 0, 2, 2, 105, 6, 56, 7, 5, 0),
(8, 155, 3, 'TER-CV', 1, 5, 3, 0, 1, 1, 75, 5, 55, 4, 5, 0),
(8, 156, 1, 'VAS-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(8, 210, 5, 'HAO-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(8, 211, 6, 'ETP-TR', 2, 3, 2, 0, 1, 0, 45, 3, 54, 2, 3, 0),
(8, 213, 7, 'SNH-ES', 3, 7, 3, 0, 3, 1, 105, 7, 56, 3, 4, 0),
(8, 219, 4, 'ETNI-TR', 2, 4, 0, 0, 0, 4, 60, 4, 56, 7, 1, 0),
(8, 220, 7, 'ETNII-TR', 3, 5, 0, 0, 0, 5, 75, 5, 56, 7, 1, 0),
(8, 257, 7, 'MEI-CV', 3, 5, 3, 0, 1, 1, 75, 5, 55, 5, 4, 0),
(9, 3, 1, 'ALG-ES', 0, 5, NULL, NULL, NULL, NULL, NULL, 1, 56, 1, 3, 0),
(9, 65, 2, 'MB-CV', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(9, 207, 1, 'TRGA-CV', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, 55, 2, 3, 0),
(9, 208, 1, 'ARA-CV', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, 55, 3, 3, 0),
(9, 209, 1, 'PSC-CV', 0, NULL, NULL, NULL, NULL, NULL, NULL, 1, 55, 4, 3, 0),
(9, 299, 2, 'CONT-ES', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 4, 3, 0),
(9, 300, 1, 'ING-C', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 5, 3, 0),
(9, 308, 1, 'HPA-CV', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 6, 4, 0),
(9, 414, 2, 'ICONT-ES', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 56, 3, 4, 0),
(9, 415, 2, 'PADMON-ES', 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 56, 2, 4, 0),
(10, 49, 1, 'INGI-TR', 1, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(10, 50, 2, 'INGII-TR', 1, 6, 3, 0, 2, 1, 90, 5, 54, 1, 3, 0),
(10, 51, 3, 'INGIII-TR', 1, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(10, 52, 4, 'INGIV-TR', 2, 6, 3, 0, 2, 1, 90, 5, 54, 1, 3, 0),
(10, 53, 5, 'INGV-TR', 2, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(10, 54, 6, 'INGVI-TR', 2, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(10, 55, 7, 'INGVII-TR', 3, 6, 3, 0, 2, 1, 90, 5, 54, 1, 3, 0),
(10, 56, 8, 'INGVIII-TR', 3, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(10, 70, 3, 'MEI-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 7, 4, 0),
(10, 80, 3, 'PRE-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 3, 5, 0),
(10, 118, 8, 'CAL-CV', 3, 6, 2, 0, 3, 1, 90, 6, 55, 2, 5, 0),
(10, 121, 3, 'DEI-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(10, 124, 10, 'EST-ES', 3, 40, 0, 0, 0, 40, 600, 40, 56, 1, 1, 0),
(10, 129, 4, 'HAP-TR', 2, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(10, 135, 9, 'INGIX-TR', 3, 6, 3, 0, 2, 1, 90, 5, 54, 1, 4, 0),
(10, 137, 2, 'INE-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(10, 156, 1, 'VAS-TR', 1, 3, 1, 0, 2, 0, 45, 3, 54, 2, 3, 0),
(10, 210, 5, 'HAO-TR', 2, 3, 2, 0, 1, 0, 45, 3, 54, 2, 3, 0),
(10, 211, 6, 'ETP-TR', 2, 3, 2, 0, 1, 0, 45, 3, 54, 2, 3, 0),
(10, 219, 4, 'ESTI-R', 2, 8, 0, 0, 0, 8, 120, 8, 54, 7, 1, 0),
(10, 220, 7, 'ESTII-TR', 3, 8, 0, 0, 0, 8, 120, 8, 54, 7, 1, 0),
(10, 227, 2, 'PRA-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 4, 5, 0),
(10, 258, 1, 'INM-CV', 1, 7, 3, 1, 2, 1, 105, 7, 55, 3, 4, 0),
(10, 259, 1, 'INA-CV', 1, 6, 3, 0, 2, 1, 90, 6, 55, 4, 5, 0),
(10, 260, 1, 'FUC-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 5, 4, 0),
(10, 261, 1, 'HEO-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 6, 6, 0),
(10, 262, 1, 'ALO-CV', 1, 6, 3, 0, 2, 1, 90, 6, 55, 7, 4, 0),
(10, 264, 2, 'MAA-CV', 1, 7, 2, 1, 3, 1, 105, 7, 55, 3, 4, 0),
(10, 265, 2, 'EOE-CV', 1, 6, 3, 1, 2, 0, 90, 6, 55, 6, 5, 0),
(10, 266, 2, 'COF-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 5, 4, 0),
(10, 267, 2, 'ASP-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 7, 6, 0),
(10, 268, 3, 'COC-CV', 1, 7, 2, 0, 3, 2, 105, 7, 55, 5, 3, 0),
(10, 269, 3, 'MIC-CV', 1, 6, 3, 0, 2, 1, 90, 6, 55, 6, 6, 0),
(10, 270, 3, 'PLE-CV', 1, 6, 2, 0, 3, 1, 90, 6, 55, 4, 5, 0),
(10, 271, 4, 'MAC-CV', 2, 6, 3, 0, 2, 1, 90, 6, 55, 3, 4, 0),
(10, 272, 4, 'ACH-CV', 2, 6, 3, 1, 2, 0, 90, 6, 55, 4, 4, 0),
(10, 273, 4, 'COA-CV', 2, 6, 2, 0, 3, 1, 90, 6, 55, 5, 4, 0),
(10, 274, 4, 'FUM-CV', 2, 5, 2, 0, 2, 1, 75, 5, 55, 6, 5, 0),
(10, 275, 5, 'MAF-CV', 2, 7, 2, 0, 3, 2, 105, 7, 55, 3, 4, 0),
(10, 276, 5, 'CDO-CV', 2, 6, 3, 1, 2, 0, 90, 6, 55, 4, 5, 0),
(10, 277, 5, 'NEE-CV', 2, 6, 3, 0, 2, 1, 90, 6, 55, 5, 5, 0),
(10, 278, 5, 'INM-CV', 2, 6, 2, 0, 3, 1, 90, 6, 55, 6, 5, 0),
(10, 279, 5, 'DEL-CV', 2, 6, 2, 1, 3, 0, 90, 6, 55, 7, 5, 0),
(10, 280, 6, 'MCP-CV', 2, 6, 2, 0, 3, 1, 90, 6, 55, 3, 5, 0),
(10, 281, 6, 'ASS-CV', 2, 6, 2, 0, 3, 1, 90, 6, 55, 4, 5, 0),
(10, 282, 6, 'ANF-CV', 2, 7, 2, 1, 3, 1, 105, 7, 55, 5, 4, 0),
(10, 283, 6, 'MEE-CV', 2, 6, 2, 0, 3, 1, 90, 6, 55, 6, 4, 0),
(10, 284, 6, 'TIA-CV', 2, 6, 2, 0, 3, 1, 90, 6, 55, 7, 5, 0),
(10, 285, 7, 'SDP-CV', 3, 5, 2, 1, 2, 0, 75, 5, 55, 2, 4, 0),
(10, 286, 7, 'COI-CV', 3, 6, 2, 0, 3, 1, 90, 6, 55, 3, 4, 0),
(10, 287, 7, 'AUA-CV', 3, 4, 1, 0, 2, 1, 60, 4, 55, 4, 4, 0),
(10, 288, 7, 'ADF-CV', 3, 6, 2, 0, 3, 1, 90, 6, 55, 5, 4, 0),
(10, 289, 7, 'COE-CV', 3, 5, 2, 0, 2, 1, 75, 5, 55, 6, 4, 0),
(10, 290, 8, 'COF-CV', 3, 6, 2, 0, 3, 1, 90, 6, 55, 3, 5, 0),
(10, 291, 8, 'DHG-CV', 3, 5, 2, 1, 2, 0, 75, 5, 55, 4, 4, 0),
(10, 292, 8, 'FEP-CV', 3, 6, 2, 0, 3, 1, 90, 6, 55, 5, 4, 0),
(10, 293, 8, 'PLN-CV', 3, 5, 2, 0, 2, 1, 75, 5, 55, 6, 5, 0),
(10, 294, 8, 'LOA-CV', 3, 6, 2, 0, 3, 1, 90, 6, 55, 7, 4, 0),
(10, 295, 9, 'CON-CV', 3, 6, 3, 0, 2, 1, 90, 6, 55, 3, 3, 0),
(10, 296, 9, 'DES-ES', 3, 6, 2, 0, 3, 1, 90, 6, 56, 2, 5, 0),
(10, 303, 9, 'AEF-OP', 3, 5, 2, 0, 2, 1, 75, 5, 57, 4, 4, 0),
(10, 304, 9, 'CAE-OP', 3, 5, 2, 1, 2, 0, 75, 5, 57, 5, 3, 0),
(10, 305, 9, 'FRA-OP', 3, 6, 2, 0, 3, 1, 90, 6, 57, 6, 4, 0),
(10, 306, 9, 'POS-OP', 3, 5, 2, 1, 2, 0, 75, 5, 57, 7, 4, 0),
(16, 49, 1, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(16, 50, 2, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(16, 51, 3, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(16, 52, 4, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 3, 0),
(16, 53, 5, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(16, 54, 6, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(16, 55, 7, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 3, 0),
(16, 56, 8, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(16, 135, 9, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(17, 80, 1, 'PROP-MI01', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(17, 297, 1, 'PROP-MI02', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 2, 4, 0),
(17, 298, 1, 'PROP-MI03', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 3, 4, 0),
(18, 301, 1, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 1, 4, 0),
(18, 302, 2, 'NULL', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 55, 2, 4, 0),
(19, 2, 1, 'ALL-CV', 1, 6, 5, 1, 0, 0, 90, 6, 55, 3, 5, 0),
(19, 9, 1, 'CDI-CV', 1, 8, 6, 2, 0, 0, 120, 7, 55, 4, 4, 0),
(19, 10, 2, 'CAV-CV', 1, 6, 5, 1, 0, 0, 90, 6, 55, 3, 6, 0),
(19, 19, 1, 'DII-ES', 1, 6, 5, 1, 0, 0, 90, 5, 56, 6, 4, 0),
(19, 26, 3, 'ECD-CV', 1, 8, 6, 2, 0, 0, 120, 7, 55, 3, 6, 0),
(19, 27, 4, 'ELM-CV', 2, 6, 5, 0, 0, 1, 90, 6, 55, 4, 4, 0),
(19, 34, 1, 'EST-CV', 1, 6, 5, 1, 0, 0, 90, 6, 55, 5, 7, 0),
(19, 49, 1, 'INGI-TR', 1, 6, 5, 1, 0, 0, 90, 5, 54, 1, 4, 0),
(19, 50, 2, 'INGII-TR', 1, 6, 5, 1, 0, 0, 90, 5, 54, 1, 3, 0),
(19, 51, 3, 'INGIII-TR', 1, 6, 5, 1, 0, 0, 90, 5, 54, 1, 4, 0),
(19, 52, 4, 'INGIV-TR', 2, 6, 5, 1, 0, 0, 90, 5, 54, 1, 3, 0),
(19, 53, 5, 'INGV-TR', 2, 6, 5, 1, 0, 0, 90, 5, 54, 1, 4, 0),
(19, 54, 6, 'INGVI-TR', 2, 6, 5, 1, 0, 0, 90, 5, 54, 1, 4, 0),
(19, 55, 7, 'INGVII-TR', 3, 6, 5, 1, 0, 0, 90, 5, 54, 1, 3, 0),
(19, 56, 8, 'INGVIII-TR', 3, 6, 5, 1, 0, 0, 90, 5, 54, 1, 4, 0),
(19, 80, 4, 'PRE-CV', 2, 6, 5, 1, 0, 0, 90, 6, 55, 3, 5, 0),
(19, 84, 5, 'PRI-ES', 2, 6, 5, 0, 0, 1, 90, 6, 56, 4, 4, 0),
(19, 94, 2, 'REM-ES', 1, 6, 5, 1, 0, 0, 90, 5, 56, 7, 4, 0),
(19, 98, 4, 'SEA-ES', 2, 5, 4, 0, 0, 1, 75, 5, 56, 5, 4, 0),
(19, 121, 3, 'DEI-TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 2, 3, 0),
(19, 124, 10, 'EST-ES', 3, 40, 0, 0, 0, 40, 600, 38, 56, 1, 1, 0),
(19, 126, 7, 'FEP-ES', 3, 5, 4, 1, 0, 0, 75, 5, 56, 5, 4, 0),
(19, 129, 4, 'HAP-TR', 2, 3, 3, 0, 0, 0, 45, 3, 54, 2, 3, 0),
(19, 135, 9, 'INGIX-TR', 3, 6, 5, 1, 0, 0, 90, 5, 54, 1, 4, 0),
(19, 137, 2, 'INE-TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 2, 3, 0),
(19, 155, 5, 'TER-CV', 2, 6, 5, 1, 0, 0, 90, 6, 55, 3, 5, 0),
(19, 156, 1, 'VAS-TR', 1, 3, 3, 0, 0, 0, 45, 3, 54, 2, 3, 0),
(19, 157, 8, 'VIM-ES', 3, 6, 5, 0, 0, 1, 90, 6, 56, 6, 5, 0),
(19, 210, 5, 'HAO-TR', 2, 3, 3, 0, 0, 0, 45, 3, 54, 2, 3, 0),
(19, 211, 6, 'ETP-TR', 2, 3, 3, 0, 0, 0, 45, 3, 54, 2, 3, 0),
(19, 219, 4, 'ETNI-ES', 2, 8, 0, 0, 0, 8, 120, 7, 56, 7, 1, 0),
(19, 220, 7, 'ETNII-ES', 3, 8, 0, 0, 0, 8, 120, 7, 56, 7, 1, 0),
(19, 245, 7, 'INE-ES', 3, 5, 4, 1, 0, 0, 75, 5, 56, 2, 4, 0),
(19, 248, 6, 'TRC-ES', 2, 6, 5, 1, 0, 0, 90, 6, 56, 7, 5, 0),
(19, 286, 8, 'COI-ES', 3, 6, 5, 1, 0, 0, 90, 5, 56, 7, 4, 0),
(19, 307, 1, 'MEA-ES', 1, 5, 4, 0, 0, 1, 75, 5, 56, 7, 4, 0),
(19, 309, 2, 'DIC-ES', 1, 6, 5, 0, 0, 2, 90, 6, 56, 4, 4, 0),
(19, 310, 2, 'MTA-ES', 1, 6, 5, 1, 0, 0, 90, 6, 56, 5, 5, 0),
(19, 311, 2, 'ELA-ES', 1, 7, 5, 0, 0, 2, 105, 6, 56, 6, 4, 0),
(19, 312, 3, 'AUT-ES', 1, 6, 5, 0, 0, 1, 90, 6, 56, 4, 4, 0),
(19, 313, 3, 'AEA-ES', 1, 6, 5, 0, 0, 1, 90, 5, 56, 5, 4, 0),
(19, 314, 3, 'EUA-ES', 1, 6, 5, 0, 0, 1, 90, 6, 56, 6, 4, 0),
(19, 315, 3, 'MOA-ES', 1, 5, 4, 0, 0, 1, 75, 5, 56, 7, 4, 0),
(19, 316, 4, 'MET-ES', 2, 6, 5, 1, 0, 0, 90, 5, 56, 6, 4, 0),
(19, 317, 5, 'MAU-ES', 2, 7, 6, 0, 0, 1, 105, 6, 56, 5, 4, 0),
(19, 318, 5, 'SAU-ES', 2, 7, 6, 1, 0, 0, 105, 6, 56, 6, 4, 0),
(19, 319, 5, 'ERG-ES', 2, 5, 4, 1, 0, 0, 75, 5, 56, 7, 4, 0),
(19, 320, 6, 'SIC-ES', 2, 6, 5, 1, 0, 0, 90, 6, 56, 3, 5, 0),
(19, 321, 6, 'SIP-ES', 2, 6, 5, 1, 0, 0, 90, 6, 56, 4, 4, 0),
(19, 322, 6, 'COP-ES', 2, 6, 5, 1, 0, 0, 90, 6, 56, 5, 4, 0),
(19, 323, 6, 'MCC-ES', 2, 7, 3, 2, 2, 0, 105, 6, 56, 6, 4, 0),
(19, 324, 7, 'COE-ES', 3, 5, 4, 1, 0, 0, 75, 5, 56, 3, 4, 0),
(19, 325, 7, 'MNA-ES', 3, 6, 5, 1, 0, 0, 90, 6, 56, 4, 4, 0),
(19, 326, 7, 'TEP-ES', 3, 5, 4, 1, 0, 0, 75, 5, 56, 6, 4, 0),
(19, 327, 8, 'SII-ES', 3, 5, 4, 0, 0, 1, 75, 5, 56, 2, 4, 0),
(19, 328, 8, 'SDF-ES', 3, 6, 5, 0, 0, 1, 90, 6, 56, 3, 4, 0),
(19, 329, 8, 'SCA-ES', 3, 5, 4, 0, 0, 1, 75, 5, 56, 4, 3, 0),
(19, 330, 8, 'MAA-ES', 3, 6, 5, 0, 0, 1, 90, 6, 56, 5, 4, 0),
(19, 331, 9, 'SIA-ES', 3, 6, 5, 1, 0, 0, 90, 6, 56, 2, 4, 0),
(19, 332, 9, 'ANM-ES', 3, 5, 4, 1, 0, 0, 75, 5, 56, 3, 4, 0),
(19, 333, 9, 'SCO-ES', 3, 6, 5, 1, 0, 0, 90, 5, 56, 4, 4, 0),
(19, 334, 9, 'DIA-ES', 3, 6, 5, 1, 0, 0, 90, 6, 56, 5, 4, 0),
(19, 335, 9, 'PRN-ES', 3, 5, 1, 4, 0, 0, 75, 5, 56, 6, 4, 0),
(19, 336, 9, 'PRM-ES', 3, 6, 5, 1, 0, 0, 90, 6, 56, 7, 4, 0),
(20, 70, 1, 'MEI15-03', 1, NULL, NULL, NULL, NULL, NULL, NULL, 6, 55, 3, 4, 0),
(20, 71, 1, 'MEM15-02', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 55, 2, 4, 0),
(20, 89, 1, 'PDA15-01', 1, 0, NULL, NULL, NULL, NULL, NULL, 8, 55, 1, 4, 0),
(20, 158, 1, 'OP115-04', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 4, 4, 0),
(20, 159, 2, 'OP215-06', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 2, 4, 0),
(20, 161, 2, 'OP315-07', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 3, 4, 0),
(20, 162, 2, 'OP415-08', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 4, 4, 0),
(20, 163, 3, 'OP515-10', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 2, 4, 0),
(20, 164, 3, 'OP615-11', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 3, 4, 0),
(20, 165, 3, 'OP715-12', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 4, 4, 0),
(20, 166, 4, 'PO815-14', 2, NULL, NULL, NULL, NULL, NULL, NULL, 8, 57, 2, 4, 0),
(20, 167, 3, 'SM115-09', 1, NULL, NULL, NULL, NULL, NULL, NULL, 3, 55, 1, 4, 0),
(20, 168, 4, 'SM215-13', 2, NULL, NULL, NULL, NULL, NULL, NULL, 3, 55, 1, 4, 0),
(20, 169, 5, 'SM315-15', 2, NULL, NULL, NULL, NULL, NULL, NULL, 3, 55, 1, 4, 0),
(20, 170, 6, 'SM415-16', 2, NULL, NULL, NULL, NULL, NULL, NULL, 3, 55, 1, 4, 0),
(20, 337, 2, 'HEC15-05', 1, NULL, NULL, NULL, NULL, NULL, NULL, 8, 55, 1, 4, 0),
(22, 231, 2, 'SEI-CV', 1, 4, 3, 2, 1, 2, 120, 8, 55, 1, 4, 0),
(22, 263, 6, 'TRT-CV', 2, 4, 3, 5, 1, 11, 300, 15, 55, 1, 4, 0),
(22, 342, 1, 'DPI-CV', 1, 4, 3, 2, 1, 2, 120, 8, 55, 1, 4, 0),
(22, 343, 1, 'ERM-CV', 1, 4, 3, 1, 1, 2, 105, 7, 55, 2, 4, 0),
(22, 346, 1, 'OG1-ES', 1, 3, 2, 1, 1, 1, 75, 5, 57, 3, 4, 0),
(22, 347, 2, 'OGII-ES', 1, 3, 2, 1, 1, 1, 75, 5, 57, 3, 4, 0),
(22, 348, 2, 'TEE-CV', 1, 4, 2, 2, 2, 1, 105, 7, 55, 2, 4, 0),
(22, 349, 3, 'DEI-CV', 1, 4, 3, 3, 1, 1, 120, 8, 55, 1, 4, 0),
(22, 350, 3, 'AND-CV', 1, 3, 2, 2, 1, 2, 105, 7, 55, 2, 4, 0),
(22, 351, 3, 'OGIII-ES', 1, 3, 3, 1, 1, 1, 75, 5, 57, 3, 4, 0),
(22, 352, 4, 'TRE-CV', 2, 4, 2, 5, 2, 6, 225, 15, 55, 1, 4, 0),
(22, 353, 4, 'RTC-CV', 2, 4, 2, 0, 2, 1, 75, 5, 55, 2, 4, 0),
(22, 354, 5, 'TRI-CV', 2, 4, 3, 5, 1, 11, 300, 15, 55, 1, 4, 0),
(23, 2, 1, 'NULL', 1, NULL, 30, NULL, 75, NULL, 105, 7, 55, 3, 4, 1),
(23, 19, 2, 'NULL', 1, NULL, 36, NULL, 54, NULL, 90, 6, 55, 8, 4, 5),
(23, 27, 2, 'NULL', 1, NULL, 34, NULL, 41, NULL, 75, 5, 55, 5, 4, 1),
(23, 44, 8, 'NULL', 3, NULL, 30, NULL, 45, NULL, 75, 5, 55, 4, 4, 5),
(23, 45, 8, 'NULL', 3, NULL, 26, NULL, 49, NULL, 75, 5, 55, 3, 4, 5),
(23, 49, 1, 'NULL', 1, NULL, 48, NULL, 42, NULL, 90, 6, 55, 1, 4, 3),
(23, 50, 2, 'NULL', 1, NULL, 67, NULL, 23, NULL, 90, 6, 55, 1, 4, 3),
(23, 51, 3, 'NULL', 1, NULL, 68, NULL, 22, NULL, 90, 6, 55, 1, 4, 3),
(23, 52, 4, 'NULL', 2, NULL, 66, NULL, 24, NULL, 90, 6, 55, 1, 4, 3),
(23, 53, 5, 'NULL', 2, NULL, 48, NULL, 42, NULL, 90, 6, 55, 1, 4, 3),
(23, 54, 6, 'NULL', 2, NULL, 48, NULL, 42, NULL, 90, 6, 55, 1, 4, 3),
(23, 55, 7, 'NULL', 3, NULL, 15, NULL, 75, NULL, 90, 6, 55, 1, 4, 3),
(23, 56, 8, 'NULL', 3, NULL, 26, NULL, 64, NULL, 90, 6, 55, 1, 4, 3),
(23, 73, 1, 'NULL', 1, NULL, 30, NULL, 45, NULL, 75, 5, 55, 6, 4, 5),
(23, 76, 7, 'NULL', 3, NULL, 40, NULL, 35, NULL, 75, 5, 55, 3, 4, 5),
(23, 80, 3, 'NULL', 1, NULL, 22, NULL, 53, NULL, 75, 5, 55, 4, 4, 1),
(23, 94, 6, 'NULL', 2, NULL, 20, NULL, 70, NULL, 90, 6, 55, 4, 4, 5),
(23, 98, 4, 'NULL', 2, NULL, 20, NULL, 40, NULL, 60, 4, 55, 7, 4, 5),
(23, 135, 9, 'NULL', 3, NULL, 15, NULL, 75, NULL, 90, 6, 55, 1, 4, 3),
(23, 155, 7, 'NULL', 3, NULL, 16, NULL, 29, NULL, 45, 3, 55, 2, 4, 1),
(23, 211, 4, 'NULL', 2, NULL, 25, NULL, 20, NULL, 45, 3, 55, 2, 4, 2),
(23, 213, 5, 'NULL', 2, NULL, 40, NULL, 50, NULL, 90, 6, 55, 7, 4, 5),
(23, 218, 5, 'NULL', 2, NULL, 30, NULL, 45, NULL, 75, 5, 55, 6, 4, 5),
(23, 219, 4, 'NULL', 2, NULL, 0, NULL, 120, NULL, 120, 8, 55, 8, 4, 5),
(23, 220, 7, 'NULL', 2, NULL, 0, NULL, 180, NULL, 180, 11, 55, 7, 4, 5),
(23, 240, 6, 'NULL', 2, NULL, 36, NULL, 54, NULL, 90, 6, 55, 6, 4, 5),
(23, 242, 6, 'NULL', 2, NULL, 52, NULL, 38, NULL, 90, 6, 55, 7, 4, 5),
(23, 243, 2, 'NULL', 1, NULL, 35, NULL, 40, NULL, 75, 5, 55, 7, 4, 5),
(23, 247, 7, 'NULL', 3, NULL, 40, NULL, 35, NULL, 75, 5, 55, 5, 4, 5),
(23, 337, 4, 'NULL', 2, NULL, 15, NULL, 30, NULL, 45, 3, 55, 3, 4, 4),
(23, 374, 1, 'NULL', 1, NULL, 23, NULL, 52, NULL, 75, 5, 55, 4, 4, 1),
(23, 375, 1, 'NULL', 1, NULL, 20, NULL, 55, NULL, 75, 5, 55, 5, 4, 1),
(23, 376, 1, 'NULL', 1, NULL, 44, NULL, 16, NULL, 60, 4, 55, 7, 4, 5),
(23, 377, 2, 'NULL', 1, NULL, 16, NULL, 29, NULL, 45, 3, 55, 2, 4, 2),
(23, 378, 2, 'NULL', 1, NULL, 19, NULL, 41, NULL, 60, 4, 55, 3, 4, 1),
(23, 379, 2, 'NULL', 1, NULL, 33, NULL, 57, NULL, 90, 6, 55, 4, 4, 1),
(23, 380, 2, 'NULL', 1, NULL, 25, NULL, 50, NULL, 75, 5, 55, 6, 4, 5),
(23, 381, 3, 'NULL', 1, NULL, 11, NULL, 34, NULL, 45, 3, 55, 2, 4, 2),
(23, 382, 3, 'NULL', 1, NULL, 25, NULL, 50, NULL, 75, 5, 55, 3, 4, 1),
(23, 383, 3, 'NULL', 1, NULL, 30, NULL, 60, NULL, 90, 6, 55, 5, 4, 5),
(23, 384, 3, 'NULL', 1, NULL, 40, NULL, 35, NULL, 75, 5, 55, 6, 4, 5),
(23, 385, 3, 'NULL', 1, NULL, 38, NULL, 52, NULL, 90, 6, 55, 7, 4, 5),
(23, 386, 3, 'NULL', 1, NULL, 40, NULL, 20, NULL, 60, 4, 55, 8, 4, 5),
(23, 387, 4, 'NULL', 2, NULL, 13, NULL, 32, NULL, 45, 3, 55, 4, 4, 1),
(23, 388, 4, 'NULL', 2, NULL, 45, NULL, 45, NULL, 90, 6, 55, 5, 4, 5),
(23, 389, 1, 'NULL', 1, NULL, 23, NULL, 52, NULL, 75, 5, 55, 8, 4, 1),
(23, 390, 9, 'NULL', 3, NULL, 25, NULL, 52, NULL, 75, 5, 55, 6, 4, 5),
(23, 391, 4, 'NULL', 2, NULL, 35, NULL, 70, NULL, 105, 7, 55, 6, 4, 5),
(23, 392, 5, 'NULL', 2, NULL, 25, NULL, 20, NULL, 45, 3, 55, 2, 4, 2),
(23, 393, 5, 'NULL', 2, NULL, 19, NULL, 41, NULL, 60, 4, 55, 3, 4, 1),
(23, 394, 6, 'NULL', 2, NULL, 30, NULL, 45, NULL, 75, 5, 55, 3, 4, 1),
(23, 395, 5, 'NULL', 2, NULL, 18, NULL, 42, NULL, 60, 4, 55, 4, 4, 1),
(23, 396, 5, 'NULL', 2, NULL, 38, NULL, 52, NULL, 90, 6, 55, 5, 4, 5),
(23, 397, 5, 'NULL', 2, NULL, 43, NULL, 47, NULL, 90, 6, 55, 8, 4, 5),
(23, 398, 6, 'NULL', 2, NULL, 25, NULL, 20, NULL, 45, 3, 55, 2, 4, 2),
(23, 399, 6, 'NULL', 2, NULL, 19, NULL, 41, NULL, 60, 4, 55, 5, 4, 5),
(23, 400, 6, 'NULL', 2, NULL, 28, NULL, 32, NULL, 60, 4, 55, 8, 4, 5),
(23, 401, 7, 'NULL', 3, NULL, 30, NULL, 60, NULL, 90, 6, 55, 4, 4, 5),
(23, 402, 7, 'NULL', 3, NULL, 21, NULL, 24, NULL, 45, 3, 55, 6, 4, 5),
(23, 403, 8, 'NULL', 3, NULL, 23, NULL, 52, NULL, 75, 5, 55, 2, 4, 5),
(23, 404, 8, 'NULL', 3, NULL, 30, NULL, 45, NULL, 75, 5, 55, 5, 4, 5),
(23, 405, 8, 'NULL', 3, NULL, 17, NULL, 58, NULL, 75, 5, 55, 6, 4, 5),
(23, 406, 8, 'NULL', 3, NULL, 24, NULL, 36, NULL, 60, 4, 55, 7, 4, 5),
(23, 407, 8, 'NULL', 3, NULL, 25, NULL, 50, NULL, 75, 5, 55, 8, 4, 5),
(23, 408, 9, 'NULL', 3, NULL, 24, NULL, 51, NULL, 75, 5, 55, 2, 4, 5),
(23, 409, 9, 'NULL', 3, NULL, 34, NULL, 71, NULL, 105, 7, 55, 3, 4, 5),
(23, 410, 9, 'NULL', 3, NULL, 40, NULL, 80, NULL, 120, 8, 55, 4, 4, 5),
(23, 411, 9, 'NULL', 3, NULL, 35, NULL, 40, NULL, 75, 5, 55, 5, 4, 5),
(23, 412, 9, 'NULL', 3, NULL, 24, NULL, 36, NULL, 60, 4, 55, 7, 4, 5),
(23, 413, 1, 'NULL', 1, NULL, 25, NULL, 20, NULL, 45, 3, 55, 2, 4, 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresreinscripcionhorario`
--

CREATE TABLE `escolaresreinscripcionhorario` (
  `idReinscripcionHorario` int(11) NOT NULL,
  `idAlumno` int(11) DEFAULT NULL,
  `idPlanDeEstudios` int(11) DEFAULT NULL,
  `idCuatrimestre` int(11) DEFAULT NULL,
  `Matricula` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `fechaProgramada` datetime DEFAULT NULL,
  `Descripcion` varchar(300) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresresultadosceneval`
--

CREATE TABLE `escolaresresultadosceneval` (
  `TIPO_EXA` longtext DEFAULT NULL,
  `APLI` longtext DEFAULT NULL,
  `FECHA_APLI` longtext DEFAULT NULL,
  `CVE_INST` longtext DEFAULT NULL,
  `IDENTIFICA` longtext DEFAULT NULL,
  `FOLIO` longtext DEFAULT NULL,
  `MATRICULA` longtext DEFAULT NULL,
  `APE_PAT` longtext DEFAULT NULL,
  `APE_MAT` longtext DEFAULT NULL,
  `NOMBRE` longtext DEFAULT NULL,
  `DIA_NAC` longtext DEFAULT NULL,
  `MES_NAC` longtext DEFAULT NULL,
  `ANO_NAC` longtext DEFAULT NULL,
  `SEXO` longtext DEFAULT NULL,
  `LI_MAD` longtext DEFAULT NULL,
  `LI_PAD` longtext DEFAULT NULL,
  `EDO_PROC` longtext DEFAULT NULL,
  `NOM_PROC` longtext DEFAULT NULL,
  `CIU_PROC` longtext DEFAULT NULL,
  `CVE_PROC` longtext DEFAULT NULL,
  `POS_SEL` int(11) DEFAULT NULL,
  `ICNE` int(11) DEFAULT NULL,
  `PERCEN` decimal(18,2) DEFAULT NULL,
  `PORCECNE` decimal(18,2) DEFAULT NULL,
  `PCNE` decimal(18,2) DEFAULT NULL,
  `PRLM` decimal(18,2) DEFAULT NULL,
  `PMAT` decimal(18,2) DEFAULT NULL,
  `PRV` decimal(18,2) DEFAULT NULL,
  `PESP` decimal(18,2) DEFAULT NULL,
  `PTIC` decimal(18,2) DEFAULT NULL,
  `IRLM` decimal(18,2) DEFAULT NULL,
  `IMAT` decimal(18,2) DEFAULT NULL,
  `IRV` decimal(18,2) DEFAULT NULL,
  `IESP` decimal(18,2) DEFAULT NULL,
  `ITIC` decimal(18,2) DEFAULT NULL,
  `columnaDeControl` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolaresseriacion`
--

CREATE TABLE `escolaresseriacion` (
  `idplan_estudios` int(11) NOT NULL,
  `idmateria` int(11) NOT NULL,
  `idmateria_previa` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarestitulacioningenieria`
--

CREATE TABLE `escolarestitulacioningenieria` (
  `idTitulacionIngenieria` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `idPlan_estudios` int(11) NOT NULL,
  `idEstadiaEmpresa` smallint(6) DEFAULT NULL,
  `EstadiaProyecto` longtext DEFAULT NULL,
  `SSFechaConstancia` datetime DEFAULT NULL,
  `SSFolioConstancia` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `ActaExamenFolio` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `ActaExamenFecha` datetime DEFAULT NULL,
  `CertificadoFecha` datetime DEFAULT NULL,
  `CertificadoNumero` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `CertificadoNumLegalizacion` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `TituloFecha` datetime DEFAULT NULL,
  `TituloFolio` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `Cedula` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `NumLegalizacionTitulo` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `TramiteSolicitudTitulo` datetime DEFAULT NULL,
  `TramiteEstatusTitulo` smallint(6) DEFAULT NULL,
  `TramiteEntregaTitulo` datetime DEFAULT NULL,
  `FechaGraduacion` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `escolarestitulacioningenieria`
--

INSERT INTO `escolarestitulacioningenieria` (`idTitulacionIngenieria`, `idAlumno`, `idPlan_estudios`, `idEstadiaEmpresa`, `EstadiaProyecto`, `SSFechaConstancia`, `SSFolioConstancia`, `ActaExamenFolio`, `ActaExamenFecha`, `CertificadoFecha`, `CertificadoNumero`, `CertificadoNumLegalizacion`, `TituloFecha`, `TituloFolio`, `Cedula`, `NumLegalizacionTitulo`, `TramiteSolicitudTitulo`, `TramiteEstatusTitulo`, `TramiteEntregaTitulo`, `FechaGraduacion`) VALUES
(0, 83, 1, 98, 'modulo web control escolar', '2020-04-10 00:00:00', '53645345', '141452', '2020-04-10 00:00:00', '2020-04-17 00:00:00', '8478', '4884', '2020-04-17 00:00:00', '5484565', '54284684788996', '456345', '2020-04-10 00:00:00', NULL, '2020-04-16 00:00:00', '2020-04-25 00:00:00'),
(1, 0, 0, NULL, 'modulo web', '2020-03-11 00:00:00', '45746558', 'jnhbgv', '2020-03-26 00:00:00', '2020-03-11 00:00:00', '74554', '455', '2020-03-19 00:00:00', '111', 'vb525235', '156252', '2020-03-18 00:00:00', NULL, '2020-03-11 00:00:00', '2020-03-11 00:00:00'),
(2, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(3, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(4, 0, 0, NULL, 'modulo web', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 0, 0, NULL, 'modulo web', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(6, 72, 1, NULL, 'modulo web controlescolar', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(7, 73, 7, 99, 'prueba TITULO88', '2020-03-24 00:00:00', '948498498', '1111598', '2020-03-24 00:00:00', '2020-03-25 00:00:00', '8478', '4884', '2020-03-18 00:00:00', '65595', '4854851', '59498', '2020-03-25 00:00:00', NULL, '2020-03-25 00:00:00', '2020-03-18 00:00:00');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarestitulacioningenieriahistorico`
--

CREATE TABLE `escolarestitulacioningenieriahistorico` (
  `idTitulacionIngenieriaEstatus` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `idEstatusTramite` int(11) NOT NULL,
  `fecha` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarestmpespeciales`
--

CREATE TABLE `escolarestmpespeciales` (
  `MAtricula` varchar(7) CHARACTER SET utf8 DEFAULT NULL,
  `idPlan` int(11) DEFAULT NULL,
  `idCuatrimestre` int(11) DEFAULT NULL,
  `fecha` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `escolarestutoria`
--

CREATE TABLE `escolarestutoria` (
  `idalumno` int(11) NOT NULL,
  `idempleado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `esp$`
--

CREATE TABLE `esp$` (
  `P#A#` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `MATRÍCULA` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `ALUMNO` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `HORA DE REINSCRIPCIÓN` datetime(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `evadoc`
--

CREATE TABLE `evadoc` (
  `idalumno` double DEFAULT NULL,
  `MATRICULA` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `ALUMNO` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `CARRERA` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `NUM_EV` double DEFAULT NULL,
  `EV_REALIZADAS` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `failed_jobs`
--

CREATE TABLE `failed_jobs` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financieros`
--

CREATE TABLE `financieros` (
  `idParada` int(11) NOT NULL,
  `Parada` int(11) DEFAULT NULL,
  `idTransporteRuta` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosaprobacionclasificacion`
--

CREATE TABLE `financierosaprobacionclasificacion` (
  `IdClasificacionAprobacion` int(11) NOT NULL,
  `Clasificacion` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Descripcion` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosaprobacioninscripcion`
--

CREATE TABLE `financierosaprobacioninscripcion` (
  `IdInscripcionAprobacion` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `IdClasificacionAprobacion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosaprobacionmovimiento`
--

CREATE TABLE `financierosaprobacionmovimiento` (
  `IdAprobacionMovimiento` int(11) NOT NULL,
  `IdMovimiento` int(11) NOT NULL,
  `Tipo` tinyint(3) UNSIGNED NOT NULL,
  `IdInscripcionAprobacion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosbecario`
--

CREATE TABLE `financierosbecario` (
  `idcarrera` int(11) NOT NULL,
  `idplan_estudios` int(11) NOT NULL,
  `idalumno` int(11) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `idbeca` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financieroscobrosconfiguracion`
--

CREATE TABLE `financieroscobrosconfiguracion` (
  `IdCobroConfiguracion` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `IdConcepto` int(11) NOT NULL,
  `CostoConcepto` decimal(18,2) NOT NULL,
  `MontoAdeuda` decimal(18,2) NOT NULL,
  `MontoPagado` decimal(18,2) NOT NULL,
  `IdCobroDetalle` int(11) NOT NULL,
  `NecesarioParaInscribirse` tinyint(4) NOT NULL,
  `IdPlanEstudio` int(11) NOT NULL,
  `FechaRegistro` datetime(3) DEFAULT NULL,
  `Observaciones` varchar(150) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financieroscobrosprogramacion`
--

CREATE TABLE `financieroscobrosprogramacion` (
  `IdCobroProgramacion` int(11) NOT NULL,
  `IdCobroConfiguracion` int(11) NOT NULL,
  `Fecha` date NOT NULL,
  `Monto` decimal(18,2) NOT NULL,
  `Cancelado` tinyint(4) NOT NULL,
  `Pagado` tinyint(4) NOT NULL,
  `IdCobroDetalle` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosconceptosaprecargar`
--

CREATE TABLE `financierosconceptosaprecargar` (
  `IdConceptoAPrecargar` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `IdPlanEstudio` int(11) NOT NULL,
  `IdConcepto` int(11) NOT NULL,
  `Cantidad` smallint(6) NOT NULL,
  `PrecioUnitario` decimal(18,2) NOT NULL,
  `NecesarioParaInscribirse` tinyint(4) NOT NULL,
  `ParaNuevoIngreso` tinyint(4) NOT NULL,
  `ParaReinscripciones` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosconceptosotrosingresos`
--

CREATE TABLE `financierosconceptosotrosingresos` (
  `IdConceptoOtrosIngresos` int(11) NOT NULL,
  `Concepto` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Costo` decimal(18,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosconceptosotrosingresosdetalle`
--

CREATE TABLE `financierosconceptosotrosingresosdetalle` (
  `IdConceptoOtrosIngresosDetalle` int(11) NOT NULL,
  `IdConceptoOtrosIngresos` int(11) NOT NULL,
  `Monto` decimal(18,2) NOT NULL,
  `IdRBConceptoDetalle` int(11) NOT NULL,
  `Cantidad` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierospagosenlinea`
--

CREATE TABLE `financierospagosenlinea` (
  `idPago` int(11) NOT NULL,
  `idusuario` int(11) DEFAULT NULL,
  `usuario` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `idConcepto` int(11) DEFAULT NULL,
  `importe` decimal(18,2) DEFAULT NULL,
  `folioPago` int(11) DEFAULT NULL,
  `idFinanzas` int(11) DEFAULT NULL,
  `fechaPago` datetime DEFAULT NULL,
  `cancelado` tinyint(4) DEFAULT NULL,
  `folioCancela` int(11) DEFAULT NULL,
  `fechaCancela` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierospaquetes`
--

CREATE TABLE `financierospaquetes` (
  `IdPaquete` int(11) NOT NULL,
  `Paquete` varchar(150) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierospaquetesasignados`
--

CREATE TABLE `financierospaquetesasignados` (
  `IdPaqueteAsignado` int(11) NOT NULL,
  `IdCarrera` int(11) NOT NULL,
  `IdPlanEstudio` int(11) NOT NULL,
  `Generacion` varchar(3) CHARACTER SET utf8 NOT NULL,
  `IdPaquete` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierospaquetesconceptos`
--

CREATE TABLE `financierospaquetesconceptos` (
  `IdPaquetesConceptos` int(11) NOT NULL,
  `IdPaquete` int(11) NOT NULL,
  `IdConcepto` int(11) NOT NULL,
  `Precio` decimal(18,2) NOT NULL,
  `NecesarioParaInscribirse` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierospromocionesbecas`
--

CREATE TABLE `financierospromocionesbecas` (
  `IdPromocionBeca` int(11) NOT NULL,
  `IdPromocion` int(11) NOT NULL,
  `IdCatalogo` smallint(6) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `Generacion1y2` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierospromocionesconceptos`
--

CREATE TABLE `financierospromocionesconceptos` (
  `IdPromocionConcepto` int(11) NOT NULL,
  `IdPromocion` int(11) NOT NULL,
  `IdConcepto` int(11) NOT NULL,
  `Costo` decimal(18,2) NOT NULL,
  `Cantidad` int(11) NOT NULL,
  `Activo` tinyint(4) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosrazonsocial`
--

CREATE TABLE `financierosrazonsocial` (
  `IdRazonSocial` int(11) NOT NULL,
  `Nombre` varchar(150) CHARACTER SET utf8 NOT NULL,
  `RFC` varchar(50) CHARACTER SET utf8 NOT NULL,
  `Domicilio` varchar(250) CHARACTER SET utf8 NOT NULL,
  `curp` varchar(50) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosrazonsocialpersonas`
--

CREATE TABLE `financierosrazonsocialpersonas` (
  `IdRazonSocialPersona` int(11) NOT NULL,
  `IdRazonSocial` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `Nota` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
  `Activo` tinyint(4) NOT NULL,
  `Fecha` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosrbconceptos`
--

CREATE TABLE `financierosrbconceptos` (
  `IdRBConcepto` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `Monto` decimal(18,2) NOT NULL,
  `Fecha` datetime NOT NULL,
  `IdCuenta` int(11) NOT NULL,
  `IdBanco` int(11) NOT NULL,
  `Observaciones` varchar(250) CHARACTER SET utf8 NOT NULL,
  `IdRazonSocial` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosrbconceptosdetalle`
--

CREATE TABLE `financierosrbconceptosdetalle` (
  `IdRBConceptoDetalle` int(11) NOT NULL,
  `IdRBConcepto` int(11) NOT NULL,
  `IdConcepto` int(11) NOT NULL,
  `CostoConcepto` decimal(18,2) NOT NULL,
  `Cantidad` smallint(6) NOT NULL,
  `Monto` decimal(18,2) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `IdPlanEstudio` int(11) NOT NULL,
  `ConceptoInscribe` tinyint(4) NOT NULL,
  `Cancelado` tinyint(4) NOT NULL,
  `IdPromocion` int(11) DEFAULT NULL,
  `Entregado` tinyint(4) DEFAULT NULL,
  `IdCobroProgramacion` int(11) DEFAULT NULL,
  `Tipo` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosrecursamientodeasignaturarbconceptosdetallematerias`
--

CREATE TABLE `financierosrecursamientodeasignaturarbconceptosdetallematerias` (
  `IdrecursamientoDeAsignaturaRBConceptosDetalleMaterias` int(11) NOT NULL,
  `IdRBConceptoDetalle` int(11) NOT NULL,
  `IdMateria` int(11) NOT NULL,
  `Pagada` tinyint(4) NOT NULL,
  `Cursada` tinyint(4) NOT NULL,
  `Aprobada` tinyint(4) NOT NULL,
  `IdGrupo` int(11) NOT NULL,
  `IdplanEstudios` int(11) NOT NULL,
  `IdAlumno` int(11) NOT NULL,
  `IdCobroDetalle` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosreferenciasbancarias`
--

CREATE TABLE `financierosreferenciasbancarias` (
  `IdReferncia` int(11) NOT NULL,
  `ReferenciaBancaria` varchar(100) CHARACTER SET utf8 NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `Monto` decimal(18,2) NOT NULL,
  `Pagado` tinyint(4) NOT NULL,
  `Cancelado` tinyint(4) NOT NULL,
  `IdRBEventoConfiguracion` int(11) NOT NULL,
  `IdFinanzas` int(11) DEFAULT NULL,
  `Observaciones` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
  `ArgumentoFinanzasVMaeVMov` longtext DEFAULT NULL,
  `IdRazonSocial` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosreferenciasbancariasconfiguracion`
--

CREATE TABLE `financierosreferenciasbancariasconfiguracion` (
  `IdReferenciaBancariaConfiguracion` int(11) NOT NULL,
  `NumeroEstablecimiento` varchar(50) CHARACTER SET utf8 NOT NULL,
  `TipoPago` varchar(50) CHARACTER SET utf8 NOT NULL,
  `IdBanco` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosreferenciasbancariaseventoconfiguracion`
--

CREATE TABLE `financierosreferenciasbancariaseventoconfiguracion` (
  `IdReferenciaBancariaEventoConfiguracion` int(11) NOT NULL,
  `IdReferenciaBancariaConfiguracion` int(11) NOT NULL,
  `IdReferenciaBancariaEvento` int(11) NOT NULL,
  `FechaLimitePago` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosreferenciasbancariaseventos`
--

CREATE TABLE `financierosreferenciasbancariaseventos` (
  `IdReferenciaBancariaEvento` int(11) NOT NULL,
  `Evento` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosreferenciasbancariasmovimientos`
--

CREATE TABLE `financierosreferenciasbancariasmovimientos` (
  `IdReferenciaMovimiento` int(11) NOT NULL,
  `IdMovimiento` int(11) NOT NULL,
  `Tipo` tinyint(3) UNSIGNED NOT NULL,
  `IdReferencia` int(11) NOT NULL,
  `IdRBMovimientoImportado` int(11) NOT NULL,
  `IdCobro` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosreferenciasbancariasmovimientoscuentaconcentradora`
--

CREATE TABLE `financierosreferenciasbancariasmovimientoscuentaconcentradora` (
  `idReferenciaMovimientoCuentaConcentradora` int(11) NOT NULL,
  `idRbConcepto` int(11) NOT NULL,
  `idReferencia` int(11) NOT NULL,
  `idReferenciaMovimientoImportadoCC` int(11) DEFAULT NULL,
  `idCobro` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierosreferenciasbancariasmovimientosimportados`
--

CREATE TABLE `financierosreferenciasbancariasmovimientosimportados` (
  `IdRBMovimientoImportado` int(11) NOT NULL,
  `Fecha` date NOT NULL,
  `Importe` decimal(18,2) NOT NULL,
  `Identificacion` varchar(50) CHARACTER SET utf8 NOT NULL,
  `Referencia` varchar(16) CHARACTER SET utf8 NOT NULL,
  `ReferenciaCuatrimestre` varchar(4) CHARACTER SET utf8 NOT NULL,
  `ReferenciaMovimiento` varchar(12) CHARACTER SET utf8 NOT NULL,
  `ReferenciaMovimientoTipo` tinyint(3) UNSIGNED NOT NULL,
  `FechaCorte` varchar(6) CHARACTER SET utf8 NOT NULL,
  `TipoPago` varchar(6) CHARACTER SET utf8 NOT NULL,
  `Sucursal` varchar(4) CHARACTER SET utf8 NOT NULL,
  `Cajero` varchar(2) CHARACTER SET utf8 NOT NULL,
  `Autorizacion` varchar(7) CHARACTER SET utf8 NOT NULL,
  `RegistroProcesado` tinyint(4) NOT NULL,
  `Relacionado` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierossaldoafavor`
--

CREATE TABLE `financierossaldoafavor` (
  `IdSaldoAFavor` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdPlanEstudio` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `IdConcepto` int(11) NOT NULL,
  `Monto` decimal(18,2) NOT NULL,
  `Fecha` date NOT NULL,
  `Nota` varchar(250) CHARACTER SET utf8 NOT NULL,
  `Aplicado` tinyint(4) NOT NULL,
  `IdCobro` int(11) NOT NULL,
  `IdRBConceptoDetalle` int(11) DEFAULT NULL,
  `Cancelado` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierostransportecostos`
--

CREATE TABLE `financierostransportecostos` (
  `IdTransporteCosto` int(11) NOT NULL,
  `IdRuta` int(11) NOT NULL,
  `BoletoTipo` int(11) NOT NULL,
  `Costo` int(11) NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierostransporterutas`
--

CREATE TABLE `financierostransporterutas` (
  `IdTransporteRuta` int(11) NOT NULL,
  `Ruta` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierostransportesolicitudcorte`
--

CREATE TABLE `financierostransportesolicitudcorte` (
  `IdTransporteSolicitudCorte` int(11) NOT NULL,
  `FechaInicio` date DEFAULT NULL,
  `FechaFin` date DEFAULT NULL,
  `VisibleInicio` datetime NOT NULL,
  `VisibleFin` datetime NOT NULL,
  `FechaIncioUso` date DEFAULT NULL,
  `FechaFinUso` date DEFAULT NULL,
  `DiasDeUso` int(11) DEFAULT NULL,
  `Activa` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `financierostransportesolicitudes`
--

CREATE TABLE `financierostransportesolicitudes` (
  `IdTransporteSolicitud` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdRuta` int(11) NOT NULL,
  `Hora` datetime DEFAULT NULL,
  `FechaInicio` date DEFAULT NULL,
  `FechaFin` date DEFAULT NULL,
  `IdBoletoTipo` int(11) NOT NULL,
  `Costo` decimal(18,2) NOT NULL,
  `Activo` tinyint(4) NOT NULL,
  `IdTransporteSolicitudCorte` int(11) NOT NULL,
  `Pagado` tinyint(4) DEFAULT NULL,
  `Folio` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `Parada` int(11) DEFAULT NULL,
  `IdPerfil` int(11) DEFAULT NULL,
  `FechaDePago_` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `horarios`
--

CREATE TABLE `horarios` (
  `idplan` double DEFAULT NULL,
  `idcuatrimestre` double DEFAULT NULL,
  `matricula` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `fecha` datetime(3) DEFAULT NULL,
  `descripcion` varchar(255) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `imagen`
--

CREATE TABLE `imagen` (
  `ID` int(11) NOT NULL,
  `FileName` varchar(50) DEFAULT NULL,
  `FilePath` varchar(200) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `informes`
--

CREATE TABLE `informes` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `log_cardex`
--

CREATE TABLE `log_cardex` (
  `idplan_estudios` int(11) NOT NULL,
  `idalumno` int(11) NOT NULL,
  `idmateria` int(11) NOT NULL,
  `calif_anterior` tinyint(3) UNSIGNED NOT NULL,
  `calif_nueva` tinyint(3) UNSIGNED NOT NULL,
  `fecha` datetime(3) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `migrations`
--

CREATE TABLE `migrations` (
  `id` int(10) UNSIGNED NOT NULL,
  `migration` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `migrations`
--

INSERT INTO `migrations` (`id`, `migration`, `batch`) VALUES
(4, '2014_10_12_000000_create_users_table', 1),
(5, '2014_10_12_100000_create_password_resets_table', 1),
(6, '2019_08_19_000000_create_failed_jobs_table', 1),
(7, '2020_01_15_031847_table_aspirantes', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `password_resets`
--

CREATE TABLE `password_resets` (
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personadomicilio`
--

CREATE TABLE `personadomicilio` (
  `iddomicilio` int(11) NOT NULL,
  `idpersona` int(11) NOT NULL,
  `calle` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `num_exterior` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `num_interior` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `colonia` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `cp` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `localidad` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `tipo` tinyint(3) UNSIGNED DEFAULT NULL,
  `idPais` smallint(6) NOT NULL,
  `idEstado` int(11) NOT NULL,
  `idmunicipio` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personadomicilio`
--

INSERT INTO `personadomicilio` (`iddomicilio`, `idpersona`, `calle`, `num_exterior`, `num_interior`, `colonia`, `cp`, `localidad`, `tipo`, `idPais`, `idEstado`, `idmunicipio`) VALUES
(1, 41, 'Fraccionamiento San Luisito Calle Michoacan #413', NULL, NULL, NULL, '87049', 'Victoria', 48, 1, 4, 24),
(2, 41, NULL, NULL, NULL, NULL, NULL, NULL, 49, 2, 33, 2476),
(3, 42, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(4, 43, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 3),
(5, 44, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 1, 1),
(6, 44, NULL, NULL, NULL, NULL, NULL, NULL, 49, 2, 33, 2476),
(7, 45, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 1, 1),
(8, 45, NULL, NULL, NULL, NULL, NULL, NULL, 49, 2, 33, 2476),
(9, 46, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 2, 14),
(10, 47, NULL, NULL, NULL, NULL, NULL, NULL, 49, 1, 1, 2),
(11, 48, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(12, 49, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(13, 50, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 2),
(14, 51, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(15, 52, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(16, 60, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, 18),
(17, 60, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(18, 61, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(19, 62, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(20, 63, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(21, 64, 'Fraccionamiento San Luisito Calle Michoacan #413', '555', '55', '44', '877777049', 'Victoria', 48, 1, 3, 18),
(22, 65, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(23, 66, NULL, NULL, NULL, NULL, NULL, NULL, 49, 2, 33, 2476),
(24, 67, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 16),
(25, 68, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(26, 69, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(27, 70, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 2, 16),
(28, 71, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 2),
(29, 72, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(30, 73, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(31, 74, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(32, 75, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(33, 76, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 4),
(34, 77, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(35, 78, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 2),
(36, 79, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 2),
(37, 80, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(38, 81, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(39, 82, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(40, 83, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(41, 84, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(42, 85, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(43, 86, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(44, 88, NULL, 's', NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(45, 89, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, 18),
(46, 90, NULL, NULL, NULL, NULL, NULL, NULL, 49, 1, 28, 2033),
(47, 91, 'Fraccionamiento San Luisito Calle Michoacan #413', NULL, NULL, NULL, '87049', 'Victoria', 48, 1, 28, 2033),
(48, 91, NULL, NULL, NULL, NULL, NULL, NULL, 49, 1, 33, 2476),
(49, 93, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 1, 3),
(50, 94, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 1, 1),
(51, 95, 'Fraccionamiento San Luisito Calle Michoacan #413', NULL, NULL, NULL, '87049', 'Victoria', 48, 2, 33, 2476),
(52, 96, NULL, NULL, NULL, NULL, NULL, NULL, 48, 2, 33, 2476),
(53, 97, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(54, 98, NULL, NULL, NULL, NULL, NULL, NULL, 49, 1, 2, 15),
(55, 99, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(56, 100, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 12),
(57, 101, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(58, 102, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 4),
(59, 103, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 15),
(60, 104, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(61, 105, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 2),
(62, 106, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 4, 2),
(63, 107, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 4),
(64, 75, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(65, 75, 'rfe', '54', '4', 'grfed', '765432', 'uyterweqw', 49, 1, 4, 23),
(66, 75, 'Fraccionamiento San Luisito Calle Michoacan #413', NULL, NULL, NULL, '87049', 'Victoria', NULL, 1, 1, 1),
(67, 75, NULL, NULL, NULL, '44', NULL, 'tamp', NULL, 1, 4, 5),
(68, 75, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, 7),
(69, 75, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 1),
(70, 130, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 15),
(71, 131, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 14),
(72, 132, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 15),
(73, 133, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 16),
(74, 134, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(75, 135, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 2),
(76, 136, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 3),
(77, 137, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 1, 3),
(78, 138, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 14),
(79, 139, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 16),
(80, 140, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 28, 2010),
(81, 141, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, 17),
(82, 142, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, 21),
(83, 143, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(84, 144, NULL, NULL, NULL, NULL, NULL, NULL, 48, 1, 20, 999),
(85, 145, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 2, 33, 2476),
(86, 146, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 13),
(87, 147, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 12),
(88, 148, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 2, 12),
(89, 152, NULL, NULL, NULL, NULL, NULL, 'ghfhjdgg', NULL, 1, 2, 14),
(90, 153, '555', NULL, NULL, 'PROFR. RAUL GARCIA Y PROFRA. ELIA GTZ', NULL, 'victoria', 48, 1, 2, 14);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personaempresas`
--

CREATE TABLE `personaempresas` (
  `idEmpresa` smallint(6) NOT NULL,
  `Empresa` varchar(250) CHARACTER SET utf8 NOT NULL,
  `Domicilio` longtext DEFAULT NULL,
  `Telefonos` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `Email` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `Observaciones` longtext DEFAULT NULL,
  `Activa` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personaempresas`
--

INSERT INTO `personaempresas` (`idEmpresa`, `Empresa`, `Domicilio`, `Telefonos`, `Email`, `Observaciones`, `Activa`) VALUES
(1, 'Cervezas de Victoria, S.A. De C.V.', 'NULL', '', '', 'NULL', 1),
(2, 'Construye de Victoria S.A. DE C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(3, 'Universidad Tecnológica del Mar de Tamaulipas Bicentenario', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(4, 'Secretaria de Educación de Tamulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(5, 'ABA Seguros', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(6, 'Acro Soluciones', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(7, 'BARDAHL', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(8, 'Brose México, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(9, 'Centro de Bachillerato Tecnológico industrial y de servicios Num. 236', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(10, 'Centro de Excelencia de la Universidad Autónoma de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(11, 'Centro de Innovación y Tecnología Educativa', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(12, 'Centro Nacional de Investigación y Desarrollo Tecnológico ', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(13, 'CINVESTAV, Querétaro', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(14, 'CINVESTAV, Unidad Tamaulipas, Laboratorio de Tecnologías de la Información', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(15, 'CISA Administración Integral', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(16, 'CIVIS Tecnologías de la Información, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(17, 'Coca-Cola México, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(18, 'Comisión Federal de Electricidad', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(19, 'Comisión Municipal de Agua Potable y Alcantarillado', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(20, 'Comisión Nacional Del Agua', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(21, 'Conectores Especializados S.A. DE C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(22, 'Continental Automotive Guadalajara México, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(23, 'Continental Guadalajara Services S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(24, 'Continental Tire de México, S.A. De C.V.  San Luis Potosí', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(25, 'Cruz Roja Mexicana', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(26, 'DELPHI Ensamble de cables y componentes S. de R.L. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(27, 'DELPHI Victoria II Ensamble de cables y componentes S.A. de R.L de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(28, 'DELPHI, Ensamble de Cables y Componentes Linares', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(29, 'Dirección de Educación a Distancia UAEM, DGED', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(30, 'Dirección de Sistemas Administrativos de la Rectoría de la U.A.T.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(31, 'Dirección General de Movilidad, Sistemas e Informática. Departamento de Programación', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(32, 'EBCOM LIMITED', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(33, 'EBCOMM S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(34, 'Electrónica y Automatización del Noreste, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(35, 'EMZ Hanauer de México de S.A de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(36, 'e-One Busines Solution, S.A. ', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(37, 'F.G.R. INGENIEROS S.A.de C.V', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(38, 'FANUC Robotics México, Aguascalientes', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(39, 'Flextronics S.A. de C.V', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(40, 'Ford S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(41, 'GAESCCO S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(42, 'Grupo INSOLME, San Luis Potosí ', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(43, 'H. Congreso del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(44, 'HARMAN De México  S. de R.L. de R.L. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(46, 'Hospital Regional de Alta Especialidad Bicentenario 2010', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(47, 'Htch Stamping México ', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(48, 'IDTec Automatización S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(49, 'IDTEC Automatización, S.A. De C.V., Monterrey', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(50, 'Impresora DONNECO International S. de R.L. C.V. Donnelley', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(51, 'Instituto Electoral del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(52, 'Instituto Tamaulipeco para la Capacitación del Empleo, Cd. Victoria', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(53, 'Integra de Victoria S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(54, 'Integradores Profesionales Asociados S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(55, 'ISCAR de México S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(56, 'Jabil Global Services de México, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(57, 'KEMET de México, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(58, 'Keveo.net', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(59, 'Kinetek de México, S. de R.L.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(60, 'MOTEC MEX', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(61, 'NETAFIM MÉXICO, S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(62, 'Opensoft, S.de R.L.M.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(63, 'Pas Providing Appliance Systems S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(64, 'Pentair Water Mexico, S.de  R.L. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(65, 'Petro Grúas Industriales G & G S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(66, 'PHI Automation, Querétaro', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(67, 'Procimart S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(68, 'Procuraduría General de Justicia de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(69, 'QuetzalcoaTech', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(70, 'REMY COMPONENTES, S. DE R.L. DE C.V. SAN LUIS POTOSI, S.L.P.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(71, 'Remy Componentes S. de R.L. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(72, 'REMY Componentes planta y fabricación', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(73, 'Remy International, Inc. S. de R.L de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(74, 'REMY Planta ensambles alternadores', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(75, 'SANMINA-SCI ', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(76, 'SCOUTECH S.A. DE C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(77, 'Secretaría de Desarrollo Urbano y Medio Ambiente', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(78, 'Secretaría de Salud de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(79, 'Secretaría de Educación Publica', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(80, 'Secretaría de Salud del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(81, 'Secretaría de Seguridad Pública', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(82, 'Secretaría de Turismo del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(83, 'Servicios Herramentales S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(84, 'Servicios Profesionales De Almacenamiento', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(85, 'SICA, Sistemas Industriales y Control Automático, Altamira, Tam.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(86, 'Sistema para el Desarrollo Integral de La Familia De Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(87, 'SOLIDES', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(88, 'SORTEL  S.A. de  CV.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(89, 'Steeringmex S. de R. L. de C. V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(90, 'Subsecretaría de Planeación de la Secretaria de Educación en Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(91, 'SVAM International de Mexico, S. de R.L. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(92, 'Talleres Industriales Braña S. de R.L. M.I. ', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(93, 'TEGIK S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(94, 'TELECOMS', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(95, 'Telemática Alcor', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(96, 'The capacitence company KEMET Charged', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(97, 'TRANSPAIS UNICO, S.A de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(98, 'Universidad Politécnica de Victoria', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(99, 'Universidad Politécnica de San Luis ', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(100, 'Universidad Tecnológica del Mar de Tamaulipas Bicentenario', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(101, 'UPYSSET, Unidad de Previsión y Seguridad Social del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(102, 'Valk Technologies', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(103, 'Whirpool, Saltillo, Coahuila', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(104, 'WILLIAM MARSH RICE UNIVERSITY', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(105, 'Cruz Roja Mexicana, Delegación Cd. Victoria', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(106, 'ECARESOFT México S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(107, 'H. Supremo Tribunal de Justicia del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(108, 'PAS Appliance Systems S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(109, 'Safran-Messier Bugatti Dowty', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(110, 'Soluciones en Ingeniería & Tecnología, S.C.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(111, 'Universidad La Salle', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(112, 'Springs Window Fashions de Victoria S. de R. L. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(113, 'Transpaís, Victoria,Tamps', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(114, 'ECARESOFT México S.A de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(115, 'Soluciones Hardware', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(116, 'CISA Administración General', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(117, 'DALKIA México', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(118, 'GOMCO FURNITURE INDUSTRIES S.A de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(119, 'Centro de Investigación de Estudios Avanzados, Unidad Tamaulipas (CINVESTAV)', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(120, 'ALCOM Electrónicos de México S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(121, 'Cepillos del Castor S.A. de C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(122, 'Centro Estatal de Tecnología  Educativa', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(123, 'Consultora Mexicana de Negocios S.C.', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(124, 'Archivo General e Histórico del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(125, 'Despacho Jurídico y Laboral', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(126, 'Centro de Control, Comando, Comunicaciones y Cómputo del Estado de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(127, 'Facultad de Ingeniería y Ciencias de la Universidad Autónoma de Tamaulipas', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(128, 'OTTO', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(129, 'LUBRICANTES DE AMERICA SA DE CV', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(130, 'PLAINFIELD PRECISIÓN, SA DE CV', 'NULL', 'NULL', 'NULL', 'NULL', 1),
(131, 'PROCESADORA DE SERVICIOS SOHAEVI (SOCIEDAD OPERADORA HOSPITAL REGIONAL DE ALTA ESPECIALIDAD VICTORIA) S.A. DE C.V.', 'NULL', 'NULL', 'NULL', 'NULL', 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personaestados`
--

CREATE TABLE `personaestados` (
  `idEstado` int(11) NOT NULL,
  `Estado` varchar(70) CHARACTER SET utf8 NOT NULL,
  `idPais` smallint(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personaestados`
--

INSERT INTO `personaestados` (`idEstado`, `Estado`, `idPais`) VALUES
(1, 'AGUASCALIENTES', 1),
(2, 'BAJA CALIFORNIA', 1),
(3, 'BAJA CALIFORNIA SUR', 1),
(4, 'CAMPECHE', 1),
(5, 'CHIAPAS', 1),
(6, 'CHIHUAHUA', 1),
(7, 'COAHUILA', 1),
(8, 'COLIMA', 1),
(9, 'DISTRITO FEDERAL', 1),
(10, 'DURANGO', 1),
(11, 'GUANAJUATO', 1),
(12, 'GUERRERO', 1),
(13, 'HIDALGO', 1),
(14, 'JALISCO', 1),
(15, 'MÉXICO', 1),
(16, 'MICHOACÁN', 1),
(17, 'MORELOS', 1),
(18, 'NAYARIT', 1),
(19, 'NUEVO LEÓN', 1),
(20, 'OAXACA', 1),
(21, 'PUEBLA', 1),
(22, 'QUERÉTARO', 1),
(23, 'QUINTANA ROO', 1),
(24, 'SAN LUIS POTOSÍ', 1),
(25, 'SINALOA', 1),
(26, 'SONORA', 1),
(27, 'TABASCO', 1),
(28, 'TAMAULIPAS', 1),
(29, 'TLAXCALA', 1),
(30, 'VERACRUZ', 1),
(31, 'YUCATÁN', 1),
(32, 'ZACATECAS', 1),
(33, 'EXTRANJERO', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personamunicipio`
--

CREATE TABLE `personamunicipio` (
  `idmunicipio` int(11) NOT NULL,
  `nombre` varchar(50) CHARACTER SET utf8 NOT NULL,
  `clave` int(11) NOT NULL,
  `idEstado` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personamunicipio`
--

INSERT INTO `personamunicipio` (`idmunicipio`, `nombre`, `clave`, `idEstado`) VALUES
(1, 'AGUASCALIENTES', 1, 1),
(2, 'ASIENTOS', 2, 1),
(3, 'CALVILLO', 3, 1),
(4, 'COSÍO', 4, 1),
(5, 'EL LLANO', 5, 1),
(6, 'JESÚS MARÍA', 6, 1),
(7, 'PABELLÓN DE ARTEAGA', 7, 1),
(8, 'RINCÓN DE ROMOS', 8, 1),
(9, 'SAN FRANCISCO DE LOS ROMO', 9, 1),
(10, 'SAN JOSÉ DE GRACIA', 10, 1),
(11, 'TEPEZALÁ', 11, 1),
(12, 'ENSENADA', 1, 2),
(13, 'MEXICALI', 2, 2),
(14, 'PLAYAS DE ROSARITO', 3, 2),
(15, 'TECATE', 4, 2),
(16, 'TIJUANA', 5, 2),
(17, 'COMONDÚ', 1, 3),
(18, 'LA PAZ', 2, 3),
(19, 'LORETO', 3, 3),
(20, 'LOS CABOS', 4, 3),
(21, 'MULEGÉ', 5, 3),
(22, 'CALAKMUL', 1, 4),
(23, 'CALKINÍ', 2, 4),
(24, 'CAMPECHE', 3, 4),
(25, 'CANDELARIA', 4, 4),
(26, 'CARMEN', 5, 4),
(27, 'CHAMPOTÓN', 6, 4),
(28, 'ESCÁRCEGA', 7, 4),
(29, 'HECELCHAKÁN', 8, 4),
(30, 'HOPELCHÉN', 9, 4),
(31, 'PALIZADA', 10, 4),
(32, 'TENABO', 11, 4),
(33, 'ACACOYAGUA', 1, 5),
(34, 'ACALA', 2, 5),
(35, 'ACAPETAHUA', 3, 5),
(36, 'ALTAMIRANO', 4, 5),
(37, 'AMATÁN', 5, 5),
(38, 'AMATENANGO DE LA FRONTERA', 6, 5),
(39, 'AMATENANGO DEL VALLE', 7, 5),
(40, 'ANGEL ALBINO CORZO', 8, 5),
(41, 'ARRIAGA', 9, 5),
(42, 'BEJUCAL DE OCAMPO', 10, 5),
(43, 'BELLA VISTA', 11, 5),
(44, 'BERRIOZÁBAL', 12, 5),
(45, 'BOCHIL', 13, 5),
(46, 'CACAHOATÁN', 14, 5),
(47, 'CATAZAJÁ', 15, 5),
(48, 'CHALCHIHUITÁN', 16, 5),
(49, 'CHAMULA', 17, 5),
(50, 'CHANAL', 18, 5),
(51, 'CHAPULTENANGO', 19, 5),
(52, 'CHENALHÓ', 20, 5),
(53, 'CHIAPA DE CORZO', 21, 5),
(54, 'CHIAPILLA', 22, 5),
(55, 'CHICOASÉN', 23, 5),
(56, 'CHICOMUSELO', 24, 5),
(57, 'CHILÓN', 25, 5),
(58, 'CINTALAPA', 26, 5),
(59, 'COAPILLA', 27, 5),
(60, 'COMITÁN DE DOMÍNGUEZ', 28, 5),
(61, 'COPAINALÁ', 29, 5),
(62, 'EL BOSQUE', 30, 5),
(63, 'EL PORVENIR', 31, 5),
(64, 'ESCUINTLA', 32, 5),
(65, 'FRANCISCO LEÓN', 33, 5),
(66, 'FRONTERA COMALAPA', 34, 5),
(67, 'FRONTERA HIDALGO', 35, 5),
(68, 'HUEHUETÁN', 36, 5),
(69, 'HUITIUPÁN', 37, 5),
(70, 'HUIXTÁN', 38, 5),
(71, 'HUIXTLA', 39, 5),
(72, 'IXHUATÁN', 40, 5),
(73, 'IXTACOMITÁN', 41, 5),
(74, 'IXTAPA', 42, 5),
(75, 'IXTAPANGAJOYA', 43, 5),
(76, 'JIQUIPILAS', 44, 5),
(77, 'JITOTOL', 45, 5),
(78, 'JUÁREZ', 46, 5),
(79, 'LA CONCORDIA', 47, 5),
(80, 'LA GRANDEZA', 48, 5),
(81, 'LA INDEPENDENCIA', 49, 5),
(82, 'LA LIBERTAD', 50, 5),
(83, 'LA TRINITARIA', 51, 5),
(84, 'LARRAINZAR', 52, 5),
(85, 'LAS MARGARITAS', 53, 5),
(86, 'LAS ROSAS', 54, 5),
(87, 'MAPASTEPEC', 55, 5),
(88, 'MAZAPA DE MADERO', 56, 5),
(89, 'MAZATÁN', 57, 5),
(90, 'METAPA', 58, 5),
(91, 'MITONTIC', 59, 5),
(92, 'MOTOZINTLA', 60, 5),
(93, 'NICOLÁS RUÍZ', 61, 5),
(94, 'OCOSINGO', 62, 5),
(95, 'OCOTEPEC', 63, 5),
(96, 'OCOZOCOAUTLA DE ESPINOSA', 64, 5),
(97, 'OSTUACÁN', 65, 5),
(98, 'OSUMACINTA', 66, 5),
(99, 'OXCHUC', 67, 5),
(100, 'PALENQUE', 68, 5),
(101, 'PANTELHÓ', 69, 5),
(102, 'PANTEPEC', 70, 5),
(103, 'PICHUCALCO', 71, 5),
(104, 'PIJIJIAPAN', 72, 5),
(105, 'PUEBLO NUEVO SOLISTAHUACÁN', 73, 5),
(106, 'RAYÓN', 74, 5),
(107, 'REFORMA', 75, 5),
(108, 'SABANILLA', 76, 5),
(109, 'SALTO DE AGUA', 77, 5),
(110, 'SAN CRISTÓBAL DE LAS CASAS', 78, 5),
(111, 'SAN FERNANDO', 79, 5),
(112, 'SAN JUAN CANCUC', 80, 5),
(113, 'SAN LUCAS', 81, 5),
(114, 'SILTEPEC', 82, 5),
(115, 'SIMOJOVEL', 83, 5),
(116, 'SITALÁ', 84, 5),
(117, 'SOCOLTENANGO', 85, 5),
(118, 'SOLOSUCHIAPA', 86, 5),
(119, 'SOYALÓ', 87, 5),
(120, 'SUCHIAPA', 88, 5),
(121, 'SUCHIATE', 89, 5),
(122, 'SUNUAPA', 90, 5),
(123, 'TAPACHULA', 91, 5),
(124, 'TAPALAPA', 92, 5),
(125, 'TAPILULA', 93, 5),
(126, 'TECPATÁN', 94, 5),
(127, 'TENEJAPA', 95, 5),
(128, 'TEOPISCA', 96, 5),
(129, 'TILA', 97, 5),
(130, 'TONALÁ', 98, 5),
(131, 'TOTOLAPA', 99, 5),
(132, 'TUMBALÁ', 100, 5),
(133, 'TUXTLA CHICO', 101, 5),
(134, 'TUXTLA GUTIÉRREZ', 102, 5),
(135, 'TUZANTÁN', 103, 5),
(136, 'TZIMOL', 104, 5),
(137, 'UNIÓN JUÁREZ', 105, 5),
(138, 'VENUSTIANO CARRANZA', 106, 5),
(139, 'VILLA COMALTITLÁN', 107, 5),
(140, 'VILLA CORZO', 108, 5),
(141, 'VILLAFLORES', 109, 5),
(142, 'YAJALÓN', 110, 5),
(143, 'ZINACANTÁN', 111, 5),
(144, 'AHUMADA', 1, 6),
(145, 'ALDAMA', 2, 6),
(146, 'ALLENDE', 3, 6),
(147, 'AQUILES SERDÁN', 4, 6),
(148, 'ASCENSIÓN', 5, 6),
(149, 'BACHÍNIVA', 6, 6),
(150, 'BALLEZA', 7, 6),
(151, 'BATOPILAS', 8, 6),
(152, 'BOCOYNA', 9, 6),
(153, 'BUENAVENTURA', 10, 6),
(154, 'CAMARGO', 11, 6),
(155, 'CARICHI', 12, 6),
(156, 'CASAS GRANDES', 13, 6),
(157, 'CHIHUAHUA', 14, 6),
(158, 'CHÍNIPAS', 15, 6),
(159, 'CORONADO', 16, 6),
(160, 'COYAME', 17, 6),
(161, 'CUAUHTÉMOC', 18, 6),
(162, 'CUSIHUIRIÁCHI', 19, 6),
(163, 'DELICIAS', 20, 6),
(164, 'DOCTOR BELISARIO DOMÍNGUEZ', 21, 6),
(165, 'EL TULE', 22, 6),
(166, 'GALEANA', 23, 6),
(167, 'GÓMEZ FARÍAS', 24, 6),
(168, 'GRAN MORELOS', 25, 6),
(169, 'GUACHOCHI', 26, 6),
(170, 'GUADALUPE', 27, 6),
(171, 'GUADALUPE Y CALVO', 28, 6),
(172, 'GUAZAPARES', 29, 6),
(173, 'GUERRERO', 30, 6),
(174, 'HIDALGO DEL PARRAL', 31, 6),
(175, 'HUEJOTITÁN', 32, 6),
(176, 'IGNACIO ZARAGOZA', 33, 6),
(177, 'JANOS', 34, 6),
(178, 'JIMÉNEZ', 35, 6),
(179, 'JUÁREZ', 36, 6),
(180, 'JULIMES', 37, 6),
(181, 'LA CRUZ', 38, 6),
(182, 'LÓPEZ', 39, 6),
(183, 'MADERA', 40, 6),
(184, 'MAGUARICHI', 41, 6),
(185, 'MANUEL BENAVIDES', 42, 6),
(186, 'MATACHI', 43, 6),
(187, 'MATAMOROS', 44, 6),
(188, 'MEOQUI', 45, 6),
(189, 'MORELOS', 46, 6),
(190, 'MORIS', 47, 6),
(191, 'NAMIQUIPA', 48, 6),
(192, 'NONOAVA', 49, 6),
(193, 'NUEVO CASAS GRANDES', 50, 6),
(194, 'OCAMPO', 51, 6),
(195, 'OJINAGA', 52, 6),
(196, 'PRAXEDIS G. GUERRERO', 53, 6),
(197, 'RIVA PALACIO', 54, 6),
(198, 'ROSALES', 55, 6),
(199, 'ROSARIO', 56, 6),
(200, 'SAN FRANCISCO DE BORJA', 57, 6),
(201, 'SAN FRANCISCO DE CONCHOS', 58, 6),
(202, 'SAN FRANCISCO DEL ORO', 59, 6),
(203, 'SANTA BÁRBARA', 60, 6),
(204, 'SANTA ISABEL', 61, 6),
(205, 'SATEVÓ', 62, 6),
(206, 'SAUCILLO', 63, 6),
(207, 'TEMÓSACHI', 64, 6),
(208, 'URIQUE', 65, 6),
(209, 'URUÁCHI', 66, 6),
(210, 'VALLE DE ZARAGOZA', 67, 6),
(211, 'ABASOLO', 1, 7),
(212, 'ACUÑA', 2, 7),
(213, 'ALLENDE', 3, 7),
(214, 'ARTEAGA', 4, 7),
(215, 'CANDELA', 5, 7),
(216, 'CASTAÑOS', 6, 7),
(217, 'CUATROCIÉNEGAS', 7, 7),
(218, 'ESCOBEDO', 8, 7),
(219, 'FRANCISCO I. MADERO', 9, 7),
(220, 'FRONTERA', 10, 7),
(221, 'GENERAL CEPEDA', 11, 7),
(222, 'GUERRERO', 12, 7),
(223, 'HIDALGO', 13, 7),
(224, 'JIMÉNEZ', 14, 7),
(225, 'JUÁREZ', 15, 7),
(226, 'LAMADRID', 16, 7),
(227, 'MATAMOROS', 17, 7),
(228, 'MONCLOVA', 18, 7),
(229, 'MORELOS', 19, 7),
(230, 'MÚZQUIZ', 20, 7),
(231, 'NADADORES', 21, 7),
(232, 'NAVA', 22, 7),
(233, 'OCAMPO', 23, 7),
(234, 'PARRAS', 24, 7),
(235, 'PIEDRAS NEGRAS', 25, 7),
(236, 'PROGRESO', 26, 7),
(237, 'RAMOS ARIZPE', 27, 7),
(238, 'SABINAS', 28, 7),
(239, 'SACRAMENTO', 29, 7),
(240, 'SALTILLO', 30, 7),
(241, 'SAN BUENAVENTURA', 31, 7),
(242, 'SAN JUAN DE SABINAS', 32, 7),
(243, 'SAN PEDRO', 33, 7),
(244, 'SIERRA MOJADA', 34, 7),
(245, 'TORREÓN', 35, 7),
(246, 'VIESCA', 36, 7),
(247, 'VILLA UNIÓN', 37, 7),
(248, 'ZARAGOZA', 38, 7),
(249, 'ARMERÍA', 1, 8),
(250, 'COLIMA', 2, 8),
(251, 'COMALA', 3, 8),
(252, 'COQUIMATLÁN', 4, 8),
(253, 'CUAUHTÉMOC', 5, 8),
(254, 'IXTLAHUACÁN', 6, 8),
(255, 'MANZANILLO', 7, 8),
(256, 'MINATITLÁN', 8, 8),
(257, 'TECOMÁN', 9, 8),
(258, 'VILLA DE ALVAREZ', 10, 8),
(259, 'ALVARO OBREGÓN', 1, 9),
(260, 'AZCAPOTZALCO', 2, 9),
(261, 'BENITO JUÁREZ', 3, 9),
(262, 'COYOACÁN', 4, 9),
(263, 'CUAJIMALPA', 5, 9),
(264, 'CUAJIMALPA DE MORELOS', 6, 9),
(265, 'CUAUHTÉMOC', 7, 9),
(266, 'GUSTAVO A. MADERO', 8, 9),
(267, 'IZTACALCO', 9, 9),
(268, 'IZTAPALAPA', 10, 9),
(269, 'LA MAGDALENA CONTRERAS', 11, 9),
(270, 'MIGUEL HIDALGO', 12, 9),
(271, 'MILPA ALTA', 13, 9),
(272, 'TLÁHUAC', 14, 9),
(273, 'TLALPAN', 15, 9),
(274, 'VENUSTIANO CARRANZA', 16, 9),
(275, 'XOCHIMILCO', 17, 9),
(276, 'CANATLÁN', 1, 10),
(277, 'CANELAS', 2, 10),
(278, 'CONETO DE COMONFORT', 3, 10),
(279, 'CUENCAMÉ', 4, 10),
(280, 'DURANGO', 5, 10),
(281, 'EL ORO', 6, 10),
(282, 'GENERAL SIMÓN BOLÍVAR', 7, 10),
(283, 'GÓMEZ PALACIO', 8, 10),
(284, 'GUADALUPE VICTORIA', 9, 10),
(285, 'GUANACEVÍ', 10, 10),
(286, 'HIDALGO', 11, 10),
(287, 'INDÉ', 12, 10),
(288, 'LERDO', 13, 10),
(289, 'MAPIMÍ', 14, 10),
(290, 'MEZQUITAL', 15, 10),
(291, 'NAZAS', 16, 10),
(292, 'NOMBRE DE DIOS', 17, 10),
(293, 'NUEVO IDEAL', 18, 10),
(294, 'OCAMPO', 19, 10),
(295, 'OTÁEZ', 20, 10),
(296, 'PÁNUCO DE CORONADO', 21, 10),
(297, 'PEÑÓN BLANCO', 22, 10),
(298, 'POANAS', 23, 10),
(299, 'PUEBLO NUEVO', 24, 10),
(300, 'RODEO', 25, 10),
(301, 'SAN BERNARDO', 26, 10),
(302, 'SAN DIMAS', 27, 10),
(303, 'SAN JUAN DE GUADALUPE', 28, 10),
(304, 'SAN JUAN DEL RÍO', 29, 10),
(305, 'SAN LUIS DEL CORDERO', 30, 10),
(306, 'SAN PEDRO DEL GALLO', 31, 10),
(307, 'SANTA CLARA', 32, 10),
(308, 'SANTIAGO PAPASQUIARO', 33, 10),
(309, 'SÚCHIL', 34, 10),
(310, 'TAMAZULA', 35, 10),
(311, 'TEPEHUANES', 36, 10),
(312, 'TLAHUALILO', 37, 10),
(313, 'TOPIA', 38, 10),
(314, 'VICENTE GUERRERO', 39, 10),
(315, 'ABASOLO', 1, 11),
(316, 'ACÁMBARO', 2, 11),
(317, 'ALLENDE', 3, 11),
(318, 'APASEO EL ALTO', 4, 11),
(319, 'APASEO EL GRANDE', 5, 11),
(320, 'ATARJEA', 6, 11),
(321, 'CELAYA', 7, 11),
(322, 'CIUDAD MANUEL DOBLADO', 8, 11),
(323, 'COMONFORT', 9, 11),
(324, 'CORONEO', 10, 11),
(325, 'CORTAZAR', 11, 11),
(326, 'CUERÁMARO', 12, 11),
(327, 'DOCTOR MORA', 13, 11),
(328, 'DOLORES HIDALGO', 14, 11),
(329, 'GUANAJUATO', 15, 11),
(330, 'HUANÍMARO', 16, 11),
(331, 'IRAPUATO', 17, 11),
(332, 'JARAL DEL PROGRESO', 18, 11),
(333, 'JERÉCUARO', 19, 11),
(334, 'LEÓN', 20, 11),
(335, 'MANUEL DOBLADO', 21, 11),
(336, 'MOROLEÓN', 22, 11),
(337, 'OCAMPO', 23, 11),
(338, 'PÉNJAMO', 24, 11),
(339, 'PUEBLO NUEVO', 25, 11),
(340, 'PURÍSIMA DEL RINCÓN', 26, 11),
(341, 'ROMITA', 27, 11),
(342, 'SALAMANCA', 28, 11),
(343, 'SALVATIERRA', 29, 11),
(344, 'SAN DIEGO DE LA UNIÓN', 30, 11),
(345, 'SAN FELIPE', 31, 11),
(346, 'SAN FRANCISCO DEL RINCÓN', 32, 11),
(347, 'SAN JOSÉ ITURBIDE', 33, 11),
(348, 'SAN LUIS DE LA PAZ', 34, 11),
(349, 'SANTA CATARINA', 35, 11),
(350, 'SANTA CRUZ DE JUVENTINO ROSAS', 36, 11),
(351, 'SANTIAGO MARAVATÍO', 37, 11),
(352, 'SILAO', 38, 11),
(353, 'TARANDACUAO', 39, 11),
(354, 'TARIMORO', 40, 11),
(355, 'TIERRA BLANCA', 41, 11),
(356, 'TIERRABLANCA', 42, 11),
(357, 'URIANGATO', 43, 11),
(358, 'VALLE DE SANTIAGO', 44, 11),
(359, 'VICTORIA', 45, 11),
(360, 'VILLAGRÁN', 46, 11),
(361, 'XICHÚ', 47, 11),
(362, 'YURIRIA', 48, 11),
(363, 'ACAPULCO DE JUÁREZ', 1, 12),
(364, 'ACATEPEC', 2, 12),
(365, 'AHUACUOTZINGO', 3, 12),
(366, 'AJUCHITLÁN DEL PROGRESO', 4, 12),
(367, 'ALCOZAUCA DE GUERRERO', 5, 12),
(368, 'ALPOYECA', 6, 12),
(369, 'APAXTLA', 7, 12),
(370, 'ARCELIA', 8, 12),
(371, 'ATENANGO DEL RÍO', 9, 12),
(372, 'ATLAMAJALCINGO DEL MONTE', 10, 12),
(373, 'ATLIXTAC', 11, 12),
(374, 'ATOYAC DE ALVAREZ', 12, 12),
(375, 'AYUTLA DE LOS LIBRES', 13, 12),
(376, 'AZOYÚ', 14, 12),
(377, 'BENITO JUÁREZ', 15, 12),
(378, 'BUENAVISTA DE CUÉLLAR', 16, 12),
(379, 'CHILAPA DE ALVAREZ', 17, 12),
(380, 'CHILPANCINGO DE LOS BRAVO', 18, 12),
(381, 'COAHUAYUTLA DE JOSÉ MARÍA IZAZAGA', 19, 12),
(382, 'COCULA', 20, 12),
(383, 'COPALA', 21, 12),
(384, 'COPALILLO', 22, 12),
(385, 'COPANATOYAC', 23, 12),
(386, 'COYUCA DE BENÍTEZ', 24, 12),
(387, 'COYUCA DE CATALÁN', 25, 12),
(388, 'CUAJINICUILAPA', 26, 12),
(389, 'CUALÁC', 27, 12),
(390, 'CUAUTEPEC', 28, 12),
(391, 'CUETZALA DEL PROGRESO', 29, 12),
(392, 'CUTZAMALA DE PINZÓN', 30, 12),
(393, 'EDUARDO NERI', 31, 12),
(394, 'FLORENCIO VILLARREAL', 32, 12),
(395, 'GENERAL CANUTO A. NERI', 33, 12),
(396, 'GENERAL HELIODORO CASTILLO', 34, 12),
(397, 'HUAMUXTITLÁN', 35, 12),
(398, 'HUITZUCO DE LOS FIGUEROA', 36, 12),
(399, 'IGUALA DE LA INDEPENDENCIA', 37, 12),
(400, 'IGUALAPA', 38, 12),
(401, 'IXCATEOPAN DE CUAUHTÉMOC', 39, 12),
(402, 'JOSÉ AZUETA', 40, 12),
(403, 'JUAN R. ESCUDERO', 41, 12),
(404, 'LA UNIÓN DE ISIDORO MONTES DE OCA', 42, 12),
(405, 'LEONARDO BRAVO', 43, 12),
(406, 'MALINALTEPEC', 44, 12),
(407, 'MÁRTIR DE CUILAPAN', 45, 12),
(408, 'METLATÓNOC', 46, 12),
(409, 'MOCHITLÁN', 47, 12),
(410, 'OLINALÁ', 48, 12),
(411, 'OMETEPEC', 49, 12),
(412, 'PEDRO ASCENCIO ALQUISIRAS', 50, 12),
(413, 'PETATLÁN', 51, 12),
(414, 'PILCAYA', 52, 12),
(415, 'PUNGARABATO', 53, 12),
(416, 'QUECHULTENANGO', 54, 12),
(417, 'SAN LUIS ACATLÁN', 55, 12),
(418, 'SAN MARCOS', 56, 12),
(419, 'SAN MIGUEL TOTOLAPAN', 57, 12),
(420, 'TAXCO DE ALARCÓN', 58, 12),
(421, 'TECOANAPA', 59, 12),
(422, 'TECPAN DE GALEANA', 60, 12),
(423, 'TELOLOAPAN', 61, 12),
(424, 'TEPECOACUILCO DE TRUJANO', 62, 12),
(425, 'TETIPAC', 63, 12),
(426, 'TIXTLA DE GUERRERO', 64, 12),
(427, 'TLACOACHISTLAHUACA', 65, 12),
(428, 'TLACOAPA', 66, 12),
(429, 'TLALCHAPA', 67, 12),
(430, 'TLALIXTAQUILLA DE MALDONADO', 68, 12),
(431, 'TLAPA DE COMONFORT', 69, 12),
(432, 'TLAPEHUALA', 70, 12),
(433, 'XALPATLÁHUAC', 71, 12),
(434, 'XOCHIHUEHUETLÁN', 72, 12),
(435, 'XOCHISTLAHUACA', 73, 12),
(436, 'ZAPOTITLÁN TABLAS', 74, 12),
(437, 'ZIRÁNDARO', 75, 12),
(438, 'ZITLALA', 76, 12),
(439, 'ZUMPANGO DEL RIO', 77, 12),
(440, 'ACATLÁN', 1, 13),
(441, 'ACAXOCHITLÁN', 2, 13),
(442, 'ACTOPAN', 3, 13),
(443, 'AGUA BLANCA DE ITURBIDE', 4, 13),
(444, 'AJACUBA', 5, 13),
(445, 'ALFAJAYUCAN', 6, 13),
(446, 'ALMOLOYA', 7, 13),
(447, 'APAN', 8, 13),
(448, 'ATITALAQUIA', 9, 13),
(449, 'ATLAPEXCO', 10, 13),
(450, 'ATOTONILCO DE TULA', 11, 13),
(451, 'ATOTONILCO EL GRANDE', 12, 13),
(452, 'CALNALI', 13, 13),
(453, 'CARDONAL', 14, 13),
(454, 'CHAPANTONGO', 15, 13),
(455, 'CHAPULHUACÁN', 16, 13),
(456, 'CHILCUAUTLA', 17, 13),
(457, 'CUAUTEPEC DE HINOJOSA', 18, 13),
(458, 'EL ARENAL', 19, 13),
(459, 'ELOXOCHITLÁN', 20, 13),
(460, 'EMILIANO ZAPATA', 21, 13),
(461, 'EPAZOYUCAN', 22, 13),
(462, 'FRANCISCO I. MADERO', 23, 13),
(463, 'HUASCA DE OCAMPO', 24, 13),
(464, 'HUAUTLA', 25, 13),
(465, 'HUAZALINGO', 26, 13),
(466, 'HUEHUETLA', 27, 13),
(467, 'HUEJUTLA DE REYES', 28, 13),
(468, 'HUICHAPAN', 29, 13),
(469, 'IXMIQUILPAN', 30, 13),
(470, 'JACALA DE LEDEZMA', 31, 13),
(471, 'JALTOCÁN', 32, 13),
(472, 'JUÁREZ HIDALGO', 33, 13),
(473, 'LA MISION', 34, 13),
(474, 'LOLOTLA', 35, 13),
(475, 'METEPEC', 36, 13),
(476, 'METZTITLÁN', 37, 13),
(477, 'MINERAL DE LA REFORMA', 38, 13),
(478, 'MINERAL DEL CHICO', 39, 13),
(479, 'MINERAL DEL MONTE', 40, 13),
(480, 'MIXQUIAHUALA DE JUÁREZ', 41, 13),
(481, 'MOLANGO DE ESCAMILLA', 42, 13),
(482, 'NICOLÁS FLORES', 43, 13),
(483, 'NOPALA DE VILLAGRÁN', 44, 13),
(484, 'OMITLÁN DE JUÁREZ', 45, 13),
(485, 'PACHUCA DE SOTO', 46, 13),
(486, 'PACULA', 47, 13),
(487, 'PISAFLORES', 48, 13),
(488, 'PROGRESO DE OBREGÓN', 49, 13),
(489, 'SAN AGUSTÍN METZQUITITLÁN', 50, 13),
(490, 'SAN AGUSTÍN TLAXIACA', 51, 13),
(491, 'SAN BARTOLO TUTOTEPEC', 52, 13),
(492, 'SAN FELIPE ORIZATLÁN', 53, 13),
(493, 'SAN SALVADOR', 54, 13),
(494, 'SANTIAGO DE ANAYA', 55, 13),
(495, 'SANTIAGO TULANTEPEC DE LUGO GUERRERO', 56, 13),
(496, 'SINGUILUCAN', 57, 13),
(497, 'TASQUILLO', 58, 13),
(498, 'TECOZAUTLA', 59, 13),
(499, 'TENANGO DE DORIA', 60, 13),
(500, 'TEPEAPULCO', 61, 13),
(501, 'TEPEHUACÁN DE GUERRERO', 62, 13),
(502, 'TEPEJI DEL RÍO DE OCAMPO', 63, 13),
(503, 'TEPETITLÁN', 64, 13),
(504, 'TETEPANGO', 65, 13),
(505, 'TEZONTEPEC DE ALDAMA', 66, 13),
(506, 'TIANGUISTENGO', 67, 13),
(507, 'TIZAYUCA', 68, 13),
(508, 'TLAHUELILPAN', 69, 13),
(509, 'TLAHUILTEPA', 70, 13),
(510, 'TLANALAPA', 71, 13),
(511, 'TLANCHINOL', 72, 13),
(512, 'TLAXCOAPAN', 73, 13),
(513, 'TOLCAYUCA', 74, 13),
(514, 'TULA DE ALLENDE', 75, 13),
(515, 'TULANCINGO DE BRAVO', 76, 13),
(516, 'VILLA DE TEZONTEPEC', 77, 13),
(517, 'XOCHIATIPAN', 78, 13),
(518, 'XOCHICOATLÁN', 79, 13),
(519, 'YAHUALICA', 80, 13),
(520, 'ZACUALTIPÁN DE ANGELES', 81, 13),
(521, 'ZAPOTLÁN DE JUÁREZ', 82, 13),
(522, 'ZEMPOALA', 83, 13),
(523, 'ZIMAPÁN', 84, 13),
(524, 'ACATIC', 1, 14),
(525, 'ACATLÁN DE JUÁREZ', 2, 14),
(526, 'AHUALULCO DE MERCADO', 3, 14),
(527, 'AMACUECA', 4, 14),
(528, 'AMATITÁN', 5, 14),
(529, 'AMECA', 6, 14),
(530, 'ANTONIO ESCOBEDO', 7, 14),
(531, 'ARANDAS', 8, 14),
(532, 'ARENAL', 9, 14),
(533, 'ATEMAJAC DE BRIZUELA', 10, 14),
(534, 'ATENGO', 11, 14),
(535, 'ATENGUILLO', 12, 14),
(536, 'ATOTONILCO EL ALTO', 13, 14),
(537, 'ATOYAC', 14, 14),
(538, 'AUTLÁN DE NAVARRO', 15, 14),
(539, 'AYOTLÁN', 16, 14),
(540, 'AYUTLA', 17, 14),
(541, 'BOLAÑOS', 18, 14),
(542, 'CABO CORRIENTES', 19, 14),
(543, 'CAÑADAS DE OBREGÓN', 20, 14),
(544, 'CASIMIRO CASTILLO', 21, 14),
(545, 'CHAPALA', 22, 14),
(546, 'CHIMALTITÁN', 23, 14),
(547, 'CHIQUILISTLÁN', 24, 14),
(548, 'CIHUATLÁN', 25, 14),
(549, 'CIUDAD GUZMÁN', 26, 14),
(550, 'CIUDAD GUZMAN (ZAPOTLAN EL GRANDE)', 27, 14),
(551, 'COCULA', 28, 14),
(552, 'COLOTLÁN', 29, 14),
(553, 'CONCEPCIÓN DE BUENOS AIRES', 30, 14),
(554, 'CUAUTITLÁN DE GARCÍA BARRAGÁN', 31, 14),
(555, 'CUAUTLA', 32, 14),
(556, 'CUQUÍO', 33, 14),
(557, 'DEGOLLADO', 34, 14),
(558, 'EJUTLA', 35, 14),
(559, 'EL GRULLO', 36, 14),
(560, 'EL LIMÓN', 37, 14),
(561, 'EL SALTO', 38, 14),
(562, 'ENCARNACIÓN DE DÍAZ', 39, 14),
(563, 'ETZATLÁN', 40, 14),
(564, 'GÓMEZ FARÍAS', 41, 14),
(565, 'GUACHINANGO', 42, 14),
(566, 'GUADALAJARA', 43, 14),
(567, 'HOSTOTIPAQUILLO', 44, 14),
(568, 'HUEJÚCAR', 45, 14),
(569, 'HUEJUQUILLA EL ALTO', 46, 14),
(570, 'IXTLAHUACÁN DE LOS MEMBRILLOS', 47, 14),
(571, 'IXTLAHUACÁN DEL RÍO', 48, 14),
(572, 'JALOSTOTITLÁN', 49, 14),
(573, 'JAMAY', 50, 14),
(574, 'JESÚS MARÍA', 51, 14),
(575, 'JILOTLÁN DE LOS DOLORES', 52, 14),
(576, 'JOCOTEPEC', 53, 14),
(577, 'JUANACATLÁN', 54, 14),
(578, 'JUCHITLÁN', 55, 14),
(579, 'LA BARCA', 56, 14),
(580, 'LA HUERTA', 57, 14),
(581, 'LA MANZANILLA DE LA PAZ', 58, 14),
(582, 'LAGOS DE MORENO', 59, 14),
(583, 'MAGDALENA', 60, 14),
(584, 'MANUEL M. DIÉGUEZ', 61, 14),
(585, 'MASCOTA', 62, 14),
(586, 'MAZAMITLA', 63, 14),
(587, 'MEXTICACÁN', 64, 14),
(588, 'MEZQUITIC', 65, 14),
(589, 'MIXTLÁN', 66, 14),
(590, 'OCOTLÁN', 67, 14),
(591, 'OJUELOS DE JALISCO', 68, 14),
(592, 'PIHUAMO', 69, 14),
(593, 'PONCITLÁN', 70, 14),
(594, 'PUERTO VALLARTA', 71, 14),
(595, 'QUITUPAN', 72, 14),
(596, 'SAN CRISTÓBAL DE LA BARRANCA', 73, 14),
(597, 'SAN DIEGO DE ALEJANDRÍA', 74, 14),
(598, 'SAN GABRIEL', 75, 14),
(599, 'SAN JUAN DE LOS LAGOS', 76, 14),
(600, 'SAN JULIÁN', 77, 14),
(601, 'SAN MARCOS', 78, 14),
(602, 'SAN MARTÍN DE BOLAÑOS', 79, 14),
(603, 'SAN MARTÍN HIDALGO', 80, 14),
(604, 'SAN MIGUEL EL ALTO', 81, 14),
(605, 'SAN SEBASTIÁN DEL OESTE', 82, 14),
(606, 'SANTA MARÍA DE LOS ANGELES', 83, 14),
(607, 'SANTA MARIA DEL ORO', 84, 14),
(608, 'SAYULA', 85, 14),
(609, 'TALA', 86, 14),
(610, 'TALPA DE ALLENDE', 87, 14),
(611, 'TAMAZULA DE GORDIANO', 88, 14),
(612, 'TAPALPA', 89, 14),
(613, 'TECALITLÁN', 90, 14),
(614, 'TECHALUTA DE MONTENEGRO', 91, 14),
(615, 'TECOLOTLÁN', 92, 14),
(616, 'TENAMAXTLÁN', 93, 14),
(617, 'TEOCALTICHE', 94, 14),
(618, 'TEOCUITATLÁN DE CORONA', 95, 14),
(619, 'TEPATITLÁN DE MORELOS', 96, 14),
(620, 'TEQUILA', 97, 14),
(621, 'TEUCHITLÁN', 98, 14),
(622, 'TIZAPÁN EL ALTO', 99, 14),
(623, 'TLAJOMULCO DE ZUÑIGA', 100, 14),
(624, 'TLAQUEPAQUE', 101, 14),
(625, 'TOLIMÁN', 102, 14),
(626, 'TOMATLÁN', 103, 14),
(627, 'TONALÁ', 104, 14),
(628, 'TONAYA', 105, 14),
(629, 'TONILA', 106, 14),
(630, 'TOTATICHE', 107, 14),
(631, 'TOTOTLÁN', 108, 14),
(632, 'TUXCACUESCO', 109, 14),
(633, 'TUXCUECA', 110, 14),
(634, 'TUXPAN', 111, 14),
(635, 'UNIÓN DE SAN ANTONIO', 112, 14),
(636, 'UNIÓN DE TULA', 113, 14),
(637, 'VALLE DE GUADALUPE', 114, 14),
(638, 'VALLE DE JUÁREZ', 115, 14),
(639, 'VENUSTIANO CARRANZA', 116, 14),
(640, 'VILLA CORONA', 117, 14),
(641, 'VILLA GUERRERO', 118, 14),
(642, 'VILLA HIDALGO', 119, 14),
(643, 'VILLA PURIFICACIÓN', 120, 14),
(644, 'YAHUALICA DE GONZÁLEZ GALLO', 121, 14),
(645, 'ZACOALCO DE TORRES', 122, 14),
(646, 'ZAPOPAN', 123, 14),
(647, 'ZAPOTILTIC', 124, 14),
(648, 'ZAPOTITLÁN DE VADILLO', 125, 14),
(649, 'ZAPOTLÁN DEL REY', 126, 14),
(650, 'ZAPOTLANEJO', 127, 14),
(651, 'ACAMBAY', 1, 15),
(652, 'ACOLMAN', 2, 15),
(653, 'ACULCO', 3, 15),
(654, 'ALMOLOYA DE ALQUISIRAS', 4, 15),
(655, 'ALMOLOYA DE JUÁREZ', 5, 15),
(656, 'ALMOLOYA DEL RÍO', 6, 15),
(657, 'AMANALCO', 7, 15),
(658, 'AMATEPEC', 8, 15),
(659, 'AMECAMECA', 9, 15),
(660, 'APAXCO', 10, 15),
(661, 'ATENCO', 11, 15),
(662, 'ATIZAPÁN', 12, 15),
(663, 'ATIZAPÁN DE ZARAGOZA', 13, 15),
(664, 'ATLACOMULCO', 14, 15),
(665, 'ATLAUTLA', 15, 15),
(666, 'AXAPUSCO', 16, 15),
(667, 'AYAPANGO', 17, 15),
(668, 'CALIMAYA', 18, 15),
(669, 'CAPULHUAC', 19, 15),
(670, 'CHALCO', 20, 15),
(671, 'CHAPA DE MOTA', 21, 15),
(672, 'CHAPULTEPEC', 22, 15),
(673, 'CHIAUTLA', 23, 15),
(674, 'CHICOLOAPAN', 24, 15),
(675, 'CHICONCUAC', 25, 15),
(676, 'CHIMALHUACÁN', 26, 15),
(677, 'COACALCO DE BERRIOZÁBAL', 27, 15),
(678, 'COATEPEC HARINAS', 28, 15),
(679, 'COCOTITLÁN', 29, 15),
(680, 'COYOTEPEC', 30, 15),
(681, 'CUAUTITLÁN', 31, 15),
(682, 'CUAUTITLÁN IZCALLI', 32, 15),
(683, 'DONATO GUERRA', 33, 15),
(684, 'ECATEPEC', 34, 15),
(685, 'ECATZINGO', 35, 15),
(686, 'EL ORO', 36, 15),
(687, 'HUEHUETOCA', 37, 15),
(688, 'HUEYPOXTLA', 38, 15),
(689, 'HUIXQUILUCAN', 39, 15),
(690, 'ISIDRO FABELA', 40, 15),
(691, 'IXTAPALUCA', 41, 15),
(692, 'IXTAPAN DE LA SAL', 42, 15),
(693, 'IXTAPAN DEL ORO', 43, 15),
(694, 'IXTLAHUACA', 44, 15),
(695, 'JALATLACO', 45, 15),
(696, 'JALTENCO', 46, 15),
(697, 'JILOTEPEC', 47, 15),
(698, 'JILOTZINGO', 48, 15),
(699, 'JIQUIPILCO', 49, 15),
(700, 'JOCOTITLÁN', 50, 15),
(701, 'JOQUICINGO', 51, 15),
(702, 'JUCHITEPEC', 52, 15),
(703, 'LA PAZ', 53, 15),
(704, 'LERMA', 54, 15),
(705, 'MALINALCO', 55, 15),
(706, 'MELCHOR OCAMPO', 56, 15),
(707, 'METEPEC', 57, 15),
(708, 'MEXICALTZINGO', 58, 15),
(709, 'MORELOS', 59, 15),
(710, 'NAUCALPAN DE JUÁREZ', 60, 15),
(711, 'NEXTLALPAN', 61, 15),
(712, 'NEZAHUALCÓYOTL', 62, 15),
(713, 'NICOLÁS ROMERO', 63, 15),
(714, 'NOPALTEPEC', 64, 15),
(715, 'OCOYOACAC', 65, 15),
(716, 'OCUILAN', 66, 15),
(717, 'OTUMBA', 67, 15),
(718, 'OTZOLOAPAN', 68, 15),
(719, 'OTZOLOTEPEC', 69, 15),
(720, 'OZUMBA', 70, 15),
(721, 'PAPALOTLA', 71, 15),
(722, 'POLOTITLÁN', 72, 15),
(723, 'RAYÓN', 73, 15),
(724, 'SAN ANTONIO LA ISLA', 74, 15),
(725, 'SAN FELIPE DEL PROGRESO', 75, 15),
(726, 'SAN MARTÍN DE LAS PIRÁMIDES', 76, 15),
(727, 'SAN MATEO ATENCO', 77, 15),
(728, 'SAN SIMÓN DE GUERRERO', 78, 15),
(729, 'SANTO TOMÁS', 79, 15),
(730, 'SOYANIQUILPAN DE JUÁREZ', 80, 15),
(731, 'SULTEPEC', 81, 15),
(732, 'TECÁMAC', 82, 15),
(733, 'TEJUPILCO', 83, 15),
(734, 'TEMAMATLA', 84, 15),
(735, 'TEMASCALAPA', 85, 15),
(736, 'TEMASCALCINGO', 86, 15),
(737, 'TEMASCALTEPEC', 87, 15),
(738, 'TEMOAYA', 88, 15),
(739, 'TENANCINGO', 89, 15),
(740, 'TENANGO DEL AIRE', 90, 15),
(741, 'TENANGO DEL VALLE', 91, 15),
(742, 'TEOLOYUCÁN', 92, 15),
(743, 'TEOTIHUACÁN', 93, 15),
(744, 'TEPETLAOXTOC', 94, 15),
(745, 'TEPETLIXPA', 95, 15),
(746, 'TEPOTZOTLÁN', 96, 15),
(747, 'TEQUIXQUIAC', 97, 15),
(748, 'TEXCALTITLÁN', 98, 15),
(749, 'TEXCALYACAC', 99, 15),
(750, 'TEXCOCO', 100, 15),
(751, 'TEZOYUCA', 101, 15),
(752, 'TIANGUISTENCO', 102, 15),
(753, 'TIMILPAN', 103, 15),
(754, 'TLALMANALCO', 104, 15),
(755, 'TLALNEPANTLA DE BAZ', 105, 15),
(756, 'TLATLAYA', 106, 15),
(757, 'TOLUCA', 107, 15),
(758, 'TONATICO', 108, 15),
(759, 'TULTEPEC', 109, 15),
(760, 'TULTITLÁN', 110, 15),
(761, 'VALLE DE BRAVO', 111, 15),
(762, 'VALLE DE CHALCO SOLIDARIDAD', 112, 15),
(763, 'VILLA DE ALLENDE', 113, 15),
(764, 'VILLA DEL CARBÓN', 114, 15),
(765, 'VILLA GUERRERO', 115, 15),
(766, 'VILLA VICTORIA', 116, 15),
(767, 'XALATLACO', 117, 15),
(768, 'XONACATLÁN', 118, 15),
(769, 'ZACAZONAPAN', 119, 15),
(770, 'ZACUALPAN', 120, 15),
(771, 'ZINACANTEPEC', 121, 15),
(772, 'ZUMPAHUACÁN', 122, 15),
(773, 'ZUMPANGO', 123, 15),
(774, 'ACUITZIO', 1, 16),
(775, 'AGUILILLA', 2, 16),
(776, 'ALVARO OBREGÓN', 3, 16),
(777, 'ANGAMACUTIRO', 4, 16),
(778, 'ANGANGUEO', 5, 16),
(779, 'APATZINGÁN', 6, 16),
(780, 'APORO', 7, 16),
(781, 'AQUILA', 8, 16),
(782, 'ARIO', 9, 16),
(783, 'ARTEAGA', 10, 16),
(784, 'BRISEÑAS', 11, 16),
(785, 'BUENAVISTA', 12, 16),
(786, 'CARÁCUARO', 13, 16),
(787, 'CHARAPAN', 14, 16),
(788, 'CHARO', 15, 16),
(789, 'CHAVINDA', 16, 16),
(790, 'CHERÁN', 17, 16),
(791, 'CHILCHOTA', 18, 16),
(792, 'CHINICUILA', 19, 16),
(793, 'CHUCÁNDIRO', 20, 16),
(794, 'CHURINTZIO', 21, 16),
(795, 'CHURUMUCO', 22, 16),
(796, 'COAHUAYANA', 23, 16),
(797, 'COALCOMAN', 24, 16),
(798, 'COALCOMÁN DE VÁZQUEZ PALLARES', 25, 16),
(799, 'COENEO', 26, 16),
(800, 'COJUMATLÁN DE RÉGULES', 27, 16),
(801, 'CONTEPEC', 28, 16),
(802, 'COPÁNDARO', 29, 16),
(803, 'COTIJA', 30, 16),
(804, 'CUITZEO', 31, 16),
(805, 'ECUANDUREO', 32, 16),
(806, 'EPITACIO HUERTA', 33, 16),
(807, 'ERONGARÍCUARO', 34, 16),
(808, 'GABRIEL ZAMORA', 35, 16),
(809, 'HIDALGO', 36, 16),
(810, 'HUANDACAREO', 37, 16),
(811, 'HUANIQUEO', 38, 16),
(812, 'HUETAMO', 39, 16),
(813, 'HUIRAMBA', 40, 16),
(814, 'INDAPARAPEO', 41, 16),
(815, 'IRIMBO', 42, 16),
(816, 'IXTLÁN', 43, 16),
(817, 'JACONA', 44, 16),
(818, 'JIMÉNEZ', 45, 16),
(819, 'JIQUILPAN', 46, 16),
(820, 'JOSÉ SIXTO VERDUZCO', 47, 16),
(821, 'JUÁREZ', 48, 16),
(822, 'JUNGAPEO', 49, 16),
(823, 'LA HUACANA', 50, 16),
(824, 'LA PIEDAD', 51, 16),
(825, 'LAGUNILLAS', 52, 16),
(826, 'LÁZARO CÁRDENAS', 53, 16),
(827, 'LOS REYES', 54, 16),
(828, 'MADERO', 55, 16),
(829, 'MARAVATÍO', 56, 16),
(830, 'MARCOS CASTELLANOS', 57, 16),
(831, 'MORELIA', 58, 16),
(832, 'MORELOS', 59, 16),
(833, 'MÚGICA', 60, 16),
(834, 'NAHUATZEN', 61, 16),
(835, 'NOCUPÉTARO', 62, 16),
(836, 'NUEVO PARANGARICUTIRO', 63, 16),
(837, 'NUEVO URECHO', 64, 16),
(838, 'NUMARÁN', 65, 16),
(839, 'OCAMPO', 66, 16),
(840, 'PAJACUARÁN', 67, 16),
(841, 'PANINDÍCUARO', 68, 16),
(842, 'PARACHO', 69, 16),
(843, 'PARÁCUARO', 70, 16),
(844, 'PÁTZCUARO', 71, 16),
(845, 'PENJAMILLO', 72, 16),
(846, 'PERIBÁN', 73, 16),
(847, 'PURÉPERO', 74, 16),
(848, 'PURUÁNDIRO', 75, 16),
(849, 'QUERÉNDARO', 76, 16),
(850, 'QUIROGA', 77, 16),
(851, 'SAHUAYO', 78, 16),
(852, 'SALVADOR ESCALANTE', 79, 16),
(853, 'SAN LUCAS', 80, 16),
(854, 'SANTA ANA MAYA', 81, 16),
(855, 'SENGUIO', 82, 16),
(856, 'SUSUPUATO', 83, 16),
(857, 'TACÁMBARO', 84, 16),
(858, 'TANCÍTARO', 85, 16),
(859, 'TANGAMANDAPIO', 86, 16),
(860, 'TANGANCÍCUARO', 87, 16),
(861, 'TANHUATO', 88, 16),
(862, 'TARETAN', 89, 16),
(863, 'TARÍMBARO', 90, 16),
(864, 'TEPALCATEPEC', 91, 16),
(865, 'TINGAMBATO', 92, 16),
(866, 'TINGUINDÍN', 93, 16),
(867, 'TIQUICHEO DE NICOLÁS ROMERO', 94, 16),
(868, 'TLALPUJAHUA', 95, 16),
(869, 'TLAZAZALCA', 96, 16),
(870, 'TOCUMBO', 97, 16),
(871, 'TUMBISCATÍO', 98, 16),
(872, 'TURICATO', 99, 16),
(873, 'TUXPAN', 100, 16),
(874, 'TUZANTLA', 101, 16),
(875, 'TZINTZUNTZAN', 102, 16),
(876, 'TZITZIO', 103, 16),
(877, 'URUAPAN', 104, 16),
(878, 'VENUSTIANO CARRANZA', 105, 16),
(879, 'VILLAMAR', 106, 16),
(880, 'VISTA HERMOSA', 107, 16),
(881, 'VISTAHERMOSA', 108, 16),
(882, 'YURÉCUARO', 109, 16),
(883, 'ZACAPU', 110, 16),
(884, 'ZAMORA', 111, 16),
(885, 'ZINÁPARO', 112, 16),
(886, 'ZINAPÉCUARO', 113, 16),
(887, 'ZIRACUARETIRO', 114, 16),
(888, 'ZITÁCUARO', 115, 16),
(889, 'AMACUZAC', 1, 17),
(890, 'ATLATLAHUCAN', 2, 17),
(891, 'AXOCHIAPAN', 3, 17),
(892, 'AYALA', 4, 17),
(893, 'COATLÁN DEL RÍO', 5, 17),
(894, 'CUAUTLA', 6, 17),
(895, 'CUERNAVACA', 7, 17),
(896, 'EMILIANO ZAPATA', 8, 17),
(897, 'HUITZILAC', 9, 17),
(898, 'JANTETELCO', 10, 17),
(899, 'JIUTEPEC', 11, 17),
(900, 'JOJUTLA', 12, 17),
(901, 'JONACATEPEC', 13, 17),
(902, 'MAZATEPEC', 14, 17),
(903, 'MIACATLÁN', 15, 17),
(904, 'OCUITUCO', 16, 17),
(905, 'PUENTE DE IXTLA', 17, 17),
(906, 'TEMIXCO', 18, 17),
(907, 'TEMOAC', 19, 17),
(908, 'TEPALCINGO', 20, 17),
(909, 'TEPOZTLÁN', 21, 17),
(910, 'TETECALA', 22, 17),
(911, 'TETELA DEL VOLCÁN', 23, 17),
(912, 'TLALNEPANTLA', 24, 17),
(913, 'TLALTIZAPÁN', 25, 17),
(914, 'TLAQUILTENANGO', 26, 17),
(915, 'TLAYACAPAN', 27, 17),
(916, 'TOTOLAPAN', 28, 17),
(917, 'XOCHITEPEC', 29, 17),
(918, 'YAUTEPEC', 30, 17),
(919, 'YECAPIXTLA', 31, 17),
(920, 'ZACATEPEC', 32, 17),
(921, 'ZACUALPAN', 33, 17),
(922, 'ACAPONETA', 1, 18),
(923, 'AHUACATLÁN', 2, 18),
(924, 'AMATLÁN DE CAÑAS', 3, 18),
(925, 'BAHÍA DE BANDERAS', 4, 18),
(926, 'COMPOSTELA', 5, 18),
(927, 'EL NAYAR', 6, 18),
(928, 'HUAJICORI', 7, 18),
(929, 'IXTLÁN DEL RÍO', 8, 18),
(930, 'JALA', 9, 18),
(931, 'LA YESCA', 10, 18),
(932, 'ROSAMORADA', 11, 18),
(933, 'RUÍZ', 12, 18),
(934, 'SAN BLAS', 13, 18),
(935, 'SAN PEDRO LAGUNILLAS', 14, 18),
(936, 'SANTA MARÍA DEL ORO', 15, 18),
(937, 'SANTIAGO IXCUINTLA', 16, 18),
(938, 'TECUALA', 17, 18),
(939, 'TEPIC', 18, 18),
(940, 'TUXPAN', 19, 18),
(941, 'XALISCO', 20, 18),
(942, 'ABASOLO', 1, 19),
(943, 'AGUALEGUAS', 2, 19),
(944, 'ALLENDE', 3, 19),
(945, 'ANÁHUAC', 4, 19),
(946, 'APODACA', 5, 19),
(947, 'ARAMBERRI', 6, 19),
(948, 'BUSTAMANTE', 7, 19),
(949, 'CADEREYTA JIMÉNEZ', 8, 19),
(950, 'CARMEN', 9, 19),
(951, 'CERRALVO', 10, 19),
(952, 'CHINA', 11, 19),
(953, 'CIÉNEGA DE FLORES', 12, 19),
(954, 'DOCTOR ARROYO', 13, 19),
(955, 'DOCTOR COSS', 14, 19),
(956, 'DOCTOR GONZÁLEZ', 15, 19),
(957, 'GALEANA', 16, 19),
(958, 'GARCÍA', 17, 19),
(959, 'GARZA GARCIA', 18, 19),
(960, 'GENERAL BRAVO', 19, 19),
(961, 'GENERAL ESCOBEDO', 20, 19),
(962, 'GENERAL TERÁN', 21, 19),
(963, 'GENERAL TREVIÑO', 22, 19),
(964, 'GENERAL ZARAGOZA', 23, 19),
(965, 'GENERAL ZUAZUA', 24, 19),
(966, 'GUADALUPE', 25, 19),
(967, 'HIDALGO', 26, 19),
(968, 'HIGUERAS', 27, 19),
(969, 'HUALAHUISES', 28, 19),
(970, 'ITURBIDE', 29, 19),
(971, 'JUÁREZ', 30, 19),
(972, 'LAMPAZOS DE NARANJO', 31, 19),
(973, 'LINARES', 32, 19),
(974, 'LOS ALDAMAS', 33, 19),
(975, 'LOS HERRERAS', 34, 19),
(976, 'LOS RAMONES', 35, 19),
(977, 'MARÍN', 36, 19),
(978, 'MELCHOR OCAMPO', 37, 19),
(979, 'MIER Y NORIEGA', 38, 19),
(980, 'MINA', 39, 19),
(981, 'MONTEMORELOS', 40, 19),
(982, 'MONTERREY', 41, 19),
(983, 'PARÁS', 42, 19),
(984, 'PESQUERÍA', 43, 19),
(985, 'RAYONES', 44, 19),
(986, 'SABINAS HIDALGO', 45, 19),
(987, 'SALINAS VICTORIA', 46, 19),
(988, 'SAN NICOLÁS DE LOS GARZA', 47, 19),
(989, 'SAN PEDRO GARZA GARCÍA', 48, 19),
(990, 'SANTA CATARINA', 49, 19),
(991, 'SANTIAGO', 50, 19),
(992, 'VALLECILLO', 51, 19),
(993, 'VILLALDAMA', 52, 19),
(994, 'ABEJONES', 1, 20),
(995, 'ACATLÁN DE PÉREZ FIGUEROA', 2, 20),
(996, 'ANIMAS TRUJANO', 3, 20),
(997, 'ASUNCIÓN CACALOTEPEC', 4, 20),
(998, 'ASUNCIÓN CUYOTEPEJI', 5, 20),
(999, 'ASUNCIÓN IXTALTEPEC', 6, 20),
(1000, 'ASUNCIÓN NOCHIXTLÁN', 7, 20),
(1001, 'ASUNCIÓN OCOTLÁN', 8, 20),
(1002, 'ASUNCIÓN TLACOLULITA', 9, 20),
(1003, 'AYOQUEZCO DE ALDAMA', 10, 20),
(1004, 'AYOTZINTEPEC', 11, 20),
(1005, 'CALIHUALÁ', 12, 20),
(1006, 'CANDELARIA LOXICHA', 13, 20),
(1007, 'CAPULALPAM DE MÉNDEZ', 14, 20),
(1008, 'CHAHUITES', 15, 20),
(1009, 'CHALCATONGO DE HIDALGO', 16, 20),
(1010, 'CHIQUIHUITLÁN DE BENITO JUÁREZ', 17, 20),
(1011, 'CIÉNEGA DE ZIMATLÁN', 18, 20),
(1012, 'CIUDAD DE HUAJUAPAM DE LEÓN', 19, 20),
(1013, 'CIUDAD IXTEPEC', 20, 20),
(1014, 'COATECAS ALTAS', 21, 20),
(1015, 'COICOYÁN DE LAS FLORES', 22, 20),
(1016, 'CONCEPCIÓN BUENAVISTA', 23, 20),
(1017, 'CONCEPCIÓN PÁPALO', 24, 20),
(1018, 'CONSTANCIA DEL ROSARIO', 25, 20),
(1019, 'COSOLAPA', 26, 20),
(1020, 'COSOLTEPEC', 27, 20),
(1021, 'CUILAPAM DE GUERRERO', 28, 20),
(1022, 'CUYAMECALCO VILLA DE ZARAGOZA', 29, 20),
(1023, 'EJUTLA DE CRESPO', 30, 20),
(1024, 'EL BARRIO DE LA SOLEDAD', 31, 20),
(1025, 'EL ESPINAL', 32, 20),
(1026, 'ELOXOCHITLÁN DE FLORES MAGÓN', 33, 20),
(1027, 'FRESNILLO DE TRUJANO', 34, 20),
(1028, 'GUADALUPE DE RAMÍREZ', 35, 20),
(1029, 'GUADALUPE ETLA', 36, 20),
(1030, 'GUELATAO DE JUÁREZ', 37, 20),
(1031, 'GUEVEA DE HUMBOLDT', 38, 20),
(1032, 'HEROICA CIUDAD DE EJUTLA DE CRESPO', 39, 20),
(1033, 'HEROICA CIUDAD DE TLAXIACO', 40, 20),
(1034, 'HUAJUAPAN DE LEON', 41, 20),
(1035, 'HUAUTEPEC', 42, 20),
(1036, 'HUAUTLA DE JIMÉNEZ', 43, 20),
(1037, 'IXPANTEPEC NIEVES', 44, 20),
(1038, 'IXTLÁN DE JUÁREZ', 45, 20),
(1039, 'JUCHITÁN DE ZARAGOZA', 46, 20),
(1040, 'LA COMPAÑÍA', 47, 20),
(1041, 'LA PE', 48, 20),
(1042, 'LA REFORMA', 49, 20),
(1043, 'LA TRINIDAD VISTA HERMOSA', 50, 20),
(1044, 'LOMA BONITA', 51, 20),
(1045, 'MAGDALENA APASCO', 52, 20),
(1046, 'MAGDALENA JALTEPEC', 53, 20),
(1047, 'MAGDALENA MIXTEPEC', 54, 20),
(1048, 'MAGDALENA OCOTLÁN', 55, 20),
(1049, 'MAGDALENA PEÑASCO', 56, 20),
(1050, 'MAGDALENA TEITIPAC', 57, 20),
(1051, 'MAGDALENA TEQUISISTLÁN', 58, 20),
(1052, 'MAGDALENA TLACOTEPEC', 59, 20),
(1053, 'MAGDALENA YODOCONO DE PORFIRIO DÍAZ', 60, 20),
(1054, 'MAGDALENA ZAHUATLÁN', 61, 20),
(1055, 'MARISCALA DE JUÁREZ', 62, 20),
(1056, 'MÁRTIRES DE TACUBAYA', 63, 20),
(1057, 'MATÍAS ROMERO', 64, 20),
(1058, 'MAZATLÁN VILLA DE FLORES', 65, 20),
(1059, 'MESONES HIDALGO', 66, 20),
(1060, 'MIAHUATLÁN DE PORFIRIO DÍAZ', 67, 20),
(1061, 'MIXISTLÁN DE LA REFORMA', 68, 20),
(1062, 'MONJAS', 69, 20),
(1063, 'NATIVIDAD', 70, 20),
(1064, 'NAZARENO ETLA', 71, 20),
(1065, 'NEJAPA DE MADERO', 72, 20),
(1066, 'NUEVO ZOQUIAPAM', 73, 20),
(1067, 'OAXACA DE JUÁREZ', 74, 20),
(1068, 'OCOTLÁN DE MORELOS', 75, 20),
(1069, 'PINOTEPA DE DON LUIS', 76, 20),
(1070, 'PLUMA HIDALGO', 77, 20),
(1071, 'PUTLA VILLA DE GUERRERO', 78, 20),
(1072, 'REFORMA DE PINEDA', 79, 20),
(1073, 'REYES ETLA', 80, 20),
(1074, 'ROJAS DE CUAUHTÉMOC', 81, 20),
(1075, 'SALINA CRUZ', 82, 20),
(1076, 'SAN AGUSTÍN AMATENGO', 83, 20),
(1077, 'SAN AGUSTÍN ATENANGO', 84, 20),
(1078, 'SAN AGUSTÍN CHAYUCO', 85, 20),
(1079, 'SAN AGUSTÍN DE LAS JUNTAS', 86, 20),
(1080, 'SAN AGUSTÍN ETLA', 87, 20),
(1081, 'SAN AGUSTÍN LOXICHA', 88, 20),
(1082, 'SAN AGUSTÍN TLACOTEPEC', 89, 20),
(1083, 'SAN AGUSTÍN YATARENI', 90, 20),
(1084, 'SAN ANDRÉS CABECERA NUEVA', 91, 20),
(1085, 'SAN ANDRÉS DINICUITI', 92, 20),
(1086, 'SAN ANDRÉS HUAXPALTEPEC', 93, 20),
(1087, 'SAN ANDRÉS HUAYAPAM', 94, 20),
(1088, 'SAN ANDRÉS IXTLAHUACA', 95, 20),
(1089, 'SAN ANDRÉS LAGUNAS', 96, 20),
(1090, 'SAN ANDRÉS NUXIÑO', 97, 20),
(1091, 'SAN ANDRÉS PAXTLÁN', 98, 20),
(1092, 'SAN ANDRÉS SINAXTLA', 99, 20),
(1093, 'SAN ANDRÉS SOLAGA', 100, 20),
(1094, 'SAN ANDRÉS TEOTILALPAM', 101, 20),
(1095, 'SAN ANDRES TEOTILALPAN', 102, 20),
(1096, 'SAN ANDRÉS TEPETLAPA', 103, 20),
(1097, 'SAN ANDRÉS YAÁ', 104, 20),
(1098, 'SAN ANDRÉS ZABACHE', 105, 20),
(1099, 'SAN ANDRÉS ZAUTLA', 106, 20),
(1100, 'SAN ANTONINO CASTILLO VELASCO', 107, 20),
(1101, 'SAN ANTONINO EL ALTO', 108, 20),
(1102, 'SAN ANTONINO MONTE VERDE', 109, 20),
(1103, 'SAN ANTONIO ACUTLA', 110, 20),
(1104, 'SAN ANTONIO DE LA CAL', 111, 20),
(1105, 'SAN ANTONIO HUITEPEC', 112, 20),
(1106, 'SAN ANTONIO NANAHUATIPAM', 113, 20),
(1107, 'SAN ANTONIO SINICAHUA', 114, 20),
(1108, 'SAN ANTONIO TEPETLAPA', 115, 20),
(1109, 'SAN BALTAZAR CHICHICAPAM', 116, 20),
(1110, 'SAN BALTAZAR LOXICHA', 117, 20),
(1111, 'SAN BALTAZAR YATZACHI EL BAJO', 118, 20),
(1112, 'SAN BARTOLO COYOTEPEC', 119, 20),
(1113, 'SAN BARTOLO SOYALTEPEC', 120, 20),
(1114, 'SAN BARTOLO YAUTEPEC', 121, 20),
(1115, 'SAN BARTOLOMÉ AYAUTLA', 122, 20),
(1116, 'SAN BARTOLOMÉ LOXICHA', 123, 20),
(1117, 'SAN BARTOLOMÉ QUIALANA', 124, 20),
(1118, 'SAN BARTOLOMÉ YUCUAÑE', 125, 20),
(1119, 'SAN BARTOLOMÉ ZOOGOCHO', 126, 20),
(1120, 'SAN BERNARDO MIXTEPEC', 127, 20),
(1121, 'SAN BLAS ATEMPA', 128, 20),
(1122, 'SAN CARLOS YAUTEPEC', 129, 20),
(1123, 'SAN CRISTÓBAL AMATLÁN', 130, 20),
(1124, 'SAN CRISTÓBAL AMOLTEPEC', 131, 20),
(1125, 'SAN CRISTÓBAL LACHIRIOAG', 132, 20),
(1126, 'SAN CRISTÓBAL SUCHIXTLAHUACA', 133, 20),
(1127, 'SAN DIONISIO DEL MAR', 134, 20),
(1128, 'SAN DIONISIO OCOTEPEC', 135, 20),
(1129, 'SAN DIONISIO OCOTLÁN', 136, 20),
(1130, 'SAN ESTEBAN ATATLAHUCA', 137, 20),
(1131, 'SAN FELIPE JALAPA DE DÍAZ', 138, 20),
(1132, 'SAN FELIPE TEJALAPAM', 139, 20),
(1133, 'SAN FELIPE USILA', 140, 20),
(1134, 'SAN FRANCISCO CAHUACUÁ', 141, 20),
(1135, 'SAN FRANCISCO CAJONOS', 142, 20),
(1136, 'SAN FRANCISCO CHAPULAPA', 143, 20),
(1137, 'SAN FRANCISCO CHINDÚA', 144, 20),
(1138, 'SAN FRANCISCO DEL MAR', 145, 20),
(1139, 'SAN FRANCISCO HUEHUETLÁN', 146, 20),
(1140, 'SAN FRANCISCO IXHUATÁN', 147, 20),
(1141, 'SAN FRANCISCO JALTEPETONGO', 148, 20),
(1142, 'SAN FRANCISCO LACHIGOLÓ', 149, 20),
(1143, 'SAN FRANCISCO LOGUECHE', 150, 20),
(1144, 'SAN FRANCISCO NUXAÑO', 151, 20),
(1145, 'SAN FRANCISCO OZOLOTEPEC', 152, 20),
(1146, 'SAN FRANCISCO SOLA', 153, 20),
(1147, 'SAN FRANCISCO TELIXTLAHUACA', 154, 20),
(1148, 'SAN FRANCISCO TEOPAN', 155, 20),
(1149, 'SAN FRANCISCO TLAPANCINGO', 156, 20),
(1150, 'SAN GABRIEL MIXTEPEC', 157, 20),
(1151, 'SAN ILDEFONSO AMATLÁN', 158, 20),
(1152, 'SAN ILDEFONSO SOLA', 159, 20),
(1153, 'SAN ILDEFONSO VILLA ALTA', 160, 20),
(1154, 'SAN JACINTO AMILPAS', 161, 20),
(1155, 'SAN JACINTO TLACOTEPEC', 162, 20),
(1156, 'SAN JERÓNIMO COATLÁN', 163, 20),
(1157, 'SAN JERÓNIMO SILACAYOAPILLA', 164, 20),
(1158, 'SAN JERÓNIMO SOSOLA', 165, 20),
(1159, 'SAN JERÓNIMO TAVICHE', 166, 20),
(1160, 'SAN JERÓNIMO TECOATL', 167, 20),
(1161, 'SAN JERÓNIMO TLACOCHAHUAYA', 168, 20),
(1162, 'SAN JORGE NUCHITA', 169, 20),
(1163, 'SAN JOSÉ AYUQUILA', 170, 20),
(1164, 'SAN JOSÉ CHILTEPEC', 171, 20),
(1165, 'SAN JOSÉ DEL PEÑASCO', 172, 20),
(1166, 'SAN JOSÉ DEL PROGRESO', 173, 20),
(1167, 'SAN JOSÉ ESTANCIA GRANDE', 174, 20),
(1168, 'SAN JOSÉ INDEPENDENCIA', 175, 20),
(1169, 'SAN JOSÉ LACHIGUIRÍ', 176, 20),
(1170, 'SAN JOSÉ TENANGO', 177, 20),
(1171, 'SAN JUAN ACHIUTLA', 178, 20),
(1172, 'SAN JUAN ATEPEC', 179, 20),
(1173, 'SAN JUAN BAUTISTA ATATLAHUCA', 180, 20),
(1174, 'SAN JUAN BAUTISTA COIXTLAHUACA', 181, 20),
(1175, 'SAN JUAN BAUTISTA CUICATLÁN', 182, 20),
(1176, 'SAN JUAN BAUTISTA GUELACHE', 183, 20),
(1177, 'SAN JUAN BAUTISTA JAYACATLÁN', 184, 20),
(1178, 'SAN JUAN BAUTISTA LO DE SOTO', 185, 20),
(1179, 'SAN JUAN BAUTISTA SUCHITEPEC', 186, 20),
(1180, 'SAN JUAN BAUTISTA TLACHICHILCO', 187, 20),
(1181, 'SAN JUAN BAUTISTA TLACOATZINTEPEC', 188, 20),
(1182, 'SAN JUAN BAUTISTA TUXTEPEC', 189, 20),
(1183, 'SAN JUAN BAUTISTA VALLE NACIONAL', 190, 20),
(1184, 'SAN JUAN CACAHUATEPEC', 191, 20),
(1185, 'SAN JUAN CHICOMEZÚCHIL', 192, 20),
(1186, 'SAN JUAN CHILATECA', 193, 20),
(1187, 'SAN JUAN CIENEGUILLA', 194, 20),
(1188, 'SAN JUAN COATZOSPAM', 195, 20),
(1189, 'SAN JUAN COLORADO', 196, 20),
(1190, 'SAN JUAN COMALTEPEC', 197, 20),
(1191, 'SAN JUAN COTZOCÓN', 198, 20),
(1192, 'SAN JUAN DE LOS CUES', 199, 20),
(1193, 'SAN JUAN DEL ESTADO', 200, 20),
(1194, 'SAN JUAN DEL RÍO', 201, 20),
(1195, 'SAN JUAN DIUXI', 202, 20),
(1196, 'SAN JUAN EVANGELISTA ANALCO', 203, 20),
(1197, 'SAN JUAN GUELAVÍA', 204, 20),
(1198, 'SAN JUAN GUICHICOVI', 205, 20),
(1199, 'SAN JUAN IHUALTEPEC', 206, 20),
(1200, 'SAN JUAN JUQUILA MIXES', 207, 20),
(1201, 'SAN JUAN JUQUILA VIJANOS', 208, 20),
(1202, 'SAN JUAN LACHAO', 209, 20),
(1203, 'SAN JUAN LACHIGALLA', 210, 20),
(1204, 'SAN JUAN LAJARCIA', 211, 20),
(1205, 'SAN JUAN LALANA', 212, 20),
(1206, 'SAN JUAN MAZATLÁN', 213, 20),
(1207, 'SAN JUAN MIXTEPEC - DISTR. 08 -', 214, 20),
(1208, 'SAN JUAN MIXTEPEC - DISTR. 26 -', 215, 20),
(1209, 'SAN JUAN MIXTEPEC MIAHUATLAN', 216, 20),
(1210, 'SAN JUAN ÑUMÍ', 217, 20),
(1211, 'SAN JUAN OZOLOTEPEC', 218, 20),
(1212, 'SAN JUAN PETLAPA', 219, 20),
(1213, 'SAN JUAN QUIAHIJE', 220, 20),
(1214, 'SAN JUAN QUIOTEPEC', 221, 20),
(1215, 'SAN JUAN SAYULTEPEC', 222, 20),
(1216, 'SAN JUAN TABAÁ', 223, 20),
(1217, 'SAN JUAN TAMAZOLA', 224, 20),
(1218, 'SAN JUAN TEITA', 225, 20),
(1219, 'SAN JUAN TEITIPAC', 226, 20),
(1220, 'SAN JUAN TEPEUXILA', 227, 20),
(1221, 'SAN JUAN TEPOSCOLULA', 228, 20),
(1222, 'SAN JUAN YAEÉ', 229, 20),
(1223, 'SAN JUAN YATZONA', 230, 20),
(1224, 'SAN JUAN YUCUITA', 231, 20),
(1225, 'SAN LORENZO', 232, 20),
(1226, 'SAN LORENZO ALBARRADAS', 233, 20),
(1227, 'SAN LORENZO CACAOTEPEC', 234, 20),
(1228, 'SAN LORENZO CUAUNECUILTITLA', 235, 20),
(1229, 'SAN LORENZO TEXMELUCAN', 236, 20),
(1230, 'SAN LORENZO VICTORIA', 237, 20),
(1231, 'SAN LUCAS CAMOTLÁN', 238, 20),
(1232, 'SAN LUCAS OJITLÁN', 239, 20),
(1233, 'SAN LUCAS QUIAVINÍ', 240, 20),
(1234, 'SAN LUCAS ZOQUIAPAM', 241, 20),
(1235, 'SAN LUIS AMATLÁN', 242, 20),
(1236, 'SAN MARCIAL OZOLOTEPEC', 243, 20),
(1237, 'SAN MARCOS ARTEAGA', 244, 20),
(1238, 'SAN MARTÍN DE LOS CANSECOS', 245, 20),
(1239, 'SAN MARTÍN HUAMELULPAM', 246, 20),
(1240, 'SAN MARTÍN ITUNYOSO', 247, 20),
(1241, 'SAN MARTÍN LACHILÁ', 248, 20),
(1242, 'SAN MARTÍN PERAS', 249, 20),
(1243, 'SAN MARTÍN TILCAJETE', 250, 20),
(1244, 'SAN MARTÍN TOXPALAN', 251, 20),
(1245, 'SAN MARTÍN ZACATEPEC', 252, 20),
(1246, 'SAN MATEO CAJONOS', 253, 20),
(1247, 'SAN MATEO DEL MAR', 254, 20),
(1248, 'SAN MATEO ETLATONGO', 255, 20),
(1249, 'SAN MATEO NEJAPAM', 256, 20),
(1250, 'SAN MATEO PEÑASCO', 257, 20),
(1251, 'SAN MATEO PIÑAS', 258, 20),
(1252, 'SAN MATEO RÍO HONDO', 259, 20),
(1253, 'SAN MATEO SINDIHUI', 260, 20),
(1254, 'SAN MATEO TLAPILTEPEC', 261, 20),
(1255, 'SAN MATEO YOLOXOCHITLÁN', 262, 20),
(1256, 'SAN MELCHOR BETAZA', 263, 20),
(1257, 'SAN MIGUEL ACHIUTLA', 264, 20),
(1258, 'SAN MIGUEL AHUEHUETITLÁN', 265, 20),
(1259, 'SAN MIGUEL ALOÁPAM', 266, 20),
(1260, 'SAN MIGUEL AMATITLÁN', 267, 20),
(1261, 'SAN MIGUEL AMATLÁN', 268, 20),
(1262, 'SAN MIGUEL CHICAHUA', 269, 20),
(1263, 'SAN MIGUEL CHIMALAPA', 270, 20),
(1264, 'SAN MIGUEL COATLÁN', 271, 20),
(1265, 'SAN MIGUEL DEL PUERTO', 272, 20),
(1266, 'SAN MIGUEL DEL RÍO', 273, 20),
(1267, 'SAN MIGUEL EJUTLA', 274, 20),
(1268, 'SAN MIGUEL EL GRANDE', 275, 20),
(1269, 'SAN MIGUEL HUAUTLA', 276, 20),
(1270, 'SAN MIGUEL MIXTEPEC', 277, 20),
(1271, 'SAN MIGUEL PANIXTLAHUACA', 278, 20),
(1272, 'SAN MIGUEL PERAS', 279, 20),
(1273, 'SAN MIGUEL PIEDRAS', 280, 20),
(1274, 'SAN MIGUEL QUETZALTEPEC', 281, 20),
(1275, 'SAN MIGUEL SANTA FLOR', 282, 20),
(1276, 'SAN MIGUEL SOYALTEPEC', 283, 20),
(1277, 'SAN MIGUEL SUCHIXTEPEC', 284, 20),
(1278, 'SAN MIGUEL TALEA DE CASTRO', 285, 20),
(1279, 'SAN MIGUEL TECOMATLÁN', 286, 20),
(1280, 'SAN MIGUEL TENANGO', 287, 20),
(1281, 'SAN MIGUEL TEQUIXTEPEC', 288, 20),
(1282, 'SAN MIGUEL TILQUIAPAM', 289, 20),
(1283, 'SAN MIGUEL TLACAMAMA', 290, 20),
(1284, 'SAN MIGUEL TLACOTEPEC', 291, 20),
(1285, 'SAN MIGUEL TULANCINGO', 292, 20),
(1286, 'SAN MIGUEL YOTAO', 293, 20),
(1287, 'SAN NICOLÁS', 294, 20),
(1288, 'SAN NICOLÁS HIDALGO', 295, 20),
(1289, 'SAN PABLO COATLÁN', 296, 20),
(1290, 'SAN PABLO CUATRO VENADOS', 297, 20),
(1291, 'SAN PABLO ETLA', 298, 20),
(1292, 'SAN PABLO HUITZO', 299, 20),
(1293, 'SAN PABLO HUIXTEPEC', 300, 20),
(1294, 'SAN PABLO MACUILTIANGUIS', 301, 20),
(1295, 'SAN PABLO TIJALTEPEC', 302, 20),
(1296, 'SAN PABLO VILLA DE MITLA', 303, 20),
(1297, 'SAN PABLO YAGANIZA', 304, 20),
(1298, 'SAN PEDRO AMUZGOS', 305, 20),
(1299, 'SAN PEDRO APÓSTOL', 306, 20),
(1300, 'SAN PEDRO ATOYAC', 307, 20),
(1301, 'SAN PEDRO CAJONOS', 308, 20),
(1302, 'SAN PEDRO COMITANCILLO', 309, 20),
(1303, 'SAN PEDRO COXCALTEPEC CÁNTAROS', 310, 20),
(1304, 'SAN PEDRO EL ALTO', 311, 20),
(1305, 'SAN PEDRO HUAMELULA', 312, 20),
(1306, 'SAN PEDRO HUILOTEPEC', 313, 20),
(1307, 'SAN PEDRO IXCATLÁN', 314, 20),
(1308, 'SAN PEDRO IXTLAHUACA', 315, 20),
(1309, 'SAN PEDRO JALTEPETONGO', 316, 20),
(1310, 'SAN PEDRO JICAYÁN', 317, 20),
(1311, 'SAN PEDRO JOCOTIPAC', 318, 20),
(1312, 'SAN PEDRO JUCHATENGO', 319, 20),
(1313, 'SAN PEDRO MÁRTIR', 320, 20),
(1314, 'SAN PEDRO MÁRTIR QUIECHAPA', 321, 20),
(1315, 'SAN PEDRO MÁRTIR YUCUXACO', 322, 20),
(1316, 'SAN PEDRO MIXTEPEC (DISTR. 22)', 323, 20),
(1317, 'SAN PEDRO MIXTEPEC - DISTR. 22 -', 324, 20),
(1318, 'SAN PEDRO MIXTEPEC - DISTR. 26 -', 325, 20),
(1319, 'SAN PEDRO MIXTEPEC JUQUILA', 326, 20),
(1320, 'SAN PEDRO MIXTEPEC MIAHUATLAN', 327, 20),
(1321, 'SAN PEDRO MOLINOS', 328, 20),
(1322, 'SAN PEDRO NOPALA', 329, 20),
(1323, 'SAN PEDRO OCOPETATILLO', 330, 20),
(1324, 'SAN PEDRO OCOTEPEC', 331, 20),
(1325, 'SAN PEDRO POCHUTLA', 332, 20),
(1326, 'SAN PEDRO QUIATONI', 333, 20),
(1327, 'SAN PEDRO SOCHIAPAM', 334, 20),
(1328, 'SAN PEDRO TAPANATEPEC', 335, 20),
(1329, 'SAN PEDRO TAVICHE', 336, 20),
(1330, 'SAN PEDRO TEOZACOALCO', 337, 20),
(1331, 'SAN PEDRO TEUTILA', 338, 20),
(1332, 'SAN PEDRO TIDAÁ', 339, 20),
(1333, 'SAN PEDRO TOPILTEPEC', 340, 20),
(1334, 'SAN PEDRO TOTOLAPA', 341, 20),
(1335, 'SAN PEDRO TUTUTEPEC', 342, 20),
(1336, 'SAN PEDRO Y SAN PABLO AYUTLA', 343, 20),
(1337, 'SAN PEDRO Y SAN PABLO TEPOSCOLULA', 344, 20),
(1338, 'SAN PEDRO Y SAN PABLO TEQUIXTEPEC', 345, 20),
(1339, 'SAN PEDRO YANERI', 346, 20),
(1340, 'SAN PEDRO YÓLOX', 347, 20),
(1341, 'SAN PEDRO YUCUNAMA', 348, 20),
(1342, 'SAN RAYMUNDO JALPAN', 349, 20),
(1343, 'SAN SEBASTIÁN ABASOLO', 350, 20),
(1344, 'SAN SEBASTIÁN COATLÁN', 351, 20),
(1345, 'SAN SEBASTIÁN IXCAPA', 352, 20),
(1346, 'SAN SEBASTIÁN NICANANDUTA', 353, 20),
(1347, 'SAN SEBASTIÁN RÍO HONDO', 354, 20),
(1348, 'SAN SEBASTIÁN TECOMAXTLAHUACA', 355, 20),
(1349, 'SAN SEBASTIÁN TEITIPAC', 356, 20),
(1350, 'SAN SEBASTIÁN TUTLA', 357, 20),
(1351, 'SAN SIMÓN ALMOLONGAS', 358, 20),
(1352, 'SAN SIMÓN ZAHUATLÁN', 359, 20),
(1353, 'SAN VICENTE COATLÁN', 360, 20),
(1354, 'SAN VICENTE LACHIXÍO', 361, 20),
(1355, 'SAN VICENTE NUÑÚ', 362, 20),
(1356, 'SANTA ANA', 363, 20),
(1357, 'SANTA ANA ATEIXTLAHUACA', 364, 20),
(1358, 'SANTA ANA CUAUHTÉMOC', 365, 20),
(1359, 'SANTA ANA DEL VALLE', 366, 20),
(1360, 'SANTA ANA TAVELA', 367, 20),
(1361, 'SANTA ANA TLAPACOYAN', 368, 20),
(1362, 'SANTA ANA YARENI', 369, 20),
(1363, 'SANTA ANA ZEGACHE', 370, 20),
(1364, 'SANTA CATALINA QUIERI', 371, 20),
(1365, 'SANTA CATARINA CUIXTLA', 372, 20),
(1366, 'SANTA CATARINA IXTEPEJI', 373, 20),
(1367, 'SANTA CATARINA JUQUILA', 374, 20),
(1368, 'SANTA CATARINA LACHATAO', 375, 20),
(1369, 'SANTA CATARINA LOXICHA', 376, 20),
(1370, 'SANTA CATARINA MECHOACÁN', 377, 20),
(1371, 'SANTA CATARINA MINAS', 378, 20),
(1372, 'SANTA CATARINA QUIANÉ', 379, 20),
(1373, 'SANTA CATARINA QUIOQUITANI', 380, 20),
(1374, 'SANTA CATARINA TAYATA', 381, 20),
(1375, 'SANTA CATARINA TICUÁ', 382, 20),
(1376, 'SANTA CATARINA YOSONOTÚ', 383, 20),
(1377, 'SANTA CATARINA ZAPOQUILA', 384, 20),
(1378, 'SANTA CRUZ ACATEPEC', 385, 20),
(1379, 'SANTA CRUZ AMILPAS', 386, 20),
(1380, 'SANTA CRUZ DE BRAVO', 387, 20),
(1381, 'SANTA CRUZ ITUNDUJIA', 388, 20),
(1382, 'SANTA CRUZ MIXTEPEC', 389, 20),
(1383, 'SANTA CRUZ NUNDACO', 390, 20),
(1384, 'SANTA CRUZ PAPALUTLA', 391, 20),
(1385, 'SANTA CRUZ TACACHE DE MINA', 392, 20),
(1386, 'SANTA CRUZ TACAHUA', 393, 20),
(1387, 'SANTA CRUZ TAYATA', 394, 20),
(1388, 'SANTA CRUZ XITLA', 395, 20),
(1389, 'SANTA CRUZ XOXOCOTLAN', 396, 20),
(1390, 'SANTA CRUZ ZENZONTEPEC', 397, 20),
(1391, 'SANTA GERTRUDIS', 398, 20),
(1392, 'SANTA INÉS DE ZARAGOZA', 399, 20),
(1393, 'SANTA INÉS DEL MONTE', 400, 20),
(1394, 'SANTA INÉS YATZECHE', 401, 20),
(1395, 'SANTA LUCÍA DEL CAMINO', 402, 20),
(1396, 'SANTA LUCÍA MIAHUATLÁN', 403, 20),
(1397, 'SANTA LUCÍA MONTEVERDE', 404, 20),
(1398, 'SANTA LUCÍA OCOTLÁN', 405, 20),
(1399, 'SANTA MAGDALENA JICOTLÁN', 406, 20),
(1400, 'SANTA MARÍA ALOTEPEC', 407, 20),
(1401, 'SANTA MARÍA APAZCO', 408, 20),
(1402, 'SANTA MARÍA ATZOMPA', 409, 20),
(1403, 'SANTA MARÍA CAMOTLÁN', 410, 20),
(1404, 'SANTA MARÍA CHACHOAPAM', 411, 20),
(1405, 'SANTA MARÍA CHILCHOTLA', 412, 20),
(1406, 'SANTA MARÍA CHIMALAPA', 413, 20),
(1407, 'SANTA MARÍA COLOTEPEC', 414, 20),
(1408, 'SANTA MARÍA CORTIJO', 415, 20),
(1409, 'SANTA MARÍA COYOTEPEC', 416, 20),
(1410, 'SANTA MARÍA DEL ROSARIO', 417, 20),
(1411, 'SANTA MARÍA DEL TULE', 418, 20),
(1412, 'SANTA MARÍA ECATEPEC', 419, 20),
(1413, 'SANTA MARÍA GUELACÉ', 420, 20),
(1414, 'SANTA MARÍA GUIENAGATI', 421, 20),
(1415, 'SANTA MARÍA HUATULCO', 422, 20),
(1416, 'SANTA MARÍA HUAZOLOTITLÁN', 423, 20),
(1417, 'SANTA MARÍA IPALAPA', 424, 20),
(1418, 'SANTA MARÍA IXCATLÁN', 425, 20),
(1419, 'SANTA MARÍA JACATEPEC', 426, 20),
(1420, 'SANTA MARÍA JALAPA DEL MARQUÉS', 427, 20),
(1421, 'SANTA MARÍA JALTIANGUIS', 428, 20),
(1422, 'SANTA MARÍA LA ASUNCIÓN', 429, 20),
(1423, 'SANTA MARÍA LACHIXÍO', 430, 20),
(1424, 'SANTA MARÍA MIXTEQUILLA', 431, 20),
(1425, 'SANTA MARÍA NATÍVITAS', 432, 20),
(1426, 'SANTA MARÍA NDUAYACO', 433, 20),
(1427, 'SANTA MARÍA OZOLOTEPEC', 434, 20),
(1428, 'SANTA MARÍA PAPALO', 435, 20),
(1429, 'SANTA MARÍA PEÑOLES', 436, 20),
(1430, 'SANTA MARÍA PETAPA', 437, 20),
(1431, 'SANTA MARÍA QUIEGOLANI', 438, 20),
(1432, 'SANTA MARÍA SOLA', 439, 20),
(1433, 'SANTA MARÍA TATALTEPEC', 440, 20),
(1434, 'SANTA MARÍA TECOMAVACA', 441, 20),
(1435, 'SANTA MARÍA TEMAXCALAPA', 442, 20),
(1436, 'SANTA MARÍA TEMAXCALTEPEC', 443, 20),
(1437, 'SANTA MARÍA TEOPOXCO', 444, 20),
(1438, 'SANTA MARÍA TEPANTLALI', 445, 20),
(1439, 'SANTA MARÍA TEXCATITLÁN', 446, 20),
(1440, 'SANTA MARÍA TLAHUITOLTEPEC', 447, 20),
(1441, 'SANTA MARÍA TLALIXTAC', 448, 20),
(1442, 'SANTA MARÍA TONAMECA', 449, 20),
(1443, 'SANTA MARÍA TOTOLAPILLA', 450, 20),
(1444, 'SANTA MARÍA XADANI', 451, 20),
(1445, 'SANTA MARÍA YALINA', 452, 20),
(1446, 'SANTA MARÍA YAVESÍA', 453, 20),
(1447, 'SANTA MARÍA YOLOTEPEC', 454, 20),
(1448, 'SANTA MARÍA YOSOYÚA', 455, 20),
(1449, 'SANTA MARÍA YUCUHITI', 456, 20),
(1450, 'SANTA MARÍA ZACATEPEC', 457, 20),
(1451, 'SANTA MARÍA ZANIZA', 458, 20),
(1452, 'SANTA MARÍA ZOQUITLÁN', 459, 20),
(1453, 'SANTIAGO AMOLTEPEC', 460, 20),
(1454, 'SANTIAGO APOALA', 461, 20),
(1455, 'SANTIAGO APÓSTOL', 462, 20),
(1456, 'SANTIAGO ASTATA', 463, 20),
(1457, 'SANTIAGO ATITLÁN', 464, 20),
(1458, 'SANTIAGO AYUQUILILLA', 465, 20),
(1459, 'SANTIAGO CACALOXTEPEC', 466, 20),
(1460, 'SANTIAGO CAMOTLÁN', 467, 20),
(1461, 'SANTIAGO CHAZUMBA', 468, 20),
(1462, 'SANTIAGO CHOAPAM', 469, 20),
(1463, 'SANTIAGO COMALTEPEC', 470, 20),
(1464, 'SANTIAGO DEL RÍO', 471, 20),
(1465, 'SANTIAGO HUAJOLOTITLÁN', 472, 20),
(1466, 'SANTIAGO HUAUCLILLA', 473, 20),
(1467, 'SANTIAGO IHUITLÁN PLUMAS', 474, 20),
(1468, 'SANTIAGO IXCUINTEPEC', 475, 20),
(1469, 'SANTIAGO IXTAYUTLA', 476, 20),
(1470, 'SANTIAGO JAMILTEPEC', 477, 20),
(1471, 'SANTIAGO JOCOTEPEC', 478, 20),
(1472, 'SANTIAGO JUXTLAHUACA', 479, 20),
(1473, 'SANTIAGO LACHIGUIRÍ', 480, 20),
(1474, 'SANTIAGO LALOPA', 481, 20),
(1475, 'SANTIAGO LAOLLAGA', 482, 20),
(1476, 'SANTIAGO LAXOPA', 483, 20),
(1477, 'SANTIAGO LLANO GRANDE', 484, 20),
(1478, 'SANTIAGO MATATLÁN', 485, 20),
(1479, 'SANTIAGO MILTEPEC', 486, 20),
(1480, 'SANTIAGO MINAS', 487, 20),
(1481, 'SANTIAGO NACALTEPEC', 488, 20),
(1482, 'SANTIAGO NEJAPILLA', 489, 20),
(1483, 'SANTIAGO NILTEPEC', 490, 20),
(1484, 'SANTIAGO NUNDICHE', 491, 20),
(1485, 'SANTIAGO NUYOÓ', 492, 20),
(1486, 'SANTIAGO PINOTEPA NACIONAL', 493, 20),
(1487, 'SANTIAGO SUCHILQUITONGO', 494, 20),
(1488, 'SANTIAGO TAMAZOLA', 495, 20),
(1489, 'SANTIAGO TAPEXTLA', 496, 20),
(1490, 'SANTIAGO TENANGO', 497, 20),
(1491, 'SANTIAGO TEPETLAPA', 498, 20),
(1492, 'SANTIAGO TETEPEC', 499, 20),
(1493, 'SANTIAGO TEXCALCINGO', 500, 20),
(1494, 'SANTIAGO TEXTITLÁN', 501, 20),
(1495, 'SANTIAGO TILANTONGO', 502, 20),
(1496, 'SANTIAGO TILLO', 503, 20),
(1497, 'SANTIAGO TLAZOYALTEPEC', 504, 20),
(1498, 'SANTIAGO XANICA', 505, 20),
(1499, 'SANTIAGO XIACUÍ', 506, 20),
(1500, 'SANTIAGO YAITEPEC', 507, 20),
(1501, 'SANTIAGO YAVEO', 508, 20),
(1502, 'SANTIAGO YOLOMÉCATL', 509, 20),
(1503, 'SANTIAGO YOSONDÚA', 510, 20),
(1504, 'SANTIAGO YUCUYACHI', 511, 20),
(1505, 'SANTIAGO ZACATEPEC', 512, 20),
(1506, 'SANTIAGO ZOOCHILA', 513, 20),
(1507, 'SANTO DOMINGO ALBARRADAS', 514, 20),
(1508, 'SANTO DOMINGO ARMENTA', 515, 20),
(1509, 'SANTO DOMINGO CHIHUITÁN', 516, 20),
(1510, 'SANTO DOMINGO DE MORELOS', 517, 20),
(1511, 'SANTO DOMINGO INGENIO', 518, 20),
(1512, 'SANTO DOMINGO IXCATLÁN', 519, 20),
(1513, 'SANTO DOMINGO NUXAÁ', 520, 20),
(1514, 'SANTO DOMINGO OZOLOTEPEC', 521, 20),
(1515, 'SANTO DOMINGO PETAPA', 522, 20),
(1516, 'SANTO DOMINGO ROAYAGA', 523, 20),
(1517, 'SANTO DOMINGO TEHUANTEPEC', 524, 20),
(1518, 'SANTO DOMINGO TEOJOMULCO', 525, 20),
(1519, 'SANTO DOMINGO TEPUXTEPEC', 526, 20),
(1520, 'SANTO DOMINGO TLATAYAPAM', 527, 20),
(1521, 'SANTO DOMINGO TOMALTEPEC', 528, 20),
(1522, 'SANTO DOMINGO TONALÁ', 529, 20),
(1523, 'SANTO DOMINGO TONALTEPEC', 530, 20),
(1524, 'SANTO DOMINGO XAGACÍA', 531, 20),
(1525, 'SANTO DOMINGO YANHUITLÁN', 532, 20),
(1526, 'SANTO DOMINGO YODOHINO', 533, 20),
(1527, 'SANTO DOMINGO ZANATEPEC', 534, 20),
(1528, 'SANTO TOMÁS JALIEZA', 535, 20),
(1529, 'SANTO TOMÁS MAZALTEPEC', 536, 20),
(1530, 'SANTO TOMÁS OCOTEPEC', 537, 20),
(1531, 'SANTO TOMÁS TAMAZULAPAN', 538, 20),
(1532, 'SANTOS REYES NOPALA', 539, 20),
(1533, 'SANTOS REYES PÁPALO', 540, 20),
(1534, 'SANTOS REYES TEPEJILLO', 541, 20),
(1535, 'SANTOS REYES YUCUNÁ', 542, 20),
(1536, 'SILACAYOAPAM', 543, 20),
(1537, 'SILACAYOAPAN', 544, 20),
(1538, 'SITIO DE XITLAPEHUA', 545, 20),
(1539, 'SOLEDAD ETLA', 546, 20),
(1540, 'TAMAZULAPAM DEL ESPÍRITU SANTO', 547, 20),
(1541, 'TANETZE DE ZARAGOZA', 548, 20),
(1542, 'TANICHE', 549, 20),
(1543, 'TATALTEPEC DE VALDÉS', 550, 20),
(1544, 'TEOCOCUILCO DE MARCOS PÉREZ', 551, 20),
(1545, 'TEOTITLÁN DE FLORES MAGÓN', 552, 20),
(1546, 'TEOTITLÁN DEL VALLE', 553, 20),
(1547, 'TEOTONGO', 554, 20),
(1548, 'TEPELMEME VILLA DE MORELOS', 555, 20),
(1549, 'TEZOATLÁN DE SEGURA Y LUNA', 556, 20),
(1550, 'TLACOLULA DE MATAMOROS', 557, 20),
(1551, 'TLACOTEPEC PLUMAS', 558, 20),
(1552, 'TLALIXTAC DE CABRERA', 559, 20),
(1553, 'TLAXIACO', 560, 20),
(1554, 'TOTONTEPEC VILLA DE MORELOS', 561, 20),
(1555, 'TRINIDAD ZAACHILA', 562, 20),
(1556, 'UNIÓN HIDALGO', 563, 20),
(1557, 'VALERIO TRUJANO', 564, 20),
(1558, 'VILLA DE CHILAPA DE DÍAZ', 565, 20),
(1559, 'VILLA DE ETLA', 566, 20),
(1560, 'VILLA DE TAMAZULAPAM DEL PROGRESO', 567, 20),
(1561, 'VILLA DE TUTUTEPEC DE MELCHOR OCAMPO', 568, 20),
(1562, 'VILLA DE ZAACHILA', 569, 20),
(1563, 'VILLA DÍAZ ORDAZ', 570, 20),
(1564, 'VILLA HIDALGO', 571, 20),
(1565, 'VILLA SOLA DE VEGA', 572, 20),
(1566, 'VILLA TALEA DE CASTRO', 573, 20);
INSERT INTO `personamunicipio` (`idmunicipio`, `nombre`, `clave`, `idEstado`) VALUES
(1567, 'VILLA TEJUPAM DE LA UNIÓN', 574, 20),
(1568, 'YAXE', 575, 20),
(1569, 'YOGANA', 576, 20),
(1570, 'YUTANDUCHI DE GUERRERO', 577, 20),
(1571, 'ZAACHILA', 578, 20),
(1572, 'ZAPOTITLÁN DEL RÍO', 579, 20),
(1573, 'ZAPOTITLÁN LAGUNAS', 580, 20),
(1574, 'ZAPOTITLÁN PALMAS', 581, 20),
(1575, 'ZIMATLÁN DE ALVAREZ', 582, 20),
(1576, 'ACAJETE', 1, 21),
(1577, 'ACATENO', 2, 21),
(1578, 'ACATLÁN', 3, 21),
(1579, 'ACATZINGO', 4, 21),
(1580, 'ACTEOPAN', 5, 21),
(1581, 'AHUACATLÁN', 6, 21),
(1582, 'AHUATLÁN', 7, 21),
(1583, 'AHUAZOTEPEC', 8, 21),
(1584, 'AHUEHUETITLA', 9, 21),
(1585, 'AJALPAN', 10, 21),
(1586, 'ALBINO ZERTUCHE', 11, 21),
(1587, 'ALJOJUCA', 12, 21),
(1588, 'ALTEPEXI', 13, 21),
(1589, 'AMIXTLÁN', 14, 21),
(1590, 'AMOZOC', 15, 21),
(1591, 'AQUIXTLA', 16, 21),
(1592, 'ATEMPAN', 17, 21),
(1593, 'ATEXCAL', 18, 21),
(1594, 'ATLEQUIZAYAN', 19, 21),
(1595, 'ATLIXCO', 20, 21),
(1596, 'ATOYATEMPAN', 21, 21),
(1597, 'ATZALA', 22, 21),
(1598, 'ATZITZIHUACÁN', 23, 21),
(1599, 'ATZITZINTLA', 24, 21),
(1600, 'AXUTLA', 25, 21),
(1601, 'AYOTOXCO DE GUERRERO', 26, 21),
(1602, 'CALPAN', 27, 21),
(1603, 'CALTEPEC', 28, 21),
(1604, 'CAMOCUAUTLA', 29, 21),
(1605, 'CAÑADA MORELOS', 30, 21),
(1606, 'CAXHUACAN', 31, 21),
(1607, 'CHALCHICOMULA DE SESMA', 32, 21),
(1608, 'CHAPULCO', 33, 21),
(1609, 'CHIAUTLA', 34, 21),
(1610, 'CHIAUTZINGO', 35, 21),
(1611, 'CHICHIQUILA', 36, 21),
(1612, 'CHICONCUAUTLA', 37, 21),
(1613, 'CHIETLA', 38, 21),
(1614, 'CHIGMECATITLÁN', 39, 21),
(1615, 'CHIGNAHUAPAN', 40, 21),
(1616, 'CHIGNAUTLA', 41, 21),
(1617, 'CHILA', 42, 21),
(1618, 'CHILA DE LA SAL', 43, 21),
(1619, 'CHILA HONEY', 44, 21),
(1620, 'CHILCHOTLA', 45, 21),
(1621, 'CHINANTLA', 46, 21),
(1622, 'COATEPEC', 47, 21),
(1623, 'COATZINGO', 48, 21),
(1624, 'COHETZALA', 49, 21),
(1625, 'COHUECÁN', 50, 21),
(1626, 'CORONANGO', 51, 21),
(1627, 'COXCATLÁN', 52, 21),
(1628, 'COYOMEAPAN', 53, 21),
(1629, 'COYOTEPEC', 54, 21),
(1630, 'CUAPIAXTLA DE MADERO', 55, 21),
(1631, 'CUAUTEMPAN', 56, 21),
(1632, 'CUAUTINCHÁN', 57, 21),
(1633, 'CUAUTLANCINGO', 58, 21),
(1634, 'CUAYUCA', 59, 21),
(1635, 'CUAYUCA DE ANDRADE', 60, 21),
(1636, 'CUETZALAN DEL PROGRESO', 61, 21),
(1637, 'CUYOACO', 62, 21),
(1638, 'DOMINGO ARENAS', 63, 21),
(1639, 'ELOXOCHITLÁN', 64, 21),
(1640, 'EPATLÁN', 65, 21),
(1641, 'ESPERANZA', 66, 21),
(1642, 'FRANCISCO Z. MENA', 67, 21),
(1643, 'GENERAL FELIPE ANGELES', 68, 21),
(1644, 'GUADALUPE', 69, 21),
(1645, 'GUADALUPE VICTORIA', 70, 21),
(1646, 'HERMENEGILDO GALEANA', 71, 21),
(1647, 'HONEY', 72, 21),
(1648, 'HUAQUECHULA', 73, 21),
(1649, 'HUATLATLAUCA', 74, 21),
(1650, 'HUAUCHINANGO', 75, 21),
(1651, 'HUEHUETLA', 76, 21),
(1652, 'HUEHUETLÁN EL CHICO', 77, 21),
(1653, 'HUEHUETLÁN EL GRANDE', 78, 21),
(1654, 'HUEJOTZINGO', 79, 21),
(1655, 'HUEYAPAN', 80, 21),
(1656, 'HUEYTAMALCO', 81, 21),
(1657, 'HUEYTLALPAN', 82, 21),
(1658, 'HUITZILAN DE SERDÁN', 83, 21),
(1659, 'HUITZILTEPEC', 84, 21),
(1660, 'IGNACIO ALLENDE', 85, 21),
(1661, 'IXCAMILPA DE GUERRERO', 86, 21),
(1662, 'IXCAQUIXTLA', 87, 21),
(1663, 'IXTACAMAXTITLÁN', 88, 21),
(1664, 'IXTEPEC', 89, 21),
(1665, 'IZÚCAR DE MATAMOROS', 90, 21),
(1666, 'JALPAN', 91, 21),
(1667, 'JOLALPAN', 92, 21),
(1668, 'JONOTLA', 93, 21),
(1669, 'JOPALA', 94, 21),
(1670, 'JUAN C. BONILLA', 95, 21),
(1671, 'JUAN GALINDO', 96, 21),
(1672, 'JUAN N. MÉNDEZ', 97, 21),
(1673, 'LA MAGDALENA TLATLAUQUITEPEC', 98, 21),
(1674, 'LAFRAGUA', 99, 21),
(1675, 'LIBRES', 100, 21),
(1676, 'LOS REYES DE JUÁREZ', 101, 21),
(1677, 'MAZAPILTEPEC DE JUÁREZ', 102, 21),
(1678, 'MIXTLA', 103, 21),
(1679, 'MOLCAXAC', 104, 21),
(1680, 'MORELOS CANADA', 105, 21),
(1681, 'NAUPAN', 106, 21),
(1682, 'NAUZONTLA', 107, 21),
(1683, 'NEALTICAN', 108, 21),
(1684, 'NICOLÁS BRAVO', 109, 21),
(1685, 'NOPALUCAN', 110, 21),
(1686, 'OCOTEPEC', 111, 21),
(1687, 'OCOYUCAN', 112, 21),
(1688, 'OLINTLA', 113, 21),
(1689, 'ORIENTAL', 114, 21),
(1690, 'PAHUATLÁN', 115, 21),
(1691, 'PALMAR DE BRAVO', 116, 21),
(1692, 'PANTEPEC', 117, 21),
(1693, 'PETLALCINGO', 118, 21),
(1694, 'PIAXTLA', 119, 21),
(1695, 'PUEBLA', 120, 21),
(1696, 'QUECHOLAC', 121, 21),
(1697, 'QUIMIXTLÁN', 122, 21),
(1698, 'RAFAEL LARA GRAJALES', 123, 21),
(1699, 'SAN ANDRÉS CHOLULA', 124, 21),
(1700, 'SAN ANTONIO CAÑADA', 125, 21),
(1701, 'SAN DIEGO LA MESA TOCHIMILTZINGO', 126, 21),
(1702, 'SAN FELIPE TEOTLALCINGO', 127, 21),
(1703, 'SAN FELIPE TEPATLÁN', 128, 21),
(1704, 'SAN GABRIEL CHILAC', 129, 21),
(1705, 'SAN GREGORIO ATZOMPA', 130, 21),
(1706, 'SAN JERÓNIMO TECUANIPAN', 131, 21),
(1707, 'SAN JERÓNIMO XAYACATLÁN', 132, 21),
(1708, 'SAN JOSÉ CHIAPA', 133, 21),
(1709, 'SAN JOSÉ MIAHUATLÁN', 134, 21),
(1710, 'SAN JUAN ATENCO', 135, 21),
(1711, 'SAN JUAN ATZOMPA', 136, 21),
(1712, 'SAN MARTÍN TEXMELUCAN', 137, 21),
(1713, 'SAN MARTÍN TOTOLTEPEC', 138, 21),
(1714, 'SAN MATÍAS TLALANCALECA', 139, 21),
(1715, 'SAN MIGUEL IXITLÁN', 140, 21),
(1716, 'SAN MIGUEL XOXTLA', 141, 21),
(1717, 'SAN NICOLÁS BUENOS AIRES', 142, 21),
(1718, 'SAN NICOLAS DE BUENOS AIRES', 143, 21),
(1719, 'SAN NICOLÁS DE LOS RANCHOS', 144, 21),
(1720, 'SAN NICOLAS LOS RANCHOS', 145, 21),
(1721, 'SAN PABLO ANICANO', 146, 21),
(1722, 'SAN PEDRO CHOLULA', 147, 21),
(1723, 'SAN PEDRO YELOIXTLAHUACA', 148, 21),
(1724, 'SAN PEDRO YELOIXTLAHUACAN', 149, 21),
(1725, 'SAN SALVADOR EL SECO', 150, 21),
(1726, 'SAN SALVADOR EL VERDE', 151, 21),
(1727, 'SAN SALVADOR HUIXCOLOTLA', 152, 21),
(1728, 'SAN SEBASTIÁN TLACOTEPEC', 153, 21),
(1729, 'SANTA CATARINA TLALTEMPAN', 154, 21),
(1730, 'SANTA INÉS AHUATEMPAN', 155, 21),
(1731, 'SANTA ISABEL CHOLULA', 156, 21),
(1732, 'SANTIAGO MIAHUATLÁN', 157, 21),
(1733, 'SANTO DOMINGO HUEHUETLAN', 158, 21),
(1734, 'SANTO TOMÁS HUEYOTLIPAN', 159, 21),
(1735, 'SOLTEPEC', 160, 21),
(1736, 'TECALI DE HERRERA', 161, 21),
(1737, 'TECAMACHALCO', 162, 21),
(1738, 'TECOMATLÁN', 163, 21),
(1739, 'TEHUACÁN', 164, 21),
(1740, 'TEHUITZINGO', 165, 21),
(1741, 'TENAMPULCO', 166, 21),
(1742, 'TEOPANTLÁN', 167, 21),
(1743, 'TEOTLALCO', 168, 21),
(1744, 'TEPANCO DE LÓPEZ', 169, 21),
(1745, 'TEPANGO DE RODRÍGUEZ', 170, 21),
(1746, 'TEPATLAXCO DE HIDALGO', 171, 21),
(1747, 'TEPEACA', 172, 21),
(1748, 'TEPEMAXALCO', 173, 21),
(1749, 'TEPEOJUMA', 174, 21),
(1750, 'TEPETZINTLA', 175, 21),
(1751, 'TEPEXCO', 176, 21),
(1752, 'TEPEXI DE RODRÍGUEZ', 177, 21),
(1753, 'TEPEYAHUALCO', 178, 21),
(1754, 'TEPEYAHUALCO CUAUHTEMOC', 179, 21),
(1755, 'TEPEYAHUALCO DE CUAUHTÉMOC', 180, 21),
(1756, 'TETELA DE OCAMPO', 181, 21),
(1757, 'TETELES DE AVILA CASTILLO', 182, 21),
(1758, 'TEZIUTLÁN', 183, 21),
(1759, 'TIANGUISMANALCO', 184, 21),
(1760, 'TILAPA', 185, 21),
(1761, 'TLACHICHUCA', 186, 21),
(1762, 'TLACOTEPEC DE BENITO JUÁREZ', 187, 21),
(1763, 'TLACUILOTEPEC', 188, 21),
(1764, 'TLAHUAPAN', 189, 21),
(1765, 'TLALTENANGO', 190, 21),
(1766, 'TLANEPANTLA', 191, 21),
(1767, 'TLAOLA', 192, 21),
(1768, 'TLAPACOYA', 193, 21),
(1769, 'TLAPANALÁ', 194, 21),
(1770, 'TLATLAUQUITEPEC', 195, 21),
(1771, 'TLAXCO', 196, 21),
(1772, 'TOCHIMILCO', 197, 21),
(1773, 'TOCHTEPEC', 198, 21),
(1774, 'TOTOLTEPEC DE GUERRERO', 199, 21),
(1775, 'TULCINGO', 200, 21),
(1776, 'TUZAMAPAN DE GALEANA', 201, 21),
(1777, 'TZICATLACOYAN', 202, 21),
(1778, 'VENUSTIANO CARRANZA', 203, 21),
(1779, 'VICENTE GUERRERO', 204, 21),
(1780, 'XAYACATLÁN DE BRAVO', 205, 21),
(1781, 'XICOTEPEC', 206, 21),
(1782, 'XICOTLÁN', 207, 21),
(1783, 'XIUTETELCO', 208, 21),
(1784, 'XOCHIAPULCO', 209, 21),
(1785, 'XOCHILTEPEC', 210, 21),
(1786, 'XOCHITLAN', 211, 21),
(1787, 'XOCHITLÁN DE VICENTE SUÁREZ', 212, 21),
(1788, 'XOCHITLÁN TODOS SANTOS', 213, 21),
(1789, 'YAONÁHUAC', 214, 21),
(1790, 'YEHUALTEPEC', 215, 21),
(1791, 'ZACAPALA', 216, 21),
(1792, 'ZACAPOAXTLA', 217, 21),
(1793, 'ZACATLÁN', 218, 21),
(1794, 'ZAPOTITLÁN', 219, 21),
(1795, 'ZAPOTITLÁN DE MÉNDEZ', 220, 21),
(1796, 'ZARAGOZA', 221, 21),
(1797, 'ZAUTLA', 222, 21),
(1798, 'ZIHUATEUTLA', 223, 21),
(1799, 'ZINACATEPEC', 224, 21),
(1800, 'ZONGOZOTLA', 225, 21),
(1801, 'ZOQUIAPAN', 226, 21),
(1802, 'ZOQUITLÁN', 227, 21),
(1803, 'AMEALCO DE BONFIL', 1, 22),
(1804, 'ARROYO SECO', 2, 22),
(1805, 'CADEREYTA DE MONTES', 3, 22),
(1806, 'COLÓN', 4, 22),
(1807, 'CORREGIDORA', 5, 22),
(1808, 'EL MARQUÉS', 6, 22),
(1809, 'EZEQUIEL MONTES', 7, 22),
(1810, 'HUIMILPAN', 8, 22),
(1811, 'JALPAN DE SERRA', 9, 22),
(1812, 'LANDA DE MATAMOROS', 10, 22),
(1813, 'PEDRO ESCOBEDO', 11, 22),
(1814, 'PEÑAMILLER', 12, 22),
(1815, 'PINAL DE AMOLES', 13, 22),
(1816, 'QUERÉTARO', 14, 22),
(1817, 'SAN JOAQUÍN', 15, 22),
(1818, 'SAN JUAN DEL RÍO', 16, 22),
(1819, 'TEQUISQUIAPAN', 17, 22),
(1820, 'TOLIMÁN', 18, 22),
(1821, 'BENITO JUÁREZ', 1, 23),
(1822, 'COZUMEL', 2, 23),
(1823, 'FELIPE CARRILLO PUERTO', 3, 23),
(1824, 'ISLA MUJERES', 4, 23),
(1825, 'JOSÉ MARÍA MORELOS', 5, 23),
(1826, 'LÁZARO CÁRDENAS', 6, 23),
(1827, 'OTHÓN P. BLANCO', 7, 23),
(1828, 'SOLIDARIDAD', 8, 23),
(1829, 'AHUALULCO', 1, 24),
(1830, 'ALAQUINES', 2, 24),
(1831, 'AQUISMÓN', 3, 24),
(1832, 'ARMADILLO DE LOS INFANTE', 4, 24),
(1833, 'AXTLA DE TERRAZAS', 5, 24),
(1834, 'CÁRDENAS', 6, 24),
(1835, 'CATORCE', 7, 24),
(1836, 'CEDRAL', 8, 24),
(1837, 'CERRITOS', 9, 24),
(1838, 'CERRO DE SAN PEDRO', 10, 24),
(1839, 'CHARCAS', 11, 24),
(1840, 'CIUDAD DEL MAÍZ', 12, 24),
(1841, 'CIUDAD FERNÁNDEZ', 13, 24),
(1842, 'CIUDAD VALLES', 14, 24),
(1843, 'COXCATLÁN', 15, 24),
(1844, 'EBANO', 16, 24),
(1845, 'EL NARANJO', 17, 24),
(1846, 'GUADALCÁZAR', 18, 24),
(1847, 'HUEHUETLÁN', 19, 24),
(1848, 'LAGUNILLAS', 20, 24),
(1849, 'MATEHUALA', 21, 24),
(1850, 'MATLAPA', 22, 24),
(1851, 'MEXQUITIC DE CARMONA', 23, 24),
(1852, 'MOCTEZUMA', 24, 24),
(1853, 'RAYÓN', 25, 24),
(1854, 'RÍOVERDE', 26, 24),
(1855, 'SALINAS', 27, 24),
(1856, 'SAN ANTONIO', 28, 24),
(1857, 'SAN CIRO DE ACOSTA', 29, 24),
(1858, 'SAN LUIS POTOSÍ', 30, 24),
(1859, 'SAN MARTÍN CHALCHICUAUTLA', 31, 24),
(1860, 'SAN NICOLÁS TOLENTINO', 32, 24),
(1861, 'SAN VICENTE TANCUAYALAB', 33, 24),
(1862, 'SANTA CATARINA', 34, 24),
(1863, 'SANTA MARÍA DEL RÍO', 35, 24),
(1864, 'SANTO DOMINGO', 36, 24),
(1865, 'SOLEDAD DE GRACIANO SÁNCHEZ', 37, 24),
(1866, 'TAMASOPO', 38, 24),
(1867, 'TAMAZUNCHALE', 39, 24),
(1868, 'TAMPACÁN', 40, 24),
(1869, 'TAMPAMOLÓN CORONA', 41, 24),
(1870, 'TAMUÍN', 42, 24),
(1871, 'TANCANHUITZ DE SANTOS', 43, 24),
(1872, 'TANLAJÁS', 44, 24),
(1873, 'TANQUIÁN DE ESCOBEDO', 45, 24),
(1874, 'TIERRA NUEVA', 46, 24),
(1875, 'TIERRANUEVA', 47, 24),
(1876, 'VANEGAS', 48, 24),
(1877, 'VENADO', 49, 24),
(1878, 'VILLA DE ARISTA', 50, 24),
(1879, 'VILLA DE ARRIAGA', 51, 24),
(1880, 'VILLA DE GUADALUPE', 52, 24),
(1881, 'VILLA DE LA PAZ', 53, 24),
(1882, 'VILLA DE RAMOS', 54, 24),
(1883, 'VILLA DE REYES', 55, 24),
(1884, 'VILLA HIDALGO', 56, 24),
(1885, 'VILLA JUÁREZ', 57, 24),
(1886, 'XILITLA', 58, 24),
(1887, 'ZARAGOZA', 59, 24),
(1888, 'AHOME', 1, 25),
(1889, 'ANGOSTURA', 2, 25),
(1890, 'BADIRAGUATO', 3, 25),
(1891, 'CHOIX', 4, 25),
(1892, 'CONCORDIA', 5, 25),
(1893, 'COSALÁ', 6, 25),
(1894, 'CULIACÁN', 7, 25),
(1895, 'EL FUERTE', 8, 25),
(1896, 'ELOTA', 9, 25),
(1897, 'ESCUINAPA', 10, 25),
(1898, 'GUASAVE', 11, 25),
(1899, 'MAZATLÁN', 12, 25),
(1900, 'MOCORITO', 13, 25),
(1901, 'NAVOLATO', 14, 25),
(1902, 'ROSARIO', 15, 25),
(1903, 'SALVADOR ALVARADO', 16, 25),
(1904, 'SAN IGNACIO', 17, 25),
(1905, 'SINALOA', 18, 25),
(1906, 'ACONCHI', 1, 26),
(1907, 'AGUA PRIETA', 2, 26),
(1908, 'ALAMOS', 3, 26),
(1909, 'ALTAR', 4, 26),
(1910, 'ARIVECHI', 5, 26),
(1911, 'ARIZPE', 6, 26),
(1912, 'ATIL', 7, 26),
(1913, 'BACADÉHUACHI', 8, 26),
(1914, 'BACANORA', 9, 26),
(1915, 'BACERAC', 10, 26),
(1916, 'BACOACHI', 11, 26),
(1917, 'BÁCUM', 12, 26),
(1918, 'BANÁMICHI', 13, 26),
(1919, 'BAVIÁCORA', 14, 26),
(1920, 'BAVISPE', 15, 26),
(1921, 'BENJAMÍN HILL', 16, 26),
(1922, 'CABORCA', 17, 26),
(1923, 'CAJEME', 18, 26),
(1924, 'CANANEA', 19, 26),
(1925, 'CARBÓ', 20, 26),
(1926, 'CUCURPE', 21, 26),
(1927, 'CUMPAS', 22, 26),
(1928, 'DIVISADEROS', 23, 26),
(1929, 'EMPALME', 24, 26),
(1930, 'ETCHOJOA', 25, 26),
(1931, 'FRONTERAS', 26, 26),
(1932, 'GENERAL PLUTARCO ELÍAS CALLES', 27, 26),
(1933, 'GRANADOS', 28, 26),
(1934, 'GUAYMAS', 29, 26),
(1935, 'HERMOSILLO', 30, 26),
(1936, 'HUACHINERA', 31, 26),
(1937, 'HUÁSABAS', 32, 26),
(1938, 'HUATABAMPO', 33, 26),
(1939, 'HUÉPAC', 34, 26),
(1940, 'IMURIS', 35, 26),
(1941, 'LA COLORADA', 36, 26),
(1942, 'MAGDALENA', 37, 26),
(1943, 'MAZATÁN', 38, 26),
(1944, 'MOCTEZUMA', 39, 26),
(1945, 'NACO', 40, 26),
(1946, 'NÁCORI CHICO', 41, 26),
(1947, 'NACOZARI DE GARCÍA', 42, 26),
(1948, 'NAVOJOA', 43, 26),
(1949, 'NOGALES', 44, 26),
(1950, 'ONAVAS', 45, 26),
(1951, 'OPODEPE', 46, 26),
(1952, 'OQUITOA', 47, 26),
(1953, 'PITIQUITO', 48, 26),
(1954, 'PUERTO PEÑASCO', 49, 26),
(1955, 'QUIRIEGO', 50, 26),
(1956, 'RAYÓN', 51, 26),
(1957, 'ROSARIO', 52, 26),
(1958, 'SAHUARIPA', 53, 26),
(1959, 'SAN FELIPE DE JESÚS', 54, 26),
(1960, 'SAN JAVIER', 55, 26),
(1961, 'SAN LUIS RÍO COLORADO', 56, 26),
(1962, 'SAN MIGUEL DE HORCASITAS', 57, 26),
(1963, 'SAN PEDRO DE LA CUEVA', 58, 26),
(1964, 'SANTA ANA', 59, 26),
(1965, 'SANTA CRUZ', 60, 26),
(1966, 'SÁRIC', 61, 26),
(1967, 'SOYOPA', 62, 26),
(1968, 'SUAQUI GRANDE', 63, 26),
(1969, 'TEPACHE', 64, 26),
(1970, 'TRINCHERAS', 65, 26),
(1971, 'TUBUTAMA', 66, 26),
(1972, 'URES', 67, 26),
(1973, 'VILLA HIDALGO', 68, 26),
(1974, 'VILLA PESQUEIRA', 69, 26),
(1975, 'YÉCORA', 70, 26),
(1976, 'BALANCÁN', 1, 27),
(1977, 'CÁRDENAS', 2, 27),
(1978, 'CENTLA', 3, 27),
(1979, 'CENTRO', 4, 27),
(1980, 'COMALCALCO', 5, 27),
(1981, 'CUNDUACÁN', 6, 27),
(1982, 'EMILIANO ZAPATA', 7, 27),
(1983, 'HUIMANGUILLO', 8, 27),
(1984, 'JALAPA', 9, 27),
(1985, 'JALPA DE MÉNDEZ', 10, 27),
(1986, 'JONUTA', 11, 27),
(1987, 'MACUSPANA', 12, 27),
(1988, 'NACAJUCA', 13, 27),
(1989, 'PARAÍSO', 14, 27),
(1990, 'TACOTALPA', 15, 27),
(1991, 'TEAPA', 16, 27),
(1992, 'TENOSIQUE', 17, 27),
(1993, 'ABASOLO', 1, 28),
(1994, 'ALDAMA', 2, 28),
(1995, 'ALTAMIRA', 3, 28),
(1996, 'ANTIGUO MORELOS', 4, 28),
(1997, 'BURGOS', 5, 28),
(1998, 'BUSTAMANTE', 6, 28),
(1999, 'CAMARGO', 7, 28),
(2000, 'CASAS', 8, 28),
(2001, 'CIUDAD MADERO', 9, 28),
(2002, 'CRUILLAS', 10, 28),
(2003, 'EL MANTE', 11, 28),
(2004, 'GÓMEZ FARÍAS', 12, 28),
(2005, 'GONZÁLEZ', 13, 28),
(2006, 'GUERRERO', 14, 28),
(2007, 'GUSTAVO DÍAZ ORDAZ', 15, 28),
(2008, 'GÜEMEZ', 16, 28),
(2009, 'HIDALGO', 17, 28),
(2010, 'JAUMAVE', 18, 28),
(2011, 'JIMÉNEZ', 19, 28),
(2012, 'LLERA', 20, 28),
(2013, 'MAINERO', 21, 28),
(2014, 'MATAMOROS', 22, 28),
(2015, 'MÉNDEZ', 23, 28),
(2016, 'MIER', 24, 28),
(2017, 'MIGUEL ALEMÁN', 25, 28),
(2018, 'MIQUIHUANA', 26, 28),
(2019, 'NUEVO LAREDO', 27, 28),
(2020, 'NUEVO MORELOS', 28, 28),
(2021, 'OCAMPO', 29, 28),
(2022, 'PADILLA', 30, 28),
(2023, 'PALMILLAS', 31, 28),
(2024, 'REYNOSA', 32, 28),
(2025, 'RÍO BRAVO', 33, 28),
(2026, 'SAN CARLOS', 34, 28),
(2027, 'SAN FERNANDO', 35, 28),
(2028, 'SAN NICOLÁS', 36, 28),
(2029, 'SOTO LA MARINA', 37, 28),
(2030, 'TAMPICO', 38, 28),
(2031, 'TULA', 39, 28),
(2032, 'VALLE HERMOSO', 40, 28),
(2033, 'VICTORIA', 41, 28),
(2034, 'VILLAGRÁN', 42, 28),
(2035, 'XICOTÉNCATL', 43, 28),
(2036, 'ACUAMANALA DE MIGUEL HIDALGO', 1, 29),
(2037, 'ALTZAYANCA', 2, 29),
(2038, 'AMAXAC DE GUERRERO', 3, 29),
(2039, 'APETATITLÁN DE ANTONIO CARVAJAL', 4, 29),
(2040, 'APIZACO', 5, 29),
(2041, 'ATLANGATEPEC', 6, 29),
(2042, 'ATLZAYANCA', 7, 29),
(2043, 'BENITO JUÁREZ', 8, 29),
(2044, 'CALPULALPAN', 9, 29),
(2045, 'CHIAUTEMPAN', 10, 29),
(2046, 'CONTLA DE JUAN CUAMATZI', 11, 29),
(2047, 'CUAPIAXTLA', 12, 29),
(2048, 'CUAXOMULCO', 13, 29),
(2049, 'EL CARMEN TEQUEXQUITLA', 14, 29),
(2050, 'EMILIANO ZAPATA', 15, 29),
(2051, 'ESPAÑITA', 16, 29),
(2052, 'HUAMANTLA', 17, 29),
(2053, 'HUEYOTLIPAN', 18, 29),
(2054, 'IXTACUIXTLA DE MARIANO MATAMOROS', 19, 29),
(2055, 'IXTENCO', 20, 29),
(2056, 'LA MAGDALENA TLALTELULCO', 21, 29),
(2057, 'LÁZARO CÁRDENAS', 22, 29),
(2058, 'MAZATECOCHCO DE JOSÉ MARÍA MORELOS', 23, 29),
(2059, 'MUÑOZ DE DOMINGO ARENAS', 24, 29),
(2060, 'NANACAMILPA DE MARIANO ARISTA', 25, 29),
(2061, 'NATÍVITAS', 26, 29),
(2062, 'PANOTLA', 27, 29),
(2063, 'PAPALOTLA DE XICOHTÉNCATL', 28, 29),
(2064, 'SAN DAMIÁN TEXOLOC', 29, 29),
(2065, 'SAN FRANCISCO TETLANOHCAN', 30, 29),
(2066, 'SAN JERÓNIMO ZACUALPAN', 31, 29),
(2067, 'SAN JOSÉ TEACALCO', 32, 29),
(2068, 'SAN JUAN HUACTZINCO', 33, 29),
(2069, 'SAN LORENZO AXOCOMANITLA', 34, 29),
(2070, 'SAN LUCAS TECOPILCO', 35, 29),
(2071, 'SAN PABLO DEL MONTE', 36, 29),
(2072, 'SANCTÓRUM DE LÁZARO CÁRDENAS', 37, 29),
(2073, 'SANTA ANA NOPALUCAN', 38, 29),
(2074, 'SANTA APOLONIA TEACALCO', 39, 29),
(2075, 'SANTA CATARINA AYOMETLA', 40, 29),
(2076, 'SANTA CRUZ QUILEHTLA', 41, 29),
(2077, 'SANTA CRUZ TLAXCALA', 42, 29),
(2078, 'SANTA ISABEL XILOXOXTLA', 43, 29),
(2079, 'TENANCINGO', 44, 29),
(2080, 'TEOLOCHOLCO', 45, 29),
(2081, 'TEPETITLA DE LARDIZÁBAL', 46, 29),
(2082, 'TEPEYANCO', 47, 29),
(2083, 'TERRENATE', 48, 29),
(2084, 'TETLA DE LA SOLIDARIDAD', 49, 29),
(2085, 'TETLATLAHUCA', 50, 29),
(2086, 'TLAXCALA', 51, 29),
(2087, 'TLAXCO', 52, 29),
(2088, 'TOCATLÁN', 53, 29),
(2089, 'TOTOLAC', 54, 29),
(2090, 'TZOMPANTEPEC', 55, 29),
(2091, 'XALÓSTOC', 56, 29),
(2092, 'XALTOCAN', 57, 29),
(2093, 'XICOHTZINCO', 58, 29),
(2094, 'YAUHQUEMECAN', 59, 29),
(2095, 'YAUHQUEMEHCAN', 60, 29),
(2096, 'ZACATELCO', 61, 29),
(2097, 'ZITLALTEPEC DE TRINIDAD SÁNCHEZ SANTOS', 62, 29),
(2098, 'ACAJETE', 1, 30),
(2099, 'ACATLÁN', 2, 30),
(2100, 'ACAYUCAN', 3, 30),
(2101, 'ACTOPAN', 4, 30),
(2102, 'ACULA', 5, 30),
(2103, 'ACULTZINGO', 6, 30),
(2104, 'AGUA DULCE', 7, 30),
(2105, 'ALPATLÁHUAC', 8, 30),
(2106, 'ALTO LUCERO CLAUS.', 9, 30),
(2107, 'ALTO LUCERO DE GUTIÉRREZ BARRIOS', 10, 30),
(2108, 'ALTOTONGA', 11, 30),
(2109, 'ALVARADO', 12, 30),
(2110, 'AMATITLÁN', 13, 30),
(2111, 'AMATLÁN DE LOS REYES', 14, 30),
(2112, 'AMATLÁN TUXPAN', 15, 30),
(2113, 'ANGEL R. CABADA', 16, 30),
(2114, 'APAZAPAN', 17, 30),
(2115, 'AQUILA', 18, 30),
(2116, 'ASTACINGA', 19, 30),
(2117, 'ATLAHUILCO', 20, 30),
(2118, 'ATOYAC', 21, 30),
(2119, 'ATZACAN', 22, 30),
(2120, 'ATZALAN', 23, 30),
(2121, 'AYAHUALULCO', 24, 30),
(2122, 'BANDERILLA', 25, 30),
(2123, 'BENITO JUÁREZ', 26, 30),
(2124, 'BOCA DEL RÍO', 27, 30),
(2125, 'CALCAHUALCO', 28, 30),
(2126, 'CAMARÓN DE TEJEDA', 29, 30),
(2127, 'CAMERINO Z. MENDOZA', 30, 30),
(2128, 'CARLOS A. CARRILLO', 31, 30),
(2129, 'CARRILLO PUERTO', 32, 30),
(2130, 'CASTILLO DE TEAYO', 33, 30),
(2131, 'CATEMACO', 34, 30),
(2132, 'CAZONES DE HERRERA', 35, 30),
(2133, 'CERRO AZUL', 36, 30),
(2134, 'CHACALTIANGUIS', 37, 30),
(2135, 'CHALMA', 38, 30),
(2136, 'CHICONAMEL', 39, 30),
(2137, 'CHICONQUIACO', 40, 30),
(2138, 'CHICONTEPEC', 41, 30),
(2139, 'CHINAMECA', 42, 30),
(2140, 'CHINAMPA DE GOROSTIZA', 43, 30),
(2141, 'CHOCAMÁN', 44, 30),
(2142, 'CHONTLA', 45, 30),
(2143, 'CHUMATLÁN', 46, 30),
(2144, 'CITLALTÉPETL', 47, 30),
(2145, 'COACOATZINTLA', 48, 30),
(2146, 'COAHUITLÁN', 49, 30),
(2147, 'COATEPEC', 50, 30),
(2148, 'COATZACOALCOS', 51, 30),
(2149, 'COATZINTLA', 52, 30),
(2150, 'COETZALA', 53, 30),
(2151, 'COLIPA', 54, 30),
(2152, 'COMAPA', 55, 30),
(2153, 'CÓRDOBA', 56, 30),
(2154, 'COSAMALOAPAN', 57, 30),
(2155, 'COSAUTLÁN DE CARVAJAL', 58, 30),
(2156, 'COSCOMATEPEC', 59, 30),
(2157, 'COSOLEACAQUE', 60, 30),
(2158, 'COTAXTLA', 61, 30),
(2159, 'COXQUIHUI', 62, 30),
(2160, 'COYUTLA', 63, 30),
(2161, 'CUICHAPA', 64, 30),
(2162, 'CUITLÁHUAC', 65, 30),
(2163, 'EL HIGO', 66, 30),
(2164, 'EMILIANO ZAPATA', 67, 30),
(2165, 'ESPINAL', 68, 30),
(2166, 'FILOMENO MATA', 69, 30),
(2167, 'FORTÍN', 70, 30),
(2168, 'GUTIÉRREZ ZAMORA', 71, 30),
(2169, 'HIDALGOTITLÁN', 72, 30),
(2170, 'HUATUSCO', 73, 30),
(2171, 'HUAYACOCOTLA', 74, 30),
(2172, 'HUEYAPAN DE OCAMPO', 75, 30),
(2173, 'HUILOAPAN DE CUAUHTÉMOC', 76, 30),
(2174, 'IGNACIO DE LA LLAVE', 77, 30),
(2175, 'ILAMATLÁN', 78, 30),
(2176, 'ISLA', 79, 30),
(2177, 'IXCATEPEC', 80, 30),
(2178, 'IXHUACÁN DE LOS REYES', 81, 30),
(2179, 'IXHUATLÁN DE MADERO', 82, 30),
(2180, 'IXHUATLÁN DEL CAFÉ', 83, 30),
(2181, 'IXHUATLÁN DEL SURESTE', 84, 30),
(2182, 'IXHUATLANCILLO', 85, 30),
(2183, 'IXMATLAHUACAN', 86, 30),
(2184, 'IXTACZOQUITLÁN', 87, 30),
(2185, 'JALACINGO', 88, 30),
(2186, 'JALCOMULCO', 89, 30),
(2187, 'JÁLTIPAN', 90, 30),
(2188, 'JAMAPA', 91, 30),
(2189, 'JESÚS CARRANZA', 92, 30),
(2190, 'JILOTEPEC', 93, 30),
(2191, 'JOSÉ AZUETA', 94, 30),
(2192, 'JUAN RODRÍGUEZ CLARA', 95, 30),
(2193, 'JUCHIQUE DE FERRER', 96, 30),
(2194, 'LA ANTIGUA', 97, 30),
(2195, 'LA PERLA', 98, 30),
(2196, 'LANDERO Y COSS', 99, 30),
(2197, 'LAS CHOAPAS', 100, 30),
(2198, 'LAS MINAS', 101, 30),
(2199, 'LAS VIGAS DE RAMÍREZ', 102, 30),
(2200, 'LERDO DE TEJADA', 103, 30),
(2201, 'LOS REYES', 104, 30),
(2202, 'MAGDALENA', 105, 30),
(2203, 'MALTRATA', 106, 30),
(2204, 'MANLIO FABIO ALTAMIRANO', 107, 30),
(2205, 'MARIANO ESCOBEDO', 108, 30),
(2206, 'MARTÍNEZ DE LA TORRE', 109, 30),
(2207, 'MECATLÁN', 110, 30),
(2208, 'MECAYAPAN', 111, 30),
(2209, 'MEDELLÍN', 112, 30),
(2210, 'MIAHUATLÁN', 113, 30),
(2211, 'MINATITLÁN', 114, 30),
(2212, 'MISANTLA', 115, 30),
(2213, 'MIXTLA DE ALTAMIRANO', 116, 30),
(2214, 'MOLOACÁN', 117, 30),
(2215, 'NANCHITAL DE LÁZARO CÁRDENAS DEL RÍO', 118, 30),
(2216, 'NAOLINCO', 119, 30),
(2217, 'NARANJAL', 120, 30),
(2218, 'NAUTLA', 121, 30),
(2219, 'NOGALES', 122, 30),
(2220, 'OLUTA', 123, 30),
(2221, 'OMEALCA', 124, 30),
(2222, 'ORIZABA', 125, 30),
(2223, 'OTATITLÁN', 126, 30),
(2224, 'OTEAPAN', 127, 30),
(2225, 'OZULUAMA', 128, 30),
(2226, 'PAJAPAN', 129, 30),
(2227, 'PÁNUCO', 130, 30),
(2228, 'PAPANTLA', 131, 30),
(2229, 'PAPANTLA  CLAUS.', 132, 30),
(2230, 'PASO DE OVEJAS', 133, 30),
(2231, 'PASO DEL MACHO', 134, 30),
(2232, 'PEROTE', 135, 30),
(2233, 'PLATÓN SÁNCHEZ', 136, 30),
(2234, 'PLAYA VICENTE', 137, 30),
(2235, 'POZA RICA DE HIDALGO', 138, 30),
(2236, 'PUEBLO VIEJO', 139, 30),
(2237, 'PUENTE NACIONAL', 140, 30),
(2238, 'RAFAEL DELGADO', 141, 30),
(2239, 'RAFAEL LUCIO', 142, 30),
(2240, 'RÍO BLANCO', 143, 30),
(2241, 'SALTABARRANCA', 144, 30),
(2242, 'SAN ANDRÉS TENEJAPAN', 145, 30),
(2243, 'SAN ANDRÉS TUXTLA', 146, 30),
(2244, 'SAN JUAN EVANGELISTA', 147, 30),
(2245, 'SANTIAGO TUXTLA', 148, 30),
(2246, 'SAYULA DE ALEMÁN', 149, 30),
(2247, 'SOCHIAPA', 150, 30),
(2248, 'SOCONUSCO', 151, 30),
(2249, 'SOLEDAD ATZOMPA', 152, 30),
(2250, 'SOLEDAD DE DOBLADO', 153, 30),
(2251, 'SOTEAPAN', 154, 30),
(2252, 'TAMALÍN', 155, 30),
(2253, 'TAMIAHUA', 156, 30),
(2254, 'TAMPICO ALTO', 157, 30),
(2255, 'TANCOCO', 158, 30),
(2256, 'TANTIMA', 159, 30),
(2257, 'TANTOYUCA', 160, 30),
(2258, 'TATAHUICAPAN DE JUAREZ', 161, 30),
(2259, 'TATATILA', 162, 30),
(2260, 'TECOLUTLA', 163, 30),
(2261, 'TECOLUTLA    CLAUS.', 164, 30),
(2262, 'TEHUIPANGO', 165, 30),
(2263, 'TEMAPACHE', 166, 30),
(2264, 'TEMPOAL', 167, 30),
(2265, 'TENAMPA', 168, 30),
(2266, 'TENOCHTITLÁN', 169, 30),
(2267, 'TEOCELO', 170, 30),
(2268, 'TEPATLAXCO', 171, 30),
(2269, 'TEPETLÁN', 172, 30),
(2270, 'TEPETZINTLA', 173, 30),
(2271, 'TEQUILA', 174, 30),
(2272, 'TEXCATEPEC', 175, 30),
(2273, 'TEXHUACÁN', 176, 30),
(2274, 'TEXISTEPEC', 177, 30),
(2275, 'TEZONAPA', 178, 30),
(2276, 'TIERRA BLANCA', 179, 30),
(2277, 'TIHUATLÁN', 180, 30),
(2278, 'TLACHICHILCO', 181, 30),
(2279, 'TLACOJALPAN', 182, 30),
(2280, 'TLACOLULAN', 183, 30),
(2281, 'TLACOTALPAN', 184, 30),
(2282, 'TLACOTEPEC DE MEJÍA', 185, 30),
(2283, 'TLALIXCOYAN', 186, 30),
(2284, 'TLALNELHUAYOCAN', 187, 30),
(2285, 'TLALTETELA', 188, 30),
(2286, 'TLAPACOYAN', 189, 30),
(2287, 'TLAQUILPAN', 190, 30),
(2288, 'TLILAPAN', 191, 30),
(2289, 'TOMATLÁN', 192, 30),
(2290, 'TONAYÁN', 193, 30),
(2291, 'TOTUTLA', 194, 30),
(2292, 'TRES VALLES', 195, 30),
(2293, 'TÚXPAM', 196, 30),
(2294, 'TUXPAN', 197, 30),
(2295, 'TUXTILLA', 198, 30),
(2296, 'URSULO GALVÁN', 199, 30),
(2297, 'UXPANAPA', 200, 30),
(2298, 'VEGA DE ALATORRE', 201, 30),
(2299, 'VERACRUZ', 202, 30),
(2300, 'VILLA ALDAMA', 203, 30),
(2301, 'XALAPA', 204, 30),
(2302, 'XICO', 205, 30),
(2303, 'XOXOCOTLA', 206, 30),
(2304, 'YANGA', 207, 30),
(2305, 'YECUATLÁN', 208, 30),
(2306, 'ZACUALPAN', 209, 30),
(2307, 'ZARAGOZA', 210, 30),
(2308, 'ZENTLA', 211, 30),
(2309, 'ZONGOLICA', 212, 30),
(2310, 'ZONTECOMATLÁN', 213, 30),
(2311, 'ZOZOCOLCO DE HIDALGO', 214, 30),
(2312, 'ABALÁ', 1, 31),
(2313, 'ACANCEH', 2, 31),
(2314, 'AKIL', 3, 31),
(2315, 'BACA', 4, 31),
(2316, 'BOKOBÁ', 5, 31),
(2317, 'BUCTZOTZ', 6, 31),
(2318, 'CACALCHÉN', 7, 31),
(2319, 'CALOTMUL', 8, 31),
(2320, 'CANSAHCAB', 9, 31),
(2321, 'CANTAMAYEC', 10, 31),
(2322, 'CELESTÚN', 11, 31),
(2323, 'CENOTILLO', 12, 31),
(2324, 'CHACSINKÍN', 13, 31),
(2325, 'CHANKOM', 14, 31),
(2326, 'CHAPAB', 15, 31),
(2327, 'CHEMAX', 16, 31),
(2328, 'CHICHIMILÁ', 17, 31),
(2329, 'CHICXULUB PUEBLO', 18, 31),
(2330, 'CHIKINDZONOT', 19, 31),
(2331, 'CHOCHOLÁ', 20, 31),
(2332, 'CHUMAYEL', 21, 31),
(2333, 'CONKAL', 22, 31),
(2334, 'CUNCUNUL', 23, 31),
(2335, 'CUZAMÁ', 24, 31),
(2336, 'DZAN', 25, 31),
(2337, 'DZEMUL', 26, 31),
(2338, 'DZIDZANTÚN', 27, 31),
(2339, 'DZILAM DE BRAVO', 28, 31),
(2340, 'DZILAM GONZÁLEZ', 29, 31),
(2341, 'DZITÁS', 30, 31),
(2342, 'DZONCAUICH', 31, 31),
(2343, 'ESPITA', 32, 31),
(2344, 'HALACHÓ', 33, 31),
(2345, 'HOCABÁ', 34, 31),
(2346, 'HOCTÚN', 35, 31),
(2347, 'HOMÚN', 36, 31),
(2348, 'HUHÍ', 37, 31),
(2349, 'HUNUCMÁ', 38, 31),
(2350, 'IXIL', 39, 31),
(2351, 'IZAMAL', 40, 31),
(2352, 'KANASÍN', 41, 31),
(2353, 'KANTUNIL', 42, 31),
(2354, 'KÁUA', 43, 31),
(2355, 'KINCHIL', 44, 31),
(2356, 'KOPOMÁ', 45, 31),
(2357, 'MAMA', 46, 31),
(2358, 'MANÍ', 47, 31),
(2359, 'MAXCANÚ', 48, 31),
(2360, 'MAYAPÁN', 49, 31),
(2361, 'MÉRIDA', 50, 31),
(2362, 'MOCOCHÁ', 51, 31),
(2363, 'MOTUL', 52, 31),
(2364, 'MUNA', 53, 31),
(2365, 'MUXUPIP', 54, 31),
(2366, 'OPICHÉN', 55, 31),
(2367, 'OXKUTZCAB', 56, 31),
(2368, 'PANABÁ', 57, 31),
(2369, 'PETO', 58, 31),
(2370, 'PROGRESO', 59, 31),
(2371, 'QUINTANA ROO', 60, 31),
(2372, 'RÍO LAGARTOS', 61, 31),
(2373, 'SACALUM', 62, 31),
(2374, 'SAMAHIL', 63, 31),
(2375, 'SAN FELIPE', 64, 31),
(2376, 'SANAHCAT', 65, 31),
(2377, 'SANTA ELENA', 66, 31),
(2378, 'SEYÉ', 67, 31),
(2379, 'SINANCHÉ', 68, 31),
(2380, 'SOTUTA', 69, 31),
(2381, 'SUCILÁ', 70, 31),
(2382, 'SUDZAL', 71, 31),
(2383, 'SUMA', 72, 31),
(2384, 'TAHDZIÚ', 73, 31),
(2385, 'TAHMEK', 74, 31),
(2386, 'TEABO', 75, 31),
(2387, 'TECOH', 76, 31),
(2388, 'TEKAL DE VENEGAS', 77, 31),
(2389, 'TEKANTÓ', 78, 31),
(2390, 'TEKAX', 79, 31),
(2391, 'TEKIT', 80, 31),
(2392, 'TEKOM', 81, 31),
(2393, 'TELCHAC PUEBLO', 82, 31),
(2394, 'TELCHAC PUERTO', 83, 31),
(2395, 'TEMAX', 84, 31),
(2396, 'TEMOZÓN', 85, 31),
(2397, 'TEPAKÁN', 86, 31),
(2398, 'TETIZ', 87, 31),
(2399, 'TEYA', 88, 31),
(2400, 'TICUL', 89, 31),
(2401, 'TIMUCUY', 90, 31),
(2402, 'TINUM', 91, 31),
(2403, 'TIXCACALCUPUL', 92, 31),
(2404, 'TIXKOKOB', 93, 31),
(2405, 'TIXMÉHUAC', 94, 31),
(2406, 'TIXMEUAC', 95, 31),
(2407, 'TIXPÉHUAL', 96, 31),
(2408, 'TIZIMÍN', 97, 31),
(2409, 'TUNKÁS', 98, 31),
(2410, 'TZUCACAB', 99, 31),
(2411, 'UAYMA', 100, 31),
(2412, 'UCÚ31101UMÁN', 101, 31),
(2413, 'UMAN', 102, 31),
(2414, 'VALLADOLID', 103, 31),
(2415, 'XOCCHEL', 104, 31),
(2416, 'YAXCABÁ', 105, 31),
(2417, 'YAXKUKUL', 106, 31),
(2418, 'YOBAIN', 107, 31),
(2419, 'APOZOL', 1, 32),
(2420, 'APULCO', 2, 32),
(2421, 'ATOLINGA', 3, 32),
(2422, 'BENITO JUÁREZ', 4, 32),
(2423, 'CALERA', 5, 32),
(2424, 'CAÑITAS DE FELIPE PESCADOR', 6, 32),
(2425, 'CHALCHIHUITES', 7, 32),
(2426, 'CONCEPCIÓN DEL ORO', 8, 32),
(2427, 'CUAUHTÉMOC', 9, 32),
(2428, 'EL SALVADOR', 10, 32),
(2429, 'FRANCISCO R. MURGUÍA', 11, 32),
(2430, 'FRESNILLO', 12, 32),
(2431, 'GARCIA DE LA CADENA', 13, 32),
(2432, 'GENARO CODINA', 14, 32),
(2433, 'GENERAL ENRIQUE ESTRADA', 15, 32),
(2434, 'GENERAL JOAQUÍN AMARO', 16, 32),
(2435, 'GENERAL PÁNFILO NATERA', 17, 32),
(2436, 'GUADALUPE', 18, 32),
(2437, 'HUANUSCO', 19, 32),
(2438, 'JALPA', 20, 32),
(2439, 'JEREZ', 21, 32),
(2440, 'JIMÉNEZ DEL TÉUL', 22, 32),
(2441, 'JUAN ALDAMA', 23, 32),
(2442, 'JUCHIPILA', 24, 32),
(2443, 'LORETO', 25, 32),
(2444, 'LUIS MOYA', 26, 32),
(2445, 'MAZAPIL', 27, 32),
(2446, 'MELCHOR OCAMPO', 28, 32),
(2447, 'MEZQUITAL DEL ORO', 29, 32),
(2448, 'MIGUEL AUZA', 30, 32),
(2449, 'MOMAX', 31, 32),
(2450, 'MONTE ESCOBEDO', 32, 32),
(2451, 'MORELOS', 33, 32),
(2452, 'MOYAHUA DE ESTRADA', 34, 32),
(2453, 'NOCHISTLÁN DE MEJÍA', 35, 32),
(2454, 'NORIA DE ANGELES', 36, 32),
(2455, 'OJOCALIENTE', 37, 32),
(2456, 'PÁNUCO', 38, 32),
(2457, 'PINOS', 39, 32),
(2458, 'RÍO GRANDE', 40, 32),
(2459, 'SAIN ALTO', 41, 32),
(2460, 'SOMBRERETE', 42, 32),
(2461, 'SUSTICACÁN', 43, 32),
(2462, 'TABASCO', 44, 32),
(2463, 'TEPECHITLÁN', 45, 32),
(2464, 'TEPETONGO', 46, 32),
(2465, 'TÉUL DE GONZÁLEZ ORTEGA', 47, 32),
(2466, 'TLALTENANGO DE SÁNCHEZ ROMÁN', 48, 32),
(2467, 'TRINIDAD GARCÍA DE LA CADENA', 49, 32),
(2468, 'VALPARAÍSO', 50, 32),
(2469, 'VETAGRANDE', 51, 32),
(2470, 'VILLA DE COS', 52, 32),
(2471, 'VILLA GARCÍA', 53, 32),
(2472, 'VILLA GONZÁLEZ ORTEGA', 54, 32),
(2473, 'VILLA HIDALGO', 55, 32),
(2474, 'VILLANUEVA', 56, 32),
(2475, 'ZACATECAS', 57, 32),
(2476, 'EXTRANJERO', 999, 33);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personapaises`
--

CREATE TABLE `personapaises` (
  `idPais` smallint(6) NOT NULL,
  `Pais` varchar(50) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personapaises`
--

INSERT INTO `personapaises` (`idPais`, `Pais`) VALUES
(1, 'México'),
(2, 'EXTRANJERO');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personapersona`
--

CREATE TABLE `personapersona` (
  `idpersona` int(11) NOT NULL,
  `nombre` varchar(50) CHARACTER SET utf8 NOT NULL,
  `paterno` varchar(50) CHARACTER SET utf8 NOT NULL,
  `materno` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `genero` tinyint(3) UNSIGNED NOT NULL,
  `fecha_nac` date DEFAULT NULL,
  `curp` varchar(18) CHARACTER SET utf8 DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `edo_civil` tinyint(3) UNSIGNED DEFAULT NULL,
  `foto` varchar(255) DEFAULT NULL,
  `tel_casa` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `tel_cel` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `tel_otro` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `tipo_sangre` tinyint(3) UNSIGNED DEFAULT NULL,
  `idestado_nac` int(11) NOT NULL,
  `EstadoNacimiento` int(11) NOT NULL,
  `MunicipioNacimiento` int(11) NOT NULL,
  `esPadre` tinyint(4) NOT NULL,
  `Trabaja` tinyint(4) NOT NULL,
  `LugarHorarioTrabajo` varchar(500) CHARACTER SET utf8 DEFAULT NULL,
  `esDiscapacitado` tinyint(4) NOT NULL,
  `Discapacidad` longtext DEFAULT NULL,
  `esExternoALaUPV` tinyint(4) DEFAULT NULL,
  `IFE` varchar(50) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personapersona`
--

INSERT INTO `personapersona` (`idpersona`, `nombre`, `paterno`, `materno`, `genero`, `fecha_nac`, `curp`, `email`, `edo_civil`, `foto`, `tel_casa`, `tel_cel`, `tel_otro`, `tipo_sangre`, `idestado_nac`, `EstadoNacimiento`, `MunicipioNacimiento`, `esPadre`, `Trabaja`, `LugarHorarioTrabajo`, `esDiscapacitado`, `Discapacidad`, `esExternoALaUPV`, `IFE`) VALUES
(1, 'ROSA ELVIA', 'GARZA', 'AGUILAR', 2, '1998-04-15', 'GAAR980830MTSRGS03', 'ROZYELVIA.308@GMAIL.COM', 10, '', '8342124858', '8342124858', '8342124858', NULL, 1, 1, 2, 0, 0, NULL, 0, NULL, NULL, NULL),
(130, 'ORLANDO GUADALUPE', 'ACOSTA', 'SANTOS', 1, '1982-11-03', NULL, 'X@HOTMAIL.COM', 10, NULL, NULL, NULL, NULL, NULL, 28, 28, 2033, 0, 0, NULL, 0, NULL, NULL, NULL),
(131, 'GUADALUPE', 'ACOSTA', 'VILLARREAL', 2, '1995-12-12', NULL, 'gacostav@upv.edu.mx', 10, NULL, '8343135033', '8343135033', NULL, NULL, 1, 1, 1, 1, 0, NULL, 0, NULL, NULL, 'prueba'),
(132, 'AMÉRICA', 'BERRONES', 'CORONA', 2, '1995-02-03', NULL, 'd@hin.g', 10, NULL, NULL, NULL, NULL, NULL, 1, 1, 3, 0, 0, NULL, 0, NULL, NULL, NULL),
(133, 'EDNA DALILA', 'BECERRA', 'MARTÍNEZ', 2, '1995-06-02', NULL, 'd@hin.g', 10, NULL, NULL, NULL, NULL, NULL, 1, 1, 2, 0, 0, NULL, 0, NULL, NULL, NULL),
(134, 'GUILLERMO', 'BECERRA', 'SALAZAR', 1, '1989-03-05', NULL, 'd@hin.g', 10, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, 0, 1, 'hggf', 0, NULL, NULL, NULL),
(135, 'JOSÉ ROBERTO', 'BECERRA', 'HUERTA', 1, '1997-12-02', NULL, 'd@hin.g', 10, NULL, '8341301808', NULL, NULL, NULL, 2, 2, 14, 0, 0, NULL, 0, NULL, NULL, NULL),
(136, 'DEYSI GUADALUPE', 'ALEJANDRO', 'RUIZ', 2, NULL, NULL, 'ALEX@hin.g', 10, NULL, '8341301808', NULL, NULL, NULL, 28, 28, 2033, 0, 0, NULL, 0, NULL, NULL, NULL),
(137, 'CLAUDIA DANIELA', 'BAUTISTA', 'TREVIÑO', 2, '1993-03-11', NULL, 'clau_danielita@hotmail.com', 10, 'personal/76Of0aPuvE3VcnKTIyQPmWF3HFsAKYFwi6KVAkJy.jpeg', NULL, NULL, NULL, NULL, 28, 28, 2033, 0, 0, NULL, 0, NULL, NULL, NULL),
(138, 'LEONARDO DANIEL', 'AGUILAR', 'GARCÍA', 1, '1990-03-18', NULL, NULL, 10, 'personal/lUn0X06Mbi8qQkGwsQfA24tp0BLSbIhbPk3jqmZF.jpeg', '8341476962', NULL, NULL, NULL, 1, 1, 4, 0, 0, NULL, 0, NULL, NULL, NULL),
(139, 'ADRIANA MICHEL', 'AGUILAR', 'AMAYA', 1, '1999-05-15', 'AUAA890605HTSGMD06', 'adrian_aguilar@hotmail.com', 10, 'C:\\xampp\\tmp\\php936D.tmp', '3130446', '8341396907', NULL, NULL, 1, 1, 2, 0, 0, NULL, 0, NULL, NULL, NULL),
(140, 'JULIO CESAR', 'ALVARADO', 'AVALOS', 1, '2000-05-06', 'AAAJ860113HTSLVL01', 'julio_rasec5@hotmail.com', 10, NULL, '3137456', '8341514367', '8341514367', NULL, 29, 29, 2051, 0, 0, NULL, 0, NULL, NULL, NULL),
(141, 'JENIFFER CASSANDRA', 'ABUNDIS', 'AVALOS', 2, '1995-08-04', 'AUAJ900911MTSBVN02', 'ksandra_r_98@HOTMAIL.COM', 10, NULL, '3137379', '8341584039', NULL, NULL, 5, 5, 137, 0, 0, NULL, 0, NULL, NULL, NULL),
(142, 'ARTURO FERNANDO', 'AGUILAR', 'SÁMANO', 1, '1990-03-21', 'AUSA900928HTSGMR00', 'arturo_fer58@hotmail.com', 116, NULL, '8343122316', '8341068314', '8341068314', NULL, 5, 5, 34, 0, 1, 'prueba', 0, NULL, NULL, NULL),
(143, 'LUIS RICARDO', 'ABUNDIS', 'CANO', 1, '1992-04-05', 'AUCL900414HTSBNS06', NULL, 10, NULL, '8341662833', NULL, NULL, NULL, 10, 10, 276, 0, 0, NULL, 0, NULL, NULL, NULL),
(144, 'EMMA LAURA', 'AGUILAR', 'SILVA', 2, '1993-12-31', 'AUSE900210MTSGLM01', 'emmaguilars@HOTMAIL.COM', 10, NULL, '8341244142', NULL, NULL, NULL, 21, 21, 1697, 0, 0, NULL, 0, NULL, NULL, NULL),
(145, 'RENÉ', 'ALEJANDRO', 'SILVA', 1, '2000-01-22', 'AESR740822HCLLLN08', 'rene_as007@hotmail.com', 10, 'personal/WueDJZT713Y6EHh0NfteSGDBQxdeMz6Q1Bmqznvf.jpeg', '8341093781', NULL, NULL, NULL, 28, 28, 2033, 0, 0, NULL, 0, NULL, NULL, NULL),
(146, 'd', 'f', 'f', 1, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 4, 4, 24, 0, 0, NULL, 0, NULL, NULL, NULL),
(147, 'CARLA', 'RODIGUEZ', 'GARCIA', 2, NULL, NULL, NULL, 10, '', '8341301808', NULL, NULL, NULL, 1, 1, 3, 0, 0, NULL, 0, NULL, NULL, NULL),
(148, 'DANIELA', 'GARCIA', 'HERNANDEZ', 2, NULL, 'GAHEDA051397MSDF', 'DANIELA3454@GMAIL.COM', 10, 'personal/wcT4ZhEYJN6qhAIUzyfQwOQFc19xMUS2wGggzQfO.jpeg', '3163548', '8341592682', NULL, NULL, 5, 5, 37, 1, 1, 'hoaraio:', 0, NULL, NULL, NULL),
(149, 'EMMA LAURA', 'AGUILAR', 'SILVA', 2, '2020-04-19', 'AUSE900210MTSGLM01', 'emmaguilars@HOTMAIL.COM', 11, NULL, NULL, NULL, NULL, NULL, 2, 2, 14, 0, 0, NULL, 0, NULL, NULL, NULL),
(150, 'ttt5', 'esquivel', 'Esquivel', 2, '2020-04-17', 'AUSE900210MTSGLM01', 'ALEX@hin.g', 10, NULL, '8341301808', NULL, NULL, NULL, 1, 1, 3, 0, 0, NULL, 0, NULL, NULL, NULL),
(151, 'ttt5', 'esquivel', 'Esquivel', 2, '2020-04-17', 'AUSE900210MTSGLM01', 'ALEX@hin.g', 10, NULL, '8341301808', NULL, NULL, NULL, 1, 1, 3, 0, 0, NULL, 0, NULL, NULL, NULL),
(152, 'ttt5', 'esquivel', 'Esquivel', 2, '2020-04-17', 'AUSE900210MTSGLM01', 'ALEX@hin.g', 10, '', '8341301808', NULL, NULL, NULL, 1, 1, 3, 0, 0, NULL, 0, NULL, NULL, NULL),
(153, 'MONICA', 'MEDELLIN', 'URIEGAS', 2, '1997-04-17', 'MEUM970812MTSDRN01', 'monika.-12@hotmail.com', NULL, '', '8341394045', '8341553746', '8341553746', NULL, 2, 2, 14, 0, 0, NULL, 0, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `personareferencias`
--

CREATE TABLE `personareferencias` (
  `IdReferencia` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `Nombre` varchar(150) CHARACTER SET utf8 NOT NULL,
  `IdParentesco` smallint(6) NOT NULL,
  `email` varchar(100) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `personareferencias`
--

INSERT INTO `personareferencias` (`IdReferencia`, `IdPersona`, `Nombre`, `IdParentesco`, `email`) VALUES
(0, 153, 'JUAN MARTÍN HERNÁNDEZ SOTO', 95, NULL),
(1, 1, 'prueba', 96, NULL),
(2, 2, 'prueba2', 95, NULL),
(3, 1, 'VALERIA ALEXANDRA', 97, NULL),
(4, 1, 'Julia', 96, NULL),
(5, 1, 'Julia', 95, NULL),
(6, 1, 'ttt5', 95, NULL),
(7, 1, 'Jorge', 95, NULL),
(8, 1, '2', 95, NULL),
(9, 1, '22', 95, NULL),
(10, 1, '22', 96, NULL),
(11, 51, 'ttt5', 96, NULL),
(12, 51, 'valeria', 97, NULL),
(13, 52, 'Julia', 95, NULL),
(14, 52, 'VALERIA ALEXANDRA', 97, NULL),
(15, 0, 'ttt5', 96, NULL),
(16, 0, 'mm', 96, NULL),
(17, 67, 'ttt5', 95, NULL),
(18, 68, 'Julia', 95, NULL),
(19, 0, 'Julia', 95, NULL),
(20, 77, 'ttt5', 97, NULL),
(21, 0, 'Julia', 97, NULL),
(22, 85, 'VALERIA ALEXANDRA', 97, NULL),
(23, 89, 'VALERIA ALEXANDRA', 97, NULL),
(24, 90, 'Eduardo Cervantes', 95, NULL),
(25, 91, 'Jorge', 95, NULL),
(26, 79, 'Julia', 95, NULL),
(27, 100, 'ttt5', 95, NULL),
(28, 132, 'B', 95, NULL),
(29, 145, 'Juan Hernández Hernández', 95, NULL),
(30, 131, 'MARÍA GARCÍA RODRÍGUEZ', 96, NULL),
(31, 131, 'JUAN HERNÁNDEZ HERNÁNDEZ', 95, NULL),
(32, 131, 'Francisco Hernández Hernández', 97, NULL),
(33, 148, 'Karla Herrera', 96, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionaux_resultadosaludoc`
--

CREATE TABLE `planeacionaux_resultadosaludoc` (
  `idempleado` int(11) NOT NULL,
  `profesor` varchar(150) NOT NULL,
  `idcategoria` int(11) NOT NULL,
  `categoria` varchar(100) NOT NULL,
  `calificacion` decimal(10,2) DEFAULT NULL,
  `idcampus` smallint(6) NOT NULL,
  `campus` varchar(100) CHARACTER SET utf8 NOT NULL,
  `idcuatrimestre` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionaux_resultadosalutut`
--

CREATE TABLE `planeacionaux_resultadosalutut` (
  `idcuatrimestre` int(11) NOT NULL,
  `idevaluado` int(11) NOT NULL,
  `evaluado` varchar(150) CHARACTER SET utf8 NOT NULL,
  `aplicada` tinyint(4) DEFAULT NULL,
  `idcampus` int(11) NOT NULL,
  `campus` varchar(100) CHARACTER SET utf8 NOT NULL,
  `respuesta` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionaux_resultadosdirdoc`
--

CREATE TABLE `planeacionaux_resultadosdirdoc` (
  `idcuatrimestre` int(11) NOT NULL,
  `idevaluado` int(11) NOT NULL,
  `evaluado` varchar(150) CHARACTER SET utf8 NOT NULL,
  `idcarrera` int(11) NOT NULL,
  `carrera` varchar(100) CHARACTER SET utf8 NOT NULL,
  `respuesta` int(11) DEFAULT NULL,
  `idpregunta` int(11) DEFAULT NULL,
  `pregunta` varchar(400) CHARACTER SET utf8 DEFAULT NULL,
  `idpuesto` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionaux_resultadosdocdoc`
--

CREATE TABLE `planeacionaux_resultadosdocdoc` (
  `idcuatrimestre` int(11) NOT NULL,
  `idevaluado` int(11) NOT NULL,
  `evaluado` varchar(150) CHARACTER SET utf8 NOT NULL,
  `idcarrera` int(11) NOT NULL,
  `carrera` varchar(100) CHARACTER SET utf8 NOT NULL,
  `respuesta` int(11) DEFAULT NULL,
  `idpregunta` int(11) DEFAULT NULL,
  `pregunta` varchar(400) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncarrera`
--

CREATE TABLE `planeacioncarrera` (
  `idcarrera` int(11) NOT NULL,
  `carrera_nomb` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncategoria`
--

CREATE TABLE `planeacioncategoria` (
  `idcategoria` int(11) NOT NULL,
  `cat_nombre` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_area`
--

CREATE TABLE `planeacioncl_area` (
  `idarea` tinyint(3) UNSIGNED NOT NULL,
  `area` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_area_perfil`
--

CREATE TABLE `planeacioncl_area_perfil` (
  `idarea` tinyint(3) UNSIGNED NOT NULL,
  `idperfil` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_cuatrimestre_sugerencia`
--

CREATE TABLE `planeacioncl_cuatrimestre_sugerencia` (
  `idcuatrimestre` int(11) NOT NULL,
  `idsugerencia` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_cuestionario`
--

CREATE TABLE `planeacioncl_cuestionario` (
  `idcuestionario` int(11) NOT NULL,
  `fecha_creacion` datetime(3) NOT NULL,
  `activo` tinyint(4) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `cuestionario` varchar(100) CHARACTER SET utf8 NOT NULL,
  `idgrupo` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_cuestionario_pregunta`
--

CREATE TABLE `planeacioncl_cuestionario_pregunta` (
  `idcuestionario` int(11) NOT NULL,
  `idrama` int(11) NOT NULL,
  `idpregunta` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_evaluacion`
--

CREATE TABLE `planeacioncl_evaluacion` (
  `idevaluacion` int(11) NOT NULL,
  `idcuestionario` int(11) NOT NULL,
  `idevaluador` int(11) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `aplicada` tinyint(4) DEFAULT NULL,
  `fecha` datetime(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_grupo`
--

CREATE TABLE `planeacioncl_grupo` (
  `idgrupo` tinyint(3) UNSIGNED NOT NULL,
  `grupo` varchar(50) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_grupo_respuesta`
--

CREATE TABLE `planeacioncl_grupo_respuesta` (
  `idgrupo` tinyint(3) UNSIGNED NOT NULL,
  `idrespuesta` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_pregunta`
--

CREATE TABLE `planeacioncl_pregunta` (
  `idpregunta` int(11) NOT NULL,
  `pregunta` varchar(400) CHARACTER SET utf8 NOT NULL,
  `borrada` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_rama`
--

CREATE TABLE `planeacioncl_rama` (
  `idrama` int(11) NOT NULL,
  `rama` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_registro_evaluaciones`
--

CREATE TABLE `planeacioncl_registro_evaluaciones` (
  `idregistro` int(11) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `idcuestionario` int(11) NOT NULL,
  `fecha` datetime(3) NOT NULL,
  `activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_respuesta`
--

CREATE TABLE `planeacioncl_respuesta` (
  `idrespuesta` tinyint(3) UNSIGNED NOT NULL,
  `respuesta` varchar(50) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_resultado`
--

CREATE TABLE `planeacioncl_resultado` (
  `idresultado` int(11) NOT NULL,
  `idevaluacion` int(11) NOT NULL,
  `idpregunta` int(11) NOT NULL,
  `respuesta` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncl_sugerencia`
--

CREATE TABLE `planeacioncl_sugerencia` (
  `idsugerencia` int(11) NOT NULL,
  `sugerencia` varchar(600) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncuestionario`
--

CREATE TABLE `planeacioncuestionario` (
  `idcuestionario` int(11) NOT NULL,
  `fecha_creacion` datetime(3) NOT NULL,
  `activo` tinyint(4) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `idtipocuestionario` int(11) NOT NULL,
  `cuest_nombre` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacioncuestionario_pregunta`
--

CREATE TABLE `planeacioncuestionario_pregunta` (
  `idcuestionario` int(11) NOT NULL,
  `idcategoria` int(11) NOT NULL,
  `idpregunta` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionevaluacion`
--

CREATE TABLE `planeacionevaluacion` (
  `idevaluacion` int(11) NOT NULL,
  `idcuestionario` int(11) NOT NULL,
  `idevaluador` int(11) NOT NULL,
  `idgrupo` int(11) DEFAULT NULL,
  `idevaluado` int(11) NOT NULL,
  `idmateria` int(11) DEFAULT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `aplicada` tinyint(4) DEFAULT NULL,
  `fecha` datetime(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionplan_estudios`
--

CREATE TABLE `planeacionplan_estudios` (
  `idplan_estudios` int(11) NOT NULL,
  `clave` varchar(50) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionpregunta`
--

CREATE TABLE `planeacionpregunta` (
  `idpregunta` int(11) NOT NULL,
  `pregunta` varchar(400) CHARACTER SET utf8 NOT NULL,
  `borrada` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionregistro_evaluaciones`
--

CREATE TABLE `planeacionregistro_evaluaciones` (
  `idregistro` int(11) NOT NULL,
  `idcampus` int(11) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `fecha` datetime(3) NOT NULL,
  `activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionregistro_evaluaciones_cuestionario`
--

CREATE TABLE `planeacionregistro_evaluaciones_cuestionario` (
  `idregistro` int(11) NOT NULL,
  `idcuestionario_aludoc` int(11) NOT NULL,
  `idcuestionario_dirdoc` int(11) NOT NULL,
  `idcuestionario_docdoc` int(11) NOT NULL,
  `idcuestionario_alutut` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionrespuesta`
--

CREATE TABLE `planeacionrespuesta` (
  `idrespuesta` tinyint(3) UNSIGNED NOT NULL,
  `respuesta` varchar(50) CHARACTER SET utf8 NOT NULL,
  `valor` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionresultado`
--

CREATE TABLE `planeacionresultado` (
  `idresultado` int(11) NOT NULL,
  `idevaluacion` int(11) NOT NULL,
  `idpregunta` int(11) NOT NULL,
  `respuesta` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeaciontipo_cuestionario`
--

CREATE TABLE `planeaciontipo_cuestionario` (
  `idtipocuestionario` int(11) NOT NULL,
  `tipo` varchar(50) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacionvwresultadosaludoc`
--

CREATE TABLE `planeacionvwresultadosaludoc` (
  `idempleado` int(11) NOT NULL,
  `profesor` varchar(255) NOT NULL,
  `categoria` varchar(255) NOT NULL,
  `calificacion` decimal(2,2) NOT NULL,
  `porcentaje` double(13,13) NOT NULL,
  `idcategoria` int(11) NOT NULL,
  `idcampus` int(11) NOT NULL,
  `campus` varchar(255) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Volcado de datos para la tabla `planeacionvwresultadosaludoc`
--

INSERT INTO `planeacionvwresultadosaludoc` (`idempleado`, `profesor`, `categoria`, `calificacion`, `porcentaje`, `idcategoria`, `idcampus`, `campus`, `idcuatrimestre`) VALUES
(8, 'EDDIE NAHÚM ARMENDÁRIZ MIRELES', 'Asistencia y puntualidad', '0.99', 0.9999999999999, 4, 1, 'VICTORIA', 21),
(8, 'EDDIE NAHÚM ARMENDÁRIZ MIRELES', 'Asistencia y puntualidad', '0.99', 0.9999999999999, 4, 1, 'VICTORIA', 21),
(8, 'EDDIE NAHÚM ARMENDÁRIZ MIRELES', 'Dominio de la disciplina', '0.99', 0.9999999999999, 5, 1, 'VICTORIA', 21),
(8, 'EDDIE NAHÚM ARMENDÁRIZ MIRELES', 'Evaluación del aprendizaje', '0.99', 0.9999999999999, 6, 1, 'VICTORIA', 21),
(8, 'EDDIE NAHÚM ARMENDÁRIZ MIRELES', 'Motivación', '0.99', 0.9999999999999, 7, 1, 'VICTORIA', 21);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacion_cuestionario`
--

CREATE TABLE `planeacion_cuestionario` (
  `idcuestionario` int(11) NOT NULL,
  `fecha_creacion` datetime(3) NOT NULL,
  `activo` tinyint(4) NOT NULL,
  `idcuatrimestre` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacion_cuestionario_pregunta`
--

CREATE TABLE `planeacion_cuestionario_pregunta` (
  `idcuestionario` int(11) NOT NULL,
  `idseccion` int(11) NOT NULL,
  `idpregunta` int(11) NOT NULL,
  `numero_preg` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacion_evaluacion`
--

CREATE TABLE `planeacion_evaluacion` (
  `idevaluacion` int(11) NOT NULL,
  `idcuestionario` int(11) NOT NULL,
  `idalumno` int(11) NOT NULL,
  `idgrupo` int(11) NOT NULL,
  `idempleado` int(11) NOT NULL,
  `idmateria` int(11) NOT NULL,
  `idcuatrimestre` int(11) NOT NULL,
  `aplicada` tinyint(4) DEFAULT NULL,
  `fecha` datetime(3) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacion_pregunta`
--

CREATE TABLE `planeacion_pregunta` (
  `idpregunta` int(11) NOT NULL,
  `pregunta` varchar(400) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacion_prueba_results`
--

CREATE TABLE `planeacion_prueba_results` (
  `idempleado` int(11) DEFAULT NULL,
  `profesor` varchar(150) DEFAULT NULL,
  `idseccion` int(11) DEFAULT NULL,
  `seccion` varchar(100) DEFAULT NULL,
  `calificacion` decimal(10,2) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacion_resultado`
--

CREATE TABLE `planeacion_resultado` (
  `idresultado` int(11) NOT NULL,
  `idevaluacion` int(11) NOT NULL,
  `idpregunta` int(11) NOT NULL,
  `respuesta` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `planeacion_seccion`
--

CREATE TABLE `planeacion_seccion` (
  `idseccion` int(11) NOT NULL,
  `nombre` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `productos`
--

CREATE TABLE `productos` (
  `id_Cod` int(11) NOT NULL,
  `cod_prod` varchar(4) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `existencia` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rev_calif`
--

CREATE TABLE `rev_calif` (
  `idperiodo` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `idgrupo` double DEFAULT NULL,
  `grupo mysql` double DEFAULT NULL,
  `cve_gpo` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `idalumno` double DEFAULT NULL,
  `idmateria` double DEFAULT NULL,
  `materia` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `baja` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `corte1` double DEFAULT NULL,
  `tipo1` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `corte2` double DEFAULT NULL,
  `tipo2` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `global` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `final` double DEFAULT NULL,
  `tipo_final` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `IdMateriaRef` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `asistencia` double DEFAULT NULL,
  `tipo_ex` varchar(255) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rharea`
--

CREATE TABLE `rharea` (
  `idarea` int(11) NOT NULL,
  `nombre` varchar(50) CHARACTER SET utf8 NOT NULL,
  `iddependencia` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhareasjefes`
--

CREATE TABLE `rhareasjefes` (
  `IdAreaJefe` int(11) NOT NULL,
  `IdArea` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhcalendario`
--

CREATE TABLE `rhcalendario` (
  `IdCalendario` int(11) NOT NULL,
  `IdIncidenciaTipo` int(11) NOT NULL,
  `Descripcion` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
  `DiaInicio` date NOT NULL,
  `DiaFin` date NOT NULL,
  `HoraInicio` time NOT NULL,
  `HoraFin` time NOT NULL,
  `PresicionHoras` tinyint(4) NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhdescuentosaplicados`
--

CREATE TABLE `rhdescuentosaplicados` (
  `IdDescuentoAplicado` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdEmpleado` int(11) NOT NULL,
  `NumeroEmpleado` smallint(6) NOT NULL,
  `FechaInicio` date NOT NULL,
  `FechaFin` date NOT NULL,
  `RegistroCancelado` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhempleado`
--

CREATE TABLE `rhempleado` (
  `idempleado` int(11) NOT NULL,
  `idpersona` int(11) NOT NULL,
  `numero` smallint(6) DEFAULT NULL,
  `grado` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `siglas_grado` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `rfc` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `titulado` tinyint(3) UNSIGNED DEFAULT NULL,
  `idarea` int(11) NOT NULL,
  `perfil_docente` tinyint(3) UNSIGNED DEFAULT NULL,
  `tipo_empleado` int(11) DEFAULT NULL,
  `fecha_ingreso` date DEFAULT NULL,
  `borrado` tinyint(3) UNSIGNED DEFAULT NULL,
  `IdPuesto` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhempleadoshorarios`
--

CREATE TABLE `rhempleadoshorarios` (
  `IdEmpleadoHorario` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdEmpleado` int(11) NOT NULL,
  `IdHorario` int(11) NOT NULL,
  `Activo` tinyint(4) NOT NULL,
  `Fecha` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhextensionestelefonicas`
--

CREATE TABLE `rhextensionestelefonicas` (
  `IdExtension` int(11) NOT NULL,
  `Extension` varchar(50) CHARACTER SET utf8 NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdArea` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhhorarios`
--

CREATE TABLE `rhhorarios` (
  `IdHorario` int(11) NOT NULL,
  `Horario` varchar(150) CHARACTER SET utf8 NOT NULL,
  `HorasXSemana` tinyint(3) UNSIGNED NOT NULL,
  `ValidadoXHoras` tinyint(4) NOT NULL,
  `Activo` tinyint(4) NOT NULL,
  `Observaciones` varchar(250) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhhorariosdetalle`
--

CREATE TABLE `rhhorariosdetalle` (
  `IdHorarioDetalle` int(11) NOT NULL,
  `IdHorario` int(11) NOT NULL,
  `HoraInicio` time NOT NULL,
  `HoraFin` time NOT NULL,
  `Lunes` tinyint(4) NOT NULL,
  `Martes` tinyint(4) NOT NULL,
  `Miercoles` tinyint(4) NOT NULL,
  `Jueves` tinyint(4) NOT NULL,
  `Viernes` tinyint(4) NOT NULL,
  `Sabado` tinyint(4) NOT NULL,
  `Domingo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhhorariosvisualizar`
--

CREATE TABLE `rhhorariosvisualizar` (
  `IdHorarioVisualizar` int(11) NOT NULL,
  `IdHorario` int(11) NOT NULL,
  `Horario` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhincidenciasconfiguracion`
--

CREATE TABLE `rhincidenciasconfiguracion` (
  `IdIncidenciaConfiguracion` int(11) NOT NULL,
  `IdIncidenciaTipo` int(11) NOT NULL,
  `SancionEconomica` tinyint(4) NOT NULL,
  `AplicaEntradaSalida` tinyint(4) NOT NULL,
  `Tolerancia` tinyint(3) UNSIGNED NOT NULL,
  `Activo` tinyint(4) NOT NULL,
  `Cantidad` tinyint(3) UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhincidenciasjustificaciones`
--

CREATE TABLE `rhincidenciasjustificaciones` (
  `IdIncidenciaJustificacion` int(11) NOT NULL,
  `IdRegistroAsistencia` int(11) NOT NULL,
  `IdPersonaJustifica` int(11) NOT NULL,
  `IdJustificante` int(11) NOT NULL,
  `Fecha` date NOT NULL,
  `Justificado` tinyint(4) NOT NULL,
  `Activo` tinyint(4) NOT NULL,
  `IdMotivoJustificacion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhincidenciastipo`
--

CREATE TABLE `rhincidenciastipo` (
  `IdIncidenciaTipo` int(11) NOT NULL,
  `Incidencia` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Descripcion` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
  `Activo` tinyint(4) NOT NULL,
  `EsNegativa` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhjustificantes`
--

CREATE TABLE `rhjustificantes` (
  `IdJustificante` int(11) NOT NULL,
  `Justificante` varchar(150) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhmotivosjustificacion`
--

CREATE TABLE `rhmotivosjustificacion` (
  `IdMotivo` int(11) NOT NULL,
  `Motivo` varchar(250) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhpuestos`
--

CREATE TABLE `rhpuestos` (
  `IdPuesto` int(11) NOT NULL,
  `Puesto` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Descripcion` varchar(250) CHARACTER SET utf8 DEFAULT NULL,
  `TiempoParcial` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhregistroasistencia`
--

CREATE TABLE `rhregistroasistencia` (
  `IdRegistroAsistencia` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdEmpleado` int(11) NOT NULL,
  `Fecha` date NOT NULL,
  `HoraRegistro` time NOT NULL,
  `Diferencia` int(11) NOT NULL,
  `EntradaSalida` tinyint(4) NOT NULL,
  `EsRegistroManual` tinyint(4) NOT NULL,
  `IdIncidenciaTipo` int(11) NOT NULL,
  `RegistroCancelado` tinyint(4) NOT NULL,
  `CheckNumero` tinyint(3) UNSIGNED NOT NULL,
  `JustificadoPorJefe` tinyint(4) NOT NULL,
  `IncidenciaSancionada` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhregistroasistencia_excepciones`
--

CREATE TABLE `rhregistroasistencia_excepciones` (
  `IdRAExcepcion` int(11) NOT NULL,
  `IdPersona` int(11) NOT NULL,
  `IdEmpleado` int(11) NOT NULL,
  `Numero` int(11) NOT NULL,
  `FechaInicio` date NOT NULL,
  `FechaFin` date NOT NULL,
  `HoraInicio` time NOT NULL,
  `HoraFin` time NOT NULL,
  `PresicionHora` tinyint(4) NOT NULL,
  `Activo` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rhregistrosdispositivo`
--

CREATE TABLE `rhregistrosdispositivo` (
  `IdRegistroDispositivo` int(11) NOT NULL,
  `EnrollNumber` int(11) NOT NULL,
  `VerifyMode` tinyint(3) UNSIGNED NOT NULL,
  `InOutMode` tinyint(3) UNSIGNED NOT NULL,
  `DateDispositivo` date NOT NULL,
  `HourDispositivo` time NOT NULL,
  `DateHourDispositivo` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadcatalogo`
--

CREATE TABLE `seguridadcatalogo` (
  `idCatalogo` smallint(6) NOT NULL,
  `Clasificacion` smallint(6) NOT NULL,
  `Nombre` varchar(100) CHARACTER SET utf8 NOT NULL,
  `Descripcion` varchar(100) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadcuentasreestablecidas`
--

CREATE TABLE `seguridadcuentasreestablecidas` (
  `idCuentaReestablecida` int(11) NOT NULL,
  `Cuenta` varchar(50) CHARACTER SET utf8 NOT NULL,
  `FechaEnvio` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadfunciones`
--

CREATE TABLE `seguridadfunciones` (
  `idFuncion` int(11) NOT NULL,
  `Funcion` varchar(100) CHARACTER SET utf8 NOT NULL,
  `Descripcion` varchar(300) CHARACTER SET utf8 DEFAULT NULL,
  `esMenuPrincipal` tinyint(4) NOT NULL,
  `idPadre` int(11) NOT NULL,
  `sistema` tinyint(3) UNSIGNED NOT NULL,
  `url` varchar(100) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadmoesc`
--

CREATE TABLE `seguridadmoesc` (
  `IdMoesc` int(11) NOT NULL,
  `idUsuario` int(11) NOT NULL,
  `idGrupo` int(11) NOT NULL,
  `idMateria` int(11) NOT NULL,
  `idMateriaReferencia` int(11) DEFAULT NULL,
  `TipoMovimiento` tinyint(3) UNSIGNED NOT NULL,
  `idCuatrimestre` int(11) NOT NULL,
  `fecha` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadperfiles`
--

CREATE TABLE `seguridadperfiles` (
  `idperfil` int(11) NOT NULL,
  `Perfil` varchar(50) CHARACTER SET utf8 NOT NULL,
  `idClasificacion` smallint(6) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadperfilesfunciones`
--

CREATE TABLE `seguridadperfilesfunciones` (
  `idPerfilFuncion` int(11) NOT NULL,
  `idPerfil` int(11) NOT NULL,
  `idFuncion` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadstoreipaddress`
--

CREATE TABLE `seguridadstoreipaddress` (
  `Id` int(11) NOT NULL,
  `IpAddress` varchar(50) DEFAULT NULL,
  `VisitedDate` datetime(3) DEFAULT NULL,
  `Host` longtext DEFAULT NULL,
  `IdPersona` int(11) DEFAULT NULL,
  `IdGrupo` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadtiempodeuso`
--

CREATE TABLE `seguridadtiempodeuso` (
  `idTiempoDeUso` int(11) NOT NULL,
  `idPersona` int(11) NOT NULL,
  `idCatalogo` int(11) NOT NULL,
  `fecha` date NOT NULL,
  `horaInicio` time(1) DEFAULT NULL,
  `horaFin` time(1) DEFAULT NULL,
  `idCuatrimestre` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadusuarioerrores`
--

CREATE TABLE `seguridadusuarioerrores` (
  `idUsuarioErrores` int(11) NOT NULL,
  `idPersona` int(11) NOT NULL,
  `ErrorObtenido` longtext NOT NULL,
  `Fecha` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seguridadusuarios`
--

CREATE TABLE `seguridadusuarios` (
  `idUsuario` int(11) NOT NULL,
  `idPersona` int(11) NOT NULL,
  `Usuariox2` longtext DEFAULT NULL,
  `Usuario` longtext NOT NULL,
  `Contraseña` longtext NOT NULL,
  `Activo` tinyint(4) NOT NULL,
  `idPerfil` int(11) NOT NULL,
  `Actualizado` datetime DEFAULT NULL,
  `ContraseñaX2` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `sin_gpo`
--

CREATE TABLE `sin_gpo` (
  `idalumno` int(11) NOT NULL,
  `idgrupo` int(11) NOT NULL,
  `idmateria` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `table1$`
--

CREATE TABLE `table1$` (
  `idcuatrimestre` double DEFAULT NULL,
  `idgrupo` double DEFAULT NULL,
  `grupo mysql` double DEFAULT NULL,
  `cve_gpo` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `idalumno` double DEFAULT NULL,
  `idmateria` double DEFAULT NULL,
  `materia` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `baja` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `corte1` double DEFAULT NULL,
  `tipo1` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `corte2` double DEFAULT NULL,
  `tipo2` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `global` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `final` double DEFAULT NULL,
  `tipo_final` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `IdMateriaRef` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `asistencia` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `temporal20160422`
--

CREATE TABLE `temporal20160422` (
  `idpersona` double DEFAULT NULL,
  `IdConcepto` double DEFAULT NULL,
  `Concepto` varchar(255) CHARACTER SET utf8 DEFAULT NULL,
  `monto` double DEFAULT NULL,
  `IdPromocion` double DEFAULT NULL,
  `IdCuatrimestre` double DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tmpactualizarcorreo`
--

CREATE TABLE `tmpactualizarcorreo` (
  `matricula_` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `email_` varchar(150) CHARACTER SET utf8 DEFAULT NULL,
  `idPersona_` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tmpaspirantes`
--

CREATE TABLE `tmpaspirantes` (
  `Matricula_` varchar(10) CHARACTER SET utf8 DEFAULT NULL,
  `Folio` varchar(20) CHARACTER SET utf8 DEFAULT NULL,
  `puntuacion` int(11) DEFAULT NULL,
  `resultado` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `idResultado_` int(11) DEFAULT NULL,
  `idpersona_` int(11) DEFAULT NULL,
  `realizado` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tmpgrupos`
--

CREATE TABLE `tmpgrupos` (
  `idGrupo` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tmpimss`
--

CREATE TABLE `tmpimss` (
  `matricula` varchar(10) CHARACTER SET utf8 DEFAULT NULL,
  `NSS` longtext DEFAULT NULL,
  `curp` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tmpvaciarespeciales`
--

CREATE TABLE `tmpvaciarespeciales` (
  `idalumno` int(11) DEFAULT NULL,
  `idplan_estudios` int(11) DEFAULT NULL,
  `idcuatrimestre` int(11) DEFAULT NULL,
  `mesp` int(11) DEFAULT NULL,
  `mrep` int(11) DEFAULT NULL,
  `dictamen` tinyint(4) DEFAULT NULL,
  `idpersona` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tmpvalidaralumnos`
--

CREATE TABLE `tmpvalidaralumnos` (
  `matricula` varchar(7) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tutoriasenviarcorreos`
--

CREATE TABLE `tutoriasenviarcorreos` (
  `Matricula` char(10) CHARACTER SET utf8 DEFAULT NULL,
  `Contrasena` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `Nombre` longtext DEFAULT NULL,
  `Correo` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `NumEnvio` smallint(6) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `tutoriastutoralumnos`
--

CREATE TABLE `tutoriastutoralumnos` (
  `idTutorAlumnos` int(11) NOT NULL,
  `idEmpleado` int(11) NOT NULL,
  `idAlumno` int(11) NOT NULL,
  `idplan_estudios` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `users`
--

CREATE TABLE `users` (
  `id` bigint(20) UNSIGNED NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `remember_token` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Volcado de datos para la tabla `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `email_verified_at`, `password`, `remember_token`, `created_at`, `updated_at`) VALUES
(1, 'prueba', 'correo@correo.com', NULL, '$2y$10$sMxfIW80dgYy8ERBCglVr.lzpxOtCUzZhyB4.9t2JgBeqt5MfSBg2', NULL, '2021-03-31 08:25:24', '2021-03-31 08:25:24');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionalumnoempresa2_`
--

CREATE TABLE `vinculacionalumnoempresa2_` (
  `IdAlumnoEmpresa` int(11) NOT NULL,
  `IdEmpresa` int(11) NOT NULL,
  `NombreProyecto` longtext NOT NULL,
  `IdAlumno` int(11) NOT NULL,
  `IdContacto` int(11) NOT NULL,
  `Activa` tinyint(4) NOT NULL,
  `IdPlanEstudios` int(11) NOT NULL,
  `IdMateria` int(11) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `Felaboracion` date NOT NULL,
  `FInicio` date DEFAULT NULL,
  `FFin` date DEFAULT NULL,
  `EntregoVinculacion` tinyint(4) DEFAULT NULL,
  `FechaDeEntrega` datetime DEFAULT NULL,
  `FirmaDirector` tinyint(4) DEFAULT NULL,
  `idempleado` int(11) DEFAULT NULL,
  `idPersona` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionbeneficiario`
--

CREATE TABLE `vinculacionbeneficiario` (
  `IdBeneficiario` int(11) NOT NULL,
  `Beneficiario` varchar(100) CHARACTER SET utf8 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacioncartasestanciasestadia`
--

CREATE TABLE `vinculacioncartasestanciasestadia` (
  `id` int(11) NOT NULL,
  `IdAlumno` int(11) NOT NULL,
  `IdMateria` int(11) NOT NULL,
  `IdPlanEstudios` int(11) NOT NULL,
  `IdTipoCarta` smallint(6) NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `Fecha` date NOT NULL,
  `NombreArchivo` varchar(32) NOT NULL,
  `CodigoQR` varchar(32) DEFAULT NULL,
  `FirmaDirector` tinyint(4) NOT NULL,
  `Activa` tinyint(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacioncatalogoempresas_`
--

CREATE TABLE `vinculacioncatalogoempresas_` (
  `IdCatalogoEmpresa` int(11) NOT NULL,
  `NombreEmpresa` longtext NOT NULL,
  `IdPais` int(11) NOT NULL,
  `IdEstado` int(11) NOT NULL,
  `IdMunicipio` int(11) NOT NULL,
  `NombreContactoEmpresarial` longtext NOT NULL,
  `Cargo` longtext NOT NULL,
  `Telefono` varchar(150) CHARACTER SET utf8 NOT NULL,
  `Correo` varchar(100) CHARACTER SET utf8 NOT NULL,
  `IdSectorEmpresarial` int(11) NOT NULL,
  `IdActividad` int(11) NOT NULL,
  `IdBeneficiario` int(11) NOT NULL,
  `IdTipoConvenio` int(11) NOT NULL,
  `Convenio` tinyint(4) NOT NULL,
  `Activa` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionciudades`
--

CREATE TABLE `vinculacionciudades` (
  `IdCiudad` int(11) NOT NULL,
  `Nombre` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `IdEstado` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacioncontactoempresarial_`
--

CREATE TABLE `vinculacioncontactoempresarial_` (
  `IdContacto` int(11) NOT NULL,
  `NombreContacto` varchar(250) CHARACTER SET utf8 NOT NULL,
  `IdEmpresa` int(11) NOT NULL,
  `Puesto` varchar(250) CHARACTER SET utf8 NOT NULL,
  `Telefono` varchar(150) CHARACTER SET utf8 DEFAULT NULL,
  `Correo` varchar(150) CHARACTER SET utf8 DEFAULT NULL,
  `NombreDeLaEmpresa` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionestados`
--

CREATE TABLE `vinculacionestados` (
  `IdEstado` int(11) NOT NULL,
  `Nombre` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `IdPais` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionfechasparaperiodos`
--

CREATE TABLE `vinculacionfechasparaperiodos` (
  `IdFechasPEstancias` int(11) NOT NULL,
  `IdMateria` int(11) NOT NULL,
  `FechaInicioPeriodo` date NOT NULL,
  `FechaFinPerioodo` date NOT NULL,
  `IdCuatrimestre` int(11) NOT NULL,
  `HorasDePractica` int(11) NOT NULL,
  `FechaInicioVisible` date NOT NULL,
  `FechaFinVisible` date NOT NULL,
  `Activo` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionpaises`
--

CREATE TABLE `vinculacionpaises` (
  `IdPais` int(11) NOT NULL,
  `Abrev` char(3) CHARACTER SET utf8 DEFAULT NULL,
  `Pais` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionregistrocartas`
--

CREATE TABLE `vinculacionregistrocartas` (
  `IdArchivo` int(11) NOT NULL,
  `Nombre` varchar(150) DEFAULT NULL,
  `TipoDeArchivo` varchar(250) DEFAULT NULL,
  `Dato` longblob DEFAULT NULL,
  `idPersona` int(11) DEFAULT NULL,
  `IdCuatrimestre` int(11) DEFAULT NULL,
  `IdPlanDeEstudios` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculacionsectorempresarial`
--

CREATE TABLE `vinculacionsectorempresarial` (
  `IdSectorEconomico` int(11) NOT NULL,
  `TipoSector` varchar(100) CHARACTER SET utf8 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculaciontipoactividad`
--

CREATE TABLE `vinculaciontipoactividad` (
  `IdActividad` int(11) NOT NULL,
  `TipoActividad` varchar(100) CHARACTER SET utf8 DEFAULT NULL,
  `IdSectorEconimico` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculaciontipoconvenio`
--

CREATE TABLE `vinculaciontipoconvenio` (
  `IdTipoConvenio` int(11) NOT NULL,
  `TipoConvenio` varchar(100) CHARACTER SET utf8 NOT NULL,
  `IdBeneficiario` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `vinculaciontmpalumnosestadia`
--

CREATE TABLE `vinculaciontmpalumnosestadia` (
  `IdAlumno` int(11) NOT NULL,
  `IdPlanDeEstudios` int(11) DEFAULT NULL,
  `Matricula` varchar(7) CHARACTER SET utf8 DEFAULT NULL,
  `Alumno` longtext DEFAULT NULL,
  `PlanEstudios` char(20) CHARACTER SET utf8 DEFAULT NULL,
  `MateriasPlan` int(11) DEFAULT NULL,
  `Acreditadas` int(11) DEFAULT NULL,
  `InscritoEnElCuatri` int(11) DEFAULT NULL,
  `reporoboEstadia` tinyint(4) DEFAULT NULL,
  `aproboEstadia` tinyint(4) DEFAULT NULL,
  `Estancia1y2` int(11) DEFAULT NULL,
  `CursaEstadiaEnEsteCuatri` tinyint(4) DEFAULT NULL,
  `MateriasCursandoEnCuatri` int(11) DEFAULT NULL,
  `Estatus` varchar(50) CHARACTER SET utf8 DEFAULT NULL,
  `idEstatus` int(11) DEFAULT NULL,
  `IdCuatrimestre` int(11) DEFAULT NULL,
  `Aprobado` tinyint(4) DEFAULT NULL,
  `IdMateria` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `almacenarimagenes`
--
ALTER TABLE `almacenarimagenes`
  ADD PRIMARY KEY (`Id`);

--
-- Indices de la tabla `aspirantes`
--
ALTER TABLE `aspirantes`
  ADD PRIMARY KEY (`idaspirante`);

--
-- Indices de la tabla `calidadarea`
--
ALTER TABLE `calidadarea`
  ADD PRIMARY KEY (`IdArea`);

--
-- Indices de la tabla `calidaddocumentosvariados`
--
ALTER TABLE `calidaddocumentosvariados`
  ADD PRIMARY KEY (`IdDocumento`);

--
-- Indices de la tabla `calidadformatosdocumentos`
--
ALTER TABLE `calidadformatosdocumentos`
  ADD PRIMARY KEY (`IdFormatoDocumento`);

--
-- Indices de la tabla `calidadinstructivotrabajo`
--
ALTER TABLE `calidadinstructivotrabajo`
  ADD PRIMARY KEY (`IdInstructivoTrabajo`);

--
-- Indices de la tabla `calidadmodulo`
--
ALTER TABLE `calidadmodulo`
  ADD PRIMARY KEY (`IdModulo`);

--
-- Indices de la tabla `calidadorganigrama`
--
ALTER TABLE `calidadorganigrama`
  ADD PRIMARY KEY (`IdOrganigrama`);

--
-- Indices de la tabla `calidadprocedimiento`
--
ALTER TABLE `calidadprocedimiento`
  ADD PRIMARY KEY (`IdProcedimiento`);

--
-- Indices de la tabla `calidadpuesto`
--
ALTER TABLE `calidadpuesto`
  ADD PRIMARY KEY (`IdPuesto`);

--
-- Indices de la tabla `calidadusuario`
--
ALTER TABLE `calidadusuario`
  ADD PRIMARY KEY (`IdUsuario`);

--
-- Indices de la tabla `catalogosclasificacionmaterias`
--
ALTER TABLE `catalogosclasificacionmaterias`
  ADD PRIMARY KEY (`idCatalogo`);

--
-- Indices de la tabla `catalogosgeneral`
--
ALTER TABLE `catalogosgeneral`
  ADD PRIMARY KEY (`IdCatalogo`);

--
-- Indices de la tabla `catalogosmovimientoestatusalumno`
--
ALTER TABLE `catalogosmovimientoestatusalumno`
  ADD PRIMARY KEY (`idMovimientoEstatusAlumno`);

--
-- Indices de la tabla `catalogostitulacion`
--
ALTER TABLE `catalogostitulacion`
  ADD PRIMARY KEY (`idCatalogo`);

--
-- Indices de la tabla `escolaresalumno`
--
ALTER TABLE `escolaresalumno`
  ADD PRIMARY KEY (`idalumno`),
  ADD UNIQUE KEY `matricula` (`idalumno`);

--
-- Indices de la tabla `escolaresalumnobecas`
--
ALTER TABLE `escolaresalumnobecas`
  ADD PRIMARY KEY (`idAlumnoBeca`);

--
-- Indices de la tabla `escolaresalumnobecashistorico`
--
ALTER TABLE `escolaresalumnobecashistorico`
  ADD PRIMARY KEY (`idAlumnoBecaHistorico`);

--
-- Indices de la tabla `escolaresalumnocarreras`
--
ALTER TABLE `escolaresalumnocarreras`
  ADD PRIMARY KEY (`IdAlumnoCarrera`);

--
-- Indices de la tabla `escolaresalumnohistoricodeestatus`
--
ALTER TABLE `escolaresalumnohistoricodeestatus`
  ADD PRIMARY KEY (`idAlumnoHistoricoDeEstatus`);

--
-- Indices de la tabla `escolaresalumnomovilidad`
--
ALTER TABLE `escolaresalumnomovilidad`
  ADD PRIMARY KEY (`idAlumnoMovilidad`);

--
-- Indices de la tabla `escolaresalumnospendientes`
--
ALTER TABLE `escolaresalumnospendientes`
  ADD PRIMARY KEY (`IdAlumnoPendiente`);

--
-- Indices de la tabla `escolaresalumno_especial`
--
ALTER TABLE `escolaresalumno_especial`
  ADD PRIMARY KEY (`idalumno`,`idplan_estudios`,`idcuatrimestre`);

--
-- Indices de la tabla `escolaresaspirante`
--
ALTER TABLE `escolaresaspirante`
  ADD PRIMARY KEY (`idaspirante`);

--
-- Indices de la tabla `escolaresaula`
--
ALTER TABLE `escolaresaula`
  ADD PRIMARY KEY (`idaula`);

--
-- Indices de la tabla `escolaresbecas`
--
ALTER TABLE `escolaresbecas`
  ADD PRIMARY KEY (`idBeca`);

--
-- Indices de la tabla `escolarescampus`
--
ALTER TABLE `escolarescampus`
  ADD PRIMARY KEY (`idCampus`);

--
-- Indices de la tabla `escolarescardex`
--
ALTER TABLE `escolarescardex`
  ADD PRIMARY KEY (`idalumno`,`idplan_estudios`,`idmateria`);

--
-- Indices de la tabla `escolarescarga`
--
ALTER TABLE `escolarescarga`
  ADD PRIMARY KEY (`idcarga`);

--
-- Indices de la tabla `escolarescarrera`
--
ALTER TABLE `escolarescarrera`
  ADD PRIMARY KEY (`idcarrera`);

--
-- Indices de la tabla `escolaresciclos`
--
ALTER TABLE `escolaresciclos`
  ADD PRIMARY KEY (`idciclo`);

--
-- Indices de la tabla `escolarescompetenciasporciclo`
--
ALTER TABLE `escolarescompetenciasporciclo`
  ADD PRIMARY KEY (`idCompetencia`);

--
-- Indices de la tabla `escolaresconfiguracionhorasgrupos`
--
ALTER TABLE `escolaresconfiguracionhorasgrupos`
  ADD PRIMARY KEY (`idConfiguracionHorasGrupos`);

--
-- Indices de la tabla `escolarescuatrimestre`
--
ALTER TABLE `escolarescuatrimestre`
  ADD PRIMARY KEY (`idcuatrimestre`);

--
-- Indices de la tabla `escolarescuatrimestrecreditos`
--
ALTER TABLE `escolarescuatrimestrecreditos`
  ADD PRIMARY KEY (`idCuatrimestreCreditos`);

--
-- Indices de la tabla `escolaresdirectoresdecarrera`
--
ALTER TABLE `escolaresdirectoresdecarrera`
  ADD PRIMARY KEY (`idDirectorCarrera`);

--
-- Indices de la tabla `escolaresdocumentos`
--
ALTER TABLE `escolaresdocumentos`
  ADD PRIMARY KEY (`idDocumento`);

--
-- Indices de la tabla `escolaresdocumentosconfiguracion`
--
ALTER TABLE `escolaresdocumentosconfiguracion`
  ADD PRIMARY KEY (`IdDocumentoConfiguracion`);

--
-- Indices de la tabla `escolaresdocumentosnotas`
--
ALTER TABLE `escolaresdocumentosnotas`
  ADD PRIMARY KEY (`idDocumentoNotas`);

--
-- Indices de la tabla `escolaresdocumentosrecibidos`
--
ALTER TABLE `escolaresdocumentosrecibidos`
  ADD PRIMARY KEY (`IdDocumentoRecibido`);

--
-- Indices de la tabla `escolaresedificios`
--
ALTER TABLE `escolaresedificios`
  ADD PRIMARY KEY (`idEdificio`);

--
-- Indices de la tabla `escolaresesc_procedencia`
--
ALTER TABLE `escolaresesc_procedencia`
  ADD PRIMARY KEY (`idesc_procedencia`);

--
-- Indices de la tabla `escolaresgrupo`
--
ALTER TABLE `escolaresgrupo`
  ADD PRIMARY KEY (`idgrupo`);

--
-- Indices de la tabla `escolaresgrupo_alumno`
--
ALTER TABLE `escolaresgrupo_alumno`
  ADD PRIMARY KEY (`idgrupo`,`idalumno`);

--
-- Indices de la tabla `escolaresgrupo_alumno_calificaciones`
--
ALTER TABLE `escolaresgrupo_alumno_calificaciones`
  ADD PRIMARY KEY (`idGrupoAlumnoCalificacion`);

--
-- Indices de la tabla `escolareshorario`
--
ALTER TABLE `escolareshorario`
  ADD PRIMARY KEY (`idhorario`);

--
-- Indices de la tabla `escolaresimagen`
--
ALTER TABLE `escolaresimagen`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `escolaresinfresultadosptc`
--
ALTER TABLE `escolaresinfresultadosptc`
  ADD PRIMARY KEY (`IdProfActividades`);

--
-- Indices de la tabla `escolaresinscripcion`
--
ALTER TABLE `escolaresinscripcion`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique` (`idplan_estudios`,`idalumno`,`idcuatrimestre`) USING BTREE;

--
-- Indices de la tabla `escolaresmateria`
--
ALTER TABLE `escolaresmateria`
  ADD PRIMARY KEY (`idmateria`);

--
-- Indices de la tabla `escolaresnivelesdominioescala`
--
ALTER TABLE `escolaresnivelesdominioescala`
  ADD PRIMARY KEY (`idNivelDominioEscala`);

--
-- Indices de la tabla `escolarespendientes`
--
ALTER TABLE `escolarespendientes`
  ADD PRIMARY KEY (`IdPendiente`);

--
-- Indices de la tabla `escolaresperiodoinscripciones`
--
ALTER TABLE `escolaresperiodoinscripciones`
  ADD PRIMARY KEY (`idPeriodoInscripcion`);

--
-- Indices de la tabla `escolaresperiodos`
--
ALTER TABLE `escolaresperiodos`
  ADD PRIMARY KEY (`IdPeriodo`);

--
-- Indices de la tabla `escolaresplan_estudios`
--
ALTER TABLE `escolaresplan_estudios`
  ADD PRIMARY KEY (`idplan_estudios`);

--
-- Indices de la tabla `escolaresplan_estudios_materia`
--
ALTER TABLE `escolaresplan_estudios_materia`
  ADD PRIMARY KEY (`idplan_estudios`,`idmateria`);

--
-- Indices de la tabla `escolaresreinscripcionhorario`
--
ALTER TABLE `escolaresreinscripcionhorario`
  ADD PRIMARY KEY (`idReinscripcionHorario`);

--
-- Indices de la tabla `escolaresseriacion`
--
ALTER TABLE `escolaresseriacion`
  ADD PRIMARY KEY (`idplan_estudios`,`idmateria_previa`,`idmateria`);

--
-- Indices de la tabla `escolarestitulacioningenieria`
--
ALTER TABLE `escolarestitulacioningenieria`
  ADD PRIMARY KEY (`idTitulacionIngenieria`);

--
-- Indices de la tabla `escolarestitulacioningenieriahistorico`
--
ALTER TABLE `escolarestitulacioningenieriahistorico`
  ADD PRIMARY KEY (`idTitulacionIngenieriaEstatus`);

--
-- Indices de la tabla `escolarestutoria`
--
ALTER TABLE `escolarestutoria`
  ADD PRIMARY KEY (`idalumno`,`idempleado`);

--
-- Indices de la tabla `failed_jobs`
--
ALTER TABLE `failed_jobs`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `financieros`
--
ALTER TABLE `financieros`
  ADD PRIMARY KEY (`idParada`);

--
-- Indices de la tabla `financierosaprobacionclasificacion`
--
ALTER TABLE `financierosaprobacionclasificacion`
  ADD PRIMARY KEY (`IdClasificacionAprobacion`);

--
-- Indices de la tabla `financierosaprobacioninscripcion`
--
ALTER TABLE `financierosaprobacioninscripcion`
  ADD PRIMARY KEY (`IdInscripcionAprobacion`);

--
-- Indices de la tabla `financierosaprobacionmovimiento`
--
ALTER TABLE `financierosaprobacionmovimiento`
  ADD PRIMARY KEY (`IdAprobacionMovimiento`);

--
-- Indices de la tabla `financierosbecario`
--
ALTER TABLE `financierosbecario`
  ADD PRIMARY KEY (`idcarrera`,`idplan_estudios`,`idalumno`,`idcuatrimestre`,`idbeca`);

--
-- Indices de la tabla `financieroscobrosconfiguracion`
--
ALTER TABLE `financieroscobrosconfiguracion`
  ADD PRIMARY KEY (`IdCobroConfiguracion`);

--
-- Indices de la tabla `financieroscobrosprogramacion`
--
ALTER TABLE `financieroscobrosprogramacion`
  ADD PRIMARY KEY (`IdCobroProgramacion`);

--
-- Indices de la tabla `financierosconceptosaprecargar`
--
ALTER TABLE `financierosconceptosaprecargar`
  ADD PRIMARY KEY (`IdConceptoAPrecargar`);

--
-- Indices de la tabla `financierosconceptosotrosingresos`
--
ALTER TABLE `financierosconceptosotrosingresos`
  ADD PRIMARY KEY (`IdConceptoOtrosIngresos`);

--
-- Indices de la tabla `financierosconceptosotrosingresosdetalle`
--
ALTER TABLE `financierosconceptosotrosingresosdetalle`
  ADD PRIMARY KEY (`IdConceptoOtrosIngresosDetalle`);

--
-- Indices de la tabla `financierospagosenlinea`
--
ALTER TABLE `financierospagosenlinea`
  ADD PRIMARY KEY (`idPago`);

--
-- Indices de la tabla `financierospaquetes`
--
ALTER TABLE `financierospaquetes`
  ADD PRIMARY KEY (`IdPaquete`);

--
-- Indices de la tabla `financierospaquetesasignados`
--
ALTER TABLE `financierospaquetesasignados`
  ADD PRIMARY KEY (`IdPaqueteAsignado`);

--
-- Indices de la tabla `financierospaquetesconceptos`
--
ALTER TABLE `financierospaquetesconceptos`
  ADD PRIMARY KEY (`IdPaquetesConceptos`);

--
-- Indices de la tabla `financierospromocionesbecas`
--
ALTER TABLE `financierospromocionesbecas`
  ADD PRIMARY KEY (`IdPromocionBeca`);

--
-- Indices de la tabla `financierospromocionesconceptos`
--
ALTER TABLE `financierospromocionesconceptos`
  ADD PRIMARY KEY (`IdPromocionConcepto`);

--
-- Indices de la tabla `financierosrazonsocial`
--
ALTER TABLE `financierosrazonsocial`
  ADD PRIMARY KEY (`IdRazonSocial`);

--
-- Indices de la tabla `financierosrazonsocialpersonas`
--
ALTER TABLE `financierosrazonsocialpersonas`
  ADD PRIMARY KEY (`IdRazonSocialPersona`);

--
-- Indices de la tabla `financierosrbconceptos`
--
ALTER TABLE `financierosrbconceptos`
  ADD PRIMARY KEY (`IdRBConcepto`);

--
-- Indices de la tabla `financierosrbconceptosdetalle`
--
ALTER TABLE `financierosrbconceptosdetalle`
  ADD PRIMARY KEY (`IdRBConceptoDetalle`);

--
-- Indices de la tabla `financierosreferenciasbancarias`
--
ALTER TABLE `financierosreferenciasbancarias`
  ADD PRIMARY KEY (`IdReferncia`);

--
-- Indices de la tabla `financierosreferenciasbancariasconfiguracion`
--
ALTER TABLE `financierosreferenciasbancariasconfiguracion`
  ADD PRIMARY KEY (`IdReferenciaBancariaConfiguracion`);

--
-- Indices de la tabla `financierosreferenciasbancariaseventoconfiguracion`
--
ALTER TABLE `financierosreferenciasbancariaseventoconfiguracion`
  ADD PRIMARY KEY (`IdReferenciaBancariaEventoConfiguracion`);

--
-- Indices de la tabla `financierosreferenciasbancariaseventos`
--
ALTER TABLE `financierosreferenciasbancariaseventos`
  ADD PRIMARY KEY (`IdReferenciaBancariaEvento`);

--
-- Indices de la tabla `financierosreferenciasbancariasmovimientos`
--
ALTER TABLE `financierosreferenciasbancariasmovimientos`
  ADD PRIMARY KEY (`IdReferenciaMovimiento`);

--
-- Indices de la tabla `financierosreferenciasbancariasmovimientoscuentaconcentradora`
--
ALTER TABLE `financierosreferenciasbancariasmovimientoscuentaconcentradora`
  ADD PRIMARY KEY (`idReferenciaMovimientoCuentaConcentradora`);

--
-- Indices de la tabla `financierosreferenciasbancariasmovimientosimportados`
--
ALTER TABLE `financierosreferenciasbancariasmovimientosimportados`
  ADD PRIMARY KEY (`IdRBMovimientoImportado`);

--
-- Indices de la tabla `financierossaldoafavor`
--
ALTER TABLE `financierossaldoafavor`
  ADD PRIMARY KEY (`IdSaldoAFavor`);

--
-- Indices de la tabla `financierostransportecostos`
--
ALTER TABLE `financierostransportecostos`
  ADD PRIMARY KEY (`IdTransporteCosto`);

--
-- Indices de la tabla `financierostransporterutas`
--
ALTER TABLE `financierostransporterutas`
  ADD PRIMARY KEY (`IdTransporteRuta`);

--
-- Indices de la tabla `financierostransportesolicitudcorte`
--
ALTER TABLE `financierostransportesolicitudcorte`
  ADD PRIMARY KEY (`IdTransporteSolicitudCorte`);

--
-- Indices de la tabla `financierostransportesolicitudes`
--
ALTER TABLE `financierostransportesolicitudes`
  ADD PRIMARY KEY (`IdTransporteSolicitud`);

--
-- Indices de la tabla `imagen`
--
ALTER TABLE `imagen`
  ADD PRIMARY KEY (`ID`);

--
-- Indices de la tabla `informes`
--
ALTER TABLE `informes`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `migrations`
--
ALTER TABLE `migrations`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `password_resets`
--
ALTER TABLE `password_resets`
  ADD KEY `password_resets_email_index` (`email`);

--
-- Indices de la tabla `personadomicilio`
--
ALTER TABLE `personadomicilio`
  ADD PRIMARY KEY (`iddomicilio`);

--
-- Indices de la tabla `personaempresas`
--
ALTER TABLE `personaempresas`
  ADD PRIMARY KEY (`idEmpresa`);

--
-- Indices de la tabla `personaestados`
--
ALTER TABLE `personaestados`
  ADD PRIMARY KEY (`idEstado`);

--
-- Indices de la tabla `personamunicipio`
--
ALTER TABLE `personamunicipio`
  ADD PRIMARY KEY (`idmunicipio`);

--
-- Indices de la tabla `personapaises`
--
ALTER TABLE `personapaises`
  ADD PRIMARY KEY (`idPais`);

--
-- Indices de la tabla `personapersona`
--
ALTER TABLE `personapersona`
  ADD PRIMARY KEY (`idpersona`);

--
-- Indices de la tabla `personareferencias`
--
ALTER TABLE `personareferencias`
  ADD PRIMARY KEY (`IdReferencia`);

--
-- Indices de la tabla `planeacioncategoria`
--
ALTER TABLE `planeacioncategoria`
  ADD PRIMARY KEY (`idcategoria`);

--
-- Indices de la tabla `planeacioncl_area`
--
ALTER TABLE `planeacioncl_area`
  ADD PRIMARY KEY (`idarea`);

--
-- Indices de la tabla `planeacioncl_cuestionario`
--
ALTER TABLE `planeacioncl_cuestionario`
  ADD PRIMARY KEY (`idcuestionario`);

--
-- Indices de la tabla `planeacioncl_cuestionario_pregunta`
--
ALTER TABLE `planeacioncl_cuestionario_pregunta`
  ADD PRIMARY KEY (`idcuestionario`,`idpregunta`,`idrama`);

--
-- Indices de la tabla `planeacioncl_evaluacion`
--
ALTER TABLE `planeacioncl_evaluacion`
  ADD PRIMARY KEY (`idevaluacion`);

--
-- Indices de la tabla `planeacioncl_grupo`
--
ALTER TABLE `planeacioncl_grupo`
  ADD PRIMARY KEY (`idgrupo`);

--
-- Indices de la tabla `planeacioncl_pregunta`
--
ALTER TABLE `planeacioncl_pregunta`
  ADD PRIMARY KEY (`idpregunta`);

--
-- Indices de la tabla `planeacioncl_rama`
--
ALTER TABLE `planeacioncl_rama`
  ADD PRIMARY KEY (`idrama`);

--
-- Indices de la tabla `planeacioncl_registro_evaluaciones`
--
ALTER TABLE `planeacioncl_registro_evaluaciones`
  ADD PRIMARY KEY (`idregistro`);

--
-- Indices de la tabla `planeacioncl_respuesta`
--
ALTER TABLE `planeacioncl_respuesta`
  ADD PRIMARY KEY (`idrespuesta`);

--
-- Indices de la tabla `planeacioncl_resultado`
--
ALTER TABLE `planeacioncl_resultado`
  ADD PRIMARY KEY (`idresultado`);

--
-- Indices de la tabla `planeacioncl_sugerencia`
--
ALTER TABLE `planeacioncl_sugerencia`
  ADD PRIMARY KEY (`idsugerencia`);

--
-- Indices de la tabla `planeacioncuestionario`
--
ALTER TABLE `planeacioncuestionario`
  ADD PRIMARY KEY (`idcuestionario`);

--
-- Indices de la tabla `planeacioncuestionario_pregunta`
--
ALTER TABLE `planeacioncuestionario_pregunta`
  ADD PRIMARY KEY (`idcuestionario`,`idpregunta`,`idcategoria`);

--
-- Indices de la tabla `planeacionevaluacion`
--
ALTER TABLE `planeacionevaluacion`
  ADD PRIMARY KEY (`idevaluacion`);

--
-- Indices de la tabla `planeacionplan_estudios`
--
ALTER TABLE `planeacionplan_estudios`
  ADD PRIMARY KEY (`idplan_estudios`);

--
-- Indices de la tabla `planeacionpregunta`
--
ALTER TABLE `planeacionpregunta`
  ADD PRIMARY KEY (`idpregunta`);

--
-- Indices de la tabla `planeacionregistro_evaluaciones`
--
ALTER TABLE `planeacionregistro_evaluaciones`
  ADD PRIMARY KEY (`idregistro`);

--
-- Indices de la tabla `planeacionregistro_evaluaciones_cuestionario`
--
ALTER TABLE `planeacionregistro_evaluaciones_cuestionario`
  ADD PRIMARY KEY (`idregistro`);

--
-- Indices de la tabla `planeacionrespuesta`
--
ALTER TABLE `planeacionrespuesta`
  ADD PRIMARY KEY (`idrespuesta`);

--
-- Indices de la tabla `planeacionresultado`
--
ALTER TABLE `planeacionresultado`
  ADD PRIMARY KEY (`idresultado`);

--
-- Indices de la tabla `planeaciontipo_cuestionario`
--
ALTER TABLE `planeaciontipo_cuestionario`
  ADD PRIMARY KEY (`idtipocuestionario`);

--
-- Indices de la tabla `planeacion_cuestionario`
--
ALTER TABLE `planeacion_cuestionario`
  ADD PRIMARY KEY (`idcuestionario`);

--
-- Indices de la tabla `planeacion_cuestionario_pregunta`
--
ALTER TABLE `planeacion_cuestionario_pregunta`
  ADD PRIMARY KEY (`idcuestionario`,`idpregunta`,`idseccion`);

--
-- Indices de la tabla `planeacion_evaluacion`
--
ALTER TABLE `planeacion_evaluacion`
  ADD PRIMARY KEY (`idevaluacion`);

--
-- Indices de la tabla `planeacion_pregunta`
--
ALTER TABLE `planeacion_pregunta`
  ADD PRIMARY KEY (`idpregunta`);

--
-- Indices de la tabla `planeacion_resultado`
--
ALTER TABLE `planeacion_resultado`
  ADD PRIMARY KEY (`idresultado`);

--
-- Indices de la tabla `planeacion_seccion`
--
ALTER TABLE `planeacion_seccion`
  ADD PRIMARY KEY (`idseccion`);

--
-- Indices de la tabla `productos`
--
ALTER TABLE `productos`
  ADD PRIMARY KEY (`id_Cod`);

--
-- Indices de la tabla `rharea`
--
ALTER TABLE `rharea`
  ADD PRIMARY KEY (`idarea`);

--
-- Indices de la tabla `rhareasjefes`
--
ALTER TABLE `rhareasjefes`
  ADD PRIMARY KEY (`IdAreaJefe`);

--
-- Indices de la tabla `rhcalendario`
--
ALTER TABLE `rhcalendario`
  ADD PRIMARY KEY (`IdCalendario`);

--
-- Indices de la tabla `rhdescuentosaplicados`
--
ALTER TABLE `rhdescuentosaplicados`
  ADD PRIMARY KEY (`IdDescuentoAplicado`);

--
-- Indices de la tabla `rhempleado`
--
ALTER TABLE `rhempleado`
  ADD PRIMARY KEY (`idempleado`);

--
-- Indices de la tabla `rhempleadoshorarios`
--
ALTER TABLE `rhempleadoshorarios`
  ADD PRIMARY KEY (`IdEmpleadoHorario`);

--
-- Indices de la tabla `rhextensionestelefonicas`
--
ALTER TABLE `rhextensionestelefonicas`
  ADD PRIMARY KEY (`IdExtension`);

--
-- Indices de la tabla `rhhorarios`
--
ALTER TABLE `rhhorarios`
  ADD PRIMARY KEY (`IdHorario`);

--
-- Indices de la tabla `rhhorariosdetalle`
--
ALTER TABLE `rhhorariosdetalle`
  ADD PRIMARY KEY (`IdHorarioDetalle`);

--
-- Indices de la tabla `rhhorariosvisualizar`
--
ALTER TABLE `rhhorariosvisualizar`
  ADD PRIMARY KEY (`IdHorarioVisualizar`);

--
-- Indices de la tabla `rhincidenciasconfiguracion`
--
ALTER TABLE `rhincidenciasconfiguracion`
  ADD PRIMARY KEY (`IdIncidenciaConfiguracion`);

--
-- Indices de la tabla `rhincidenciasjustificaciones`
--
ALTER TABLE `rhincidenciasjustificaciones`
  ADD PRIMARY KEY (`IdIncidenciaJustificacion`);

--
-- Indices de la tabla `rhincidenciastipo`
--
ALTER TABLE `rhincidenciastipo`
  ADD PRIMARY KEY (`IdIncidenciaTipo`);

--
-- Indices de la tabla `rhjustificantes`
--
ALTER TABLE `rhjustificantes`
  ADD PRIMARY KEY (`IdJustificante`);

--
-- Indices de la tabla `rhmotivosjustificacion`
--
ALTER TABLE `rhmotivosjustificacion`
  ADD PRIMARY KEY (`IdMotivo`);

--
-- Indices de la tabla `rhpuestos`
--
ALTER TABLE `rhpuestos`
  ADD PRIMARY KEY (`IdPuesto`);

--
-- Indices de la tabla `rhregistroasistencia`
--
ALTER TABLE `rhregistroasistencia`
  ADD PRIMARY KEY (`IdRegistroAsistencia`);

--
-- Indices de la tabla `rhregistroasistencia_excepciones`
--
ALTER TABLE `rhregistroasistencia_excepciones`
  ADD PRIMARY KEY (`IdRAExcepcion`);

--
-- Indices de la tabla `rhregistrosdispositivo`
--
ALTER TABLE `rhregistrosdispositivo`
  ADD PRIMARY KEY (`IdRegistroDispositivo`);

--
-- Indices de la tabla `seguridadcatalogo`
--
ALTER TABLE `seguridadcatalogo`
  ADD PRIMARY KEY (`idCatalogo`);

--
-- Indices de la tabla `seguridadcuentasreestablecidas`
--
ALTER TABLE `seguridadcuentasreestablecidas`
  ADD PRIMARY KEY (`idCuentaReestablecida`);

--
-- Indices de la tabla `seguridadfunciones`
--
ALTER TABLE `seguridadfunciones`
  ADD PRIMARY KEY (`idFuncion`);

--
-- Indices de la tabla `seguridadmoesc`
--
ALTER TABLE `seguridadmoesc`
  ADD PRIMARY KEY (`IdMoesc`);

--
-- Indices de la tabla `seguridadperfiles`
--
ALTER TABLE `seguridadperfiles`
  ADD PRIMARY KEY (`idperfil`);

--
-- Indices de la tabla `seguridadperfilesfunciones`
--
ALTER TABLE `seguridadperfilesfunciones`
  ADD PRIMARY KEY (`idPerfilFuncion`);

--
-- Indices de la tabla `seguridadtiempodeuso`
--
ALTER TABLE `seguridadtiempodeuso`
  ADD PRIMARY KEY (`idTiempoDeUso`);

--
-- Indices de la tabla `seguridadusuarioerrores`
--
ALTER TABLE `seguridadusuarioerrores`
  ADD PRIMARY KEY (`idUsuarioErrores`);

--
-- Indices de la tabla `seguridadusuarios`
--
ALTER TABLE `seguridadusuarios`
  ADD PRIMARY KEY (`idUsuario`),
  ADD UNIQUE KEY `IdUsuarioUnique` (`idPersona`);

--
-- Indices de la tabla `sin_gpo`
--
ALTER TABLE `sin_gpo`
  ADD PRIMARY KEY (`idalumno`,`idgrupo`,`idmateria`);

--
-- Indices de la tabla `tutoriastutoralumnos`
--
ALTER TABLE `tutoriastutoralumnos`
  ADD PRIMARY KEY (`idTutorAlumnos`);

--
-- Indices de la tabla `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `users_email_unique` (`email`);

--
-- Indices de la tabla `vinculacionalumnoempresa2_`
--
ALTER TABLE `vinculacionalumnoempresa2_`
  ADD PRIMARY KEY (`IdAlumnoEmpresa`);

--
-- Indices de la tabla `vinculacionbeneficiario`
--
ALTER TABLE `vinculacionbeneficiario`
  ADD PRIMARY KEY (`IdBeneficiario`);

--
-- Indices de la tabla `vinculacioncartasestanciasestadia`
--
ALTER TABLE `vinculacioncartasestanciasestadia`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `vinculacioncatalogoempresas_`
--
ALTER TABLE `vinculacioncatalogoempresas_`
  ADD PRIMARY KEY (`IdCatalogoEmpresa`);

--
-- Indices de la tabla `vinculacionciudades`
--
ALTER TABLE `vinculacionciudades`
  ADD PRIMARY KEY (`IdCiudad`);

--
-- Indices de la tabla `vinculacioncontactoempresarial_`
--
ALTER TABLE `vinculacioncontactoempresarial_`
  ADD PRIMARY KEY (`IdContacto`);

--
-- Indices de la tabla `vinculacionestados`
--
ALTER TABLE `vinculacionestados`
  ADD PRIMARY KEY (`IdEstado`);

--
-- Indices de la tabla `vinculacionfechasparaperiodos`
--
ALTER TABLE `vinculacionfechasparaperiodos`
  ADD PRIMARY KEY (`IdFechasPEstancias`);

--
-- Indices de la tabla `vinculacionpaises`
--
ALTER TABLE `vinculacionpaises`
  ADD PRIMARY KEY (`IdPais`);

--
-- Indices de la tabla `vinculacionregistrocartas`
--
ALTER TABLE `vinculacionregistrocartas`
  ADD PRIMARY KEY (`IdArchivo`);

--
-- Indices de la tabla `vinculacionsectorempresarial`
--
ALTER TABLE `vinculacionsectorempresarial`
  ADD PRIMARY KEY (`IdSectorEconomico`);

--
-- Indices de la tabla `vinculaciontipoactividad`
--
ALTER TABLE `vinculaciontipoactividad`
  ADD PRIMARY KEY (`IdActividad`);

--
-- Indices de la tabla `vinculaciontipoconvenio`
--
ALTER TABLE `vinculaciontipoconvenio`
  ADD PRIMARY KEY (`IdTipoConvenio`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `almacenarimagenes`
--
ALTER TABLE `almacenarimagenes`
  MODIFY `Id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `aspirantes`
--
ALTER TABLE `aspirantes`
  MODIFY `idaspirante` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT de la tabla `informes`
--
ALTER TABLE `informes`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT de la tabla `users`
--
ALTER TABLE `users`
  MODIFY `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
