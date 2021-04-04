@extends('adminlte::page')

@section('title', 'Kardex')

@section('content_header')
 <a href="{{ route('descargarPDF') }}"class="btn btn-success btn-sm float-right">Descargar</a>

 <nav class="navbar navbar-light float-left">
    <form class="form-inline">
  
      <input name="buscarpor" class="form-control mr-sm-2" type="search" placeholder="Buscar por matricula" aria-label="Search">
  
         <button class="btn btn-outline-success my-2 my-sm-0" type="submit">Buscar</button>
    </form>
  </nav>
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
               <h2>Universidad Politécnica de victoria.</h2>
               <h3>kardex</h3>
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
                                     <th scole="col">Materia</th>
                                    <th scole="col">Calificacion</th>
                                    <th scole="col">Resultado</th>
                                    <th scole="col">Creditos </th> 
                                    <th scole="col">Curso </th>
                                    <th scole="col">Periodo </th>  
                                </tr>
                            </thead>
                            <tbody>
                               @foreach($alumno as $i)
                              <tr>
                                <td>{{$i['matricula']}}</td> 
                                <td>{{$i['idplanestudios']}}</td> 
                               
                            </tr>
                         @endforeach 
                                
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

