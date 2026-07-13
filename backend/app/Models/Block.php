<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Block extends Model
{
    use HasFactory;

    protected $fillable = [
        'portfolio_id',
        'type',
        'title',
        'grid_position',
        'content',
        'settings',
        'is_visible',
        'sort_order',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'grid_position' => 'array',
            'content' => 'array',
            'settings' => 'array',
            'is_visible' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    /**
     * Get the portfolio that owns the block.
     */
    public function portfolio(): BelongsTo
    {
        return $this->belongsTo(Portfolio::class);
    }
}
