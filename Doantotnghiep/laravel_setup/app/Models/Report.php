<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    use HasFactory;
    protected $fillable = ['reporter_id', 'reporter_name', 'target_id', 'target_name', 'reason', 'description', 'status', 'type'];
    // Status: 'pending', 'resolved', 'dismissed'
    // Type: 'tutor_report', 'student_report', 'system_issue'
}
