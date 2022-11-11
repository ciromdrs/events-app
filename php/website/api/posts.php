<?php

require_once('db.php');

$response = '';
switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        $dbh = DB::getInstance();
        $current_user = $_GET['current_user'];
        if (isset($id)) {
            $response = find($dbh, $id, $current_user);
        } else {
            $response = findAll($dbh, $current_user);
        }
        break;

    case 'POST':
        $user = $_POST['user'];
        $text = $_POST['text'];
        $photo = $_FILES['photo'];
        insert($user, $text, $photo);
        break;
}
print_r($response);


function findAll($connection, $current_user) {
    $qry = "
        SELECT id, posts.user, text, created, CONCAT(\"uploaded_photos/\",SHA1(image)) as imgUrl, SUM(likes.user = :current_user) as liked_by_current_user
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
        WHERE posts.id=:id
        GROUP BY posts.id;";
    $sth = $connection->prepare($qry);
    $sth->execute(['id' => $id, 'current_user' => $current_user]);
    $data = $sth->fetch($mode=PDO::FETCH_ASSOC);
    $data['liked_by_current_user'] = $data['liked_by_current_user'] > 0;
    return json_encode($data);
}


function insert($user, $text, $photo) {
    $dbh = DB::getInstance();
    $sth = $dbh->prepare('INSERT INTO images () values ();');
    $sth->execute();
    $image = $dbh->lastInsertId();
    $filename = sha1($image);
    move_uploaded_file($photo['tmp_name'], "uploaded_photos/$filename");

    $qry = 'INSERT INTO posts (user, text, image) VALUES (:user, :text, :image);';
    $sth = $dbh->prepare($qry);
    $sth->execute(['user' => $user, 'text' => $text, 'image' => $image]);
    $lastId = $dbh->lastInsertId();
    http_response_code(201);
    header("Location: posts/$lastId");
}
