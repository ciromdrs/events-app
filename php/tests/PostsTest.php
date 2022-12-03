<?php
use GuzzleHttp\Psr7;
use EventsApp\Events;

$api_dir = dirname(dirname(__FILE__))."/html/api/";

require_once "RESTTestCase.php";
require_once $api_dir."events.php";
require_once $api_dir.'db.php';

final class PostsTest extends RESTTestCase {
    static $event;

    function __construct() {
        parent::__construct([
            'base_uri' => 'events-app-site-1/api/',
            'http_errors' => false
        ]);
    }


    static function setUpBeforeClass(): void {
        // Clear database
        $dbh = \EventsApp\DB::getInstance();
        $qry = 'DELETE FROM likes; DELETE FROM posts; DELETE FROM images;';
        $sth = $dbh->prepare($qry);
        $sth->execute();
        $sth->closeCursor();

        // Clear uploaded photos directory
        $files = glob('uploaded_photos/*');
        foreach($files as $file) {
            if(is_file($file)) {
                unlink($file); // delete file
            }
        }

        // Populate database
        Events\insert($dbh, 'owner', 'Test Event');
        self::$event = $dbh->lastInsertId();
    }


    function setUp(): void {
        $dbh = \EventsApp\DB::getInstance();

        $this->user = 'user1';
        $this->text = 'Hello!';
        $this->photo = 'tests/sample_data/long-horizontal.png';
        self::$event = Events\findAll(
            $dbh,
            'owner=:owner AND name=:name',
            ['owner' => 'owner', 'name' => 'Test Event']
        )[0]['id'];
    }


    function testDatabaseStartsEmpty(): void {
        $params = ['query' => ['current_user' => $this->user]];
        $response = $this->client->get('posts', $params);
        $got = (string) $response->getBody();
        $this->assertEquals('[]', $got);
    }


    function testUploadedPhotosDirectoryStartsEmpty(): void {
        $this->assertTrue(is_dir('uploaded_photos/'));
        $files = glob('uploaded_photos/*');
        $this->assertEquals(0, count($files));
    }


    /**
     * @depends testDatabaseStartsEmpty
     * @depends testUploadedPhotosDirectoryStartsEmpty
     */
    function testPostStatusCreated() {
        $response = $this->client->post(
            'posts',
            postMultipart($this->user, $this->text, $this->photo, self::$event)
        );
        $got = $response->getStatusCode();
        $body = (string) $response->getBody();
        $this->assertEquals(201, $got);
        return $response;
    }


    /**
     * @depends testPostStatusCreated
     */
    function testLocationHeader($response) {
        $location = $response->getHeader('Location')[0];
        $regex = '/posts\/(?P<id>\d+)/'; // TODO: must start with /\/api\/posts
        $this->assertMatchesRegularExpression($regex, $location);
        preg_match($regex, $location, $matches);
        return $matches['id'];
    }


    /**
     * @depends testLocationHeader
     */
    function testFind($post_id) {
        $response = $this->client->get(
            "posts/$post_id",
            ['query' => ['current_user' => $this->user]]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->testPostData($got, ['id' => $post_id]);

        return $post_id;
    }

    /**
     * Auxiliary function to test posts' retrieved data.
     */
    private function testPostData($got, $replace_expected) {
        $expected = [
            'user' => $this->user,
            'text' => $this->text,
            'photo' => $this->photo,
            'event' => self::$event,
            'liked_by_current_user' => false,
            'like_count' => 0,
        ];
        $expected = array_replace($expected, $replace_expected);

        $this->assertEquals($expected['id'], $got['id']);
        $this->assertEquals($expected['user'], $got['user']);
        $this->assertEquals($expected['text'], $got['text']);
        $this->assertNotEmpty($got['created']);
        $this->assertEquals($expected['liked_by_current_user'], $got['liked_by_current_user']);
        $this->assertEquals($expected['like_count'], $got['like_count']);

        // TODO: Test the image content
        $img_url = $got['img_url'];
        $img_url = substr($img_url, 4); // Remove duplicated 'api/'
        $response = $this->client->get($img_url);
        $body = (string) $response->getBody();
        $this->assertNotEquals(404, $response->getStatusCode(), $img_url);
        $this->assertStringNotContainsString('Not Found', $body);

        $this->assertEquals($expected['event'], $got['event']);
    }


    /**
     * @depends testFind
     */
    function testLikeStatusCreated($post_id) {
        $response = $this->client->post(
            "posts/$post_id/likes",
            ['form_params' => [
                'user' => $this->user
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
            ['query' => ['current_user' => $this->user]]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->testPostData(
            $got,
            [
                'id' => $post_id,
                'liked_by_current_user' => true,
                'like_count' => 1
            ]
        );
        return $post_id;
    }


    /**
     * @depends testLikedPostData
     */
    function testDislikeStatusOk($post_id) {
        $response = $this->client->delete(
            "posts/$post_id/likes",
            ['query' => ['user' => $this->user]]
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
            ['query' => ['current_user' => $this->user]]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->testPostData(
            $got,
            [
                'id' => $post_id,
                'liked_by_current_user' => false,
                'like_count' => 0
            ]
        );
    }


    function testInsertStatus400MissingUser() {
        $data = postMultipart('', $this->text, $this->photo, self::$event);
        unset($data['multipart'][0]);
        $response = $this->client->post('posts', $data);
        $got = $response->getStatusCode();
        $this->assertEquals(400, $got);
    }


    function testInsertStatus400EmptyUser() {
        $response = $this->client->post(
            'posts',
            postMultipart('', $this->text, $this->photo, self::$event)
        );
        $got = $response->getStatusCode();
        $this->assertEquals(400, $got);
    }


    function testInsertStatus400InvalidUser() {
        // TODO: create approprate @dataProvider
        $invalid_user_provider = [
            '',
            // 'invaliduser'
        ];

        foreach ($invalid_user_provider as $i => $invalid_user) {
            $response = $this->client->post(
                'posts',
                postMultipart(
                    $invalid_user,
                    $this->text,
                    $this->photo,
                    self::$event
                )
            );
            $got = $response->getStatusCode();
            $this->assertEquals(400, $got);
        }
    }


    function testInsertStatus400InvalidFile() {
        $photo = 'tests/sample_data/invalid-file.txt';
        $response = $this->client->post(
            'posts',
            postMultipart($this->user, $this->text, $photo, self::$event)
        );
        $got = $response->getStatusCode();
        $this->assertEquals(400, $got);
    }
}


function postMultipart($user, $text, $photo, $event) {
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
            [
                'name'     => 'event',
                'contents' => $event
            ],
        ]
    ];
}
