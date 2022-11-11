<?php
use GuzzleHttp\Psr7;

require_once("RESTTestCase.php");

final class PostsTest extends RESTTestCase {
    function __construct() {
        parent::__construct(['base_uri' => 'elm-photo-gallery-site-1/api/']);
    }


    static function setUpBeforeClass(): void {
        // Clear database
        $dbh = new PDO(
            'mysql:host=elm-photo-gallery-db-1;dbname=eventsapp',
            'root',
            'example'
        );
        $qry = 'DELETE FROM likes; DELETE FROM posts; DELETE FROM images;';
        $sth = $dbh->prepare($qry);
        $sth->execute();

        // Clear uploaded photos directory
        $files = glob('html/uploaded_photos/*');
        foreach($files as $file) {
            if(is_file($file)) {
                unlink($file); // delete file
            }
        }
    }


    function testDatabaseStartsEmpty(): void {
        $params = ['query' => ['current_user' => 'user1']];
        $response = $this->client->get('posts', $params);
        $got = (string) $response->getBody();
        $this->assertEquals('[]', $got);
    }


    function testUploadedPhotosDirectoryStartsEmpty(): void {
        $files = glob('html/uploaded_photos/*');
        $this->assertEquals(0, count($files));
    }


    /**
     * @depends testDatabaseStartsEmpty
     * @depends testUploadedPhotosDirectoryStartsEmpty
     */
    function testPostStatusCreated() {
        $user = 'user1';
        $text = 'Hello!';
        $photo = 'tests/sample_data/long-horizontal.png';
        $response = $this->client->post('posts', postMultipart($user, $text, $photo));
        $got = $response->getStatusCode();
        $body = (string) $response->getBody();
        $this->assertEquals(201, $got, $body);
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
    function testInsertedData($post_id) {
        $response = $this->client->get(
            "posts/$post_id",
            ['query' => ['current_user' => 'user1']]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->assertEquals($post_id, $got['id']);
        $this->assertEquals('user1', $got['user']);
        $this->assertEquals('Hello!', $got['text']);
        $this->assertNotEmpty($got['created']);
        $this->assertEquals(false, $got['liked_by_current_user']);
        return $post_id;
    }


    /**
     * @depends testInsertedData
     */
    function testLikeStatusCreated($post_id) {
        $response = $this->client->post(
            "posts/$post_id/likes",
            ['form_params' => [
                'user' => 'user1'
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
            "posts/$post_id",
            ['query' => ['current_user' => 'user1']]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->assertEquals($post_id, $got['id']);
        $this->assertEquals('user1', $got['user']);
        $this->assertEquals('Hello!', $got['text']);
        $this->assertNotEmpty($got['created']);
        $this->assertEquals(true, $got['liked_by_current_user']);
        return $post_id;
    }

    /**
     * @depends testLikedPostData
     */
    function testDislikeStatusOk($post_id) {
        $response = $this->client->delete(
            "posts/$post_id/likes",
            ['query' => ['user' => 'user1']]
        );
        $got = $response->getStatusCode();
        $this->assertEquals(200, $got);
        return $post_id;
    }

    /**
     * @depends testDislikeStatusOk
     */
    function testDislikedPostData($post_id) {
        $response = $this->client->get(
            "posts/$post_id",
            ['query' => ['current_user' => 'user1']]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->assertEquals($post_id, $got['id']);
        $this->assertEquals('user1', $got['user']);
        $this->assertEquals('Hello!', $got['text']);
        $this->assertNotEmpty($got['created']);
        $this->assertEquals(false, $got['liked_by_current_user']);
    }
}


function postMultipart($user, $text, $photo) {
    return [
        'multipart' => [
            [
                'name'     => 'user',
                'contents' => $user,
            ],
            [
                'name'     => 'text',
                'contents' => $text
            ],
            [
                'name'     => 'photo',
                'contents' => Psr7\Utils::tryFopen($photo, 'r'),
            ],
        ]
    ];
}
