<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Answer extends Model
{
    use HasFactory;
    protected $fillable = ['question_id', 'user_id', 'user_name', 'user_avatar', 'content', 'is_accepted', 'like_count'];
}
