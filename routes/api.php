<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

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

Route::get('/events', function () {
    return '[{"id":0, "name":"testevent"}]';
});

Route::get('/posts', function () {
    return '[{"id":0, "text":"test post", "img_url":"none", "like_count":0, "liked_by_current_user":false, "created":"dez 4 10:39", "user":"default"}]';
});
