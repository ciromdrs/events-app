<?php
use GuzzleHttp\Psr7;

$api_dir = dirname(dirname(__FILE__))."/html/api/";

require_once("RESTTestCase.php");
require_once $api_dir.'db.php';

final class EventsTest extends RESTTestCase {
    function __construct() {
        // TODO: Copied from PostsTest. Move from both to parent class.
        parent::__construct([
            'base_uri' => 'events-app-site-1/api/',
            'http_errors' => false
        ]);
    }

    private static function clearDatabase() {
        $dbh = \EventsApp\DB::getInstance();
        $qry = 'DELETE FROM likes; DELETE FROM posts;
            DELETE FROM images; DELETE FROM events;';
        $sth = $dbh->prepare($qry);
        $sth->execute();
        $sth->closeCursor();
    }

    static function setUpBeforeClass(): void {
        self::clearDatabase();
    }

    static function tearDownAfterClass(): void {
        self::clearDatabase();
    }


    function setUp(): void {
        $this->user = 'user1';
        $this->owner = 'owner1';
        $this->name = 'Test Event!';
    }


    function testDatabaseStartsEmpty(): void {
        $params = ['query' => ['current_user' => $this->user]];
        $response = $this->client->get('events', $params);
        $got = (string) $response->getBody();
        $this->assertEquals('[]', $got);
    }


    /**
     * @depends testDatabaseStartsEmpty
     */
    function testStatusCreated() {
        $response = $this->client->post(
            'events',
            multipart($this->owner, $this->name)
        );
        $got = $response->getStatusCode();
        $body = (string) $response->getBody();
        $this->assertEquals(201, $got, $body);
        return $response;
    }


    /**
     * @depends testStatusCreated
     */
    function testLocationHeader($response) {
        $location = $response->getHeader('Location')[0];
        $regex = '/\/api\/events\/(?P<id>\d+)/';
        $this->assertMatchesRegularExpression($regex, $location);
        preg_match($regex, $location, $matches);
        return $matches['id'];
    }

    /**
     * @depends testLocationHeader
     */
    function testFind($event_id) {
        $response = $this->client->get(
            "events/$event_id",
            ['query' => ['current_user' => $this->user]]
        );
        $body = (string) $response->getBody();
        $got = json_decode($body, $associative = true);
        $this->assertEquals($event_id, $got['id']);
        $this->assertEquals($this->owner, $got['owner']);
        $this->assertEquals($this->name, $got['name']);

        return $event_id;
    }
}


function multipart($owner, $name) {
    return [
        'multipart' => [
            [
                'name'     => 'owner',
                'contents' => $owner,
            ],
            [
                'name'     => 'name',
                'contents' => $name
            ]
        ]
    ];
}
