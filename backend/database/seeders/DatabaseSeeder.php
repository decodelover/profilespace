<?php

namespace Database\Seeders;

use App\Models\AnalyticsEvent;
use App\Models\Block;
use App\Models\ContactMessage;
use App\Models\CustomDomain;
use App\Models\Portfolio;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        // Seed Plans
        \App\Models\Plan::updateOrCreate(
            ['id' => 'free'],
            [
                'name' => 'Free Plan',
                'price' => 0.00,
                'features' => json_encode(['Built-in subdomain', 'Up to 1 project', 'Basic theme']),
                'limits' => json_encode(['projects' => 1, 'custom_domain' => false, 'analytics' => false]),
            ]
        );
        \App\Models\Plan::updateOrCreate(
            ['id' => 'pro'],
            [
                'name' => 'Pro Plan',
                'price' => 8.00,
                'features' => json_encode(['Full custom domain', 'Unlimited projects', 'Page analytics']),
                'limits' => json_encode(['projects' => -1, 'custom_domain' => true, 'analytics' => true]),
            ]
        );
        \App\Models\Plan::updateOrCreate(
            ['id' => 'premium'],
            [
                'name' => 'Premium VIP',
                'price' => 19.00,
                'features' => json_encode(['VIP routing', 'Advanced SEO', 'Priority support']),
                'limits' => json_encode(['projects' => -1, 'custom_domain' => true, 'analytics' => true, 'vip_support' => true]),
            ]
        );

        // Seed Templates
        \App\Models\Template::updateOrCreate(
            ['id' => 'minimal_dark'],
            [
                'name' => 'Minimal Dark',
                'preview_image_url' => 'https://tspace.me/previews/minimal_dark.png',
                'category' => 'Dark',
                'config' => json_encode(['bg' => '#0F172A', 'card' => 'rgba(255,255,255,0.03)']),
            ]
        );
        \App\Models\Template::updateOrCreate(
            ['id' => 'minimal_light'],
            [
                'name' => 'Minimal Light',
                'preview_image_url' => 'https://tspace.me/previews/minimal_light.png',
                'category' => 'Light',
                'config' => json_encode(['bg' => '#F9FAFB', 'card' => '#FFFFFF']),
            ]
        );
        \App\Models\Template::updateOrCreate(
            ['id' => 'bento_creative'],
            [
                'name' => 'Bento Creative',
                'preview_image_url' => 'https://tspace.me/previews/bento_creative.png',
                'category' => 'Artistic',
                'config' => json_encode(['bg' => '#1E1B4B', 'card' => 'rgba(255,255,255,0.02)']),
            ]
        );

        $user = User::updateOrCreate(
            ['email' => 'demo@tspace.me'],
            [
                'name' => 'Tspace Demo',
                'password' => 'password123',
                'has_completed_onboarding' => true,
            ]
        );

        Profile::updateOrCreate(
            ['user_id' => $user->id],
            [
                'full_name' => 'Tspace Demo',
                'professional_title' => 'Full-Stack Mobile Developer',
                'bio' => 'I build polished mobile products, reliable APIs, and portfolio experiences that help teams move faster.',
                'avatar_url' => 'https://ui-avatars.com/api/?name=Tspace+Demo&background=6366F1&color=fff',
                'website_url' => 'https://tspace.me',
                'resume_url' => 'https://tspace.me/resume.pdf',
                'location' => 'Lagos, Nigeria',
                'availability_status' => 'open_for_opportunities',
                'social_links' => [
                    ['label' => 'GitHub', 'url' => 'https://github.com/tspace'],
                    ['label' => 'LinkedIn', 'url' => 'https://linkedin.com/in/tspace'],
                ],
                'skills' => ['Flutter', 'Laravel', 'API Design', 'Product Engineering'],
            ]
        );

        $portfolio = Portfolio::updateOrCreate(
            ['user_id' => $user->id],
            [
                'slug' => 'tspace-demo',
                'title' => 'Tspace Demo Portfolio',
                'description' => 'A polished demo portfolio for recruiters and collaborators.',
                'theme_settings' => [
                    'accent_color' => '#6366F1',
                    'font_family' => 'Inter',
                    'layout_template' => 'minimal_dark',
                ],
                'seo_settings' => [
                    'title' => 'Tspace Demo Portfolio',
                    'description' => 'Projects, experience, and contact details for Tspace Demo.',
                ],
                'is_published' => true,
                'published_at' => now(),
            ]
        );

        $portfolio->blocks()->delete();
        Block::insert([
            [
                'portfolio_id' => $portfolio->id,
                'type' => 'profile',
                'title' => 'Profile',
                'grid_position' => json_encode(['x' => 0, 'y' => 0, 'w' => 2, 'h' => 2]),
                'content' => json_encode([
                    'name' => 'Tspace Demo',
                    'title' => 'Full-Stack Mobile Developer',
                    'bio' => 'Flutter frontend, Laravel backend, and product-minded delivery.',
                    'availability' => 'Open for contract and full-time roles',
                ]),
                'settings' => json_encode([]),
                'is_visible' => true,
                'sort_order' => 0,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'portfolio_id' => $portfolio->id,
                'type' => 'project',
                'title' => 'Tspace Portfolio Builder',
                'grid_position' => json_encode(['x' => 0, 'y' => 2, 'w' => 2, 'h' => 2]),
                'content' => json_encode([
                    'name' => 'Tspace Portfolio Builder',
                    'description' => 'A mobile-first portfolio editor with auth, analytics, inbox, uploads, and public portfolio pages.',
                    'url' => 'https://tspace.me',
                    'stack' => ['Flutter', 'Laravel', 'SQLite'],
                ]),
                'settings' => json_encode(['featured' => true]),
                'is_visible' => true,
                'sort_order' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'portfolio_id' => $portfolio->id,
                'type' => 'text',
                'title' => 'Working Style',
                'grid_position' => json_encode(['x' => 0, 'y' => 4, 'w' => 2, 'h' => 1]),
                'content' => json_encode([
                    'heading' => 'What I bring',
                    'body' => 'Clean APIs, crisp mobile flows, thoughtful data models, and a bias toward shipping usable product.',
                ]),
                'settings' => json_encode([]),
                'is_visible' => true,
                'sort_order' => 2,
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);

        CustomDomain::updateOrCreate(
            ['portfolio_id' => $portfolio->id],
            [
                'hostname' => 'demo.tspace.me',
                'verification_token' => 'tspace-verify=demo',
                'ssl_status' => 'active',
                'dns_status' => 'verified',
                'verified_at' => now(),
            ]
        );

        $portfolio->contactMessages()->delete();
        ContactMessage::create([
            'portfolio_id' => $portfolio->id,
            'sender_name' => 'Avery Recruiter',
            'sender_email' => 'avery@example.com',
            'company' => 'Bright Labs',
            'message' => 'Loved the mobile work. Are you open to a senior Flutter/Laravel role?',
            'tag' => 'recruiter',
        ]);

        $portfolio->analyticsEvents()->delete();
        foreach (range(0, 6) as $daysAgo) {
            AnalyticsEvent::create([
                'portfolio_id' => $portfolio->id,
                'event_type' => 'view',
                'session_id' => 'demo-session-' . $daysAgo,
                'metadata' => ['seeded' => true],
                'ip_country' => $daysAgo % 2 === 0 ? 'Nigeria' : 'United States',
                'device' => $daysAgo % 2 === 0 ? 'mobile' : 'desktop',
                'path' => '/public/tspace-demo',
                'created_at' => now()->subDays($daysAgo),
                'updated_at' => now()->subDays($daysAgo),
            ]);
        }
    }
}
