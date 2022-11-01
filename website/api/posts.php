<?php
$dbh = new PDO('mysql:host=elm-photo-gallery-db-1;dbname=eventsapp', 'root', 'example');
$response = "";
switch ($_SERVER['REQUEST_METHOD']) {
    case "GET":
        $sth = $dbh->prepare('SELECT * FROM posts ORDER BY created DESC LIMIT 10;');
        $sth->execute();
        $response = json_encode($sth->fetchAll());
        break;

    case "POST":
        $username = $_POST["username"];
        $text = $_POST["text"];
        $qry = 'INSERT INTO posts (user, text) VALUES (:user, :text);';
        $sth = $dbh->prepare($qry);
        $sth->execute(['user' => $username, 'text' => $text]);
        break;
}

print_r($response);
