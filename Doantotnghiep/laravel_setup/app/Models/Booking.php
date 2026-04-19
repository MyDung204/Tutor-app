<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    use HasFactory;
    protected $fillable = ['tutor_id', 'student_id', 'start_time', 'end_time', 'status', 'total_price', 'notes'];

    protected $casts = [
        'start_time' => 'datetime',
        'end_time' => 'datetime',
        'total_price' => 'decimal:2',
    ];

    protected $appends = ['date', 'time_slot', 'app_status'];

    public function getAppStatusAttribute()
    {
        // Map DB status to Frontend expected status
        switch ($this->status) {
            case 'pending':
                return 'Locked';
            case 'confirmed':
                return 'Upcoming';
            case 'cancelled':
                return 'Cancelled';
            case 'completed':
                return 'Completed';
            default:
                return $this->status;
        }
    }

    // Override toArray to use app_status as status
    public function toArray()
    {
        $array = parent::toArray();
        $array['status'] = $this->app_status;
        return $array;
    }

    public function getDateAttribute()
    {
        return $this->start_time ? $this->start_time->format('Y-m-d') : null;
    }

    public function getTimeSlotAttribute()
    {
        if ($this->start_time && $this->end_time) {
            return $this->start_time->format('H:i') . ' - ' . $this->end_time->format('H:i');
        }
        return '';
    }

    public function tutor()
    {
        return $this->belongsTo(Tutor::class);
    }

    public function student()
    {
        return $this->belongsTo(User::class, 'student_id');
    }

    public function review()
    {
        return $this->hasOne(Review::class);
    }
}
