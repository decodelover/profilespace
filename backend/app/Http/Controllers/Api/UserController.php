<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Jobs\GeneratePortfolioSite;
use App\Models\Plan;
use App\Models\Portfolio;
use App\Models\PublishJob;
use App\Models\Site;
use App\Models\Template;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class UserController extends Controller
{
    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['profile', 'portfolio.customDomain', 'site']);

        return response()->json([
            'success' => true,
            'data' => $user,
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'avatar_url' => 'sometimes|nullable|url|max:1000',
        ]);

        $user->update($validated);

        return response()->json([
            'success' => true,
            'data' => $user->fresh(['profile', 'portfolio']),
        ]);
    }

    public function specializations(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                [
                    'id' => 'developer',
                    'name' => 'Developer',
                    'fields' => [
                        ['name' => 'github_link', 'type' => 'url', 'required' => false],
                    ],
                ],
                [
                    'id' => 'designer',
                    'name' => 'Designer',
                    'fields' => [
                        ['name' => 'figma_link', 'type' => 'url', 'required' => false],
                    ],
                ],
                [
                    'id' => 'photographer',
                    'name' => 'Photographer',
                    'fields' => [
                        ['name' => 'specialty', 'type' => 'string', 'required' => false],
                        ['name' => 'social_link', 'type' => 'url', 'required' => false],
                    ],
                ],
                [
                    'id' => 'writer',
                    'name' => 'Writer',
                    'fields' => [
                        ['name' => 'writing_genre', 'type' => 'string', 'required' => false],
                        ['name' => 'substack_link', 'type' => 'url', 'required' => false],
                    ],
                ],
                [
                    'id' => 'videographer',
                    'name' => 'Videographer',
                    'fields' => [
                        ['name' => 'gear_list', 'type' => 'string', 'required' => false],
                        ['name' => 'youtube_link', 'type' => 'url', 'required' => false],
                    ],
                ],
                [
                    'id' => 'musician',
                    'name' => 'Musician',
                    'fields' => [
                        ['name' => 'soundcloud_link', 'type' => 'url', 'required' => false],
                    ],
                ],
                [
                    'id' => 'marketer',
                    'name' => 'Marketer',
                    'fields' => [
                        ['name' => 'social_link', 'type' => 'url', 'required' => false],
                    ],
                ],
                [
                    'id' => 'consultant',
                    'name' => 'Consultant',
                    'fields' => [
                        ['name' => 'social_link', 'type' => 'url', 'required' => false],
                    ],
                ],
            ],
        ]);
    }

    public function updateSpecialization(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'specialization' => 'required|string|in:developer,designer,photographer,writer,videographer,musician,marketer,consultant',
        ]);

        $user->update([
            'specialization' => $validated['specialization'],
            'onboarding_step' => 'step2',
        ]);

        return response()->json([
            'success' => true,
            'data' => $user,
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();
        $profile = $user->profile;

        if (!$profile) {
            return response()->json([
                'success' => false,
                'message' => 'Profile record not initialized.',
            ], 404);
        }

        $validated = $request->validate([
            'bio' => 'required|string|max:1000',
            'avatar_url' => 'nullable|url|max:1000',
            'website_url' => 'nullable|url|max:255',
            'social_links' => 'nullable|array',
            'skills' => 'nullable|array',
        ]);

        $profile->update($validated);
        $user->update(['onboarding_step' => 'step3']);

        return response()->json([
            'success' => true,
            'data' => $profile->fresh(),
        ]);
    }

    public function plans(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => Plan::all(),
        ]);
    }

    public function updatePlan(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'plan_id' => 'required|string|exists:plans,id',
        ]);

        $user->update([
            'plan_id' => $validated['plan_id'],
            'onboarding_step' => 'step4',
        ]);

        return response()->json([
            'success' => true,
            'data' => $user,
        ]);
    }

    public function templates(): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => Template::all(),
        ]);
    }

    public function updateTemplate(Request $request): JsonResponse
    {
        $user = $request->user();
        $portfolio = $user->portfolio;

        if (!$portfolio) {
            return response()->json([
                'success' => false,
                'message' => 'Portfolio record not initialized.',
            ], 404);
        }

        $validated = $request->validate([
            'template_id' => 'required|string|exists:templates,id',
        ]);

        $themeSettings = $portfolio->theme_settings ?? [];
        $themeSettings['layout_template'] = $validated['template_id'];

        $portfolio->update([
            'theme_settings' => $themeSettings,
        ]);

        $user->update(['onboarding_step' => 'step5']);

        return response()->json([
            'success' => true,
            'data' => $portfolio->fresh(),
        ]);
    }

    public function checkDomain(Request $request): JsonResponse
    {
        $request->validate([
            'subdomain' => 'required|string|alpha_dash|max:120',
        ]);

        $subdomain = $request->query('subdomain');
        $portfolio = $request->user() ? $request->user()->portfolio : null;

        $exists = Portfolio::where('slug', $subdomain)
            ->when($portfolio, fn ($query) => $query->where('id', '!=', $portfolio->id))
            ->exists();

        return response()->json([
            'success' => true,
            'available' => !$exists,
        ]);
    }

    public function publish(Request $request): JsonResponse
    {
        $user = $request->user();
        $portfolio = $user->portfolio;

        // 1. Validation checks
        if (!$user->specialization) {
            return response()->json([
                'success' => false,
                'message' => 'Please select a specialization track before publishing.',
            ], 400);
        }

        if (!$portfolio || empty($portfolio->slug)) {
            return response()->json([
                'success' => false,
                'message' => 'Please configure your portfolio domain slug before publishing.',
            ], 400);
        }

        // 2. Guard against duplicate active jobs (idempotency check)
        $existingJob = PublishJob::where('user_id', $user->id)
            ->whereIn('status', ['queued', 'processing'])
            ->first();

        if ($existingJob) {
            return response()->json([
                'success' => true,
                'job_id' => $existingJob->id,
                'status' => $existingJob->status,
                'message' => 'Publish job already in progress.',
            ]);
        }

        // 3. Create background publish job
        $jobId = (string) Str::uuid();
        $publishJob = PublishJob::create([
            'id' => $jobId,
            'user_id' => $user->id,
            'status' => 'queued',
            'progress_percent' => 0,
        ]);

        // Dispatch background queue job
        GeneratePortfolioSite::dispatch($jobId, $user->id);

        return response()->json([
            'success' => true,
            'job_id' => $jobId,
            'status' => 'queued',
            'message' => 'Site compilation and deployment job enqueued.',
        ], 202);
    }

    public function publishStatus(Request $request, string $jobId): JsonResponse
    {
        $publishJob = PublishJob::where('id', $jobId)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        return response()->json([
            'success' => true,
            'data' => [
                'job_id' => $publishJob->id,
                'status' => $publishJob->status,
                'progress_percent' => $publishJob->progress_percent,
                'error_message' => $publishJob->error_message,
                'started_at' => $publishJob->started_at?->toIso8601String(),
                'completed_at' => $publishJob->completed_at?->toIso8601String(),
            ],
        ]);
    }

    public function site(Request $request): JsonResponse
    {
        $site = Site::where('user_id', $request->user()->id)->firstOrFail();

        return response()->json([
            'success' => true,
            'data' => $site,
        ]);
    }
}
