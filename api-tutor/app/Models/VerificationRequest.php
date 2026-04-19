<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VerificationRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'front_image_url',
        'back_image_url',
        'status',
        'note',
    ];

    public function user()
    {
        return $table->belongsTo(User::class);
    }
}
