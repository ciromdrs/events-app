<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\EventController;
use App\Http\Controllers\PostController;
use App\Http\Controllers\ImageController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| is assigned the "api" middleware group. Enjoy building your API!
|
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

Route::post('/session', function () {
    return 'my-token-from-laravel';
});

Route::resource('events', EventController::class)
    ->only(['index', 'store'])
    ;//->middleware(['auth', 'verified']);

Route::resource('posts', PostController::class)
    ->only(['index', 'store'])
    ;//->middleware(['auth', 'verified']);


Route::get('uploaded_photos/{filename}', [ImageController::class, 'serve']);//->middleware(['auth', 'verified']);
