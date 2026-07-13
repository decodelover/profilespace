<?php

namespace App\Jobs;

use App\Models\PublishJob;
use App\Models\Site;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class GeneratePortfolioSite implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $jobId;
    protected $userId;

    public function __construct(string $jobId, int $userId)
    {
        $this->jobId = $jobId;
        $this->userId = $userId;
    }

    public function handle(): void
    {
        $publishJob = PublishJob::find($this->jobId);
        if (!$publishJob) {
            Log::error("Publish job {$this->jobId} not found.");
            return;
        }

        try {
            $publishJob->update([
                'status' => 'processing',
                'progress_percent' => 10,
                'started_at' => now(),
            ]);

            // Simulate Step 1: Setting up site assets (25%)
            usleep(1500000); // 1.5s
            $publishJob->update(['progress_percent' => 25]);

            // Simulate Step 2: Applying layout template themes (50%)
            usleep(1500000); // 1.5s
            $publishJob->update(['progress_percent' => 50]);

            // Simulate Step 3: Deploying code to edge nodes (75%)
            usleep(1500000); // 1.5s
            $publishJob->update(['progress_percent' => 75]);

            // Simulate Step 4: Finalizing DNS domain config (100%)
            usleep(1500000); // 1.5s

            $user = User::findOrFail($this->userId);
            $portfolio = $user->portfolio;

            if (!$portfolio) {
                throw new \Exception("User portfolio record not found.");
            }

            // Sync publication attributes
            $portfolio->update([
                'is_published' => true,
                'published_at' => now(),
            ]);

            $user->update([
                'is_published' => true,
                'onboarding_step' => 'completed',
            ]);

            $liveUrl = url("/public/{$portfolio->slug}");

            // Create or update the Site record
            Site::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'live_url' => $liveUrl,
                    'published_at' => now(),
                    'last_updated_at' => now(),
                ]
            );

            $publishJob->update([
                'status' => 'completed',
                'progress_percent' => 100,
                'completed_at' => now(),
            ]);

            Log::info("Publish job {$this->jobId} completed successfully for user {$this->userId}.");
        } catch (\Exception $e) {
            Log::error("Publish job {$this->jobId} failed: " . $e->getMessage());

            $publishJob->update([
                'status' => 'failed',
                'completed_at' => now(),
                'error_message' => $e->getMessage(),
            ]);
        }
    }
}
