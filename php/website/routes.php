<?php

require_once __DIR__.'/router.php';

// ##################################################
// ##################################################
// ##################################################

// Static GET
// In the URL -> http://localhost
// The output -> Index
get('/', 'website/index.html');

get('/static/*', 'website/static/');

get('/api/posts', 'api/posts.php');
get('/api/posts/$id', 'api/posts.php');
post('/api/posts', 'api/posts.php');

post('/api/likes', 'api/likes.php');
