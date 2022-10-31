<?php
$dbh = new PDO('mysql:host=elm-photo-gallery-db-1;dbname=wedding', 'root', 'example');
$sth = $dbh->prepare('SELECT * from posts;') ;
$sth->execute();
$results = $sth->fetchAll();
print_r(json_encode($results));
?>
