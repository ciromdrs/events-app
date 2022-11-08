<?php

require_once("RESTTestCase.php");


final class PostsTest extends RESTTestCase {
    function __construct() {
        parent::__construct(['base_uri' => 'elm-photo-gallery-site-1/api/']);
    }


    static function setUpBeforeClass(): void {
        $dbh = new PDO('mysql:host=elm-photo-gallery-db-1;dbname=eventsapp', 'root', 'example');
        $qry = 'DELETE FROM likes; DELETE FROM posts;';
        $sth = $dbh->prepare($qry);
        $sth->execute();
    }


    function testStartsEmpty(): void {
        $params = ['query' => ['current_user' => 'user1']];
        $response = $this->client->get('posts', $params);
        $got = (string) $response->getBody();
        $this->assertEquals('[]', $got);
    }


    /**
     * @depends testStartsEmpty
     */
    function testPostStatusCreated() {
        $username = 'user1';
        $text = 'Hello!';
        $response = $this->client->post('posts', [
            'form_params' => [
                'user' => $username,
                'text' => $text
            ]]);
        $got = $response->getStatusCode();
        $this->assertEquals(201, $got);
        return $response;
    }


    /**
     * @depends testPostStatusCreated
     */
    function testLocationHeader($response) {
        $location = $response->getHeader('Location')[0];
        $regex = '/posts\/(?P<id>\d+)/';
        $this->assertMatchesRegularExpression($regex, $location);
        preg_match($regex, $location, $matches);
        return $matches['id'];
    }

    /**
     * @depends testLocationHeader
     */
    function testInsertedData($id) {
        $response = $this->client->get(
            'posts/'.$id,
            ['query' => ['current_user' => 'user1']]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->assertEquals($id, $got['id']);
        $this->assertEquals('user1', $got['user']);
        $this->assertEquals('Hello!', $got['text']);
        $this->assertNotEmpty($got['created']);
        $this->assertEquals(false, $got['liked_by_current_user']);
        return $id;
    }


    /**
     * @depends testInsertedData
     */
    function testLikeStatusCreated($post_id) {
        $response = $this->client->post(
            'likes',
            ['form_params' => [
                'user' => 'user1',
                'post' => $post_id
            ]]
        );
        $got = $response->getStatusCode();
        $this->assertEquals(201, $got);
        return $post_id;
    }


    /**
     * @depends testLikeStatusCreated
     */
    function testLikedPostData($post_id) {
        $response = $this->client->get(
            'posts/'.$post_id,
            ['query' => ['current_user' => 'user1']]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->assertEquals($post_id, $got['id']);
        $this->assertEquals('user1', $got['user']);
        $this->assertEquals('Hello!', $got['text']);
        $this->assertNotEmpty($got['created']);
        $this->assertEquals(true, $got['liked_by_current_user']);
    }

}
