@extends('adminlte::page')

@section('title', 'kardex')

@section('content_header')

 <!--agregamos el boton para descargar kardex-->
 <a href="{{ route('descargarPDF') }}"class="btn btn-success btn-sm float-right">Descargar</a>

    <h1></h1>
@stop

@section('content')
    <p>
        <!DOCTYPE html>
        <html lang="es">
            <head>
                <meta charset="UTF-8">
                <title>kardex</title>
                <style>
                    h1{
                        text-align: center;
                        text-transform: uppercase;
                    }
                </style>
            </head>
            <body>
               <h1>Universidad Politécnica de victoria.<br>kárdex</h1>
               <hr>
               <div class="contenido">
                    <form>
                       <div class="form-group">
                        <label>Alumno:</label><br>
                        <label>Matricula:</label><br>
                        <label>Carrera:</label><br>
                        <label>Plan de Estudios:</label><br>
                        <div class="col-md-10 mx-auto bg-white p-3">
                        <table class="table">
                            <thead class="bg-white text-light">
                                <tr> <!-- ENCABEZADOS DE LAS TABLAS-->
                                    
                                    <th scole="col">matricula </th>
                                    {{-- <th scole="col">Materia</th>
                                    <th scole="col">Calificacion</th>
                                    <th scole="col">Resultado</th>
                                    <th scole="col">Creditos </th>
                                    <th scole="col">Curso </th>
                                    <th scole="col">Periodo </th> --}}
                                </tr>
                            </thead>
                            <tbody>
                              {{-- @foreach($alumno as $alumno)
                              <tr>
                                <td>{{$alumno->matricula}}</td> --}}
                               
                            {{-- </tr> --}}
                        {{-- @endforeach --}}
                                
                            </tbody>
                    </form>
                </div>
            </body>
        </html>
    </p>
@stop

@section('css')
    <link rel="stylesheet" href="/css/admin_custom.css">
@stop

@section('js')
    <script> console.log('Hi!'); </script>
@stop



