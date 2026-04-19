$ErrorActionPreference = "Stop"

Write-Host ">>> Đang thiết lập API mới tại D:\api-tutor..." -ForegroundColor Cyan

# 1. Kiểm tra và Tạo Project Laravel
if (-not (Test-Path "D:\api-tutor")) {
    Write-Host ">>> Đang tạo Project Laravel (có thể mất vài phút)..." -ForegroundColor Yellow
    cd D:\
    composer create-project laravel/laravel api-tutor
} else {
    Write-Host ">>> Thư mục D:\api-tutor đã tồn tại. Sẽ ghi đè file code..." -ForegroundColor Yellow
}

cd D:\api-tutor

# 2. Tạo Models
Write-Host ">>> Đang tạo Models..." -ForegroundColor Green
$models = @("Tutor", "Question", "Answer", "Booking")
foreach ($m in $models) {
    if (-not (Test-Path "app/Models/$m.php")) {
        # Create empty file first to ensure path exists (though Models dir usually exists)
        New-Item -ItemType File -Path "app/Models/$m.php" -Force | Out-Null
    }
}

# --- WRITE CONTENT: Tutor.php ---
Set-Content -Path "app/Models/Tutor.php" -Value @'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Tutor extends Model {
    use HasFactory;
    protected $fillable = ['name', 'avatar_url', 'bio', 'hourly_rate', 'rating', 'review_count', 'location', 'address', 'gender', 'is_verified', 'subjects', 'teaching_mode', 'weekly_schedule'];
    protected $casts = ['subjects' => 'array', 'teaching_mode' => 'array', 'weekly_schedule' => 'array', 'is_verified' => 'boolean'];
}
'@

# --- WRITE CONTENT: Question.php ---
Set-Content -Path "app/Models/Question.php" -Value @'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Question extends Model {
    use HasFactory;
    protected $fillable = ['user_id', 'user_name', 'user_avatar', 'subject', 'content', 'image_url', 'like_count', 'answer_count', 'is_solved'];
    public function answers() { return $this->hasMany(Answer::class); }
}
'@

# --- WRITE CONTENT: Answer.php ---
Set-Content -Path "app/Models/Answer.php" -Value @'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Answer extends Model {
    use HasFactory;
    protected $fillable = ['question_id', 'user_id', 'user_name', 'user_avatar', 'content', 'is_accepted', 'like_count'];
}
'@

# --- WRITE CONTENT: Booking.php ---
Set-Content -Path "app/Models/Booking.php" -Value @'
<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
class Booking extends Model {
    use HasFactory;
    protected $fillable = ['tutor_id', 'user_id', 'date', 'time_slot', 'price', 'status', 'locked_until'];
    protected $with = ['tutor'];
    public function tutor() { return $this->belongsTo(Tutor::class); }
}
'@

# 3. Tạo Controllers
Write-Host ">>> Đang tạo Controllers..." -ForegroundColor Green
New-Item -ItemType Directory -Path "app/Http/Controllers/Api" -Force | Out-Null

# --- WRITE CONTENT: TutorController.php ---
Set-Content -Path "app/Http/Controllers/Api/TutorController.php" -Value @'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Tutor;
use Illuminate\Http\Request;

class TutorController extends Controller {
    public function index(Request $request) {
        $query = Tutor::query();
        if ($request->has('featured') && $request->featured == 1) return $query->where('rating', '>=', 4.5)->limit(5)->get();
        if ($request->has('search') && $request->search != null) {
            $search = $request->search;
            $query->where(function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")->orWhere('subjects', 'like', "%{$search}%");
            });
        }
        return $query->get();
    }
    public function show($id) { return Tutor::find($id); }
}
'@

# --- WRITE CONTENT: QuestionController.php ---
Set-Content -Path "app/Http/Controllers/Api/QuestionController.php" -Value @'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Question;
use App\Models\Answer;
use Illuminate\Http\Request;

class QuestionController extends Controller {
    public function index() { return Question::with('answers')->latest()->get(); }
    public function store(Request $request) {
        $question = Question::create($request->all());
        return response()->json($question, 201);
    }
    public function storeAnswer(Request $request, $id) {
        $request->merge(['question_id' => $id]);
        $answer = Answer::create($request->all());
        Question::find($id)->increment('answer_count');
        return response()->json($answer, 201);
    }
}
'@

# --- WRITE CONTENT: BookingController.php ---
Set-Content -Path "app/Http/Controllers/Api/BookingController.php" -Value @'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Booking;
use Illuminate\Http\Request;
use Carbon\Carbon;

class BookingController extends Controller {
    public function index() { return Booking::latest()->get(); }
    public function lockSlot(Request $request) {
        $exists = Booking::where('tutor_id', $request->tutor_id)
            ->where('date', $request->date)->where('time_slot', $request->time_slot)
            ->where(function($q) {
                $q->where('status', 'Upcoming')
                  ->orWhere(function($sub) { $sub->where('status', 'Locked')->where('locked_until', '>', Carbon::now()); });
            })->exists();
        if ($exists) return response()->json(['message' => 'Slot already taken'], 409);
        
        $booking = Booking::create(array_merge($request->all(), [
            'status' => 'Locked', 'locked_until' => Carbon::now()->addMinutes(10)
        ]));
        return response()->json($booking, 201);
    }
    public function confirm($id) {
        Booking::find($id)->update(['status' => 'Upcoming', 'locked_until' => null]);
        return response()->json(['success' => true]);
    }
}
'@

# --- WRITE CONTENT: AuthController.php ---
Set-Content -Path "app/Http/Controllers/Api/AuthController.php" -Value @'
<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller {
    public function register(Request $request) {
        $user = User::create([
            'name' => $request->name, 'email' => $request->email, 'password' => Hash::make($request->password)
        ]);
        return response()->json(['token' => $user->createToken('auth')->plainTextToken, 'user' => $user]);
    }
    public function login(Request $request) {
        if (!Auth::attempt($request->only('email', 'password'))) return response()->json(['message' => 'Invalid'], 401);
        $user = User::where('email', $request->email)->first();
        return response()->json(['token' => $user->createToken('auth')->plainTextToken, 'user' => $user]);
    }
    public function me(Request $request) { return $request->user(); }
}
'@

# 4. Tạo Routes
Write-Host ">>> Đang cấu hình Routes..." -ForegroundColor Green
Set-Content -Path "routes/api.php" -Value @'
<?php
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TutorController;
use App\Http\Controllers\Api\QuestionController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\AuthController;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::middleware('auth:sanctum')->get('/user', [AuthController::class, 'me']);

Route::get('/tutors', [TutorController::class, 'index']);
Route::get('/tutors/{id}', [TutorController::class, 'show']);
Route::get('/questions', [QuestionController::class, 'index']);
Route::post('/questions', [QuestionController::class, 'store']);
Route::post('/questions/{id}/answers', [QuestionController::class, 'storeAnswer']);
Route::get('/bookings', [BookingController::class, 'index']);
Route::post('/bookings/lock', [BookingController::class, 'lockSlot']);
Route::post('/bookings/{id}/confirm', [BookingController::class, 'confirm']);
'@

# 5. Tạo Migrations
Write-Host ">>> Đang tạo Migrations..." -ForegroundColor Green
$migPath = "database/migrations"
# Xóa bớt file cũ để tránh duplicate
# Remove-Item "$migPath/*create_tutors_table.php" -ErrorAction SilentlyContinue

# New Migration filenames (timestamped to ensure they run)
Set-Content -Path "$migPath/2024_01_01_000001_create_tutors_table.php" -Value @'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('tutors', function (Blueprint $table) {
            $table->id(); $table->string('name'); $table->string('avatar_url')->nullable(); 
            $table->text('bio')->nullable(); $table->double('hourly_rate'); 
            $table->double('rating')->default(0); $table->integer('review_count')->default(0);
            $table->string('location'); $table->string('address')->nullable(); 
            $table->string('gender')->nullable(); $table->boolean('is_verified')->default(false);
            $table->json('subjects'); $table->json('teaching_mode'); $table->json('weekly_schedule')->nullable();
            $table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('tutors'); }
};
'@

Set-Content -Path "$migPath/2024_01_01_000002_create_community_tables.php" -Value @'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('questions', function (Blueprint $table) {
            $table->id(); $table->string('user_id'); $table->string('user_name')->nullable(); $table->string('user_avatar')->nullable();
            $table->string('subject'); $table->text('content'); $table->string('image_url')->nullable();
            $table->integer('like_count')->default(0); $table->integer('answer_count')->default(0); $table->boolean('is_solved')->default(false);
            $table->timestamps();
        });
        Schema::create('answers', function (Blueprint $table) {
            $table->id(); $table->foreignId('question_id')->constrained()->onDelete('cascade');
            $table->string('user_id'); $table->string('user_name')->nullable(); $table->string('user_avatar')->nullable();
            $table->text('content'); $table->boolean('is_accepted')->default(false); $table->integer('like_count')->default(0);
            $table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('answers'); Schema::dropIfExists('questions'); }
};
'@

Set-Content -Path "$migPath/2024_01_01_000003_create_bookings_table.php" -Value @'
<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up() {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id(); $table->foreignId('tutor_id')->constrained()->onDelete('cascade');
            $table->string('user_id'); $table->dateTime('date'); $table->string('time_slot'); 
            $table->double('price'); $table->string('status')->default('Upcoming'); $table->dateTime('locked_until')->nullable();
            $table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('bookings'); }
};
'@

# 6. Tạo Seeders
Write-Host ">>> Đang tạo Seeders..." -ForegroundColor Green
Set-Content -Path "database/seeders/TutorSeeder.php" -Value @'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
use App\Models\Tutor;
class TutorSeeder extends Seeder {
    public function run() {
        Tutor::create([ 'name' => 'Nguyễn Văn Hùng', 'avatar_url' => 'https://i.pravatar.cc/150?u=1', 'hourly_rate' => 200000, 'rating' => 4.8, 'review_count' => 120, 'location' => 'Hà Nội', 'address' => 'Cầu Giấy', 'is_verified' => true, 'subjects' => ['Toán', 'Lý'], 'teaching_mode' => ['Online', 'Offline'], 'weekly_schedule' => ['2' => ['08:00 - 10:00']] ]);
        Tutor::create([ 'name' => 'Trần Thị Mai', 'avatar_url' => 'https://i.pravatar.cc/150?u=2', 'hourly_rate' => 150000, 'rating' => 4.5, 'review_count' => 45, 'location' => 'Hồ Chí Minh', 'subjects' => ['Anh', 'Văn'], 'teaching_mode' => ['Online'], 'weekly_schedule' => ['3' => ['18:00 - 20:00']] ]);
        for ($i=3; $i<=10; $i++) Tutor::create([ 'name' => "Gia sư $i", 'avatar_url' => "https://i.pravatar.cc/150?u=$i", 'hourly_rate' => 100000, 'rating' => 4.0, 'location' => 'Online', 'subjects' => ['Toán'], 'teaching_mode' => ['Online'] ]);
    }
}
'@

Set-Content -Path "database/seeders/DatabaseSeeder.php" -Value @'
<?php
namespace Database\Seeders;
use Illuminate\Database\Seeder;
class DatabaseSeeder extends Seeder {
    public function run() {
        $this->call([TutorSeeder::class]);
    }
}
'@

# 7. Chạy Migration & Seed (Tự động luôn!)
Write-Host ">>> Đang chạy Database Migration & Seeding..." -ForegroundColor Magenta
# Try catch SQL errors
try {
    # Ensure .env exists (copy example if needed)
    if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env" }
    # Touch database (sqlite) if using sqlite, else assume mysql config is default
    # For user ease, let's just run it. If it fails, they see output.
    php artisan migrate:fresh --seed
} catch {
    Write-Host "!!! Lỗi Migration: $_" -ForegroundColor Red
}

Write-Host "---------------------------------------------------------" -ForegroundColor Cyan
Write-Host ">>> CÀI ĐẶT HOÀN TẤT! CLOUD ĐÃ ĐƯỢC TẠO TẠI D:\api-tutor <<<" -ForegroundColor Cyan
Write-Host "---------------------------------------------------------" -ForegroundColor Cyan
Write-Host "Để chạy Server, hãy dùng lệnh sau:" -ForegroundColor Yellow
Write-Host "php artisan serve --host 0.0.0.0" -ForegroundColor White
Write-Host "---------------------------------------------------------" -ForegroundColor Cyan
