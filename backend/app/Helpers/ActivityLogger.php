<?php

namespace App\Helpers;

use App\Models\ActivityLog;
use Illuminate\Support\Facades\Auth;

class ActivityLogger
{
    public static function log(string $action, string $table, ?int $recordId, mixed $oldData, mixed $newData, ?string $description = null): void
    {
        ActivityLog::create([
            'user_id' => Auth::id(),
            'action' => $action,
            'table_name' => $table,
            'record_id' => $recordId,
            'old_data' => $oldData,
            'new_data' => $newData,
            'description' => $description,
        ]);
    }
}
