<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class escolaresalumno extends Model
{
    use HasFactory;
    //referenciamos ala tabla
    protected $table = "escolaresalumno";


    public function persona()
    {
      return $this->belongsTo('App\Models\personapersona', 'idpersona', 'idpersona');
    }

    public function planestudios()
    {
      return $this->belongsTo('App\Models\escolaresplanestudio', 'idplanestudios', 'idplan_estudios');
    }




    
}
