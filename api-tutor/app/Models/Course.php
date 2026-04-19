<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Course Model - Lớp học do Gia sư tạo
 * 
 * **Purpose:**
 * - Quản lý thông tin lớp học (title, description, price, schedule)
 * - Liên kết với tutor (gia sư tạo lớp)
 * - Quản lý học viên đăng ký qua bảng course_students
 * 
 * **Relationships:**
 * - belongsTo Tutor: Gia sư tạo lớp
 * - hasMany CourseStudents: Danh sách học viên đăng ký
 */
class Course extends Model
{
    use HasFactory;

    protected $fillable = [
        'tutor_id',
        'title',
        'subject',
        'grade_level',
        'description',
        'price',
        'max_students',
        'start_date',
        'schedule',
        'mode',
        'address',
        'status'
    ];

    protected $casts = [
        'start_date' => 'date',
        'price' => 'decimal:2',
    ];

    /**
     * Relationship: Course thuộc về một Tutor
     * 
     * **Returns:**
     * - BelongsTo relationship với Tutor model
     */
    public function tutor()
    {
        return $this->belongsTo(Tutor::class);
    }

    /**
     * Relationship: Course có nhiều học viên đăng ký
     * 
     * **Returns:**
     * - BelongsToMany relationship với User model thông qua bảng course_students
     */
    public function students()
    {
        // Có thể tạo CourseStudent model nếu cần
        // Hiện tại sử dụng DB::table() trực tiếp
        return null; // Placeholder
    }

    /**
     * Relationship: Course có nhiều thông báo
     */
    public function announcements()
    {
        return $this->hasMany(Announcement::class)->latest();
    }
}
