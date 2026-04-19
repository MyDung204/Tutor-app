<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Badge extends Model
{
    protected $fillable = ['name', 'slug', 'icon_url', 'description', 'color_hex'];

    public function users()
    {
        return $this->belongsToMany(User::class, 'tutor_badges')->withPivot('awarded_at');
    }
}
