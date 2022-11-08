<?php

require_once('db.php');

$response = "";

switch ($_SERVER['REQUEST_METHOD']) {
    case "POST":
        $user = $_POST["user"];
        $post = $_POST["post"];
        $qry = 'INSERT INTO likes (user, post) VALUES (:user, :post);';
        $dbh = DB::getInstance();
        $sth = $dbh->prepare($qry);
        $sth->execute(['user' => $user, 'post' => $post]);
        http_response_code(201);
        header("Location: likes?user=$user&post=$post");
        break;
}
print_r($response);
