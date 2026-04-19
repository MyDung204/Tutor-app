<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Answer extends Model
{
    use HasFactory;
    protected $fillable = ['question_id', 'user_id', 'content', 'is_ai_generated', 'upvotes'];

    protected $casts = [
        'is_ai_generated' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function question()
    {
        return $this->belongsTo(Question::class);
    }
}
