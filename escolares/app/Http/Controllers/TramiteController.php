<?php

namespace App\Http\Controllers;

use App\Models\escolaresalumno;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\Console\Input\Input;

class TramiteController extends Controller
{
    
    public function indexkardex(Request $request)
    {
         $matricula = $request->get('buscarpor');//creamos la variable con el valor que se esta buscando
         $alumno = escolaresalumno::where('matricula','like',"%$matricula%");
         return view('tramites.indexkardex', compact('alumno',));
    }

    public function mostrarkardex()
    {

    //    $datos = escolaresalumno::all()->toArray();
    //    $alumnos=
    //    return view('tramites.indexpruebakardex')->with('alumno', $alumno);
    }

    

    

    public function certificado()
    {
        //
        return view('tramites.indexcertificado');
    }

    public function constanciaEstudios()
    {
        //
        return view('tramites.indexconstancia');
    }

    public function formatoRegistro()
    {
        //
        return view('tramites.indexregistro');
    }

    public function historialAcademico()
    {
        //retornamos a la vista
        return view('tramites.indexhistorialuno');
    }

    public function docRecibidos()
    {
        //retornamos a la vista
        return view('tramites.indexdocRecibidos');
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


}
