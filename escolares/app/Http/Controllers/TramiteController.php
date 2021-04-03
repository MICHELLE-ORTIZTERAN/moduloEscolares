<?php

namespace App\Http\Controllers;

use App\Models\escolaresalumno;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Symfony\Component\Console\Input\Input;

class TramiteController extends Controller
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


    public function kardex()
    {
    //     $alumno = escolaresalumno::all()->toArray();
    //    dd($alumno);
    //     $alumno = DB::table('escolaresalumno');
        return view('tramites.pruebakardex');
    }

    

    

    public function certificado()
    {
        //
        return view('tramites.certificado');
    }

    public function constanciaEstudios()
    {
        //
        return view('tramites.constancia');
    }

    public function formatoRegistro()
    {
        //
        return view('tramites.registro');
    }

    public function historialAcademico()
    {
        //retornamos a la vista
        return view('tramites.historial');
    }

    public function docRecibidos()
    {
        //retornamos a la vista
        return view('tramites.docRecibidos');
    }

}
