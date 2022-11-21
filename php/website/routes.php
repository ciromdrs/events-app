<?php

require_once __DIR__.'/router.php';

get('/api/posts', 'api/posts.php');
get('/api/posts/$id', 'api/posts.php');
post('/api/posts', 'api/posts.php');

post('/api/posts/$post/likes', 'api/likes.php');
delete('/api/posts/$post/likes', 'api/likes.php');

post('/api/session', '/api/session.php');

get('/api/uploaded_photos/$image', 'api/images.php');

get('/api/events', 'api/events.php');
get('/api/events/$id', 'api/events.php');
post('/api/events', 'api/events.php');

any('/404', '404.php');
