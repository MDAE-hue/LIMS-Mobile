<?php

namespace Database\Seeders;

use App\Models\Department;
use App\Models\ReportStatus;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        foreach (['Technical Laboratory', 'Quality Assurance', 'Production', 'Environment'] as $name) {
            Department::firstOrCreate(['name' => $name]);
        }

        foreach (['Admin', 'Manager', 'Superintendent', 'Analyst', 'Sampler'] as $name) {
            Role::firstOrCreate(['name' => $name]);
        }

        foreach ([
            1 => 'Requested',
            2 => 'In Progress',
            3 => 'Pending Review',
            4 => 'Revision',
            5 => 'Pending Acknowledge',
            6 => 'Closed',
            7 => 'Rejected',
        ] as $id => $name) {
            ReportStatus::updateOrCreate(['id' => $id], ['name' => $name]);
        }

        $admin = User::firstOrCreate(['email' => 'admin@lims.test'], [
            'name' => 'LIMS Admin',
            'password' => Hash::make('password'),
            'department_id' => Department::first()->id,
            'npk' => '0001',
            'job_title' => 'Administrator',
        ]);
        $admin->roles()->sync([Role::where('name', 'Admin')->value('id')]);

        foreach (['pH', 'TSS', 'COD', 'BOD', 'Oil & Grease'] as $name) {
            DB::table('test_types')->updateOrInsert(['name' => $name], ['created_at' => now(), 'updated_at' => now()]);
        }
        foreach (['APHA', 'SNI', 'Internal Method'] as $name) {
            DB::table('methods')->updateOrInsert(['name' => $name], ['created_at' => now(), 'updated_at' => now()]);
        }
        foreach (['Standard A', 'Standard B', 'Regulatory Limit'] as $name) {
            DB::table('standards')->updateOrInsert(['name' => $name], ['created_at' => now(), 'updated_at' => now()]);
        }
        foreach (['mg/L', 'ppm', 'pH', '%'] as $name) {
            DB::table('units')->updateOrInsert(['name' => $name], ['created_at' => now(), 'updated_at' => now()]);
        }
    }
}
