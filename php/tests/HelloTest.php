<?php declare(strict_types=1);
use PHPUnit\Framework\TestCase;

final class HelloTest extends TestCase
{
    public function testHello(): void
    {
        // Initialize Guzzle client
        $client = new GuzzleHttp\Client();

        // Create a POST request
        $response = $client->request('GET', 'elm-photo-gallery-site-1/api/hello');

        // Parse the response object, e.g. read the headers, body, etc.
        $headers = $response->getHeaders();
        $body = $response->getBody();

        // Output headers and body for debugging purposes
        $this->assertEquals($body, "Hello from PHP!");
    }
}
