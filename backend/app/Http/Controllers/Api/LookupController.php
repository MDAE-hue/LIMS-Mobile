<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Department;
use App\Models\ReportStatus;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class LookupController extends Controller
{
    public function departments()
    {
        return response()->json(Department::orderBy('name')->get());
    }

    public function showDepartment(int $id)
    {
        return response()->json(Department::findOrFail($id));
    }

    public function storeDepartment(Request $request)
    {
        return response()->json(Department::create($request->validate(['name' => ['required', 'string', 'max:255', 'unique:departments,name'], 'head_id' => ['nullable', 'exists:users,id']])), 201);
    }

    public function updateDepartment(Request $request, int $id)
    {
        $department = Department::findOrFail($id);
        $department->update($request->validate(['name' => ['required', 'string', 'max:255', 'unique:departments,name,'.$id], 'head_id' => ['nullable', 'exists:users,id']]));

        return response()->json($department);
    }

    public function destroyDepartment(int $id)
    {
        Department::findOrFail($id)->delete();

        return response()->json(['message' => 'Department deleted']);
    }

    public function roles()
    {
        return response()->json(Role::orderBy('id')->get());
    }

    public function reportStatuses()
    {
        return response()->json(ReportStatus::orderBy('id')->get());
    }

    public function list(string $table)
    {
        $this->guardTable($table);

        return response()->json(DB::table($table)->orderBy('name')->get());
    }

    public function show(string $table, int $id)
    {
        $this->guardTable($table);
        $row = DB::table($table)->find($id);
        abort_if(! $row, 404);

        return response()->json($row);
    }

    public function store(Request $request, string $table)
    {
        $this->guardTable($table);
        $validated = $request->validate(['name' => ['required', 'string', 'max:255', 'unique:'.$table.',name']]);
        $id = DB::table($table)->insertGetId([...$validated, 'created_at' => now(), 'updated_at' => now()]);

        return response()->json(['message' => 'Created', 'id' => $id], 201);
    }

    public function update(Request $request, string $table, int $id)
    {
        $this->guardTable($table);
        $validated = $request->validate(['name' => ['required', 'string', 'max:255', 'unique:'.$table.',name,'.$id]]);
        DB::table($table)->where('id', $id)->update([...$validated, 'updated_at' => now()]);

        return response()->json(['message' => 'Updated']);
    }

    public function destroy(string $table, int $id)
    {
        $this->guardTable($table);
        DB::table($table)->where('id', $id)->delete();

        return response()->json(['message' => 'Deleted']);
    }

    private function guardTable(string $table): void
    {
        abort_unless(in_array($table, ['test_types', 'methods', 'standards', 'units'], true), 404);
    }
}
