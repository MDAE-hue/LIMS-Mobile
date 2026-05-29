<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    protected $table = 'laboratory_report';

    protected $fillable = [
        'no_report',
        'requested_by',
        'department_id',
        'location',
        'status_id',
        'date_sampling',
        'date_analysis',
        'remark',
        'sampler',
        'analyst',
        'reviewed_by',
        'acknowledge_by',
        'reviewed_at',
        'acknowledge_at',
        'notes',
        'comment',
        'reason',
    ];

    protected function casts(): array
    {
        return [
            'date_sampling' => 'date:Y-m-d',
            'date_analysis' => 'date:Y-m-d',
            'reviewed_at' => 'datetime',
            'acknowledge_at' => 'datetime',
        ];
    }

    public function requester()
    {
        return $this->belongsTo(User::class, 'requested_by');
    }

    public function department()
    {
        return $this->belongsTo(Department::class, 'department_id');
    }

    public function status()
    {
        return $this->belongsTo(ReportStatus::class, 'status_id');
    }

    public function samplerUser()
    {
        return $this->belongsTo(User::class, 'sampler');
    }

    public function analystUser()
    {
        return $this->belongsTo(User::class, 'analyst');
    }

    public function reviewedBy()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }

    public function acknowledgeBy()
    {
        return $this->belongsTo(User::class, 'acknowledge_by');
    }
}
