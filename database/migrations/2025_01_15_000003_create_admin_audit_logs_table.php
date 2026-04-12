<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('admin_audit_logs')) {
            Schema::create('admin_audit_logs', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
                $table->string('user_name');
                $table->string('action', 10); // POST, PUT, PATCH, DELETE
                $table->string('url', 500);
                $table->string('route', 200)->nullable();
                $table->json('request_data')->nullable();
                $table->smallInteger('response_status');
                $table->string('ip_address', 45);
                $table->string('user_agent', 500)->nullable();
                $table->timestamp('created_at');

                $table->index('user_id');
                $table->index('created_at');
                $table->index('action');
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('admin_audit_logs');
    }
};
