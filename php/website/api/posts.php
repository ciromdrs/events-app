<?php
namespace EventsApp\Posts;

require_once('db.php');

$response = '';
$dbh = \EventsApp\DB::getInstance();
switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        [$is_valid, $current_user] = validateGet();
        if (!$is_valid) {
            http_response_code(400);
            return;
        }

        $results = null;
        $params = ['current_user' => $current_user];
        $where = '';
        if (isset($id)) {
            $results = find($dbh, $id, $params);
        } else {
            if (isset($_GET['event'])) {
                $event = $_GET['event'];
                $where = 'event=:event';
                $params['event'] = $event;
            }
            $results = findAll($dbh, $params, $where);
        }
        $response = json_encode($results);
        break;

    case 'POST':
        [$is_valid, $user, $text, $photo, $event] = validatePost();
        if (!$is_valid) {
            http_response_code(400);
            return;
        }
        insert($dbh, $user, $text, $photo, $event);
        break;
}
print_r($response);


function findAll($dbh, $params = [], $where = '') {
    $qry = "
        SELECT posts.id, posts.user, text, created,
            CONCAT(\"api/uploaded_photos/\",SHA1(image)) as img_url,
            SUM(likes.user = :current_user) as liked_by_current_user,
            COUNT(likes.user) as like_count,
            posts.event
        FROM posts LEFT JOIN likes
        ON posts.id = likes.post";
    if (!empty($where)) {
        $qry .= ' WHERE '.$where;
    }
    $qry .= " GROUP BY posts.id
        ORDER BY created DESC
        LIMIT 10;";

    $sth = $dbh->prepare($qry);
    $sth->execute($params);
    $results = $sth->fetchAll();

    foreach ($results as $i => $r) {
        $r = $results[$i];
        $r['liked_by_current_user'] = $r['liked_by_current_user'] > 0;
        $results[$i] = $r;
    }

    return $results;
}


function find($dbh, $id, $params = [], $where = '') {
    $where_with_id = 'posts.id=:id';
    $params['id'] = $id;
    if (!empty($where)) {
        $where_with_id = $where_with_id.' AND '.$where;
    }
    return findAll($dbh, $params, $where_with_id)[0];
}


function insert($dbh, $user, $text, $photo, $event) {
    $sth = $dbh->prepare('INSERT INTO images () values ();');
    $sth->execute();
    $image = $dbh->lastInsertId();
    $filename = sha1($image);

    move_uploaded_file($photo['tmp_name'], "../uploaded_photos/$filename");

    $qry = 'INSERT INTO posts (user, text, image, event) VALUES (:user, :text, :image, :event);';
    $sth = $dbh->prepare($qry);
    $sth->execute([
        'user' => $user,
        'text' => $text,
        'image' => $image,
        'event' => $event
    ]);
    $lastId = $dbh->lastInsertId();
    http_response_code(201);
    header("Location: posts/$lastId");
}


function validatePost() {
    $invalid = [False, null, null, null, null];

    $pairs = [
        ['user', $_POST],
        ['photo', $_FILES]
    ];
    foreach ($pairs as $_ => $pair) {
        [$key, $data] = $pair;
        if (empty($data[$key])) {
            return $invalid;
        }
    }

    if (!isset($_POST['text'])) {
        return $invalid;
    }

    $user = $_POST['user'];
    $text = $_POST['text'];
    $photo = $_FILES['photo'];
    // TODO: Use FileInfo to check if the image is valid
    // https://www.php.net/manual/en/book.fileinfo.php
    if(!getimagesize($photo['tmp_name'])){
        return $invalid;
    }
    $event = $_POST['event'];

    return [True, $user, $text, $photo, $event];
}

function validateGet() {
    $invalid = [False, null];

    $current_user = $_GET['current_user'];
    if (empty($current_user)) {
        return $invalid;
    }

    // The $id comes from the URL, the $event is optional
    return [True, $current_user];
}
