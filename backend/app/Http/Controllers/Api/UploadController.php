<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UploadController extends Controller
{
    /**
     * Upload an image to R2 (or fallback to local public disk).
     */
    public function uploadImage(Request $request): JsonResponse
    {
        $request->validate([
            'image' => 'required|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        $file = $request->file('image');
        $fileName = Str::uuid() . '.' . $file->getClientOriginalExtension();

        // Determine disk (R2 if AWS keys exist, fallback to local public)
        $disk = env('AWS_ACCESS_KEY_ID') ? 's3' : 'public';
        $path = $file->storeAs('images', $fileName, $disk);

        $url = $disk === 's3' 
            ? Storage::disk('s3')->url($path) 
            : asset('storage/' . $path);

        return response()->json([
            'success' => true,
            'data' => [
                'url' => $url,
                'path' => $path,
                'disk' => $disk,
            ]
        ]);
    }

    /**
     * Upload a PDF resume to R2 (or fallback to local public disk).
     */
    public function uploadResume(Request $request): JsonResponse
    {
        $request->validate([
            'resume' => 'required|file|mimes:pdf|max:10240',
        ]);

        $file = $request->file('resume');
        $fileName = Str::uuid() . '.' . $file->getClientOriginalExtension();

        $disk = env('AWS_ACCESS_KEY_ID') ? 's3' : 'public';
        $path = $file->storeAs('resumes', $fileName, $disk);

        $url = $disk === 's3' 
            ? Storage::disk('s3')->url($path) 
            : asset('storage/' . $path);

        return response()->json([
            'success' => true,
            'data' => [
                'url' => $url,
                'path' => $path,
                'disk' => $disk,
            ]
        ]);
    }
}
