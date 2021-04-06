<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class escolaresplanestudio extends Model
{
    use HasFactory;
    protected $table = "escolaresplan_estudios";

    public function alumno()
    {
      return $this->hasMany('App\Models\escolaresalumno');
    }

    public function carrera()
    {
      return $this->belongsTo('App\Models\escolarescarrera', 'idcarrera','idcarrera');
    }

}
