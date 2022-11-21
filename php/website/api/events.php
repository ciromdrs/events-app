<?php

require_once('db.php');

$response = '';
switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        $dbh = DB::getInstance();
        [$is_valid, $current_user] = validateGet();
        if (!$is_valid) {
            http_response_code(400);
            return;
        }
        $results = null;
        $params = []; // TODO: pass in ['current_user' => $current_user];
        if (isset($id)) {
            $params['id'] = $id;
            $results = find($dbh, $params, 'id=:id');
        } else {
            $results = findAll($dbh, $params);
        }
        $response = json_encode($results);
        break;

    case 'POST':
        [$is_valid, $owner, $name] = validatePost();
        if (!$is_valid) {
            http_response_code(400);
            return;
        }
        insert($owner, $name);
        break;
}
echo $response;


function find($connection, $data, $where = null) {
    return findAll($connection, $data, $where)[0];
}


function findAll($connection, $data, $where = null) {
    $qry = "SELECT * FROM events";
    if (!empty($where)) {
        $qry .= ' WHERE '.$where;
    }
    $qry .= ';';
    $sth = $connection->prepare($qry);
    $sth->execute($data);
    $results = $sth->fetchAll();
    return $results;
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


function validatePost() {
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

function validateGet() {
    $invalid = [False, null];

    $current_user = $_GET['current_user'];
    if (empty($current_user)) {
        return $invalid;
    }

    // The $id comes from the URL
    return [True, $current_user];
}
