-- ------------------------------------------------------
-- mysqldump -u root -paaa123aa -d docker
-- or
-- docker exec -it hub-mysql bash -c "mysqldump -u root -paaa123aa -d docker"
-- ------------------------------------------------------

-- MySQL dump 10.13  Distrib 5.7.11, for Linux (x86_64)
--
-- Host: localhost    Database: docker
-- ------------------------------------------------------
-- Server version	5.7.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `list_repo`
--

DROP DATABASE IF EXISTS `docker`;
CREATE DATABASE `docker`;

USE `docker`;

DROP TABLE IF EXISTS `list_repo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `list_repo` (
  `_image_name` varchar(255) NOT NULL,
  `namespace` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `star_count` int(11) NOT NULL,
  `pull_count` int(11) NOT NULL,
  `is_automated` tinyint(1) NOT NULL,
  `status` varchar(5) NOT NULL,
  `last_updated` varchar(30) NOT NULL,
  KEY `_image_name` (`_image_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `list_tag`
--

DROP TABLE IF EXISTS `list_tag`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `list_tag` (
  `_image_name` varchar(255) NOT NULL,
  `_namespace` varchar(255) NOT NULL,
  `_repo_name` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `full_size` int(11) NOT NULL,
  `v2` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search_repo`
--

DROP TABLE IF EXISTS `search_repo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `search_repo` (
  `name` varchar(255) NOT NULL,
  `_namespace` varchar(255) NOT NULL,
  `_repo_name` varchar(255) NOT NULL,
  `is_official` tinyint(1) NOT NULL,
  `is_trusted` tinyint(1) NOT NULL,
  `star_count` int(11) NOT NULL,
  `is_automated` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stat_layer`
--

DROP TABLE IF EXISTS `stat_layer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `stat_layer` (
  `repo` varchar(255) NOT NULL,
  `tag` varchar(255) NOT NULL,
  `layer_count` int(11) NOT NULL,
  `layer_size` int(11) NOT NULL,
  KEY `repo` (`repo`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `vw_image_layer`
--

DROP TABLE IF EXISTS `vw_image_layer`;
/*!50001 DROP VIEW IF EXISTS `vw_image_layer`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8;
/*!50001 CREATE VIEW `vw_image_layer` AS SELECT
 1 AS `repo`,
 1 AS `tag`,
 1 AS `layer_count`,
 1 AS `layer_size`,
 1 AS `star_count`,
 1 AS `pull_count`*/;
SET character_set_client = @saved_cs_client;

--
-- Final view structure for view `vw_image_layer`
--

/*!50001 DROP VIEW IF EXISTS `vw_image_layer`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`%` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_image_layer` AS select `l`.`repo` AS `repo`,`l`.`tag` AS `tag`,`l`.`layer_count` AS `layer_count`,`l`.`layer_size` AS `layer_size`,`r`.`star_count` AS `star_count`,`r`.`pull_count` AS `pull_count` from (`list_repo` `r` join `stat_layer` `l`) where (`r`.`_image_name` = `l`.`repo`) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2016-03-22  9:39:59
