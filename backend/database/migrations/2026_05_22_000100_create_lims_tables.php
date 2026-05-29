<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('departments', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->foreignId('head_id')->nullable()->index();
            $table->timestamps();
        });

        Schema::create('roles', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });

        Schema::create('user_roles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('role_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->unique(['user_id', 'role_id']);
        });

        Schema::create('api_tokens', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('name')->default('mobile');
            $table->string('token', 64)->unique();
            $table->timestamp('last_used_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
        });

        Schema::create('report_status', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });

        Schema::create('laboratory_report', function (Blueprint $table) {
            $table->id();
            $table->string('no_report')->unique();
            $table->foreignId('requested_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('department_id')->nullable()->constrained('departments')->nullOnDelete();
            $table->string('location');
            $table->foreignId('status_id')->default(1)->constrained('report_status');
            $table->date('date_sampling')->nullable();
            $table->date('date_analysis')->nullable();
            $table->text('remark')->nullable();
            $table->foreignId('sampler')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('analyst')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('acknowledge_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('acknowledge_at')->nullable();
            $table->text('notes')->nullable();
            $table->text('comment')->nullable();
            $table->string('reason')->nullable();
            $table->timestamps();
        });

        Schema::create('test_types', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });

        Schema::create('methods', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });

        Schema::create('standards', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });

        Schema::create('units', function (Blueprint $table) {
            $table->id();
            $table->string('name')->unique();
            $table->timestamps();
        });

        Schema::create('test_details', function (Blueprint $table) {
            $table->id();
            $table->foreignId('report_id')->constrained('laboratory_report')->cascadeOnDelete();
            $table->string('bahan_pengujian')->nullable();
            $table->foreignId('test_type_id')->nullable()->constrained('test_types')->nullOnDelete();
            $table->foreignId('method_id')->nullable()->constrained('methods')->nullOnDelete();
            $table->foreignId('standard_id')->nullable()->constrained('standards')->nullOnDelete();
            $table->foreignId('unit_id')->nullable()->constrained('units')->nullOnDelete();
            $table->string('result')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        Schema::create('activity_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('action');
            $table->string('table_name');
            $table->unsignedBigInteger('record_id')->nullable();
            $table->json('old_data')->nullable();
            $table->json('new_data')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('activity_logs');
        Schema::dropIfExists('test_details');
        Schema::dropIfExists('units');
        Schema::dropIfExists('standards');
        Schema::dropIfExists('methods');
        Schema::dropIfExists('test_types');
        Schema::dropIfExists('laboratory_report');
        Schema::dropIfExists('report_status');
        Schema::dropIfExists('api_tokens');
        Schema::dropIfExists('user_roles');
        Schema::dropIfExists('roles');
        Schema::dropIfExists('departments');
    }
};
