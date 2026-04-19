<?php
namespace App\Http\Controllers\Api;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use App\Models\User;
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

                return [
                    'id' => $conv->id,
                    'last_message' => $conv->last_message,
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
    public function show($id)
    {
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
            'content' => 'required|string'
        ]);

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

        $message = Message::create([
            'conversation_id' => $conversationId,
            'sender_id' => $senderId,
            'content' => $request->content,
            'is_read' => false
        ]);

        // Update conversation last message
        Conversation::where('id', $conversationId)->update([
            'last_message' => $request->content,
            'updated_at' => now()
        ]);

        return response()->json($message, 201);
    }
}
