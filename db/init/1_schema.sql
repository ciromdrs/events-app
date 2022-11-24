SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;

SET NAMES utf8mb4;


DROP TABLE IF EXISTS `events`;
CREATE TABLE `events` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    `owner` varchar(100) NOT NULL,
    `name` varchar(100) NOT NULL,
PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `images`;
CREATE TABLE `images` (
    `id` int unsigned NOT NULL AUTO_INCREMENT,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `posts`;
CREATE TABLE `posts` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `user` varchar(100) NOT NULL,
  `text` varchar(1000) NOT NULL DEFAULT '',
  `created` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `image` int unsigned NOT NULL,
  `event` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `image` (`image`),
  KEY `event` (`event`),
  CONSTRAINT `posts_ibfk_1` FOREIGN KEY (`image`) REFERENCES `images` (`id`),
  CONSTRAINT `posts_ibfk_2` FOREIGN KEY (`event`) REFERENCES `events` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DROP TABLE IF EXISTS `likes`;
CREATE TABLE `likes` (
  `user` varchar(100) NOT NULL,
  `post` int unsigned NOT NULL,
  KEY `post` (`post`),
  CONSTRAINT `likes_ibfk_1` FOREIGN KEY (`post`) REFERENCES `posts` (`id`),
  PRIMARY KEY (`user`, `post`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
