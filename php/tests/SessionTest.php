<?php
use GuzzleHttp\Psr7;

require_once("RESTTestCase.php");

final class SessionTest extends RESTTestCase {
    function __construct() {
        parent::__construct([
            'base_uri' => 'events-app-site-1/api/',
            'http_errors' => false
        ]);
    }


    function testDummyLoginStatusCode(): string {
        $response = $this->client->post(
            'session',
            $body = [
                 'json' => ['user' => 'dummyusr', 'password' => 'dummypwd']
             ]
        );
        $body = (string) $response->getBody();
        $got = $response->getStatusCode();
        $this->assertEquals(200, $got);
        return $body;
    }


    /**
     * @depends testDummyLoginStatusCode
     */
    function testDummyLoginToken($body): void {
        $got = json_decode($body, $associative = True);
        $this->assertEquals("super-secret-token", $got);
    }
}
