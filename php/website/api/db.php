<?php
namespace EventsApp;

use \PDO;

class DB {
	protected static $instance;

	public static function getInstance() {
		if(empty(self::$instance)) {
			$connection_info = array(
				"host" => "",
				"port" => "3306",
				"user" => "root",
				"password" => "example",
				"name" => "eventsapp"
            );

			try {
				self::$instance = new \PDO(
                    'mysql:host=events-app-db-1;dbname=eventsapp',
                    'root',
                    'example'
                );
				self::$instance->setAttribute(
                    \PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC
                );
			} catch(\PDOException $error) {
				echo $error->getMessage();
			}
		}

		return self::$instance;
	}
}
