<?php

require_once __DIR__.'/router.php';

// ##################################################
// ##################################################
// ##################################################

// Static GET
// In the URL -> http://localhost
// The output -> Index
get('/', 'index.html');

get('/api/hello', 'api/hello.php');

get('/api/posts', 'api/posts.php');
post('/api/posts', 'api/posts.php');