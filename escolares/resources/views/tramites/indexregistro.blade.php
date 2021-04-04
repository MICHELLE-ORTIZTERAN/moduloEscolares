@extends('adminlte::page')

@section('title', 'Registro') 
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
<legend></legend>
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
      <h3>Formato de Registro</h3>
        <div class="contenido">
          <legend>Datos de Ingreso</legend>
          <img src="..." class="rounded float-right" alt="...">
          <table class="table table-sm">
            <form>
              <div class="form-row">
                <div class="form-group col-md-6">
                  <label for="">Programa Academico:</label>
                  {{-- <input type="email" class="form-control" id="inputEmail4" placeholder="Email"> --}}
                </div>
              </div>
              <div class="form-group">
                <label for="">Periodo de Ingreso:</label>
                {{-- <input type="text" class="form-control" id="inputAddress" placeholder="1234 Main St"> --}}
              </div>
              <div class="form-row">
                <div class="form-group col-md-6">
                  <label for="">Sede:</label>
                  {{-- <input type="text" class="form-control" id="inputCity"> --}}
                </div>
                <div class="form-group col-md-4">
                  <label for="">Matricula</label>
                </div>
                <div class="form-group col-md-2">
                  <label for="">Generacion:</label>
                  {{-- <input type="text" class="form-control" id="inputZip"> --}}
                </div>
              </div>
            </form>
            <form class="needs-validation" novalidate>
              <div class="form-row">
                <div class="col-md-4 mb-3">
                  <label for="validationCustom01">First name</label>
                  <input type="text" class="form-control" id="validationCustom01" placeholder="First name" value="Mark" required>
                  <div class="valid-feedback">
                    Looks good!
                  </div>
                </div>
                <div class="col-md-4 mb-3">
                  <label for="validationCustom02">Last name</label>
                  <input type="text" class="form-control" id="validationCustom02" placeholder="Last name" value="Otto" required>
                  <div class="valid-feedback">
                    Looks good!
                  </div>
                </div>
                <div class="col-md-4 mb-3">
                  <label for="validationCustomUsername">Username</label>
                  <div class="input-group">
                    <div class="input-group-prepend">
                      <span class="input-group-text" id="inputGroupPrepend">@</span>
                    </div>
                    <input type="text" class="form-control" id="validationCustomUsername" placeholder="Username" aria-describedby="inputGroupPrepend" required>
                    <div class="invalid-feedback">
                      Please choose a username.
                    </div>
                  </div>
                </div>
              </div>
              <div class="form-row">
                <div class="col-md-6 mb-3">
                  <label for="validationCustom03">City</label>
                  <input type="text" class="form-control" id="validationCustom03" placeholder="City" required>
                  <div class="invalid-feedback">
                    Please provide a valid city.
                  </div>
                </div>
                <div class="col-md-3 mb-3">
                  <label for="validationCustom04">State</label>
                  <input type="text" class="form-control" id="validationCustom04" placeholder="State" required>
                  <div class="invalid-feedback">
                    Please provide a valid state.
                  </div>
                </div>
              </div>
            </form>
          
          </table>
          
        </div>
    </body>
  </html>

    

@stop

@section('css')
    <link rel="stylesheet" href="/css/admin_custom.css">
@stop

@section('js')
    <script> console.log('Hi!'); </script>
@stop
