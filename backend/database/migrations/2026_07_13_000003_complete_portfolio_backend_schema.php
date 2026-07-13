<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // 1. Extend users table
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'firebase_uid')) {
                $table->string('firebase_uid')->nullable()->unique()->after('id');
            }
            if (!Schema::hasColumn('users', 'auth_provider')) {
                $table->string('auth_provider')->nullable()->after('firebase_uid');
            }
            if (!Schema::hasColumn('users', 'plan_id')) {
                $table->string('plan_id')->default('free')->after('email');
            }
            if (!Schema::hasColumn('users', 'specialization')) {
                $table->string('specialization')->nullable()->after('plan_id');
            }
            if (!Schema::hasColumn('users', 'onboarding_step')) {
                $table->string('onboarding_step')->default('step1')->after('specialization');
            }
            if (!Schema::hasColumn('users', 'is_published')) {
                $table->boolean('is_published')->default(false)->after('onboarding_step');
            }
        });

        // 2. Create plans table
        Schema::create('plans', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('name');
            $table->decimal('price', 8, 2);
            $table->json('features')->nullable();
            $table->json('limits')->nullable();
            $table->timestamps();
        });

        // 3. Create templates table
        Schema::create('templates', function (Blueprint $table) {
            $table->string('id')->primary();
            $table->string('name');
            $table->string('preview_image_url')->nullable();
            $table->string('category')->nullable();
            $table->json('config')->nullable();
            $table->timestamps();
        });

        // 4. Create publish_jobs table
        Schema::create('publish_jobs', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('status')->default('queued'); // queued, processing, completed, failed
            $table->integer('progress_percent')->default(0);
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->text('error_message')->nullable();
            $table->timestamps();
        });

        // 5. Create sites table
        Schema::create('sites', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('live_url');
            $table->timestamp('published_at')->nullable();
            $table->timestamp('last_updated_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sites');
        Schema::dropIfExists('publish_jobs');
        Schema::dropIfExists('templates');
        Schema::dropIfExists('plans');

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['firebase_uid', 'auth_provider', 'plan_id', 'specialization', 'onboarding_step', 'is_published']);
        });
    }
};
