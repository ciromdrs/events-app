<?php

require_once("RESTTestCase.php");


final class PostsTest extends RESTTestCase {
    function testStartsEmpty(): void {
        $response = $this->client->get("elm-photo-gallery-site-1/api/posts");
        $got = (string) $response->getBody();
        $this->assertEquals("[]", $got);
    }
}
