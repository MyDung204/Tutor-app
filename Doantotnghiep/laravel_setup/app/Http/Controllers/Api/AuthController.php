<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Tutor;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role ?? 'student'
        ]);

        if ($user->role === 'tutor') {
            Tutor::create([
                'user_id' => $user->id,
                'name' => $user->name,
                'hourly_rate' => 0,
                'rating' => 0,
                'subjects' => [],
                'teaching_mode' => [],
                'location' => '',
                'is_verified' => false
            ]);
        }

        return response()->json(['token' => $user->createToken('auth')->plainTextToken, 'user' => $user]);
    }
    public function login(Request $request)
    {
        if (!Auth::attempt($request->only('email', 'password')))
            return response()->json(['message' => 'Invalid'], 401);
        $user = User::where('email', $request->email)->first();
        return response()->json(['token' => $user->createToken('auth')->plainTextToken, 'user' => $user]);
    }
    public function me(Request $request)
    {
        return $request->user();
    }
    public function changePassword(Request $request)
    {
        $request->validate([
            'current_password' => 'required',
            'new_password' => 'required|min:6|confirmed'
        ]);

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json(['message' => 'Mật khẩu hiện tại không đúng'], 400);
        }

        $user->update(['password' => Hash::make($request->new_password)]);

        return response()->json(['message' => 'Đổi mật khẩu thành công']);
    }
}
