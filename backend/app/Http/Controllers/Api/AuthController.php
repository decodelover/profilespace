<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ApiToken;
use App\Models\Block;
use App\Models\Portfolio;
use App\Models\Profile;
use App\Models\RefreshToken;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    public function register(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|max:255|unique:users,email',
            'password' => 'required|string|min:8|max:255',
            'professional_title' => 'nullable|string|max:255',
        ]);

        $user = DB::transaction(function () use ($validated) {
            $user = User::create([
                'name' => $validated['name'],
                'email' => $validated['email'],
                'password' => $validated['password'],
                'has_completed_onboarding' => false,
            ]);

            $this->ensureStarterData($user, $validated['professional_title'] ?? null);

            return $user;
        });

        return response()->json([
            'success' => true,
            'data' => $this->issueSession($user),
        ], 201);
    }

    public function loginWithEmail(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'email' => 'required|email|max:255',
            'password' => 'required|string|min:6',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user) {
            $user = DB::transaction(function () use ($validated) {
                $newUser = User::create([
                    'name' => Str::headline(Str::before($validated['email'], '@')),
                    'email' => $validated['email'],
                    'password' => $validated['password'],
                    'has_completed_onboarding' => false,
                ]);

                $this->ensureStarterData($newUser);

                return $newUser;
            });
        } elseif (!$user->password || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid email or password.',
            ], 401);
        }

        $this->ensureStarterData($user);

        return response()->json([
            'success' => true,
            'data' => $this->issueSession($user),
        ]);
    }

    public function loginWithGithub(Request $request): JsonResponse
    {
        return $this->loginWithOAuth($request, 'github');
    }

    public function loginWithGoogle(Request $request): JsonResponse
    {
        return $this->loginWithOAuth($request, 'google');
    }

    public function refresh(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'refresh_token' => 'required|string',
        ]);

        $refreshToken = RefreshToken::query()
            ->with('user.profile')
            ->where('token_hash', hash('sha256', $validated['refresh_token']))
            ->whereNull('revoked_at')
            ->where('expires_at', '>', now())
            ->first();

        if (!$refreshToken) {
            return response()->json([
                'success' => false,
                'message' => 'Refresh token is invalid or expired.',
            ], 401);
        }

        $refreshToken->forceFill(['revoked_at' => now()])->save();

        return response()->json([
            'success' => true,
            'data' => $this->issueSession($refreshToken->user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $bearerToken = $request->bearerToken();
        if ($bearerToken) {
            ApiToken::where('token_hash', hash('sha256', $bearerToken))->delete();
        }

        if ($request->filled('refresh_token')) {
            RefreshToken::where('token_hash', hash('sha256', $request->string('refresh_token')->toString()))
                ->update(['revoked_at' => now()]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully.',
        ]);
    }

    public function logoutAll(Request $request): JsonResponse
    {
        $user = $request->user();

        $user->apiTokens()->delete();
        $user->refreshTokens()->update(['revoked_at' => now()]);

        return response()->json([
            'success' => true,
            'message' => 'All sessions have been logged out.',
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load('profile', 'portfolio.blocks', 'portfolio.customDomain');
        $this->ensureStarterData($user);

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $this->serializeUser($user->fresh(['profile', 'portfolio.blocks', 'portfolio.customDomain'])),
            ],
        ]);
    }

    private function loginWithOAuth(Request $request, string $provider): JsonResponse
    {
        $validated = $request->validate([
            'code' => 'required|string',
        ]);

        $code = $validated['code'];
        $cached = Cache::pull("oauth_code:$code") ?? [];
        $providerPrefix = $provider === 'google' ? 'go' : 'gh';

        $oauthUser = [
            'name' => $cached['name'] ?? ($provider === 'google' ? 'Google Innovator' : 'GitHub Developer'),
            'email' => $cached['email'] ?? ($provider === 'google' ? 'innovator@gmail.com' : 'developer@github.com'),
            'provider' => $provider,
            'provider_id' => $cached['provider_id'] ?? $providerPrefix . '_' . substr(md5($code), 0, 16),
            'avatar_url' => $cached['avatar_url'] ?? 'https://ui-avatars.com/api/?name=' . urlencode($provider) . '&background=6366F1&color=fff',
        ];

        $user = DB::transaction(function () use ($oauthUser, $provider) {
            $user = User::where('provider', $provider)
                ->where('provider_id', $oauthUser['provider_id'])
                ->first();

            if (!$user) {
                $user = User::where('email', $oauthUser['email'])->first();
            }

            if ($user) {
                $user->update([
                    'provider' => $provider,
                    'provider_id' => $oauthUser['provider_id'],
                    'avatar_url' => $oauthUser['avatar_url'],
                ]);
            } else {
                $user = User::create([
                    'name' => $oauthUser['name'],
                    'email' => $oauthUser['email'],
                    'provider' => $provider,
                    'provider_id' => $oauthUser['provider_id'],
                    'avatar_url' => $oauthUser['avatar_url'],
                    'has_completed_onboarding' => false,
                ]);
            }

            $this->ensureStarterData($user);

            return $user;
        });

        return response()->json([
            'success' => true,
            'data' => $this->issueSession($user),
        ]);
    }

    private function issueSession(User $user): array
    {
        $accessToken = $user->createToken('mobile')->plainTextToken;
        $refreshToken = 'refresh_' . Str::random(96);

        $user->refreshTokens()->create([
            'token_hash' => hash('sha256', $refreshToken),
            'expires_at' => now()->addDays(90),
        ]);

        return [
            'access_token' => $accessToken,
            'refresh_token' => $refreshToken,
            'token_type' => 'Bearer',
            'expires_in' => 60 * 60 * 24 * 30,
            'user' => $this->serializeUser($user->fresh(['profile', 'portfolio.blocks', 'portfolio.customDomain'])),
        ];
    }

    private function ensureStarterData(User $user, ?string $professionalTitle = null): void
    {
        $profile = Profile::firstOrCreate(
            ['user_id' => $user->id],
            [
                'full_name' => $user->name,
                'professional_title' => $professionalTitle ?? 'Tech Professional',
                'bio' => 'Build your story, showcase your work, and make it easy for recruiters to reach you.',
                'avatar_url' => $user->avatar_url,
                'availability_status' => 'open_for_opportunities',
                'social_links' => [],
                'skills' => [],
            ]
        );

        if ($professionalTitle && $profile->professional_title !== $professionalTitle) {
            $profile->update(['professional_title' => $professionalTitle]);
        }

        $portfolio = Portfolio::firstOrCreate(
            ['user_id' => $user->id],
            [
                'slug' => $this->uniqueSlug($user->name),
                'title' => $user->name . ' Portfolio',
                'description' => 'A professional portfolio built with Tspace.',
                'theme_settings' => [
                    'accent_color' => '#6366F1',
                    'font_family' => 'Inter',
                    'layout_template' => 'minimal_dark',
                ],
                'seo_settings' => [
                    'title' => $user->name . ' Portfolio',
                    'description' => 'Professional portfolio, projects, and contact details.',
                ],
                'is_published' => false,
            ]
        );

        if ($portfolio->blocks()->count() === 0) {
            Block::insert([
                [
                    'portfolio_id' => $portfolio->id,
                    'type' => 'profile',
                    'title' => 'Profile',
                    'grid_position' => json_encode(['x' => 0, 'y' => 0, 'w' => 2, 'h' => 2]),
                    'content' => json_encode([
                        'name' => $user->name,
                        'title' => $profile->professional_title,
                        'bio' => $profile->bio,
                        'availability' => 'Open for opportunities',
                    ]),
                    'settings' => json_encode([]),
                    'is_visible' => true,
                    'sort_order' => 0,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'portfolio_id' => $portfolio->id,
                    'type' => 'text',
                    'title' => 'About',
                    'grid_position' => json_encode(['x' => 0, 'y' => 2, 'w' => 2, 'h' => 1]),
                    'content' => json_encode([
                        'heading' => 'About me',
                        'body' => 'Add a short, recruiter-friendly summary of your strengths and recent work.',
                    ]),
                    'settings' => json_encode([]),
                    'is_visible' => true,
                    'sort_order' => 1,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);
        }
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

    private function serializeUser(User $user): array
    {
        return [
            'id' => $user->id,
            'email' => $user->email,
            'full_name' => $user->name,
            'avatar_url' => $user->avatar_url,
            'professional_title' => $user->profile?->professional_title,
            'has_completed_onboarding' => $user->has_completed_onboarding,
            'profile' => $user->profile,
            'portfolio' => $user->portfolio,
        ];
    }
}
