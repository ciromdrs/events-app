<?php

require_once("RESTTestCase.php");


final class PostsTest extends RESTTestCase {
    function __construct() {
        parent::__construct(['base_uri' => 'elm-photo-gallery-site-1/api/']);
    }


    static function setUpBeforeClass(): void {
        $dbh = new PDO('mysql:host=elm-photo-gallery-db-1;dbname=eventsapp', 'root', 'example');
        $qry = 'DELETE FROM posts;';
        $sth = $dbh->prepare($qry);
        $sth->execute();
    }

    function testStartsEmpty(): void {
        $response = $this->client->get('posts');
        $got = (string) $response->getBody();
        $this->assertEquals('[]', $got);
    }
}
