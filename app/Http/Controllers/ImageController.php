<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;


class ImageController extends Controller
{
    static function serve($filename) {
        $dir = 'uploaded_photos'.DIRECTORY_SEPARATOR;
        $storage = Storage::disk('local');

        if (!$storage->exists($dir.$filename)){
            abort('404');
        }
        return response()->file($storage->path($dir.$filename));
    }
}
