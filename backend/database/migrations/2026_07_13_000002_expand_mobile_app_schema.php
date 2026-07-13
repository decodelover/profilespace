<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('profiles', function (Blueprint $table) {
            $table->string('website_url')->nullable()->after('avatar_url');
            $table->string('resume_url')->nullable()->after('website_url');
            $table->json('social_links')->nullable()->after('resume_url');
            $table->json('skills')->nullable()->after('social_links');
        });

        Schema::table('portfolios', function (Blueprint $table) {
            $table->string('title')->nullable()->after('slug');
            $table->text('description')->nullable()->after('title');
            $table->json('seo_settings')->nullable()->after('theme_settings');
            $table->timestamp('published_at')->nullable()->after('is_published');
        });

        Schema::table('blocks', function (Blueprint $table) {
            $table->string('title')->nullable()->after('type');
            $table->json('settings')->nullable()->after('content');
        });

        Schema::table('custom_domains', function (Blueprint $table) {
            $table->string('verification_token')->nullable()->after('hostname');
            $table->timestamp('verified_at')->nullable()->after('dns_status');
        });

        Schema::table('contact_messages', function (Blueprint $table) {
            $table->timestamp('read_at')->nullable()->after('tag');
            $table->timestamp('archived_at')->nullable()->after('read_at');
        });

        Schema::table('analytics_events', function (Blueprint $table) {
            $table->string('session_id')->nullable()->after('event_type');
            $table->string('path')->nullable()->after('device');
        });
    }

    public function down(): void
    {
        Schema::table('profiles', function (Blueprint $table) {
            $table->dropColumn(['website_url', 'resume_url', 'social_links', 'skills']);
        });

        Schema::table('portfolios', function (Blueprint $table) {
            $table->dropColumn(['title', 'description', 'seo_settings', 'published_at']);
        });

        Schema::table('blocks', function (Blueprint $table) {
            $table->dropColumn(['title', 'settings']);
        });

        Schema::table('custom_domains', function (Blueprint $table) {
            $table->dropColumn(['verification_token', 'verified_at']);
        });

        Schema::table('contact_messages', function (Blueprint $table) {
            $table->dropColumn(['read_at', 'archived_at']);
        });

        Schema::table('analytics_events', function (Blueprint $table) {
            $table->dropColumn(['session_id', 'path']);
        });
    }
};
