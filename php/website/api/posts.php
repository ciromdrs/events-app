<?php

require_once('db.php');

$response = "";
switch ($_SERVER['REQUEST_METHOD']) {
    case "GET":
        $dbh = DB::getInstance();
        $current_user = $_GET['current_user'];
        if (isset($id)) {
            $response = find($dbh, $id, $current_user);
        } else {
            $response = findAll($dbh, $current_user);
        }
        break;

    case "POST":
        $user = $_POST["user"];
        $text = $_POST["text"];
        $qry = 'INSERT INTO posts (user, text) VALUES (:user, :text);';
        $dbh = DB::getInstance();
        $sth = $dbh->prepare($qry);
        $sth->execute(['user' => $user, 'text' => $text]);
        $lastId = $dbh->lastInsertId();
        http_response_code(201);
        header("Location: posts/$lastId");
        break;
}
print_r($response);


function findAll($connection, $current_user) {
    $qry = "
        SELECT posts.*, SUM((likes.user = :current_user)) as liked_by_current_user
        FROM posts LEFT JOIN likes
        ON posts.id = likes.post
        GROUP BY posts.id
        ORDER BY created DESC
        LIMIT 10;";
    $sth = $connection->prepare($qry);
    $sth->execute(['current_user' => $current_user]);
    $results = $sth->fetchAll();
    foreach ($results as $i => $r) {
        $r = $results[$i];
        $r['liked_by_current_user'] = $r['liked_by_current_user'] > 0;
        $results[$i] = $r;
    }
    return json_encode($results);
}


function find($connection, $id, $current_user) {
    $qry = "
        SELECT posts.*, SUM((likes.user = :current_user)) as liked_by_current_user
        FROM posts LEFT JOIN likes
        ON posts.id = likes.post
        WHERE id=:id
        GROUP BY posts.id
        ORDER BY created DESC";
    $sth = $connection->prepare($qry);
    $sth->execute(['id' => $id, 'current_user' => $current_user]);
    $data = $sth->fetch($mode=PDO::FETCH_ASSOC);
    return json_encode($data);
}
