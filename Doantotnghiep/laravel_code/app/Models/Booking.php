<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    use HasFactory;

    protected $fillable = [
        'tutor_id',
        'user_id',
        'date',
        'time_slot',
        'price',
        'status',
        'locked_until'
    ];

    // Auto-load relationship to get Tutor info
    protected $with = ['tutor'];

    public function tutor()
    {
        return $this->belongsTo(Tutor::class);
    }
}
