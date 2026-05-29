<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ActivityLogger;
use App\Http\Controllers\Controller;
use App\Models\Report;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    private array $relations = [
        'requester',
        'department',
        'status',
        'samplerUser',
        'analystUser',
        'reviewedBy',
        'acknowledgeBy',
    ];

    public function index()
    {
        $reports = Report::with($this->relations)->latest()->get()->each(fn ($report) => $this->attachNames($report));

        return response()->json(['message' => 'Data laporan berhasil diambil.', 'data' => $reports]);
    }

    public function show(int $id)
    {
        $report = Report::with($this->relations)->findOrFail($id);
        $this->attachNames($report);

        return response()->json($report);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'location' => ['required', 'string', 'max:255'],
            'remark' => ['required', 'string', 'max:500'],
            'notes' => ['nullable', 'string', 'max:1000'],
        ]);

        $user = $request->user();
        $report = Report::create([
            'no_report' => $this->generateReportNumber(),
            'requested_by' => $user->id,
            'department_id' => $user->department_id,
            'location' => $validated['location'],
            'remark' => $validated['remark'],
            'notes' => $validated['notes'] ?? null,
            'status_id' => 1,
        ]);

        ActivityLogger::log('CREATE', 'reports', $report->id, null, $report->toArray(), "{$user->name} created report [{$report->id}]");

        return response()->json(['message' => 'Report created successfully', 'report' => $report], 201);
    }

    public function update(Request $request, int $id)
    {
        $validated = $request->validate([
            'location' => ['sometimes', 'required', 'string', 'max:255'],
            'remark' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'status_id' => ['nullable', 'integer', 'exists:report_status,id'],
            'date_sampling' => ['nullable', 'date'],
            'date_analysis' => ['nullable', 'date'],
        ]);

        $report = Report::findOrFail($id);
        $oldData = $report->toArray();
        $report->update($validated);

        ActivityLogger::log('UPDATE', 'reports', $report->id, $oldData, $report->toArray(), $request->user()->name." updated report [{$report->id}]");

        return response()->json(['message' => 'Report updated successfully', 'report' => $report]);
    }

    public function destroyMultiple(Request $request)
    {
        $validated = $request->validate(['ids' => ['required', 'array'], 'ids.*' => ['integer', 'exists:laboratory_report,id']]);
        Report::whereIn('id', $validated['ids'])->delete();

        return response()->json(['message' => 'Reports deleted successfully', 'deleted_ids' => $validated['ids']]);
    }

    public function getTakeActionData(int $id)
    {
        $loginUser = auth()->user();
        $subordinates = User::with(['department', 'roles'])
            ->where('superior', $loginUser->id)
            ->get()
            ->map(fn ($user) => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'npk' => $user->npk,
                'job_title' => $user->job_title,
                'department' => $user->department?->name,
                'roles' => $user->roles->pluck('name')->values(),
            ]);

        return response()->json([
            'report' => Report::with(['requester', 'department', 'status'])->findOrFail($id),
            'subordinates' => $subordinates,
            'login_user' => [
                'id' => $loginUser->id,
                'name' => $loginUser->name,
                'department' => $loginUser->department?->name,
                'roles' => $loginUser->roles->pluck('name')->values(),
            ],
        ]);
    }

    public function takeAction(Request $request, int $id)
    {
        $validated = $request->validate([
            'sampler_id' => ['required', 'exists:users,id'],
            'analyst_id' => ['required', 'exists:users,id'],
            'remark' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $report = Report::findOrFail($id);
        $oldData = $report->toArray();
        $report->update([
            'sampler' => $validated['sampler_id'],
            'analyst' => $validated['analyst_id'],
            'remark' => $validated['remark'] ?? $report->remark,
            'notes' => $validated['notes'] ?? $report->notes,
            'status_id' => 2,
        ]);

        ActivityLogger::log('ACCEPT', 'reports', $report->id, $oldData, $report->toArray(), auth()->user()->name." accepted report [{$report->id}]");

        return response()->json(['message' => 'Report accepted successfully', 'report' => $report->fresh()]);
    }

    public function finalize(int $id)
    {
        $report = Report::findOrFail($id);

        if (! in_array((int) $report->status_id, [2, 4], true)) {
            return response()->json(['message' => 'Report belum bisa difinalisasi.'], 400);
        }

        $oldData = $report->toArray();
        $report->update(['status_id' => 3]);
        ActivityLogger::log('FINALIZE', 'reports', $report->id, $oldData, $report->toArray(), auth()->user()->name." finalized report [{$report->id}]");

        return response()->json(['message' => 'Report berhasil difinalisasi.', 'report' => $report]);
    }

    public function review(int $id)
    {
        $report = Report::with($this->relations)->findOrFail($id);
        $this->attachNames($report);

        return response()->json([
            'report' => $report,
            'test_details' => $this->joinedTestDetails($id),
        ]);
    }

    public function submitReview(Request $request, int $id)
    {
        $validated = $request->validate([
            'action' => ['required', 'in:approve,revision'],
            'comment' => ['nullable', 'string'],
        ]);

        $report = Report::findOrFail($id);
        $oldData = $report->toArray();

        if ($validated['action'] === 'approve') {
            $report->fill(['status_id' => 5, 'reviewed_at' => now(), 'reviewed_by' => auth()->id()]);
        } else {
            $report->fill(['status_id' => 4]);
        }

        if (array_key_exists('comment', $validated)) {
            $report->comment = $validated['comment'];
        }

        $report->save();
        ActivityLogger::log(strtoupper($validated['action']), 'reports', $report->id, $oldData, $report->toArray(), auth()->user()->name." reviewed report [{$report->id}]");

        return response()->json(['message' => 'Report reviewed successfully', 'report' => $report->load('reviewedBy', 'acknowledgeBy')]);
    }

    public function approveReport(int $id)
    {
        $user = auth()->user();

        if (! $user->hasRole(['Manager', 'Admin'])) {
            return response()->json(['message' => 'Unauthorized action'], 403);
        }

        $report = Report::findOrFail($id);
        $oldData = $report->toArray();
        $report->update(['status_id' => 6, 'acknowledge_by' => $user->id, 'acknowledge_at' => now()]);
        ActivityLogger::log('APPROVE', 'reports', $report->id, $oldData, $report->toArray(), "{$user->name} closed report [{$report->id}]");

        return response()->json(['message' => 'Report has been closed successfully', 'report' => $report->load('reviewedBy', 'acknowledgeBy')]);
    }

    public function reject(Request $request, int $id)
    {
        $validated = $request->validate([
            'reason' => ['required', 'string', 'max:255'],
            'notes' => ['nullable', 'string'],
            'remark' => ['nullable', 'string'],
        ]);

        $report = Report::findOrFail($id);
        $oldData = $report->toArray();
        $report->update(['status_id' => 7, ...$validated]);
        ActivityLogger::log('REJECT', 'reports', $report->id, $oldData, $report->toArray(), auth()->user()->name." rejected report [{$report->id}]");

        return response()->json(['message' => 'Report rejected successfully', 'report' => $report->fresh()]);
    }

    public function stats()
    {
        return response()->json([
            'total' => Report::count(),
            'requested' => Report::where('status_id', 1)->count(),
            'in_progress' => Report::where('status_id', 2)->count(),
            'pending_review' => Report::where('status_id', 3)->count(),
            'revision' => Report::where('status_id', 4)->count(),
            'pending_acknowledge' => Report::where('status_id', 5)->count(),
            'closed' => Report::where('status_id', 6)->count(),
            'rejected' => Report::where('status_id', 7)->count(),
        ]);
    }

    public function generateCoA(int $id)
    {
        $report = DB::table('laboratory_report as r')
            ->leftJoin('users as u_req', 'r.requested_by', '=', 'u_req.id')
            ->leftJoin('users as u_sam', 'r.sampler', '=', 'u_sam.id')
            ->leftJoin('users as u_ana', 'r.analyst', '=', 'u_ana.id')
            ->leftJoin('users as u_rev', 'r.reviewed_by', '=', 'u_rev.id')
            ->leftJoin('users as u_ack', 'r.acknowledge_by', '=', 'u_ack.id')
            ->leftJoin('departments as d', 'r.department_id', '=', 'd.id')
            ->leftJoin('report_status as s', 'r.status_id', '=', 's.id')
            ->select('r.*', 'u_req.name as requested_by_name', 'u_sam.name as sampler_name', 'u_ana.name as analyst_name', 'u_rev.name as reviewed_by_name', 'u_ack.name as acknowledge_by_name', 'd.name as department_name', 's.name as status_name')
            ->where('r.id', $id)
            ->first();

        abort_if(! $report, 404, 'Report not found');

        if ((int) $report->status_id !== 6) {
            return response()->json(['message' => 'COA hanya tersedia setelah report approved/closed.'], 403);
        }

        $testDetails = $this->joinedTestDetails($id);
        $html = view('coa', compact('report', 'testDetails'))->render();

        if (class_exists(\Dompdf\Dompdf::class)) {
            $dompdf = new \Dompdf\Dompdf();
            $dompdf->loadHtml($html);
            $dompdf->setPaper('A4');
            $dompdf->render();

            return response($dompdf->output(), 200)
                ->header('Content-Type', 'application/pdf')
                ->header('Content-Disposition', 'inline; filename="CoA_'.$report->id.'.pdf"');
        }

        return response($html)->header('Content-Type', 'text/html');
    }

    private function generateReportNumber(): string
    {
        $now = Carbon::now();
        $roman = [1 => 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'][$now->month];
        $last = Report::whereYear('created_at', $now->year)->whereMonth('created_at', $now->month)->latest('id')->first();
        $next = $last ? ((int) substr($last->no_report, 0, 3)) + 1 : 1;

        return str_pad((string) $next, 3, '0', STR_PAD_LEFT)."/AR/TEC-LAB/{$roman}/{$now->year}";
    }

    private function attachNames(Report $report): void
    {
        $report->requested_by_name = $report->requester?->name;
        $report->sampler_name = $report->samplerUser?->name;
        $report->analyst_name = $report->analystUser?->name;
        $report->reviewed_by_name = $report->reviewedBy?->name;
        $report->acknowledge_by_name = $report->acknowledgeBy?->name;
    }

    private function joinedTestDetails(int $reportId)
    {
        return DB::table('test_details as td')
            ->leftJoin('test_types as tt', 'td.test_type_id', '=', 'tt.id')
            ->leftJoin('methods as m', 'td.method_id', '=', 'm.id')
            ->leftJoin('standards as st', 'td.standard_id', '=', 'st.id')
            ->leftJoin('units as u', 'td.unit_id', '=', 'u.id')
            ->select('td.*', 'tt.name as test_type', 'm.name as method', 'st.name as standard', 'u.name as unit')
            ->where('td.report_id', $reportId)
            ->get();
    }
}
