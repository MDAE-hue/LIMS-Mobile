<?php

use App\Http\Controllers\Api\ActivityLogController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\LookupController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\TestController;
use App\Http\Controllers\Api\UserController;
use Illuminate\Support\Facades\Route;

Route::post('login', [AuthController::class, 'login']);

Route::middleware('api.token')->group(function () {
    Route::get('me', [AuthController::class, 'me']);
    Route::post('logout', [AuthController::class, 'logout']);

    Route::get('users', [UserController::class, 'index']);
    Route::get('users/{id}', [UserController::class, 'show']);
    Route::post('users', [UserController::class, 'store'])->middleware('role:Admin');
    Route::put('users/{id}', [UserController::class, 'update'])->middleware('role:Admin');
    Route::delete('users/{id}', [UserController::class, 'destroy'])->middleware('role:Admin');
    Route::post('change-password', [UserController::class, 'changePassword']);

    Route::get('departments', [LookupController::class, 'departments']);
    Route::get('departments/{id}', [LookupController::class, 'showDepartment']);
    Route::post('departments', [LookupController::class, 'storeDepartment']);
    Route::put('departments/{id}', [LookupController::class, 'updateDepartment']);
    Route::delete('departments/{id}', [LookupController::class, 'destroyDepartment']);
    Route::get('roles', [LookupController::class, 'roles']);
    Route::get('report-statuses', [LookupController::class, 'reportStatuses']);

    Route::get('laboratory/reports', [ReportController::class, 'index']);
    Route::get('laboratory/reports/stats', [ReportController::class, 'stats']);
    Route::get('laboratory/reports/{id}', [ReportController::class, 'show']);
    Route::post('laboratory/reports', [ReportController::class, 'store']);
    Route::put('laboratory/reports/{id}', [ReportController::class, 'update']);
    Route::delete('laboratory/reports', [ReportController::class, 'destroyMultiple'])->middleware('role:Admin');
    Route::get('laboratory/reports/{id}/coa', [ReportController::class, 'generateCoA']);
    Route::get('laboratory/reports/{id}/take-action', [ReportController::class, 'getTakeActionData'])->middleware('role:Admin,Superintendent,Manager');
    Route::put('laboratory/reports/{id}/take-action', [ReportController::class, 'takeAction'])->middleware('role:Admin,Superintendent,Manager');
    Route::post('laboratory/reports/{id}/reject', [ReportController::class, 'reject'])->middleware('role:Admin,Superintendent,Manager');
    Route::get('laboratory/reports/{id}/review', [ReportController::class, 'review'])->middleware('role:Admin,Superintendent,Manager');
    Route::put('laboratory/reports/{id}/submit-review', [ReportController::class, 'submitReview'])->middleware('role:Admin,Superintendent,Manager');
    Route::put('laboratory/reports/{id}/approve', [ReportController::class, 'approveReport'])->middleware('role:Admin,Manager');
    Route::put('laboratory/reports/{id}/finalize', [ReportController::class, 'finalize'])->middleware('role:Admin,Superintendent,Analyst');

    Route::get('laboratory/reports/{reportId}/test-details', [TestController::class, 'getTestDetails']);
    Route::get('laboratory/reports/{reportId}/test-details-view', [TestController::class, 'getTestDetailsView']);
    Route::post('test-details', [TestController::class, 'storeTestDetail']);
    Route::put('test-details/{id}', [TestController::class, 'updateTestDetail']);

    Route::get('test-types', [TestController::class, 'getTestTypes']);
    Route::get('methods', [TestController::class, 'getMethods']);
    Route::get('standards', [TestController::class, 'getStandards']);
    Route::get('units', [TestController::class, 'getUnits']);

    Route::get('test-types/{id}', fn (LookupController $controller, int $id) => $controller->show('test_types', $id));
    Route::post('test-types', fn (LookupController $controller, \Illuminate\Http\Request $request) => $controller->store($request, 'test_types'));
    Route::put('test-types/{id}', fn (LookupController $controller, \Illuminate\Http\Request $request, int $id) => $controller->update($request, 'test_types', $id));
    Route::delete('test-types/{id}', fn (LookupController $controller, int $id) => $controller->destroy('test_types', $id));

    Route::post('methods', fn (LookupController $controller, \Illuminate\Http\Request $request) => $controller->store($request, 'methods'));
    Route::put('methods/{id}', fn (LookupController $controller, \Illuminate\Http\Request $request, int $id) => $controller->update($request, 'methods', $id));
    Route::delete('methods/{id}', fn (LookupController $controller, int $id) => $controller->destroy('methods', $id));

    Route::post('standards', fn (LookupController $controller, \Illuminate\Http\Request $request) => $controller->store($request, 'standards'));
    Route::put('standards/{id}', fn (LookupController $controller, \Illuminate\Http\Request $request, int $id) => $controller->update($request, 'standards', $id));
    Route::delete('standards/{id}', fn (LookupController $controller, int $id) => $controller->destroy('standards', $id));

    Route::post('units', fn (LookupController $controller, \Illuminate\Http\Request $request) => $controller->store($request, 'units'));
    Route::put('units/{id}', fn (LookupController $controller, \Illuminate\Http\Request $request, int $id) => $controller->update($request, 'units', $id));
    Route::delete('units/{id}', fn (LookupController $controller, int $id) => $controller->destroy('units', $id));

    Route::get('activity-logs', [ActivityLogController::class, 'index']);
});
