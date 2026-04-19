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
        'description', 
        'price', 
        'max_students', 
        'start_date', 
        'schedule', 
        'status',
        'subject',      // Môn học
        'grade_level',  // Cấp độ (Lớp 1, Lớp 12, Đại học, v.v.)
        'mode',         // Hình thức (Online, Offline)
        'address',      // Địa điểm học (nếu Offline)
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
     * Relationship: Course có nhiều CourseStudents (học viên đăng ký)
     * 
     * **Returns:**
     * - HasMany relationship với course_students table
     * 
     * **Note:** Sử dụng DB::table() trực tiếp trong controller
     * thay vì relationship để tránh phức tạp
     */
    public function students()
    {
        // Có thể tạo CourseStudent model nếu cần
        // Hiện tại sử dụng DB::table() trực tiếp
        return null;
    }
}
