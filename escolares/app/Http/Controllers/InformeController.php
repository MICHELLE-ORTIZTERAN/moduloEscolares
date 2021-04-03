<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class InformeController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function index()
    {
        //
    }

    /**
     * Show the form for creating a new resource.
     *
     * @return \Illuminate\Http\Response
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @return \Illuminate\Http\Response
     */
    public function store(Request $request)
    {
        //
    }

    /**
     * Display the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function show($id)
    {
        //
    }

    /**
     * Show the form for editing the specified resource.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function edit($id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     *
     * @param  \Illuminate\Http\Request  $request
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function update(Request $request, $id)
    {
        //
    }

    /**
     * Remove the specified resource from storage.
     *
     * @param  int  $id
     * @return \Illuminate\Http\Response
     */
    public function destroy($id)
    {
        //
    }

    //reporte base
    public function reporteBase()
    {
        //retornamos a la vista
        return view('admin.informes.reporteBase');
    }

    //profesor materia
    public function profMaterias()
    {
        //retornamos a la vista
        return view('admin.informes.profMaterias');
    }

    //materias reprobadas
    public function matReprobadas()
    {
        //retornamos a la vista
        return view('admin.informes.materiasReprobadas');
    }

    //
    public function horarios()
    {
        //retornamos a la vista
        return view('admin.informes.horarioIndex'); //<--------- Falta agregar metodos para visualizar los horario de alumnos, profes y aulas
    }

    //
    public function listaAsistencia()
    {
        //retornamos a la vista
        return view('admin.informes.listaAsistencia');
    }

    //
    public function aspirantes()
    {
        //retornamos a la vista
        return view('admin.informes.aspirantesGrafica');
    }

    //
    public function recursamiento()
    {
        //retornamos a la vista
        return view('admin.informes.candidatosRecursamiento');
    }
    
    //
    public function califxUnidad()
    {
        //retornamos a la vista
        return view('admin.informes.calificacionXUnidad');
    }

    //
    public function becasAsignadas()
    {
        //retornamos a la vista
        return view('admin.informes.becasAsignadas');
    }

    //
    public function asigXOfertar()
    {
        //retornamos a la vista
        return view('admin.informes.asignaturaXOfertar');
    }

    //
    public function alumnosBaja()
    {
        //retornamos a la vista
        return view('admin.informes.alumnosBaja');
    }

    //
    public function alumnosReinscritos()
    {
        //retornamos a la vista
        return view('admin.informes.alumnosReinscritos');
    }
}
