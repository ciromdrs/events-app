<?php
namespace EventsApp\Events;

require_once 'db.php';


$response = '';
$dbh = \EventsApp\DB::getInstance();
/* TODO: Move logic to separate class to avoid raising warnings when requiring
   this script due to accessing, for example, $_SERVER['REQUEST_METHOD']. */
switch ($_SERVER['REQUEST_METHOD']) {
    case 'GET':
        [$is_valid, $current_user] = validateGet();
        if (!$is_valid) {
            http_response_code(400);
            return;
        }
        $results = null;
        // TODO: pass in $current_user
        if (isset($id)) {
            $results = find($dbh, $id);
        } else {
            $results = findAll($dbh);
        }
        $response = json_encode($results);
        break;

    case 'POST':
        [$is_valid, $owner, $name] = validatePost();
        if (!$is_valid) {
            http_response_code(400);
            return;
        }
        $last_id = insert($dbh, $owner, $name);
        http_response_code(201);
        header("Location: /api/events/$last_id");
        break;
}
echo $response;


function find($dbh, $id, $where = null, $params = null) {
    $where_with_id = 'id=:id';
    $params['id'] = $id;
    if (!empty($where)) {
        $where_with_id = $where_with_id.' AND '.$where;
    }
    return findAll($dbh, $where_with_id, $params)[0];
}


function findAll($dbh, $where = null, $params = null) {
    $qry = "SELECT * FROM events";
    if (!empty($where)) {
        $qry .= ' WHERE '.$where;
    }
    $qry .= ';';
    $sth = $dbh->prepare($qry);
    $sth->execute($params);
    $results = $sth->fetchAll();
    return $results;
}


function insert($dbh, $owner, $name) {
    $qry = 'INSERT INTO events (owner, name) VALUES (:owner, :name);';
    $sth = $dbh->prepare($qry);
    $sth->execute(['owner' => $owner, 'name' => $name]);
    return $lastId = $dbh->lastInsertId();
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
