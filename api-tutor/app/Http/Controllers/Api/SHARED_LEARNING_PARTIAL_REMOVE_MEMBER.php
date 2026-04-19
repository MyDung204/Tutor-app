
    // Remove Member (Creator Only)
    /// 
    /// **Purpose:**
    /// - Allows creator to remove an approved member from the group
    /// 
    /// **Parameters:**
    /// - `$groupId`: Study group ID
    /// - `$userId`: User ID to remove
    /// 
    /// **Process:**
    /// 1. Validates creator permission
    /// 2. Checks if member exists
    /// 3. Deletes member record
    /// 4. Decrements current_members count
    /// 5. Re-opens group if it was full
    public function removeMember(Request $request, $groupId, $userId)
    {
        $group = StudyGroup::findOrFail($groupId);

        if ($group->creator_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $member = \DB::table('study_group_members')
            ->where('study_group_id', $groupId)
            ->where('user_id', $userId)
            ->first();

        if (!$member) {
            return response()->json(['message' => 'Member not found'], 404);
        }

        // Delete member
        \DB::table('study_group_members')
            ->where('id', $member->id)
            ->delete();

        // Decrement count if they were approved
        if ($member->status === 'approved') {
            $group->decrement('current_members');
            $group->update(['status' => 'open']);
        }

        return response()->json(['message' => 'Đã xóa thành viên khỏi nhóm.']);
    }
