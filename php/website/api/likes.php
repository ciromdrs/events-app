<?php
namespace EventsApp;

require_once('db.php');

$response = "";

switch ($_SERVER['REQUEST_METHOD']) {
    case "POST":
        $user = $_POST["user"];
        $qry = 'INSERT INTO likes (user, post) VALUES (:user, :post);';
        $dbh = \EventsApp\DB::getInstance();
        $sth = $dbh->prepare($qry);
        $sth->execute(['user' => $user, 'post' => $post]);
        http_response_code(201);
        header("Location: likes?user=$user&post=$post");
        break;

    case "DELETE":
        parse_str($_SERVER['QUERY_STRING'], $vars);
        $user = $vars["user"];
        $qry = "DELETE FROM likes WHERE user=:user AND post=:post;";
        $dbh = \EventsApp\DB::getInstance();
        $sth = $dbh->prepare($qry);
        $sth->execute(['user' => $user, 'post' => $post]);
        http_response_code(200);
        break;
}
print_r($response);
