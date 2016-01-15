CREATE TABLE `list_repo` (
  `_image_name` varchar(255) NOT NULL,
  `namespace` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `star_count` int(11) NOT NULL,
  `pull_count` int(11) NOT NULL,
  `is_automated` tinyint(1) NOT NULL,
  `status` varchar(5) NOT NULL,
  `last_updated` varchar(30) NOT NULL
)
