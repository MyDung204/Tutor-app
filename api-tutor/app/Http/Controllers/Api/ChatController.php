<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
use App\Models\Course;
use App\Models\Tutor;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;

class ChatController extends Controller
{
    // Get list of conversations for current user
    public function index(Request $request)
    {
        $userId = $request->user()->id;

        $conversations = Conversation::where('user1_id', $userId)
            ->orWhere('user2_id', $userId)
            ->with(['user1', 'user2'])
            ->latest('updated_at')
            ->get()
            ->map(function ($conv) use ($userId) {
                // Determine partner
                $partner = $conv->user1_id == $userId ? $conv->user2 : $conv->user1;

                // Get last sender id
                $lastMsg = Message::where('conversation_id', $conv->id)->latest('created_at')->first();
                $lastSenderId = $lastMsg ? $lastMsg->sender_id : 0;

                return [
                    'id' => $conv->id,
                    'last_message' => $conv->last_message,
                    'last_sender_id' => $lastSenderId, // For Frontend logic
                    'updated_at' => $conv->updated_at,
                    'unread_count' => 0, // Implement real count if needed
                    'partner' => [
                        'id' => $partner->id,
                        'name' => $partner->name,
                        'avatar_url' => $partner->avatar_url ?? 'https://ui-avatars.com/api/?name=' . urlencode($partner->name),
                    ]
                ];
            });

        return response()->json($conversations);
    }

    // Get messages of a conversation
    public function show(Request $request, $id)
    {
        $userId = $request->user()->id;

        // Mark messages from partner as read
        Message::where('conversation_id', $id)
            ->where('sender_id', '!=', $userId)
            ->where('is_read', false)
            ->update(['is_read' => true]);

        // $id is conversation_id
        $messages = Message::where('conversation_id', $id)->orderBy('created_at', 'asc')->get();
        return response()->json($messages);
    }

    // Send a message
    public function store(Request $request)
    {
        $request->validate([
            'conversation_id' => 'nullable|exists:conversations,id',
            'receiver_id' => 'required_without:conversation_id|exists:users,id',
            'content' => 'nullable|string',
            'attachment' => 'nullable|file|max:10240' // Max 10MB
        ]);

        if (!$request->content && !$request->hasFile('attachment')) {
            return response()->json(['message' => 'Message content or attachment is required'], 422);
        }

        $senderId = $request->user()->id;
        $conversationId = $request->conversation_id;

        // If no conversation_id, find or create one
        if (!$conversationId) {
            $user1 = min($senderId, $request->receiver_id);
            $user2 = max($senderId, $request->receiver_id);

            $conv = Conversation::where('user1_id', $user1)->where('user2_id', $user2)->first();
            if (!$conv) {
                $conv = Conversation::create([
                    'user1_id' => $user1,
                    'user2_id' => $user2,
                    'last_message' => ''
                ]);
            }
            $conversationId = $conv->id;
        }

        $type = 'text';
        $attachmentUrl = null;
        $attachmentName = null;

        if ($request->hasFile('attachment')) {
            $file = $request->file('attachment');
            $attachmentName = $file->getClientOriginalName();
            $path = $file->store('chat_attachments', 'public');
            $attachmentUrl = asset('storage/' . $path);
            
            // Determine type
            $mime = $file->getMimeType();
            if (str_starts_with($mime, 'image/')) {
                $type = 'image';
            } else {
                $type = 'file';
            }
        }

        $message = Message::create([
            'conversation_id' => $conversationId,
            'sender_id' => $senderId,
            'content' => $request->content ?? '',
            'is_read' => false,
            'type' => $type,
            'attachment_url' => $attachmentUrl,
            'attachment_name' => $attachmentName
        ]);

        // Update conversation last message
        $lastMsgText = $request->content;
        if ($type === 'image') {
            $lastMsgText = '[Hình ảnh] ' . ($request->content ?? '');
        } elseif ($type === 'file') {
            $lastMsgText = '[Tệp tin] ' . ($request->content ?? '');
        }

        Conversation::where('id', $conversationId)->update([
            'last_message' => $lastMsgText,
            'updated_at' => now()
        ]);

        return response()->json($message, 201);
    }
    public function upload(Request $request) {
        $request->validate([
            'attachment' => 'required|file|max:10240'
        ]);

        $file = $request->file('attachment');
        $path = $file->store('chat_attachments', 'public');
        $url = asset('storage/' . $path);

        return response()->json(['url' => $url]);
    }

    // Accept Course Offer
    public function acceptOffer(Request $request) {
        $request->validate([
            'tutor_id' => 'required', // The ID of the tutor model (not necessarily user id, or maybe user id?)
            // We need to check what tutor_id from frontend means.
            'subject' => 'required|string',
            'schedule' => 'required|string',
            'price' => 'required|numeric',
        ]);

        $student = $request->user();

        // Normally, the frontend passes tutor_user_id or tutor_profile_id. 
        // Let's assume frontend's tutorId in CourseOffer is the Tutor's DB ID, but let's check it defensively.
        if (is_numeric($request->tutor_id)) {
            $tutor = Tutor::find($request->tutor_id);
            if (!$tutor) {
                 // Try finding by user_id
                 $tutor = Tutor::where('user_id', $request->tutor_id)->first();
            }
        } else {
             $tutor = Tutor::where('user_id', $request->tutor_id)->first();
        }

        if (!$tutor) {
            return response()->json(['message' => 'Tutor not found'], 404);
        }

        DB::beginTransaction();
        try {
            // Create a 1-1 Course
            $course = Course::create([
                'tutor_id' => $tutor->id,
                'title' => "Lớp 1-1: " . $request->subject,
                'subject' => $request->subject,
                'grade_level' => 'Theo thỏa thuận',
                'description' => 'Lớp học 1-1 được tạo tự động từ Đề xuất trong khung Chat.',
                'price' => $request->price,
                'max_students' => 1,
                'schedule' => $request->schedule,
                'mode' => 'Online', // Default
                'start_date' => now(), 
                'status' => 'ongoing' // It starts immediately
            ]);

            // Add student to the course with trial status
            DB::table('course_students')->insert([
                'course_id' => $course->id,
                'user_id' => $student->id,
                'status' => 'approved',
                'payment_status' => 'trial',
                'next_payment_due' => now()->addDays(7), // 7 days trial
                'enrolled_at' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            DB::commit();

            // Send notification to Tutor
            try {
                $notificationService = app(\App\Services\FirebaseNotificationService::class);
                $notificationService->sendToUser(
                    $tutor->user_id,
                    'Đề xuất đã được duyệt!',
                    "Học viên {$student->name} đã chấp nhận đề xuất khóa học {$request->subject}. Lớp học 1-1 đã được hệ thống tự động khởi tạo.",
                    'offer_accepted',
                    ['course_id' => $course->id]
                );
            } catch (\Exception $e) {
                 \Log::error("Failed to notify tutor on acceptOffer: " . $e->getMessage());
            }

            return response()->json(['message' => 'Lớp học đã được tạo thành công.', 'course' => $course], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            return response()->json(['message' => 'Lỗi khi tạo lớp học: ' . $e->getMessage()], 500);
        }
    }
}
