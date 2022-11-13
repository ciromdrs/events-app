<?php

$response = '';
switch ($_SERVER['REQUEST_METHOD']) {
    case 'POST':
        // TODO: generate access token and store session
        $response = json_encode("super-secret-token");
        break;
    default:
        http_response_code(405);
}
echo $response;
