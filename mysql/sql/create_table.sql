use mysql;

DROP DATABASE IF EXISTS docker;

CREATE DATABASE IF NOT EXISTS docker;

use docker;

CREATE TABLE IF NOT EXISTS `search_repo` (
  `name` varchar(255) NOT NULL,
  `_namespace` varchar(255) NOT NULL,
  `_repo_name` varchar(255) NOT NULL,
  `is_official` tinyint(1) NOT NULL,
  `is_trusted` tinyint(1) NOT NULL,
  `star_count` int(11) NOT NULL,
  `is_automated` int(11) NOT NULL
);

CREATE TABLE IF NOT EXISTS `list_repo` (
  `_image_name` varchar(255) NOT NULL,
  `namespace` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `star_count` int(11) NOT NULL,
  `pull_count` int(11) NOT NULL,
  `is_automated` tinyint(1) NOT NULL,
  `status` varchar(5) NOT NULL,
  `last_updated` varchar(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS `list_tag` (
  `_image_name` varchar(255) NOT NULL,
  `_namespace` varchar(255) NOT NULL,
  `_repo_name` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `full_size` int(11) NOT NULL,
  `v2` tinyint(1) NOT NULL
);

CREATE TABLE IF NOT EXISTS `stat_layer` (
  `repo` varchar(255) NOT NULL,
  `tag` varchar(255) NOT NULL,
  `layer_count` int(11) NOT NULL
);
