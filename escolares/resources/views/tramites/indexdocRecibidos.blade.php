@extends('adminlte::page')

@section('title', 'Documentos Recibidos') 
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


    

@stop

@section('css')
    <link rel="stylesheet" href="/css/admin_custom.css">
@stop

@section('js')
    <script> console.log('Hi!'); </script>
@stop
