<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\PortfolioController;
use App\Http\Controllers\Api\UploadController;

Route::get('/health', fn () => response()->json([
    'success' => true,
    'data' => [
        'service' => 'tspace-api',
        'status' => 'ok',
        'timestamp' => now()->toISOString(),
    ],
]));

Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'loginWithEmail']);
Route::post('/auth/refresh', [AuthController::class, 'refresh']);
Route::post('/auth/github/callback', [AuthController::class, 'loginWithGithub']);
Route::post('/auth/google/callback', [AuthController::class, 'loginWithGoogle']);
Route::post('/auth/email-login', [AuthController::class, 'loginWithEmail']);

Route::get('/public/{slug}', [PortfolioController::class, 'publicShow']);
Route::post('/public/{slug}/events', [PortfolioController::class, 'trackPublicEvent']);
Route::post('/public/portfolios/{slug}/messages', [PortfolioController::class, 'sendMessage']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/logout-all', [AuthController::class, 'logoutAll']);
    Route::get('/auth/me', [AuthController::class, 'me']);

    // Profile and Onboarding Routes
    Route::put('/profile', [PortfolioController::class, 'updateProfile']);
    Route::post('/onboarding/complete', [PortfolioController::class, 'completeOnboarding']);
    Route::get('/portfolios/check-slug', [PortfolioController::class, 'checkSlugAvailability']);

    // Portfolio Management Routes
    Route::get('/portfolios/me', [PortfolioController::class, 'getPortfolio']);
    Route::post('/portfolios/me/blocks', [PortfolioController::class, 'addBlock']);
    Route::put('/portfolios/me/blocks/{id}', [PortfolioController::class, 'updateBlock']);
    Route::put('/portfolios/me/blocks/layout', [PortfolioController::class, 'updateBlockLayout']);
    Route::delete('/portfolios/me/blocks/{id}', [PortfolioController::class, 'deleteBlock']);
    Route::put('/portfolios/me/settings', [PortfolioController::class, 'updateSettings']);
    Route::post('/portfolios/me/domain', [PortfolioController::class, 'upsertDomain']);
    Route::post('/portfolios/me/domain/verify', [PortfolioController::class, 'verifyDomain']);
    Route::delete('/portfolios/me/domain', [PortfolioController::class, 'deleteDomain']);

    // Upload Routes
    Route::post('/upload/image', [UploadController::class, 'uploadImage']);
    Route::post('/upload/resume', [UploadController::class, 'uploadResume']);

    // GitHub Integration Routes
    Route::get('/github/repos', [PortfolioController::class, 'githubRepos']);
    Route::post('/github/import', [PortfolioController::class, 'importGithubRepos']);

    // Analytics Routes
    Route::get('/analytics', [PortfolioController::class, 'analytics']);

    // Recruiter Messages Routes
    Route::get('/messages', [PortfolioController::class, 'messages']);
    Route::put('/messages/{id}', [PortfolioController::class, 'updateMessage']);
    Route::delete('/messages/{id}', [PortfolioController::class, 'deleteMessage']);
});
