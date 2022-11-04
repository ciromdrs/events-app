<?php
$dbh = new PDO('mysql:host=elm-photo-gallery-db-1;dbname=eventsapp', 'root', 'example');
$response = "";
switch ($_SERVER['REQUEST_METHOD']) {
    case "GET":
        if (isset($id)) {
            $response = find($dbh, $id);
        } else {
            $response = findAll($dbh);
        }
        break;

    case "POST":
        $username = $_POST["username"];
        $text = $_POST["text"];
        $qry = 'INSERT INTO posts (user, text) VALUES (:user, :text);';
        $sth = $dbh->prepare($qry);
        $sth->execute(['user' => $username, 'text' => $text]);
        $lastId = $dbh->lastInsertId();
        http_response_code(201);
        header("Location: posts/$lastId");
        break;
}
print_r($response);


function findAll($connection) {
    $sth = $connection->prepare('SELECT * FROM posts ORDER BY created DESC LIMIT 10;');
    $sth->execute();
    return json_encode($sth->fetchAll());
}


function find($connection, $id) {
    $sth = $connection->prepare('SELECT * FROM posts WHERE id=:id;');
    $sth->execute(['id' => $id]);
    $data = $sth->fetch($mode=PDO::FETCH_ASSOC);
    return json_encode($data);
}
