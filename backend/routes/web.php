<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;
use Illuminate\Http\Request;

Route::get('/', function () {
    return view('welcome');
});

// Helper function to return simulated login form
if (!function_exists('makeSimulationForm')) {
function makeSimulationForm($provider, $title, $description, $primaryColor, $btnGradient, Request $request) {
    $redirectOrigin = $request->query('redirect_origin', '');
    if (!$redirectOrigin) {
        $referer = $request->header('Referer', '');
        if ($referer) {
            $parsed = parse_url($referer);
            $redirectOrigin = ($parsed['scheme'] ?? 'http') . '://' . ($parsed['host'] ?? 'localhost') . (isset($parsed['port']) ? ':' . $parsed['port'] : '');
        }
    }
    if (!$redirectOrigin) {
        $redirectOrigin = 'http://localhost:8080'; // fallback
    }

    $providerName = ucfirst($provider);

    return '
        <html>
        <head>
            <title>' . $providerName . ' OAuth Simulation</title>
            <style>
                body { background-color: #0B0F19; color: #F8FAFC; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
                .card { background: rgba(20, 28, 47, 0.7); backdrop-filter: blur(12px); border: 1px solid rgba(255, 255, 255, 0.08); padding: 2.5rem; border-radius: 16px; width: 100%; max-width: 400px; box-shadow: 0 20px 40px rgba(0,0,0,0.5); box-sizing: border-box; }
                .logo-container { display: flex; justify-content: center; margin-bottom: 1.5rem; }
                .logo { width: 64px; height: 64px; border-radius: 16px; background: ' . $primaryColor . '; display: flex; justify-content: center; align-items: center; font-size: 32px; font-weight: bold; box-shadow: 0 0 20px ' . $primaryColor . '4d; }
                h2 { margin: 0 0 0.5rem 0; font-size: 1.6rem; font-weight: 800; text-align: center; letter-spacing: -0.5px; }
                p.desc { color: #94A3B8; margin: 0 0 2rem 0; font-size: 0.95rem; text-align: center; line-height: 1.5; }
                .form-group { margin-bottom: 1.25rem; }
                label { display: block; margin-bottom: 0.5rem; font-size: 0.85rem; font-weight: 600; color: #94A3B8; text-transform: uppercase; letter-spacing: 0.5px; }
                input { width: 100%; padding: 12px 16px; background: rgba(0, 0, 0, 0.25); border: 1px solid rgba(255, 255, 255, 0.08); border-radius: 10px; color: white; font-size: 1rem; transition: border-color 0.2s, box-shadow 0.2s; box-sizing: border-box; }
                input:focus { outline: none; border-color: ' . $primaryColor . '; box-shadow: 0 0 0 3px ' . $primaryColor . '33; }
                button { width: 100%; background: ' . $btnGradient . '; color: white; border: none; padding: 14px; border-radius: 10px; font-size: 1rem; cursor: pointer; font-weight: 700; transition: transform 0.2s, box-shadow 0.2s; margin-top: 1rem; }
                button:hover { transform: translateY(-2px); box-shadow: 0 8px 24px ' . $primaryColor . '66; }
                .footer { text-align: center; margin-top: 1.5rem; font-size: 0.8rem; color: #64748B; }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="logo-container">
                    <div class="logo">' . ($provider === "github" ? "GitHub" : "G") . '</div>
                </div>
                <h2>' . $title . '</h2>
                <p class="desc">' . $description . '</p>
                
                <form action="/oauth/callback-redirect" method="GET">
                    <input type="hidden" name="provider" value="' . $provider . '">
                    <input type="hidden" name="redirect_origin" value="' . htmlspecialchars($redirectOrigin) . '">
                    
                    <div class="form-group">
                        <label for="name">Full Name</label>
                        <input type="text" id="name" name="name" required placeholder="e.g. John Doe" value="' . ($provider === "github" ? "GitHub Developer" : "Google Innovator") . '">
                    </div>
                    
                    <div class="form-group">
                        <label for="email">Email Address</label>
                        <input type="email" id="email" name="email" required placeholder="e.g. john@example.com" value="' . ($provider === "github" ? "developer@github.com" : "innovator@gmail.com") . '">
                    </div>
                    
                    <button type="submit">Authorize & Connect Account</button>
                </form>
                
                <div class="footer">
                    Connecting to Flutter app at ' . htmlspecialchars($redirectOrigin) . '
                </div>
            </div>
        </body>
        </html>
    ';
}
}

Route::get('/oauth/github/simulate', function (Request $request) {
    return makeSimulationForm(
        'github',
        'Authorize GitHub',
        'Allow Tspace Portfolio to connect with your GitHub account to import repositories and verify your identity.',
        '#1F2937',
        'linear-gradient(135deg, #1F2937, #111827)',
        $request
    );
});

Route::get('/oauth/google/simulate', function (Request $request) {
    return makeSimulationForm(
        'google',
        'Sign in with Google',
        'Allow Tspace Portfolio to authenticate you using your Google Identity and customize your portfolio profile.',
        '#EA4335',
        'linear-gradient(135deg, #EA4335, #C5221F)',
        $request
    );
});

Route::get('/oauth/callback-redirect', function (Request $request) {
    $provider = $request->query('provider', 'github');
    $name = $request->query('name', 'OAuth User');
    $email = $request->query('email', 'oauth@tspace.me');
    $redirectOrigin = $request->query('redirect_origin', 'http://localhost:8080');

    // Generate unique code
    $code = 'oauth_' . $provider . '_' . Str::random(24);

    // Save details in cache for 2 minutes to exchange during token endpoint call
    Cache::put("oauth_code:$code", [
        'name' => $name,
        'email' => $email,
        'provider' => $provider,
        'avatar_url' => $provider === 'github' 
            ? 'https://avatars.githubusercontent.com/u/583231?v=4' 
            : 'https://ui-avatars.com/api/?name=' . urlencode($name) . '&background=6366F1&color=fff',
    ], 120);

    // If it's Flutter Web, we can close the popup or redirect.
    // For a cleaner and standard experience, we can use JS postMessage to parent window (if popup)
    // or direct redirect (if full page navigation).
    return '
        <html>
        <head><title>Authorizing...</title></head>
        <body style="background:#0B0F19;color:#F8FAFC;font-family:sans-serif;display:flex;flex-direction:column;justify-content:center;align-items:center;height:100vh;margin:0;">
            <div style="text-align:center;">
                <div style="border: 4px solid rgba(255,255,255,0.1); border-top: 4px solid #6366F1; border-radius: 50%; width: 40px; height: 40px; animation: spin 1s linear infinite; margin: 0 auto 1.5rem auto;"></div>
                <h2 style="font-weight: 700; margin-bottom: 0.5rem;">Authenticating...</h2>
                <p style="color: #94A3B8; font-size: 0.95rem;">Returning to Tspace Portfolio.</p>
            </div>
            <style>
                @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
            </style>
            <script>
                const code = "' . $code . '";
                const redirectOrigin = "' . htmlspecialchars($redirectOrigin) . '";
                
                // Try communicating with opener first if this was a popup
                if (window.opener) {
                    try {
                        window.opener.postMessage({ type: "oauth_callback", code: code, provider: "' . $provider . '" }, redirectOrigin);
                        window.close();
                    } catch (e) {
                        console.error("Failed to postMessage:", e);
                        // Fallback to full page redirect if cross-origin blocked it
                        window.location.href = redirectOrigin + "/#/auth/callback?code=" + code;
                    }
                } else {
                    // Direct redirect for single-page navigations
                    window.location.href = redirectOrigin + "/#/auth/callback?code=" + code;
                }
            </script>
        </body>
        </html>
    ';
});
