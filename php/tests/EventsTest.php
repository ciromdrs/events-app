<?php
use GuzzleHttp\Psr7;

require_once("RESTTestCase.php");

final class EventsTest extends RESTTestCase {
    function __construct() {
        // TODO: Copied from PostsTest. Move from both to parent class.
        parent::__construct([
            'base_uri' => 'elm-photo-gallery-site-1/api/',
            'http_errors' => false
        ]);
    }


    static function setUpBeforeClass(): void {
        // Clear database
        $dbh = new PDO(
            'mysql:host=elm-photo-gallery-db-1;dbname=eventsapp',
            'root',
            'example'
        );
        $qry = 'DELETE FROM events;';
        $sth = $dbh->prepare($qry);
        $sth->execute();
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
