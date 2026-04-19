<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Tutor extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'avatar_url',
        'bio',
        'hourly_rate',
        'rating',
        'review_count',
        'location',
        'address',
        'gender',
        'is_verified',
        'subjects',
        'teaching_mode',
        'weekly_schedule'
    ];

    protected $casts = [
        'subjects' => 'array',
        'teaching_mode' => 'array',
        'weekly_schedule' => 'array',
        'is_verified' => 'boolean',
    ];
}
