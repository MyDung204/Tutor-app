<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Tutor extends Model
{
    use HasFactory;
    protected $fillable = [
        'user_id', 'name', 'avatar_url', 'bio', 'hourly_rate', 
        'rating', 'review_count', 'location', 'address', 'gender', 
        'is_verified', 'subjects', 'teaching_mode', 'weekly_schedule',
        'university', 'degree', 'phone', 'video_url', 'certificates'
    ];
    protected $casts = ['subjects' => 'array', 'teaching_mode' => 'array', 'weekly_schedule' => 'array', 'is_verified' => 'boolean', 'certificates' => 'array', 'teaching_tags' => 'array'];

    public function availabilities()
    {
        return $this->hasMany(TutorAvailability::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
