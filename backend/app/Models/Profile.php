<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Profile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'full_name',
        'professional_title',
        'bio',
        'avatar_url',
        'website_url',
        'resume_url',
        'social_links',
        'skills',
        'location',
        'availability_status',
    ];

    protected function casts(): array
    {
        return [
            'social_links' => 'array',
            'skills' => 'array',
        ];
    }

    /**
     * Get the user that owns the profile.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
