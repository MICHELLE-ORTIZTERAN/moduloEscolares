@extends('adminlte::page')

@section('title', 'Historial') 
@section('content_header')
 <a href="{{ route('descargarPDF') }}"class="btn btn-success btn-sm float-right">Descargar</a>

 <nav class="navbar navbar-light float-left">
    <form class="form-inline">
  
      <input name="buscarpor" class="form-control mr-sm-2" type="search" placeholder="Buscar por matricula" aria-label="Search">
  
         <button class="btn btn-outline-success my-2 my-sm-0" type="submit">Buscar</button>
         <div class="form-check">
          <input class="form-check-input" type="checkbox" value="" id="defaultCheck1">
          <label class="form-check-label" for="defaultCheck1">
            Con formato
          </label>
        </div>
    </form>
    
  </nav>
@stop

@section('content') 
<p>
  <!DOCTYPE html>
  <html lang="es">
    <head>
      <meta charset="UTF-8">
      <style>
        h1{
          text-align: center;
          text-transform: uppercase;
          }
      </style>
    </head>
    <body>
      <h2>Universidad Politécnica de victoria.</h2>
      <h3>Historial Academico</h3>
        <div class="contenido">
          <form>
            <div class="form-row">
              <div class="form-group col-md-6">
                  <label for="alumno">Alumno:</label>
                  {{-- <input type="alumno" class="form-control" id="alumno"> --}}
                </div>
                <div class="form-group col-md-6">
                  <label for="fechaimpresion">Fecha de Impresión:</label>
                  {{-- <input type="fechaimpresion" class="form-control" id="fechaimpresion"> --}}
                </div>
                <div class="form-group col-md-6">
                  <label for="matricula">Matricula</label>
                  {{-- <input type="matricula" class="form-control" id="matricula"> --}}
                </div>
                <div class="form-group">
                  <label for="carrera">Carrera:</label>
                  {{-- <input type="text" class="form-control" id="inputAddress" placeholder="1234 Main St"> --}}
                </div>
                <div class="col-6">
                  <label for="planestudio">Plan de Estudios:</label>
                  {{-- <input type="text" class="form-control" placeholder="City"> --}}
                </div>
                <div class="col">
                  <label for="modalidad">Modalidad:</label>
                  {{-- <input type="text" class="form-control" placeholder="State"> --}}
              </div>
              <div class="col-6">
                <label for="promedio">Promedio General:</label>
                {{-- <input type="text" class="form-control" placeholder="City"> --}}
              </div>
              <div class="col">
                <label for="creditos">Creditos:</label>
                {{-- <input type="text" class="form-control" placeholder="State"> --}}
              </div>
              </div>
          </form>
      </div>
      <div class="col-md-10 mx-auto  p-3">
            <table class="table float-right">
              <thead class="thead-light">
                <tr>
                  <th scope="col"></th>
                  <th scope="col">calificacion</th>
                  <th scope="col">resultado</th>
                  <th scope="col">curso</th>
                  <th scope="col">creditos</th>
                  <th scope="col">modalidad</th>
                </tr>
              </thead>
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
