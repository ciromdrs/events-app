<?php

require_once('db.php');

$response = '';
switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        $dbh = DB::getInstance();
        if (isset($id)) {
            $response = find($dbh, $id);
        } else {
            $response = findAll($dbh);
        }
        break;

    case 'POST':
        [$is_valid, $owner, $name] = validateInput();
        if (!$is_valid) {
            http_response_code(400);
            return;
        }
        insert($owner, $name);
        break;
}
echo $response;


function find($connection, $id) {
    $qry = "
        SELECT *
        FROM events
        WHERE id=:id;";
    $sth = $connection->prepare($qry);
    $sth->execute(['id' => $id]);
    $results = $sth->fetch();
    return json_encode($results);
}


function findAll($connection) {
    $qry = "
        SELECT *
        FROM events;";
    $sth = $connection->prepare($qry);
    $sth->execute(); // TODO: ['current_user' => $current_user]);
    $results = $sth->fetchAll();
    return json_encode($results);
}


function insert($owner, $name) {
    $dbh = DB::getInstance();
    $qry = 'INSERT INTO events (owner, name) VALUES (:owner, :name);';
    $sth = $dbh->prepare($qry);
    $sth->execute(['owner' => $owner, 'name' => $name]);
    $lastId = $dbh->lastInsertId();
    http_response_code(201);
    header("Location: /api/events/$lastId");
}


function validateInput() {
    $invalid = [False, null, null];

    $pairs = [
        ['owner', $_POST],
        ['name', $_POST]
    ];
    foreach ($pairs as $_ => $pair) {
        [$key, $data] = $pair;
        if (empty($data[$key])) {
            return $invalid;
        }
    }

    $owner = $_POST['owner'];
    $name = $_POST['name'];

    return [True, $owner, $name];
}
