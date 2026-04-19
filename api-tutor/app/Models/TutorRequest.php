<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TutorRequest extends Model
{
    use HasFactory;
    protected $fillable = ['student_id', 'subject', 'grade_level', 'description', 'min_budget', 'max_budget', 'schedule', 'location', 'mode', 'status'];

    protected $casts = [
        'min_budget' => 'decimal:2',
        'max_budget' => 'decimal:2',
    ];

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }
}
