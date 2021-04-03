@extends('adminlte::page')

@section('title', 'Control Escolar') 


@section('content') 

   <!-- empezamos campo para mostrar la vista de bajas--> 

    
    <!--agregamos el campo para mostrar todo el contenido-->
    <article class="contenido-bajaalumno">
        <!--agregamos el campo para mostrar el titulo de la receta-->
         <h1 class="text-center mb-4"> Constancia</h1>             
            
    </article>

@stop

@section('css')
    <link rel="stylesheet" href="/css/admin_custom.css">
@stop

@section('js')
    <script> console.log('Hi!'); </script>
@stop
