<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    use HasFactory;
    protected $fillable = ['title', 'description', 'severity', 'type'];
    // severity: 'info', 'warning', 'danger', 'success'
    // type: 'scan_log', 'alert'
}
