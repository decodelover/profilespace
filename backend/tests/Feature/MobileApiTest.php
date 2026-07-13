<?php

namespace Tests\Feature;

use App\Models\Portfolio;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class MobileApiTest extends TestCase
{
    use RefreshDatabase;

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
}
