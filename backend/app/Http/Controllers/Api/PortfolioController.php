<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AnalyticsEvent;
use App\Models\Block;
use App\Models\ContactMessage;
use App\Models\CustomDomain;
use App\Models\Portfolio;
use App\Models\Profile;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class PortfolioController extends Controller
{
    public function getPortfolio(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        return response()->json([
            'success' => true,
            'data' => $portfolio,
        ]);
    }

    public function updateProfile(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'full_name' => 'sometimes|string|max:255',
            'professional_title' => 'sometimes|string|max:255',
            'bio' => 'nullable|string|max:2000',
            'avatar_url' => 'nullable|url|max:2048',
            'website_url' => 'nullable|url|max:2048',
            'resume_url' => 'nullable|url|max:2048',
            'location' => 'nullable|string|max:255',
            'availability_status' => 'nullable|string|max:255',
            'social_links' => 'nullable|array',
            'social_links.*.label' => 'required_with:social_links|string|max:80',
            'social_links.*.url' => 'required_with:social_links|url|max:2048',
            'skills' => 'nullable|array',
            'skills.*' => 'string|max:80',
        ]);

        if (isset($validated['full_name'])) {
            $user->update(['name' => $validated['full_name']]);
        }

        $profileData = $validated;
        unset($profileData['full_name']);

        $profile = Profile::updateOrCreate(
            ['user_id' => $user->id],
            array_merge([
                'full_name' => $validated['full_name'] ?? $user->name,
                'professional_title' => $validated['professional_title'] ?? 'Tech Professional',
            ], $profileData)
        );

        return response()->json([
            'success' => true,
            'data' => $profile,
        ]);
    }

    public function completeOnboarding(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'role' => 'nullable|string|max:100',
            'professional_title' => 'nullable|string|max:255',
            'full_name' => 'nullable|string|max:255',
            'bio' => 'nullable|string|max:2000',
            'avatar_url' => 'nullable|string|max:2048',
            'accent_color' => 'nullable|string|max:20',
            'layout_template' => 'nullable|string|max:100',
            'skills' => 'nullable|array',
            'skills.*' => 'string|max:80',
            'projects' => 'nullable|array',
            'projects.*.title' => 'required_with:projects|string|max:255',
            'projects.*.description' => 'nullable|string|max:1000',
            'projects.*.url' => 'nullable|string|max:2048',
            'projects.*.skills' => 'nullable|array',
            'projects.*.skills.*' => 'string|max:80',
            'projects.*.image_url' => 'nullable|string|max:2048',
        ]);

        $user = $request->user();
        if (!empty($validated['full_name'])) {
            $user->update(['name' => $validated['full_name']]);
        }

        $profile = Profile::updateOrCreate(
            ['user_id' => $user->id],
            [
                'full_name' => $validated['full_name'] ?? $user->name,
                'professional_title' => $validated['professional_title'] ?? 'Tech Professional',
                'bio' => $validated['bio'] ?? '',
                'avatar_url' => $validated['avatar_url'] ?? $user->avatar_url,
                'skills' => $validated['skills'] ?? [],
            ]
        );

        $profile->update([
            'full_name' => $validated['full_name'] ?? $profile->full_name,
            'professional_title' => $validated['professional_title'] ?? $profile->professional_title,
            'bio' => $validated['bio'] ?? $profile->bio,
            'avatar_url' => $validated['avatar_url'] ?? $profile->avatar_url,
            'skills' => $validated['skills'] ?? $profile->skills ?? [],
        ]);

        $user->update(['has_completed_onboarding' => true]);

        $portfolio = $this->portfolioFor($request);
        
        // Update portfolio theme settings
        $settings = $portfolio->theme_settings ?? [];
        $settings['accent_color'] = $validated['accent_color'] ?? $settings['accent_color'] ?? '#6366F1';
        $settings['layout_template'] = $validated['layout_template'] ?? $settings['layout_template'] ?? 'minimal_dark';
        $settings['onboarding'] = [
            'role' => $validated['role'] ?? null,
            'integrations' => [],
        ];
        
        $portfolio->update([
            'theme_settings' => $settings,
            'title' => ($validated['full_name'] ?? $user->name) . ' Portfolio',
            'description' => $validated['bio'] ?? $portfolio->description,
        ]);

        // Clean up any existing blocks to auto-build fresh custom layout based on user details
        $portfolio->blocks()->delete();

        // 1. Core Profile Block (Index 0)
        $portfolio->blocks()->create([
            'type' => 'profile',
            'title' => 'Profile',
            'grid_position' => ['x' => 0, 'y' => 0, 'w' => 2, 'h' => 2],
            'content' => [
                'name' => $validated['full_name'] ?? $user->name,
                'title' => $validated['professional_title'] ?? 'Tech Professional',
                'bio' => $validated['bio'] ?? 'Introduce yourself here.',
                'avatar_url' => $validated['avatar_url'] ?? '',
                'availability' => 'Open for contract & full-time roles',
            ],
            'settings' => [],
            'is_visible' => true,
            'sort_order' => 0,
        ]);

        // 2. Generate User Submitted Projects
        $projects = $validated['projects'] ?? [];
        $sortOrder = 1;

        foreach ($projects as $index => $project) {
            // Assign responsive grid positions based on index
            $gridPos = [];
            if ($index === 0) {
                // First project is featured large block
                $gridPos = ['x' => 0, 'y' => 2, 'w' => 2, 'h' => 2];
            } else {
                // Secondary projects
                $gridPos = ['x' => 0, 'y' => 2 + ($index * 2), 'w' => 2, 'h' => 1];
            }

            $portfolio->blocks()->create([
                'type' => 'project',
                'title' => $project['title'],
                'grid_position' => $gridPos,
                'content' => [
                    'title' => $project['title'],
                    'description' => $project['description'] ?? '',
                    'url' => $project['url'] ?? '',
                    'skills' => $project['skills'] ?? [],
                    'image_url' => $project['image_url'] ?? '',
                ],
                'settings' => [],
                'is_visible' => true,
                'sort_order' => $sortOrder++,
            ]);
        }

        // 3. Add Filler Blocks to keep Bento layout full & balanced if project count is small
        $projectCount = count($projects);
        $nextY = 2 + ($projectCount * 2);
        if ($projectCount === 1) {
            $nextY = 4; // Since first project is size 2x2, y ends at 4
        }

        // Stats Block (e.g. skills count)
        $portfolio->blocks()->create([
            'type' => 'statsCounter',
            'title' => 'Tech Stack',
            'grid_position' => ['x' => 0, 'y' => $nextY, 'w' => 1, 'h' => 1],
            'content' => [
                'value' => count($validated['skills'] ?? []) . '+',
                'label' => 'Skills Mastered',
            ],
            'settings' => [],
            'is_visible' => true,
            'sort_order' => $sortOrder++,
        ]);

        // Custom Link Block
        $portfolio->blocks()->create([
            'type' => 'link',
            'title' => 'Connect',
            'grid_position' => ['x' => 1, 'y' => $nextY, 'w' => 1, 'h' => 1],
            'content' => [
                'label' => 'Get in Touch',
                'url' => 'https://tspace.me',
            ],
            'settings' => [],
            'is_visible' => true,
            'sort_order' => $sortOrder++,
        ]);

        $this->forgetPortfolioCache($portfolio);

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $user->fresh('profile'),
                'portfolio' => $portfolio->fresh(['blocks', 'customDomain']),
            ],
        ]);
    }

    public function addBlock(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        $validated = $request->validate($this->blockValidationRules());
        $nextSortOrder = ($portfolio->blocks()->max('sort_order') ?? -1) + 1;

        $block = $portfolio->blocks()->create([
            'type' => $validated['type'],
            'title' => $validated['title'] ?? Str::headline($validated['type']),
            'grid_position' => $validated['grid_position'],
            'content' => $validated['content'],
            'settings' => $validated['settings'] ?? [],
            'is_visible' => $validated['is_visible'] ?? true,
            'sort_order' => $validated['sort_order'] ?? $nextSortOrder,
        ]);

        $this->forgetPortfolioCache($portfolio);

        return response()->json([
            'success' => true,
            'data' => $block,
        ], 201);
    }

    public function updateBlock(Request $request, int $id): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);
        $block = $portfolio->blocks()->whereKey($id)->firstOrFail();

        $validated = $request->validate([
            'type' => 'sometimes|string|max:80',
            'title' => 'nullable|string|max:255',
            'grid_position' => 'sometimes|array',
            'grid_position.x' => 'required_with:grid_position|integer|min:0',
            'grid_position.y' => 'required_with:grid_position|integer|min:0',
            'grid_position.w' => 'required_with:grid_position|integer|min:1|max:4',
            'grid_position.h' => 'required_with:grid_position|integer|min:1|max:6',
            'content' => 'sometimes|array',
            'settings' => 'nullable|array',
            'is_visible' => 'sometimes|boolean',
            'sort_order' => 'sometimes|integer|min:0',
        ]);

        $block->update($validated);
        $this->forgetPortfolioCache($portfolio);

        return response()->json([
            'success' => true,
            'data' => $block->fresh(),
        ]);
    }

    public function updateBlockLayout(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        $validated = $request->validate([
            'blocks' => 'required|array',
            'blocks.*.id' => [
                'required',
                Rule::exists('blocks', 'id')->where('portfolio_id', $portfolio->id),
            ],
            'blocks.*.sort_order' => 'required|integer|min:0',
            'blocks.*.grid_position' => 'required|array',
            'blocks.*.grid_position.x' => 'required|integer|min:0',
            'blocks.*.grid_position.y' => 'required|integer|min:0',
            'blocks.*.grid_position.w' => 'required|integer|min:1|max:4',
            'blocks.*.grid_position.h' => 'required|integer|min:1|max:6',
        ]);

        DB::transaction(function () use ($validated, $portfolio) {
            foreach ($validated['blocks'] as $blockData) {
                $portfolio->blocks()->whereKey($blockData['id'])->update([
                    'sort_order' => $blockData['sort_order'],
                    'grid_position' => $blockData['grid_position'],
                ]);
            }
        });

        $this->forgetPortfolioCache($portfolio);

        return response()->json([
            'success' => true,
            'data' => $portfolio->fresh(['blocks', 'customDomain']),
        ]);
    }

    public function deleteBlock(Request $request, int $id): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);
        $portfolio->blocks()->whereKey($id)->firstOrFail()->delete();

        $this->forgetPortfolioCache($portfolio);

        return response()->json([
            'success' => true,
            'message' => 'Block deleted successfully.',
        ]);
    }

    public function updateSettings(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:2000',
            'theme_settings' => 'sometimes|array',
            'seo_settings' => 'sometimes|array',
            'is_published' => 'sometimes|boolean',
            'slug' => [
                'sometimes',
                'string',
                'alpha_dash',
                'max:120',
                Rule::unique('portfolios', 'slug')->ignore($portfolio->id),
            ],
        ]);

        if (array_key_exists('is_published', $validated)) {
            $validated['published_at'] = $validated['is_published'] ? ($portfolio->published_at ?? now()) : null;
        }

        $oldSlug = $portfolio->slug;
        $portfolio->update($validated);
        $this->forgetPortfolioCache($portfolio, $oldSlug);

        return response()->json([
            'success' => true,
            'data' => $portfolio->fresh(['blocks', 'customDomain']),
        ]);
    }

    public function publicShow(string $slug): JsonResponse
    {
        $cacheKey = "portfolio_slug:$slug";

        $portfolio = Cache::remember($cacheKey, now()->addMinutes(10), function () use ($slug) {
            return Portfolio::query()
                ->with(['user.profile', 'blocks' => fn ($query) => $query->where('is_visible', true)->orderBy('sort_order'), 'customDomain'])
                ->where('slug', $slug)
                ->where('is_published', true)
                ->first();
        });

        if (!$portfolio) {
            return response()->json([
                'success' => false,
                'message' => 'Portfolio not found or not published.',
            ], 404);
        }

        $this->recordAnalyticsEvent($portfolio, request(), 'view');

        return response()->json([
            'success' => true,
            'data' => $portfolio,
        ]);
    }

    public function trackPublicEvent(Request $request, string $slug): JsonResponse
    {
        $validated = $request->validate([
            'event_type' => 'required|string|max:80',
            'session_id' => 'nullable|string|max:120',
            'metadata' => 'nullable|array',
            'path' => 'nullable|string|max:500',
        ]);

        $portfolio = Portfolio::where('slug', $slug)->where('is_published', true)->firstOrFail();
        $this->recordAnalyticsEvent($portfolio, $request, $validated['event_type'], $validated);

        return response()->json([
            'success' => true,
            'message' => 'Event recorded.',
        ], 201);
    }

    public function githubRepos(Request $request): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => [
                ['id' => '1', 'name' => 'antigravity-engine', 'description' => 'Agentic AI orchestration framework written in Dart.', 'stars' => 412, 'language' => 'Dart'],
                ['id' => '2', 'name' => 'bento-grid-maker', 'description' => 'Premium drag-and-drop grid editor for tech portfolios.', 'stars' => 128, 'language' => 'TypeScript'],
                ['id' => '3', 'name' => 'laravel-smooth-api', 'description' => 'REST API skeleton with structured JSON formatting.', 'stars' => 85, 'language' => 'PHP'],
                ['id' => '4', 'name' => 'creative-portfolio', 'description' => 'Curated CSS animations and typography configurations.', 'stars' => 54, 'language' => 'CSS'],
            ],
        ]);
    }

    public function importGithubRepos(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        $validated = $request->validate([
            'repos' => 'required|array|min:1',
            'repos.*.name' => 'required|string|max:255',
            'repos.*.description' => 'nullable|string|max:1000',
            'repos.*.stars' => 'required|integer|min:0',
            'repos.*.language' => 'nullable|string|max:80',
            'repos.*.url' => 'nullable|url|max:2048',
        ]);

        $currentMaxSort = $portfolio->blocks()->max('sort_order') ?? 0;
        $importedBlocks = [];

        DB::transaction(function () use ($validated, $portfolio, $currentMaxSort, &$importedBlocks) {
            foreach ($validated['repos'] as $index => $repoData) {
                $importedBlocks[] = $portfolio->blocks()->create([
                    'type' => 'github',
                    'title' => $repoData['name'],
                    'grid_position' => ['x' => 0, 'y' => $currentMaxSort + $index + 1, 'w' => 2, 'h' => 1],
                    'content' => [
                        'repo_name' => $repoData['name'],
                        'description' => $repoData['description'] ?? 'No description provided.',
                        'stars' => $repoData['stars'],
                        'language' => $repoData['language'] ?? 'Code',
                        'url' => $repoData['url'] ?? null,
                    ],
                    'settings' => [],
                    'is_visible' => true,
                    'sort_order' => $currentMaxSort + $index + 1,
                ]);
            }
        });

        $this->forgetPortfolioCache($portfolio);

        return response()->json([
            'success' => true,
            'data' => $importedBlocks,
        ], 201);
    }

    public function analytics(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        $totalViews = $portfolio->analyticsEvents()->where('event_type', 'view')->count();
        $totalClicks = $portfolio->analyticsEvents()->where('event_type', 'click')->count();
        $messageCount = $portfolio->contactMessages()->count();

        $deviceBreakdown = $portfolio->analyticsEvents()
            ->where('event_type', 'view')
            ->select('device', DB::raw('count(*) as total'))
            ->groupBy('device')
            ->pluck('total', 'device')
            ->toArray();

        $viewsOverTime = collect(range(6, 0))->map(function (int $daysAgo) use ($portfolio) {
            $date = now()->subDays($daysAgo)->format('Y-m-d');

            return [
                'date' => $date,
                'views' => $portfolio->analyticsEvents()
                    ->where('event_type', 'view')
                    ->whereDate('created_at', $date)
                    ->count(),
            ];
        })->values();

        $countries = $portfolio->analyticsEvents()
            ->where('event_type', 'view')
            ->select('ip_country as name', DB::raw('count(*) as count'))
            ->groupBy('ip_country')
            ->orderByDesc('count')
            ->take(5)
            ->get()
            ->map(fn ($item) => [
                'code' => $this->countryCode($item->name),
                'name' => $item->name ?: 'Unknown',
                'count' => $item->count,
            ]);

        return response()->json([
            'success' => true,
            'data' => [
                'total_views' => $totalViews,
                'total_clicks' => $totalClicks,
                'message_count' => $messageCount,
                'device_breakdown' => [
                    'mobile' => $deviceBreakdown['mobile'] ?? 0,
                    'desktop' => $deviceBreakdown['desktop'] ?? 0,
                    'tablet' => $deviceBreakdown['tablet'] ?? 0,
                ],
                'views_over_time' => $viewsOverTime,
                'countries' => $countries,
            ],
        ]);
    }

    public function messages(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        return response()->json([
            'success' => true,
            'data' => $portfolio->contactMessages()
                ->whereNull('archived_at')
                ->latest()
                ->get(),
        ]);
    }

    public function updateMessage(Request $request, int $id): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);
        $message = $portfolio->contactMessages()->whereKey($id)->firstOrFail();

        $validated = $request->validate([
            'is_read' => 'sometimes|boolean',
            'is_archived' => 'sometimes|boolean',
            'tag' => 'nullable|string|max:80',
        ]);

        if (array_key_exists('is_read', $validated)) {
            $message->read_at = $validated['is_read'] ? ($message->read_at ?? now()) : null;
        }

        if (array_key_exists('is_archived', $validated)) {
            $message->archived_at = $validated['is_archived'] ? ($message->archived_at ?? now()) : null;
        }

        if (array_key_exists('tag', $validated)) {
            $message->tag = $validated['tag'];
        }

        $message->save();

        return response()->json([
            'success' => true,
            'data' => $message,
        ]);
    }

    public function deleteMessage(Request $request, int $id): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);
        $portfolio->contactMessages()->whereKey($id)->firstOrFail()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Message deleted successfully.',
        ]);
    }

    public function sendMessage(Request $request, string $slug): JsonResponse
    {
        $portfolio = Portfolio::where('slug', $slug)->where('is_published', true)->firstOrFail();

        $validated = $request->validate([
            'sender_name' => 'required|string|max:255',
            'sender_email' => 'required|email|max:255',
            'company' => 'nullable|string|max:255',
            'message' => 'required|string|max:5000',
        ]);

        $message = $portfolio->contactMessages()->create([
            ...$validated,
            'tag' => 'recruiter',
        ]);

        $this->recordAnalyticsEvent($portfolio, $request, 'message', [
            'metadata' => ['sender_email' => $validated['sender_email']],
        ]);

        return response()->json([
            'success' => true,
            'data' => $message,
        ], 201);
    }

    public function upsertDomain(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);

        $validated = $request->validate([
            'hostname' => [
                'required',
                'string',
                'max:255',
                Rule::unique('custom_domains', 'hostname')->ignore($portfolio->customDomain?->id),
            ],
        ]);

        $domain = CustomDomain::updateOrCreate(
            ['portfolio_id' => $portfolio->id],
            [
                'hostname' => Str::lower($validated['hostname']),
                'verification_token' => 'tspace-verify=' . Str::random(32),
                'ssl_status' => 'pending',
                'dns_status' => 'pending',
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $domain,
        ]);
    }

    public function verifyDomain(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);
        $domain = $portfolio->customDomain()->firstOrFail();

        $domain->update([
            'dns_status' => 'verified',
            'ssl_status' => 'pending',
            'verified_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'data' => $domain,
        ]);
    }

    public function deleteDomain(Request $request): JsonResponse
    {
        $portfolio = $this->portfolioFor($request);
        $portfolio->customDomain()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Domain removed successfully.',
        ]);
    }

    private function portfolioFor(Request $request): Portfolio
    {
        $user = $request->user();
        $portfolio = Portfolio::firstOrCreate(
            ['user_id' => $user->id],
            [
                'slug' => $this->uniqueSlug($user->name),
                'title' => $user->name . ' Portfolio',
                'description' => 'A professional portfolio built with Tspace.',
                'theme_settings' => ['accent_color' => '#6366F1', 'font_family' => 'Inter', 'layout_template' => 'minimal_dark'],
                'seo_settings' => ['title' => $user->name . ' Portfolio', 'description' => 'Professional portfolio, projects, and contact details.'],
                'is_published' => false,
            ]
        );

        Profile::firstOrCreate(
            ['user_id' => $user->id],
            ['full_name' => $user->name, 'professional_title' => 'Tech Professional', 'availability_status' => 'open_for_opportunities']
        );

        if ($portfolio->blocks()->count() === 0) {
            $portfolio->blocks()->createMany([
                [
                    'type' => 'profile',
                    'title' => 'Profile',
                    'grid_position' => ['x' => 0, 'y' => 0, 'w' => 2, 'h' => 2],
                    'content' => ['name' => $user->name, 'title' => $user->profile?->professional_title ?? 'Tech Professional', 'bio' => 'Introduce yourself here.'],
                    'settings' => [],
                    'is_visible' => true,
                    'sort_order' => 0,
                ],
            ]);
        }

        return $portfolio->fresh(['blocks', 'customDomain', 'user.profile']);
    }

    private function blockValidationRules(): array
    {
        return [
            'type' => 'required|string|max:80',
            'title' => 'nullable|string|max:255',
            'grid_position' => 'required|array',
            'grid_position.x' => 'required|integer|min:0',
            'grid_position.y' => 'required|integer|min:0',
            'grid_position.w' => 'required|integer|min:1|max:4',
            'grid_position.h' => 'required|integer|min:1|max:6',
            'content' => 'required|array',
            'settings' => 'nullable|array',
            'is_visible' => 'sometimes|boolean',
            'sort_order' => 'sometimes|integer|min:0',
        ];
    }

    private function recordAnalyticsEvent(Portfolio $portfolio, Request $request, string $eventType, array $payload = []): void
    {
        try {
            $userAgent = $request->userAgent() ?? '';

            $portfolio->analyticsEvents()->create([
                'event_type' => $eventType,
                'session_id' => $payload['session_id'] ?? null,
                'metadata' => $payload['metadata'] ?? [
                    'user_agent' => $userAgent,
                    'referer' => $request->header('Referer'),
                ],
                'ip_country' => $request->header('CF-IPCountry') ?? 'Unknown',
                'device' => $this->deviceFromUserAgent($userAgent),
                'path' => $payload['path'] ?? $request->path(),
            ]);
        } catch (\Throwable) {
            // Analytics should never block the portfolio or contact experience.
        }
    }

    private function deviceFromUserAgent(string $userAgent): string
    {
        if (Str::contains($userAgent, ['iPad', 'Tablet'])) {
            return 'tablet';
        }

        if (Str::contains($userAgent, ['Mobile', 'Android', 'iPhone'])) {
            return 'mobile';
        }

        return 'desktop';
    }

    private function countryCode(?string $country): string
    {
        return match (Str::lower((string) $country)) {
            'united states', 'us' => 'US',
            'united kingdom', 'gb', 'uk' => 'GB',
            'germany', 'de' => 'DE',
            'india', 'in' => 'IN',
            'nigeria', 'ng' => 'NG',
            default => 'UN',
        };
    }

    private function uniqueSlug(string $name): string
    {
        $base = Str::slug($name) ?: 'portfolio';
        $slug = $base;
        $counter = 1;

        while (Portfolio::where('slug', $slug)->exists()) {
            $slug = $base . '-' . $counter++;
        }

        return $slug;
    }

    private function forgetPortfolioCache(Portfolio $portfolio, ?string $oldSlug = null): void
    {
        Cache::forget("portfolio_slug:{$portfolio->slug}");

        if ($oldSlug && $oldSlug !== $portfolio->slug) {
            Cache::forget("portfolio_slug:$oldSlug");
        }
    }
}
