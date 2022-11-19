<?php


$response = '';
switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        $file = '../uploaded_photos/'.$image;
        if (!file_exists($file)) {
            http_response_code(404);
            echo '<h1>Error 404 - Not Found</h1>';
            return;
        }
        $response = file_get_contents($file);
        break;
}
print_r($response);
