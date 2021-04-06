<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class personapersona extends Model
{
    use HasFactory;
    protected $table = "personapersona";

    public function alumno()
    {
      return $this->hasOne('App\Models\escolaresalumno');
    }

}
