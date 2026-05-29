<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TestController extends Controller
{
    public function getTestTypes()
    {
        return response()->json(DB::table('test_types')->orderBy('name')->get());
    }

    public function getMethods()
    {
        return response()->json(DB::table('methods')->orderBy('name')->get());
    }

    public function getStandards()
    {
        return response()->json(DB::table('standards')->orderBy('name')->get());
    }

    public function getUnits()
    {
        return response()->json(DB::table('units')->orderBy('name')->get());
    }

    public function storeTestDetail(Request $request)
    {
        $validated = $request->validate([
            'report_id' => ['required', 'integer', 'exists:laboratory_report,id'],
            'bahan_pengujian' => ['nullable', 'string', 'max:100'],
            'test_type_id' => ['nullable', 'integer', 'exists:test_types,id'],
            'method_id' => ['nullable', 'integer', 'exists:methods,id'],
            'standard_id' => ['nullable', 'integer', 'exists:standards,id'],
            'unit_id' => ['nullable', 'integer', 'exists:units,id'],
            'result' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
        ]);

        $id = DB::table('test_details')->insertGetId([...$validated, 'created_at' => now(), 'updated_at' => now()]);

        return response()->json(['message' => 'Test detail berhasil disimpan', 'id' => $id], 201);
    }

    public function getTestDetails(int $reportId)
    {
        return response()->json(DB::table('test_details')->where('report_id', $reportId)->get());
    }

    public function getTestDetailsView(int $reportId)
    {
        return response()->json(
            DB::table('test_details')
                ->leftJoin('test_types', 'test_details.test_type_id', '=', 'test_types.id')
                ->leftJoin('methods', 'test_details.method_id', '=', 'methods.id')
                ->leftJoin('standards', 'test_details.standard_id', '=', 'standards.id')
                ->leftJoin('units', 'test_details.unit_id', '=', 'units.id')
                ->select('test_details.*', 'test_types.name as test_type', 'methods.name as method', 'standards.name as standard', 'units.name as unit')
                ->where('report_id', $reportId)
                ->get()
        );
    }

    public function updateTestDetail(Request $request, int $id)
    {
        $validated = $request->validate([
            'bahan_pengujian' => ['required', 'string', 'max:100'],
            'test_type_id' => ['required', 'integer', 'exists:test_types,id'],
            'method_id' => ['required', 'integer', 'exists:methods,id'],
            'standard_id' => ['required', 'integer', 'exists:standards,id'],
            'unit_id' => ['required', 'integer', 'exists:units,id'],
            'result' => ['required', 'string'],
            'description' => ['nullable', 'string'],
        ]);

        DB::table('test_details')->where('id', $id)->update([...$validated, 'updated_at' => now()]);

        return response()->json(['message' => 'Test detail berhasil diperbarui']);
    }
}
