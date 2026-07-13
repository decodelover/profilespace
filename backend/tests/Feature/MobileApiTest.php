<?php

namespace Tests\Feature;

use App\Models\Portfolio;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class MobileApiTest extends TestCase
{
    use RefreshDatabase;

    protected bool $seed = true;

    public function test_user_can_register_and_fetch_portfolio_with_bearer_token(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Mobile Tester',
            'email' => 'mobile.tester@example.com',
            'password' => 'password123',
            'professional_title' => 'Flutter Developer',
        ]);

        $response->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'access_token',
                    'refresh_token',
                    'token_type',
                    'expires_in',
                    'user' => ['id', 'email', 'profile', 'portfolio'],
                ],
            ]);

        $token = $response->json('data.access_token');

        $this->withToken($token)
            ->getJson('/api/portfolios/me')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => ['id', 'slug', 'blocks'],
            ]);
    }

    public function test_published_portfolio_accepts_public_messages(): void
    {
        $login = $this->postJson('/api/auth/register', [
            'name' => 'Public Tester',
            'email' => 'public.tester@example.com',
            'password' => 'password123',
        ]);

        $token = $login->json('data.access_token');
        $portfolioId = $login->json('data.user.portfolio.id');

        $this->withToken($token)
            ->putJson('/api/portfolios/me/settings', ['is_published' => true])
            ->assertOk();

        $slug = Portfolio::findOrFail($portfolioId)->fresh()->slug;

        $this->postJson("/api/public/portfolios/$slug/messages", [
            'sender_name' => 'Avery Recruiter',
            'sender_email' => 'avery@example.com',
            'company' => 'Bright Labs',
            'message' => 'Can we talk about a mobile role?',
        ])->assertCreated()
            ->assertJsonPath('success', true);

        $this->withToken($token)
            ->getJson('/api/messages')
            ->assertOk()
            ->assertJsonFragment(['sender_email' => 'avery@example.com']);
    }

    public function test_firebase_sync_creates_user_and_issues_token(): void
    {
        $response = $this->postJson('/api/auth/sync', [
            'email' => 'firebase.synced@example.com',
            'name' => 'Firebase Synced User',
            'uid' => 'fb_synced_123',
            'provider' => 'google.com',
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'data' => [
                    'access_token',
                    'refresh_token',
                    'token_type',
                    'user' => ['id', 'email', 'firebase_uid', 'auth_provider'],
                ],
            ]);

        $this->assertDatabaseHas('users', [
            'email' => 'firebase.synced@example.com',
            'firebase_uid' => 'fb_synced_123',
            'auth_provider' => 'google.com',
        ]);
    }

    public function test_user_onboarding_lifecycle_steps(): void
    {
        $user = \App\Models\User::factory()->create([
            'email' => 'onboard@example.com',
            'name' => 'Onboarding User',
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        // Ensure starter data is set
        $this->postJson('/api/auth/sync', ['email' => 'onboard@example.com']);

        // Step 1: Specialization
        $this->withToken($token)
            ->patchJson('/api/users/me/specialization', ['specialization' => 'developer'])
            ->assertOk()
            ->assertJsonPath('data.specialization', 'developer')
            ->assertJsonPath('data.onboarding_step', 'step2');

        // Step 2: Dynamic profile update
        $this->withToken($token)
            ->putJson('/api/users/me/profile', [
                'bio' => 'Passionate software craftsman.',
                'skills' => ['PHP', 'Dart'],
            ])
            ->assertOk()
            ->assertJsonPath('data.bio', 'Passionate software craftsman.');

        // Step 3: Plan selection
        $this->withToken($token)
            ->patchJson('/api/users/me/plan', ['plan_id' => 'pro'])
            ->assertOk()
            ->assertJsonPath('data.plan_id', 'pro')
            ->assertJsonPath('data.onboarding_step', 'step4');

        // Step 4: Template selection
        $this->withToken($token)
            ->patchJson('/api/users/me/template', ['template_id' => 'minimal_light'])
            ->assertOk();
    }

    public function test_publish_job_lifecycle_queued_to_completed(): void
    {
        Queue::fake();

        $user = \App\Models\User::factory()->create([
            'email' => 'publish@example.com',
            'name' => 'Publisher User',
            'specialization' => 'developer',
        ]);

        // Provision profile & portfolio with slug
        \App\Models\Profile::create([
            'user_id' => $user->id,
            'full_name' => 'Publisher User',
            'professional_title' => 'Engineer',
            'bio' => 'Ready to deploy.',
        ]);

        $portfolio = \App\Models\Portfolio::create([
            'user_id' => $user->id,
            'slug' => 'publisher-site',
            'title' => 'Publisher Site',
            'is_published' => false,
        ]);

        $token = $user->createToken('mobile')->plainTextToken;

        // Trigger publish
        $response = $this->withToken($token)
            ->postJson('/api/publish')
            ->assertStatus(202)
            ->assertJsonPath('success', true)
            ->assertJsonPath('status', 'queued')
            ->assertJsonStructure(['job_id']);

        $jobId = $response->json('job_id');

        // Verify status poll
        $this->withToken($token)
            ->getJson("/api/publish/$jobId/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'queued');

        // Execute background job synchronously to verify processing logic
        $job = new \App\Jobs\GeneratePortfolioSite($jobId, $user->id);
        $job->handle();

        // Verify job complete in database
        $this->withToken($token)
            ->getJson("/api/publish/$jobId/status")
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.progress_percent', 100);

        // Verify site URL
        $this->withToken($token)
            ->getJson('/api/sites/me')
            ->assertOk()
            ->assertJsonStructure(['data' => ['live_url']]);
    }
}
