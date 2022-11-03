<?php declare(strict_types=1);
use PHPUnit\Framework\TestCase;

class RESTTestCase extends TestCase {
    var $client;

    function __construct($clientOptions = []) {
        parent::__construct();
        $this->client = new GuzzleHttp\Client($clientOptions);
    }
}
