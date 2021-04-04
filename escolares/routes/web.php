<?php

use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/
Auth::routes();

Route::get('/', [App\Http\Controllers\HomeController::class, 'index'])->name('home');
Route::get('/home', [App\Http\Controllers\HomeController::class, 'index'])->name('home');
Route::get('/prueba', [App\Http\Controllers\PruebaController::class, 'prueba'])->name('prueba');
/* ---------------------------------- RUTA DE INFORMES ----------------------------------------*/

 //REPORTE BASE
 Route::get('/reporteBase', [App\Http\Controllers\InformeController::class, 'reporteBase'])->name('Informe.reporteBase');
 //profesor materia
 Route::get('/profesoresMaterias', [App\Http\Controllers\InformeController::class, 'profMaterias'])->name('Informe.profMaterias');
 //Maetrias reprobadas
 Route::get('/MateriasReprobadas', [App\Http\Controllers\InformeController::class, 'matReprobadas'])->name('Informe.materiasReprobadas');
 //index de horario
 Route::get('/Horarios', [App\Http\Controllers\InformeController::class, 'horarios'])->name('Informe.horarioIndex');
 //horario prof
 Route::get('/HorarioProfesor', [App\Http\Controllers\InformeController::class, 'horarios'])->name('Informe.horarioProfesor');
 //horario alumn
 Route::get('/HorarioAlumno', [App\Http\Controllers\InformeController::class, 'horarios'])->name('Informe.horarioAlumno');
 //horario aulas
 Route::get('/HorarioAula', [App\Http\Controllers\InformeController::class, 'horarios'])->name('Informe.horarioAula');
 //LISTA DE ASISTENCIA
 Route::get('/ListaAsistencia', [App\Http\Controllers\InformeController::class, 'listaAsistencia'])->name('Informe.listaAsistencia');
 //ASPIRANTES
 Route::get('/GraficaAspirantes', [App\Http\Controllers\InformeController::class, 'aspirantes'])->name('Informe.aspirantesGrafica');
 //CANDIDATOS RECURSAMIENTO
 Route::get('/CandidatosRecursamiento', [App\Http\Controllers\InformeController::class, 'recursamiento'])->name('Informe.candidatosReursamiento');
 //CALIF. POR UNIDAD
 Route::get('/CalificacionPorUnidad', [App\Http\Controllers\InformeController::class, 'califXUnidad'])->name('Informe.calificacionXUnidad');
 // BECAS ASIGNADAS
 Route::get('/BecasAsignadas', [App\Http\Controllers\InformeController::class, 'becasAsignadas'])->name('Informe.becasAsignadas');
 //asigXOfertar
 Route::get('/AsignaturaPorOfertar', [App\Http\Controllers\InformeController::class, 'asigXOfertar'])->name('Informe.asignaturaXOfertar');
 // alumnos con baja
 Route::get('/AlumnosBaja', [App\Http\Controllers\InformeController::class, 'alumnosBaja'])->name('Informe.alumnosBaja');
 // alumnos reinscritos
 Route::get('/AlumnosReinscritos', [App\Http\Controllers\InformeController::class, 'alumnosReinscrito'])->name('Informe.alumnosReinscritos');
 
 /* ---------------------------------- RUTA DE TRAMITES ----------------------------------------*/
 
 // Index kardex
 Route::get('/Kardex', [App\Http\Controllers\TramiteController::class, 'indexkardex'])->name('Tramite.indexkardex');
 // historial academico
 Route::get('/HistorialAcademico', [App\Http\Controllers\TramiteController::class, 'historialAcademico'])->name('Tramite.indexhistorialuno');
 // formato de registro
 Route::get('/FormatoDeRegistro', [App\Http\Controllers\TramiteController::class, 'formatoRegistro'])->name('Tramite.indexregistro');
 // certificado
  Route::get('/Certificado', [App\Http\Controllers\TramiteController::class, 'certificado'])->name('Tramite.indexcertificado');
 // constancia de estudios
 Route::get('/ConstanciaDeEstudios', [App\Http\Controllers\TramiteController::class, 'constanciaEstudios'])->name('Tramite.indexconstancia');
 // documentos recibidos
 Route::get('/DocumentosRecibidos', [App\Http\Controllers\TramiteController::class, 'docRecibidos'])->name('Tramite.indexdocRecibidos');
/* ---------------------------------- RUTA DE PDF ----------------------------------------*/
//descargar kardex
Route::get('/descargar', [App\Http\Controllers\PDFController::class, 'descargar'])->name('descargarPDF');
 
