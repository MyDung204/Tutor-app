<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Question extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'user_name',
        'user_avatar',
        'subject',
        'content',
        'image_url',
        'like_count',
        'answer_count',
        'is_solved'
    ];

    public function answers()
    {
        return $this->hasMany(Answer::class);
    }
}
