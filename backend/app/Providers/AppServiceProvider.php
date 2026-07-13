<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Auth;
use Illuminate\Http\Request;
use App\Models\ApiToken;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Auth::viaRequest('custom-token', function (Request $request) {
            $token = $request->bearerToken();
            if (!$token) {
                return null;
            }

            $apiToken = ApiToken::query()
                ->with('user')
                ->where('token_hash', hash('sha256', $token))
                ->where(function ($query) {
                    $query->whereNull('expires_at')
                        ->orWhere('expires_at', '>', now());
                })
                ->first();

            if (!$apiToken) {
                return null;
            }

            $apiToken->forceFill(['last_used_at' => now()])->save();

            return $apiToken->user;
        });
    }
}
