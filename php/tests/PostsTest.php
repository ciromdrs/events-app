<?php

require_once("RESTTestCase.php");


final class PostsTest extends RESTTestCase {
    function __construct() {
        parent::__construct(['base_uri' => 'elm-photo-gallery-site-1/api/']);
    }


    function testStartsEmpty(): void {
        $response = $this->client->get('posts');
        $got = (string) $response->getBody();
        $this->assertEquals('[]', $got);
    }
}
