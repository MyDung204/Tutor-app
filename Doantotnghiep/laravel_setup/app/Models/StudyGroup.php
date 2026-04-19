<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class StudyGroup extends Model
{
    use HasFactory;
    protected $fillable = [
        'creator_id', 
        'topic', 
        'subject', 
        'grade_level', 
        'max_members', 
        'current_members', 
        'description', 
        'status',
        'location',  // Khu vực (Online, Hà Nội, TP.HCM, Q.1, v.v.)
        'price',     // Giá mỗi buổi học (VND)
    ];

    public function creator()
    {
        return $this->belongsTo(User::class, 'creator_id');
    }
}
