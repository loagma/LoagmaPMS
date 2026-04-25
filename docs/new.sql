-- MySQL dump 10.13  Distrib 8.0.45, for Win64 (x86_64)
--
-- Host: gateway01.ap-southeast-1.prod.aws.tidbcloud.com    Database: loagma_new
-- ------------------------------------------------------
-- Server version	8.0.11-TiDB-v7.5.6-serverless

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `Area`
--

DROP TABLE IF EXISTS `Area`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Area` (
  `area_id` int NOT NULL AUTO_INCREMENT,
  `area_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `zone_id` int NOT NULL,
  PRIMARY KEY (`area_id`) /*T![clustered_index] CLUSTERED */,
  KEY `Area_zone_id_fkey` (`zone_id`),
  CONSTRAINT `Area_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone` (`zone_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `AreaAssignment`
--

DROP TABLE IF EXISTS `AreaAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `AreaAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pinCode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `areas` json DEFAULT NULL,
  `businessTypes` json DEFAULT NULL,
  `assignedDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `totalBusinesses` int NOT NULL DEFAULT '0',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `AreaAssignment_salesmanId_idx` (`salesmanId`),
  KEY `AreaAssignment_pinCode_idx` (`pinCode`),
  KEY `AreaAssignment_city_district_idx` (`city`,`district`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `AreaAssignment_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Attendance`
--

DROP TABLE IF EXISTS `Attendance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Attendance` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `date` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `punchInTime` datetime(3) NOT NULL,
  `punchInLatitude` double NOT NULL,
  `punchInLongitude` double NOT NULL,
  `punchInPhoto` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `punchInAddress` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bikeKmStart` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `punchOutTime` datetime(3) DEFAULT NULL,
  `punchOutLatitude` double DEFAULT NULL,
  `punchOutLongitude` double DEFAULT NULL,
  `punchOutPhoto` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `punchOutAddress` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `bikeKmEnd` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `totalWorkHours` double DEFAULT NULL,
  `totalDistanceKm` double DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'active',
  `isLatePunchIn` tinyint(1) NOT NULL DEFAULT '0',
  `lateApprovalId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvalCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isEarlyPunchOut` tinyint(1) NOT NULL DEFAULT '0',
  `earlyPunchOutApprovalId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `earlyPunchOutCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Attendance_employeeId_idx` (`employeeId`),
  KEY `Attendance_date_idx` (`date`),
  KEY `Attendance_status_idx` (`status`),
  KEY `Attendance_punchInTime_idx` (`punchInTime`),
  KEY `Attendance_isLatePunchIn_idx` (`isLatePunchIn`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `BeatCompletion`
--

DROP TABLE IF EXISTS `BeatCompletion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `BeatCompletion` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dailyBeatId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `areaName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountsVisited` int NOT NULL DEFAULT '0',
  `completedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `notes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isVerified` tinyint(1) NOT NULL DEFAULT '0',
  `verifiedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `verifiedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `BeatCompletion_dailyBeatId_idx` (`dailyBeatId`),
  KEY `BeatCompletion_salesmanId_idx` (`salesmanId`),
  KEY `BeatCompletion_completedAt_idx` (`completedAt`),
  KEY `BeatCompletion_areaName_idx` (`areaName`),
  KEY `BeatCompletion_verifiedBy_fkey` (`verifiedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `BeatCompletion_dailyBeatId_fkey` FOREIGN KEY (`dailyBeatId`) REFERENCES `DailyBeatPlan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `BeatCompletion_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `BeatCompletion_verifiedBy_fkey` FOREIGN KEY (`verifiedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `BusinessType`
--

DROP TABLE IF EXISTS `BusinessType`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `BusinessType` (
  `id` varchar(10) NOT NULL,
  `name` varchar(100) NOT NULL,
  `createdAt` timestamp(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `City`
--

DROP TABLE IF EXISTS `City`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `City` (
  `city_id` int NOT NULL AUTO_INCREMENT,
  `city_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `district_id` int NOT NULL,
  PRIMARY KEY (`city_id`) /*T![clustered_index] CLUSTERED */,
  KEY `City_district_id_fkey` (`district_id`),
  CONSTRAINT `City_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District` (`district_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Country`
--

DROP TABLE IF EXISTS `Country`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Country` (
  `country_id` int NOT NULL AUTO_INCREMENT,
  `country_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`country_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `DailyBeatPlan`
--

DROP TABLE IF EXISTS `DailyBeatPlan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `DailyBeatPlan` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `weeklyBeatId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dayOfWeek` int NOT NULL,
  `dayDate` datetime(3) NOT NULL,
  `assignedAreas` json DEFAULT NULL,
  `plannedVisits` int NOT NULL DEFAULT '0',
  `actualVisits` int NOT NULL DEFAULT '0',
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PLANNED',
  `completedAt` datetime(3) DEFAULT NULL,
  `carriedFromDate` datetime(3) DEFAULT NULL,
  `carriedToDate` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `DailyBeatPlan_weeklyBeatId_idx` (`weeklyBeatId`),
  KEY `DailyBeatPlan_dayOfWeek_idx` (`dayOfWeek`),
  KEY `DailyBeatPlan_dayDate_idx` (`dayDate`),
  KEY `DailyBeatPlan_status_idx` (`status`),
  UNIQUE KEY `DailyBeatPlan_weeklyBeatId_dayOfWeek_key` (`weeklyBeatId`,`dayOfWeek`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `DailyBeatPlan_weeklyBeatId_fkey` FOREIGN KEY (`weeklyBeatId`) REFERENCES `WeeklyBeatPlan` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `District`
--

DROP TABLE IF EXISTS `District`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `District` (
  `district_id` int NOT NULL AUTO_INCREMENT,
  `district_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_id` int NOT NULL,
  PRIMARY KEY (`district_id`) /*T![clustered_index] CLUSTERED */,
  KEY `District_region_id_fkey` (`region_id`),
  CONSTRAINT `District_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region` (`region_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EarlyPunchOutApproval`
--

DROP TABLE IF EXISTS `EarlyPunchOutApproval`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `EarlyPunchOutApproval` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attendanceId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requestDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `punchOutDate` datetime(3) NOT NULL,
  `reason` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `adminRemarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvalCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `codeExpiresAt` datetime(3) DEFAULT NULL,
  `codeUsed` tinyint(1) NOT NULL DEFAULT '0',
  `codeUsedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `EarlyPunchOutApproval_employeeId_idx` (`employeeId`),
  KEY `EarlyPunchOutApproval_attendanceId_idx` (`attendanceId`),
  KEY `EarlyPunchOutApproval_status_idx` (`status`),
  KEY `EarlyPunchOutApproval_requestDate_idx` (`requestDate`),
  KEY `EarlyPunchOutApproval_approvalCode_idx` (`approvalCode`),
  KEY `EarlyPunchOutApproval_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `EarlyPunchOutApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EarlyPunchOutApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `EmployeeArea`
--

DROP TABLE IF EXISTS `EmployeeArea`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `EmployeeArea` (
  `area_id` int DEFAULT NULL,
  `city_id` int DEFAULT NULL,
  `country_id` int DEFAULT NULL,
  `district_id` int DEFAULT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `region_id` int DEFAULT NULL,
  `state_id` int DEFAULT NULL,
  `zone_id` int DEFAULT NULL,
  `id` int NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `EmployeeArea_employeeId_key` (`employeeId`),
  KEY `EmployeeArea_area_id_fkey` (`area_id`),
  KEY `EmployeeArea_city_id_fkey` (`city_id`),
  KEY `EmployeeArea_country_id_fkey` (`country_id`),
  KEY `EmployeeArea_district_id_fkey` (`district_id`),
  KEY `EmployeeArea_region_id_fkey` (`region_id`),
  KEY `EmployeeArea_state_id_fkey` (`state_id`),
  KEY `EmployeeArea_zone_id_fkey` (`zone_id`),
  CONSTRAINT `EmployeeArea_area_id_fkey` FOREIGN KEY (`area_id`) REFERENCES `Area` (`area_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City` (`city_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country` (`country_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_district_id_fkey` FOREIGN KEY (`district_id`) REFERENCES `District` (`district_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_region_id_fkey` FOREIGN KEY (`region_id`) REFERENCES `Region` (`region_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State` (`state_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `EmployeeArea_zone_id_fkey` FOREIGN KEY (`zone_id`) REFERENCES `Zone` (`zone_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Expense`
--

DROP TABLE IF EXISTS `Expense`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Expense` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expenseType` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `amount` double NOT NULL,
  `expenseDate` datetime(3) NOT NULL,
  `description` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `billNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `attachmentUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Pending',
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `rejectionReason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `paidAt` datetime(3) DEFAULT NULL,
  `remarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Expense_employeeId_idx` (`employeeId`),
  KEY `Expense_status_idx` (`status`),
  KEY `Expense_expenseDate_idx` (`expenseDate`),
  KEY `Expense_expenseType_idx` (`expenseType`),
  KEY `Expense_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Expense_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Expense_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LatePunchApproval`
--

DROP TABLE IF EXISTS `LatePunchApproval`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LatePunchApproval` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `requestDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `punchInDate` datetime(3) NOT NULL,
  `reason` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `adminRemarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvalCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `codeExpiresAt` datetime(3) DEFAULT NULL,
  `codeUsed` tinyint(1) NOT NULL DEFAULT '0',
  `codeUsedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `LatePunchApproval_employeeId_idx` (`employeeId`),
  KEY `LatePunchApproval_status_idx` (`status`),
  KEY `LatePunchApproval_requestDate_idx` (`requestDate`),
  KEY `LatePunchApproval_approvalCode_idx` (`approvalCode`),
  KEY `LatePunchApproval_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `LatePunchApproval_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `LatePunchApproval_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LeadsAccount_crm`
--

DROP TABLE IF EXISTS `LeadsAccount_crm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LeadsAccount_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountCode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `businessName` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `businessType` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `businessSize` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `personName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contactNumber` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dateOfBirth` datetime(3) DEFAULT NULL,
  `customerStage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `funnelStage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gstNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `panCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ownerImage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `shopImage` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `areaId` int DEFAULT NULL,
  `assignedToId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `assignedDays` json DEFAULT NULL,
  `createdById` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedById` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `isApproved` tinyint(1) NOT NULL DEFAULT '0',
  `verificationNotes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rejectionNotes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  UNIQUE KEY `Account_accountCode_key` (`accountCode`),
  KEY `Account_pincode_idx` (`pincode`),
  KEY `Account_isActive_idx` (`isActive`),
  KEY `Account_customerStage_idx` (`customerStage`),
  KEY `Account_createdAt_idx` (`createdAt`),
  KEY `Account_businessType_idx` (`businessType`),
  KEY `Account_businessSize_idx` (`businessSize`),
  KEY `Account_approvedById_fkey` (`approvedById`),
  KEY `Account_areaId_fkey` (`areaId`),
  KEY `Account_assignedToId_fkey` (`assignedToId`),
  KEY `Account_createdById_fkey` (`createdById`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Account_approvedById_fkey` FOREIGN KEY (`approvedById`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Account_areaId_fkey` FOREIGN KEY (`areaId`) REFERENCES `Area` (`area_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Account_assignedToId_fkey` FOREIGN KEY (`assignedToId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Account_createdById_fkey` FOREIGN KEY (`createdById`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Leave`
--

DROP TABLE IF EXISTS `Leave`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Leave` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `leaveType` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `startDate` datetime(3) NOT NULL,
  `endDate` datetime(3) NOT NULL,
  `numberOfDays` int NOT NULL,
  `reason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `requestedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `rejectionReason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `adminRemarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Leave_employeeId_idx` (`employeeId`),
  KEY `Leave_status_idx` (`status`),
  KEY `Leave_startDate_idx` (`startDate`),
  KEY `Leave_endDate_idx` (`endDate`),
  KEY `Leave_leaveType_idx` (`leaveType`),
  KEY `Leave_requestedAt_idx` (`requestedAt`),
  KEY `Leave_approvedBy_fkey` (`approvedBy`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Leave_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `Leave_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LeaveBalance`
--

DROP TABLE IF EXISTS `LeaveBalance`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LeaveBalance` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `year` int NOT NULL,
  `sickLeaves` int NOT NULL DEFAULT '12',
  `casualLeaves` int NOT NULL DEFAULT '10',
  `earnedLeaves` int NOT NULL DEFAULT '20',
  `usedSickLeaves` int NOT NULL DEFAULT '0',
  `usedCasualLeaves` int NOT NULL DEFAULT '0',
  `usedEarnedLeaves` int NOT NULL DEFAULT '0',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  UNIQUE KEY `LeaveBalance_employeeId_key` (`employeeId`),
  KEY `LeaveBalance_employeeId_idx` (`employeeId`),
  KEY `LeaveBalance_year_idx` (`year`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `LeaveBalance_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LoginUserRoles_crm`
--

DROP TABLE IF EXISTS `LoginUserRoles_crm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LoginUserRoles_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `LoginUser_crm`
--

DROP TABLE IF EXISTS `LoginUser_crm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LoginUser_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contactNumber` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alternativeNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `roleId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `roles` json DEFAULT NULL,
  `departmentId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `otp` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `otpExpiry` datetime(3) DEFAULT NULL,
  `lastLogin` datetime(3) DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `dateOfBirth` datetime(3) DEFAULT NULL,
  `gender` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `preferredLanguages` json DEFAULT NULL,
  `address` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `aadharCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `panCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `workStartTime` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT '09:00:00',
  `workEndTime` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT '18:00:00',
  `latePunchInGraceMinutes` int DEFAULT '45',
  `earlyPunchOutGraceMinutes` int DEFAULT '30',
  UNIQUE KEY `User_employeeCode_key` (`employeeCode`),
  UNIQUE KEY `User_email_key` (`email`),
  UNIQUE KEY `User_contactNumber_key` (`contactNumber`),
  KEY `User_departmentId_fkey` (`departmentId`),
  KEY `User_roleId_fkey` (`roleId`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `User_departmentId_fkey` FOREIGN KEY (`departmentId`) REFERENCES `department_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `User_roleId_fkey` FOREIGN KEY (`roleId`) REFERENCES `LoginUserRoles_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Notification`
--

DROP TABLE IF EXISTS `Notification`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Notification` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `priority` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `targetRole` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `targetUserId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data` json DEFAULT NULL,
  `isRead` tinyint(1) NOT NULL DEFAULT '0',
  `readAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `Notification_targetRole_idx` (`targetRole`),
  KEY `Notification_targetUserId_idx` (`targetUserId`),
  KEY `Notification_type_idx` (`type`),
  KEY `Notification_isRead_idx` (`isRead`),
  KEY `Notification_createdAt_idx` (`createdAt`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `Notification_targetUserId_fkey` FOREIGN KEY (`targetUserId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Region`
--

DROP TABLE IF EXISTS `Region`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Region` (
  `region_id` int NOT NULL AUTO_INCREMENT,
  `region_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state_id` int NOT NULL,
  PRIMARY KEY (`region_id`) /*T![clustered_index] CLUSTERED */,
  KEY `Region_state_id_fkey` (`state_id`),
  CONSTRAINT `Region_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `State` (`state_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SalaryInformation`
--

DROP TABLE IF EXISTS `SalaryInformation`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SalaryInformation` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `basicSalary` double NOT NULL,
  `hra` double DEFAULT '0',
  `travelAllowance` double DEFAULT '0',
  `dailyAllowance` double DEFAULT '0',
  `medicalAllowance` double DEFAULT '0',
  `specialAllowance` double DEFAULT '0',
  `otherAllowances` double DEFAULT '0',
  `providentFund` double DEFAULT '0',
  `professionalTax` double DEFAULT '0',
  `incomeTax` double DEFAULT '0',
  `otherDeductions` double DEFAULT '0',
  `effectiveFrom` datetime(3) NOT NULL,
  `effectiveTo` datetime(3) DEFAULT NULL,
  `currency` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INR',
  `paymentFrequency` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Monthly',
  `bankName` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `accountNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ifscCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `panNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  UNIQUE KEY `SalaryInformation_employeeId_key` (`employeeId`),
  KEY `SalaryInformation_employeeId_idx` (`employeeId`),
  KEY `SalaryInformation_effectiveFrom_idx` (`effectiveFrom`),
  KEY `SalaryInformation_isActive_idx` (`isActive`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `SalaryInformation_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `SalesmanTrackingPoint`
--

DROP TABLE IF EXISTS `SalesmanTrackingPoint`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `SalesmanTrackingPoint` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `clientPointId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `employeeId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attendanceId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `latitude` double NOT NULL,
  `longitude` double NOT NULL,
  `speed` double DEFAULT NULL,
  `accuracy` double DEFAULT NULL,
  `recordedAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY `SalesmanTrackingPoint_clientPointId_key` (`clientPointId`),
  KEY `SalesmanTrackingPoint_employeeId_idx` (`employeeId`),
  KEY `SalesmanTrackingPoint_attendanceId_idx` (`attendanceId`),
  KEY `SalesmanTrackingPoint_recordedAt_idx` (`recordedAt`),
  KEY `SalesmanTrackingPoint_employeeId_attendanceId_recordedAt_idx` (`employeeId`,`attendanceId`,`recordedAt`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `SalesmanTrackingPoint_attendanceId_fkey` FOREIGN KEY (`attendanceId`) REFERENCES `Attendance` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `SalesmanTrackingPoint_employeeId_fkey` FOREIGN KEY (`employeeId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `State`
--

DROP TABLE IF EXISTS `State`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `State` (
  `state_id` int NOT NULL AUTO_INCREMENT,
  `state_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country_id` int NOT NULL,
  PRIMARY KEY (`state_id`) /*T![clustered_index] CLUSTERED */,
  KEY `State_country_id_fkey` (`country_id`),
  CONSTRAINT `State_country_id_fkey` FOREIGN KEY (`country_id`) REFERENCES `Country` (`country_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TaskAssignment`
--

DROP TABLE IF EXISTS `TaskAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TaskAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `areas` json DEFAULT NULL,
  `businessTypes` json DEFAULT NULL,
  `totalBusinesses` int DEFAULT '0',
  `assignedDate` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `TaskAssignment_salesmanId_idx` (`salesmanId`),
  KEY `TaskAssignment_pincode_idx` (`pincode`),
  KEY `TaskAssignment_assignedDate_idx` (`assignedDate`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TelecallerCallLog`
--

DROP TABLE IF EXISTS `TelecallerCallLog`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TelecallerCallLog` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telecallerId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `calledAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `durationSec` int DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recordingUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nextFollowupAt` datetime(3) DEFAULT NULL,
  `followupNotes` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  KEY `TelecallerCallLog_telecallerId_calledAt_idx` (`telecallerId`,`calledAt`),
  KEY `TelecallerCallLog_accountId_calledAt_idx` (`accountId`,`calledAt`),
  KEY `TelecallerCallLog_nextFollowupAt_idx` (`nextFollowupAt`),
  KEY `TelecallerCallLog_status_idx` (`status`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `TelecallerCallLog_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `LeadsAccount_crm` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `TelecallerCallLog_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `TelecallerPincodeAssignment`
--

DROP TABLE IF EXISTS `TelecallerPincodeAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `TelecallerPincodeAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `telecallerId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dayOfWeek` int NOT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `TelecallerPincodeAssignment_telecallerId_idx` (`telecallerId`),
  KEY `TelecallerPincodeAssignment_pincode_dayOfWeek_idx` (`pincode`,`dayOfWeek`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `TelecallerPincodeAssignment_telecallerId_fkey` FOREIGN KEY (`telecallerId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WeeklyAccountAssignment`
--

DROP TABLE IF EXISTS `WeeklyAccountAssignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `WeeklyAccountAssignment` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `accountId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pincode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `weekStartDate` datetime(3) NOT NULL,
  `assignedDays` json NOT NULL,
  `visitFrequency` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `isManualOverride` tinyint(1) NOT NULL DEFAULT '0',
  `sequenceNo` int NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `overriddenAt` datetime(3) DEFAULT NULL,
  `overrideBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `overrideReason` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `plannedAt` datetime(3) DEFAULT NULL,
  `plannedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recurrenceAfterDays` int DEFAULT NULL,
  `recurrenceStartDate` datetime(3) DEFAULT NULL,
  `recurrenceNextDate` datetime(3) DEFAULT NULL,
  KEY `WeeklyAccountAssignment_salesmanId_weekStartDate_idx` (`salesmanId`,`weekStartDate`),
  KEY `WeeklyAccountAssignment_pincode_weekStartDate_idx` (`pincode`,`weekStartDate`),
  KEY `WeeklyAccountAssignment_salesmanId_pincode_weekStartDate_seq_idx` (`salesmanId`,`pincode`,`weekStartDate`,`sequenceNo`),
  UNIQUE KEY `WeeklyAccountAssignment_accountId_weekStartDate_key` (`accountId`,`weekStartDate`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `WeeklyAccountAssignment_salesmanId_recurrenceNextDate_idx` (`salesmanId`,`recurrenceNextDate`),
  CONSTRAINT `WeeklyAccountAssignment_accountId_fkey` FOREIGN KEY (`accountId`) REFERENCES `LeadsAccount_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `WeeklyBeatPlan`
--

DROP TABLE IF EXISTS `WeeklyBeatPlan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `WeeklyBeatPlan` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `salesmanName` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `weekStartDate` datetime(3) NOT NULL,
  `weekEndDate` datetime(3) NOT NULL,
  `pincodes` json DEFAULT NULL,
  `totalAreas` int NOT NULL DEFAULT '0',
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `generatedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approvedAt` datetime(3) DEFAULT NULL,
  `lockedBy` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lockedAt` datetime(3) DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  KEY `WeeklyBeatPlan_salesmanId_idx` (`salesmanId`),
  KEY `WeeklyBeatPlan_weekStartDate_idx` (`weekStartDate`),
  KEY `WeeklyBeatPlan_status_idx` (`status`),
  KEY `WeeklyBeatPlan_generatedBy_idx` (`generatedBy`),
  KEY `WeeklyBeatPlan_approvedBy_fkey` (`approvedBy`),
  KEY `WeeklyBeatPlan_lockedBy_fkey` (`lockedBy`),
  UNIQUE KEY `WeeklyBeatPlan_salesmanId_weekStartDate_key` (`salesmanId`,`weekStartDate`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  CONSTRAINT `WeeklyBeatPlan_approvedBy_fkey` FOREIGN KEY (`approvedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `WeeklyBeatPlan_generatedBy_fkey` FOREIGN KEY (`generatedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `WeeklyBeatPlan_lockedBy_fkey` FOREIGN KEY (`lockedBy`) REFERENCES `LoginUser_crm` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `WeeklyBeatPlan_salesmanId_fkey` FOREIGN KEY (`salesmanId`) REFERENCES `LoginUser_crm` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `Zone`
--

DROP TABLE IF EXISTS `Zone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Zone` (
  `zone_id` int NOT NULL AUTO_INCREMENT,
  `zone_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city_id` int NOT NULL,
  PRIMARY KEY (`zone_id`) /*T![clustered_index] CLUSTERED */,
  KEY `Zone_city_id_fkey` (`city_id`),
  CONSTRAINT `Zone_city_id_fkey` FOREIGN KEY (`city_id`) REFERENCES `City` (`city_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `_prisma_migrations`
--

DROP TABLE IF EXISTS `_prisma_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_prisma_migrations` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checksum` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `finished_at` datetime(3) DEFAULT NULL,
  `migration_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logs` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `rolled_back_at` datetime(3) DEFAULT NULL,
  `started_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `applied_steps_count` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `admin`
--

DROP TABLE IF EXISTS `admin`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `admin` (
  `userid` int unsigned NOT NULL AUTO_INCREMENT,
  `session_id` varchar(250) DEFAULT '',
  `username` varchar(250) NOT NULL,
  `name` text NOT NULL,
  `password` varchar(60) NOT NULL,
  `type` varchar(250) NOT NULL DEFAULT '',
  `register_date` int unsigned NOT NULL DEFAULT '0',
  `last_activity` int unsigned NOT NULL DEFAULT '0',
  `data` text DEFAULT NULL,
  `delivery_manage_by` varchar(255) NOT NULL DEFAULT 'SuperAdmin',
  `org_name` varchar(255) DEFAULT NULL,
  `org_email` varchar(255) DEFAULT NULL,
  `org_contact_no` varchar(255) DEFAULT NULL,
  `org_gst` varchar(255) DEFAULT NULL,
  `org_address` text NOT NULL,
  `category_id` text DEFAULT NULL,
  `city_id` varchar(255) DEFAULT NULL,
  `areas` text DEFAULT NULL,
  `web_token` text DEFAULT NULL,
  `commission` int DEFAULT NULL,
  PRIMARY KEY (`userid`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin AUTO_INCREMENT=30126;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bom_items`
--

DROP TABLE IF EXISTS `bom_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bom_items` (
  `bom_item_id` bigint NOT NULL AUTO_INCREMENT,
  `bom_id` bigint unsigned NOT NULL,
  `raw_material_id` bigint unsigned NOT NULL,
  `quantity_per_unit` decimal(10,3) NOT NULL,
  `unit_type` varchar(20) COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `wastage_percent` decimal(5,2) DEFAULT '0.00',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`bom_item_id`) /*T![clustered_index] CLUSTERED */,
  KEY `fk_bom_items_bom` (`bom_id`),
  CONSTRAINT `fk_bom_items_bom` FOREIGN KEY (`bom_id`) REFERENCES `bom_master` (`bom_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AUTO_INCREMENT=30009;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bom_master`
--

DROP TABLE IF EXISTS `bom_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bom_master` (
  `bom_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint unsigned NOT NULL,
  `bom_version` varchar(20) COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `status` enum('DRAFT','APPROVED','LOCKED') COLLATE utf8mb4_0900_ai_ci DEFAULT 'DRAFT',
  `remarks` text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `created_by` bigint DEFAULT NULL,
  `approved_by` bigint DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`bom_id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `uk_product_version` (`product_id`,`bom_version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AUTO_INCREMENT=30004;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `brand`
--

DROP TABLE IF EXISTS `brand`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `brand` (
  `brand_id` int unsigned NOT NULL AUTO_INCREMENT,
  `name` text NOT NULL,
  PRIMARY KEY (`brand_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache`
--

DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `value` mediumtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`) /*T![clustered_index] CLUSTERED */,
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cache_locks`
--

DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expiration` int NOT NULL,
  PRIMARY KEY (`key`) /*T![clustered_index] CLUSTERED */,
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `calling_staff`
--

DROP TABLE IF EXISTS `calling_staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `calling_staff` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(20) NOT NULL,
  `contact_no` varchar(11) NOT NULL,
  `type` varchar(30) NOT NULL COMMENT 'tele-marketer, converter, Cold caller, etc',
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `unique_contactNumber` (`contact_no`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin AUTO_INCREMENT=30029;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cart`
--

DROP TABLE IF EXISTS `cart`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart` (
  `cart_id` int NOT NULL AUTO_INCREMENT,
  `userid` bigint NOT NULL,
  `addressId` int NOT NULL,
  `product_id` bigint NOT NULL,
  `vendor_product_id` int NOT NULL DEFAULT '0',
  `pack_id` varchar(255) NOT NULL,
  `quantity` smallint unsigned NOT NULL DEFAULT '0',
  `total` decimal(10,2) NOT NULL DEFAULT '0.00',
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`cart_id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `unique_user_product_pack_address` (`userid`,`product_id`,`pack_id`,`addressId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `cart_type`
--

DROP TABLE IF EXISTS `cart_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cart_type` (
  `cart_tid` bigint unsigned NOT NULL AUTO_INCREMENT,
  `type_name` text NOT NULL,
  `ctype_id` text NOT NULL,
  `is_used` tinyint unsigned NOT NULL DEFAULT '0',
  `has_express` tinyint unsigned NOT NULL DEFAULT '0',
  `express_charge` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `min_total` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `delivery_charge` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `note` text NOT NULL,
  PRIMARY KEY (`cart_tid`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin AUTO_INCREMENT=30006;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categories` (
  `cat_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(250) NOT NULL,
  `parent_cat_id` int unsigned NOT NULL,
  `is_active` tinyint unsigned NOT NULL DEFAULT '0',
  `type` tinyint NOT NULL DEFAULT '0' COMMENT '0:Has_subcategories, 1: Has_products',
  `image_slug` varchar(15) DEFAULT ' ',
  `image_name` text DEFAULT NULL,
  `img_last_updated` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`cat_id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_category_name` (`name`),
  KEY `idx_parent_cat_id` (`parent_cat_id`),
  KEY `idx_category_is_active` (`is_active`),
  KEY `idx_parent_active` (`parent_cat_id`,`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin AUTO_INCREMENT=357999;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `daily_book_stock`
--

DROP TABLE IF EXISTS `daily_book_stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `daily_book_stock` (
  `id` int NOT NULL AUTO_INCREMENT,
  `vendor_product_id` int NOT NULL,
  `date` date NOT NULL,
  `closing_stock` decimal(10,2) NOT NULL DEFAULT '0.00',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `unique_product_date` (`vendor_product_id`,`date`),
  KEY `idx_product_date` (`vendor_product_id`,`date`),
  KEY `idx_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `deli_staff`
--

DROP TABLE IF EXISTS `deli_staff`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deli_staff` (
  `deli_id` int unsigned NOT NULL AUTO_INCREMENT,
  `admin_id` int unsigned NOT NULL DEFAULT '0',
  `role` varchar(20) NOT NULL DEFAULT 'driver',
  `name` text NOT NULL,
  `mobile` varchar(20) NOT NULL,
  `password` varchar(250) DEFAULT NULL,
  `sess_id` varchar(250) DEFAULT NULL,
  `lat` double(10,8) DEFAULT NULL,
  `lng` double(11,8) DEFAULT NULL,
  `location_last_updated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_locked` tinyint unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`deli_id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `mobile` (`mobile`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin AUTO_INCREMENT=30243;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `department_crm`
--

DROP TABLE IF EXISTS `department_crm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `department_crm` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  UNIQUE KEY `Department_name_key` (`name`),
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `driver_accountability_log`
--

DROP TABLE IF EXISTS `driver_accountability_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `driver_accountability_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `driver_deli_id` int NOT NULL COMMENT 'References deli_staff.deli_id (the driver being held accountable)',
  `trip_id` int NOT NULL,
  `audit_log_id` int NOT NULL,
  `item_id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `product_id` int NOT NULL,
  `loss_type` enum('theft','lost','damaged','unreturned','other') COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_lost` decimal(10,2) NOT NULL,
  `unit_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `monetary_value` decimal(10,2) NOT NULL,
  `penalty_status` enum('pending','applied','waived','disputed') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `penalty_applied_at` datetime DEFAULT NULL,
  `penalty_applied_by` int DEFAULT NULL,
  `loss_notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resolution_notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_driver` (`driver_deli_id`),
  KEY `idx_trip` (`trip_id`),
  KEY `idx_audit_log` (`audit_log_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30013;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `driver_rating`
--

DROP TABLE IF EXISTS `driver_rating`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `driver_rating` (
  `rating_id` int NOT NULL AUTO_INCREMENT,
  `order_id` bigint NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `rating` int NOT NULL,
  `review_text` text DEFAULT NULL,
  `review_type` enum('delivered','cancelled') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `rating_id` (`rating_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin AUTO_INCREMENT=33654;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `failed_jobs`
--

DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `connection` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `queue` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `exception` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `hsn_codes`
--

DROP TABLE IF EXISTS `hsn_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hsn_codes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `hsn_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_hsn_code` (`hsn_code`),
  KEY `idx_hsn_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=240216;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inventory_op`
--

DROP TABLE IF EXISTS `inventory_op`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_op` (
  `op_id` int unsigned NOT NULL,
  `product_id` int unsigned NOT NULL DEFAULT '0',
  `op_type` varchar(255) COLLATE utf8_unicode_ci NOT NULL DEFAULT 'inbound' COMMENT 'purchase, sale, damage, expire, free',
  `quantity` decimal(10,2) NOT NULL DEFAULT '0.00',
  `unit_type` text COLLATE utf8_unicode_ci DEFAULT NULL,
  `unitquantity` decimal(10,2) NOT NULL DEFAULT '0.00',
  `amount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `op_date` date NOT NULL,
  `note` text COLLATE utf8_unicode_ci NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`op_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `issue_to_production`
--

DROP TABLE IF EXISTS `issue_to_production`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `issue_to_production` (
  `issue_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `status` enum('DRAFT','ISSUED','COMPLETED','CANCELLED') COLLATE utf8mb4_0900_ai_ci DEFAULT 'DRAFT',
  `remarks` text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `issued_by` bigint DEFAULT NULL,
  `issued_at` datetime DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`issue_id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_issue_status` (`status`),
  KEY `idx_issue_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AUTO_INCREMENT=30008;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `issue_to_production_items`
--

DROP TABLE IF EXISTS `issue_to_production_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `issue_to_production_items` (
  `issue_item_id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `issue_id` bigint unsigned NOT NULL,
  `raw_material_id` bigint unsigned NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `unit_type` varchar(20) COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`issue_item_id`) /*T![clustered_index] CLUSTERED */,
  KEY `fk_issue_items_issue` (`issue_id`),
  KEY `fk_issue_items_material` (`raw_material_id`),
  CONSTRAINT `fk_issue_items_issue` FOREIGN KEY (`issue_id`) REFERENCES `issue_to_production` (`issue_id`),
  CONSTRAINT `fk_issue_items_material` FOREIGN KEY (`raw_material_id`) REFERENCES `product_old` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AUTO_INCREMENT=30012;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `job_batches`
--

DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_jobs` int NOT NULL,
  `pending_jobs` int NOT NULL,
  `failed_jobs` int NOT NULL,
  `failed_job_ids` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `options` mediumtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cancelled_at` int DEFAULT NULL,
  `created_at` int NOT NULL,
  `finished_at` int DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `jobs`
--

DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `attempts` tinyint unsigned NOT NULL,
  `reserved_at` int unsigned DEFAULT NULL,
  `available_at` int unsigned NOT NULL,
  `created_at` int unsigned NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `master_orders`
--

DROP TABLE IF EXISTS `master_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `master_orders` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `txn_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `payment_status` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `order_count` int NOT NULL,
  `payment_method` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `delivery_info` text COLLATE utf8mb4_general_ci NOT NULL,
  `order_total` float(10,2) NOT NULL,
  `delivery_charge` float(10,2) NOT NULL,
  `discount` float(10,2) NOT NULL,
  `before_discount` float(10,2) NOT NULL,
  `status` enum('1','0') COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `master_orders_old`
--

DROP TABLE IF EXISTS `master_orders_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `master_orders_old` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `txn_id` varchar(255) NOT NULL,
  `payment_status` varchar(255) NOT NULL,
  `order_count` int NOT NULL,
  `payment_method` varchar(255) NOT NULL,
  `delivery_info` text NOT NULL,
  `order_total` float(10,2) NOT NULL,
  `delivery_charge` float(10,2) NOT NULL,
  `discount` float(10,2) NOT NULL,
  `before_discount` float(10,2) NOT NULL,
  `status` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin AUTO_INCREMENT=248424;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `migrations`
--

DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `batch` int NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=953353;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `offer_log`
--

DROP TABLE IF EXISTS `offer_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offer_log` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `order_id` int NOT NULL,
  `offer_id` int NOT NULL,
  `used_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_user_offer_date` (`user_id`,`offer_id`,`used_date`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `offers`
--

DROP TABLE IF EXISTS `offers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `offers` (
  `off_id` bigint NOT NULL,
  `name` text DEFAULT NULL,
  `off_type` varchar(250) NOT NULL DEFAULT ' ',
  `product_id` bigint DEFAULT '0' COMMENT 'vendorProductId',
  `off_data` text DEFAULT NULL,
  `is_active` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`off_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `order_zone_overrides`
--

DROP TABLE IF EXISTS `order_zone_overrides`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_zone_overrides` (
  `order_id` bigint NOT NULL,
  `zone_id` int NOT NULL,
  `source_zone_id` int DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders` (
  `order_id` bigint unsigned NOT NULL,
  `bill_number` int DEFAULT NULL,
  `master_order_id` int NOT NULL DEFAULT '0',
  `txn_id` varchar(250) COLLATE utf8mb4_general_ci NOT NULL,
  `buyer_userid` bigint unsigned NOT NULL,
  `start_time` int unsigned NOT NULL DEFAULT '0',
  `last_update_time` int unsigned NOT NULL DEFAULT '0',
  `short_datetime` text COLLATE utf8mb4_general_ci NOT NULL,
  `order_state` varchar(250) COLLATE utf8mb4_general_ci NOT NULL,
  `payment_method` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'cod',
  `ctype_id` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'vegetables_fruits',
  `items_count` int unsigned NOT NULL DEFAULT '0',
  `delivery_charge` decimal(10,0) NOT NULL DEFAULT '0',
  `order_total` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `bill_amount` int DEFAULT NULL,
  `delivery_info` text COLLATE utf8mb4_general_ci NOT NULL,
  `area_name` text COLLATE utf8mb4_general_ci NOT NULL,
  `feedback` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `admin_id` bigint unsigned NOT NULL DEFAULT '0',
  `payment_status` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'not_paid',
  `amountReceivedInfo` longtext COLLATE utf8mb4_bin DEFAULT NULL,
  `trip_id` int DEFAULT NULL,
  `discount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `before_discount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `time_slot` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'Now',
  `delivered_time` int DEFAULT NULL,
  `deli_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_item`
--

DROP TABLE IF EXISTS `orders_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_item` (
  `order_id` bigint unsigned NOT NULL DEFAULT '0',
  `item_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `vendor_product_id` int DEFAULT NULL,
  `pinfo` text COLLATE utf8mb4_general_ci NOT NULL,
  `offers` text COLLATE utf8mb4_general_ci DEFAULT NULL,
  `quantity` mediumint unsigned NOT NULL DEFAULT '0',
  `qty_loaded` int DEFAULT NULL,
  `qty_delivered` int DEFAULT NULL,
  `qty_returned` int DEFAULT NULL,
  `item_price` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `item_total` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `op_id` bigint DEFAULT '0',
  `commission` double(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_item_old`
--

DROP TABLE IF EXISTS `orders_item_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_item_old` (
  `order_id` bigint unsigned NOT NULL DEFAULT '0',
  `item_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `vendor_product_id` int DEFAULT NULL,
  `pinfo` text NOT NULL,
  `offers` text DEFAULT NULL,
  `quantity` mediumint unsigned NOT NULL DEFAULT '0',
  `qty_loaded` int DEFAULT NULL,
  `qty_delivered` int DEFAULT NULL,
  `qty_returned` int DEFAULT NULL,
  `item_price` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `item_total` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `op_id` bigint DEFAULT '0',
  `commission` double(10,2) NOT NULL,
  PRIMARY KEY (`item_id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_orders_item_product_id` (`product_id`),
  KEY `idx_orders_item_order_id` (`order_id`),
  KEY `idx_orders_item_product_order` (`product_id`,`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `orders_old`
--

DROP TABLE IF EXISTS `orders_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `orders_old` (
  `order_id` bigint unsigned NOT NULL,
  `bill_number` int DEFAULT NULL,
  `master_order_id` int NOT NULL DEFAULT '0',
  `txn_id` varchar(250) NOT NULL,
  `buyer_userid` bigint unsigned NOT NULL,
  `start_time` int unsigned NOT NULL DEFAULT '0',
  `last_update_time` int unsigned NOT NULL DEFAULT '0',
  `short_datetime` text NOT NULL,
  `order_state` varchar(250) NOT NULL,
  `payment_method` varchar(250) NOT NULL DEFAULT 'cod',
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `items_count` int unsigned NOT NULL DEFAULT '0',
  `delivery_charge` decimal(10,0) NOT NULL DEFAULT '0',
  `order_total` decimal(12,2) unsigned NOT NULL DEFAULT '0.00',
  `bill_amount` int DEFAULT NULL,
  `delivery_info` text NOT NULL,
  `area_name` text NOT NULL,
  `feedback` varchar(100) NOT NULL,
  `admin_id` bigint unsigned NOT NULL DEFAULT '0',
  `payment_status` varchar(250) NOT NULL DEFAULT 'not_paid',
  `amountReceivedInfo` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `trip_id` int DEFAULT NULL,
  `discount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `before_discount` decimal(10,2) NOT NULL DEFAULT '0.00',
  `time_slot` varchar(250) NOT NULL DEFAULT 'Now',
  `delivered_time` int DEFAULT NULL,
  `deli_id` int DEFAULT NULL,
  PRIMARY KEY (`order_id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_orders_master_order_id` (`master_order_id`),
  KEY `idx_orders_bill_number` (`bill_number`),
  KEY `idx_orders_start_time` (`start_time`),
  KEY `idx_orders_state_start_time` (`order_state`,`start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `otp`
--

DROP TABLE IF EXISTS `otp`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `otp` (
  `contactno` varchar(30) NOT NULL,
  `slug` varchar(16) NOT NULL,
  `otp_num` varchar(10) NOT NULL,
  `otp_time` int unsigned NOT NULL DEFAULT '0',
  `purpose` varchar(250) NOT NULL,
  PRIMARY KEY (`contactno`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `physical_stock`
--

DROP TABLE IF EXISTS `physical_stock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `physical_stock` (
  `id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `stock` double NOT NULL,
  `last_updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `note` text DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `vendor_product_id` (`vendor_product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product`
--

DROP TABLE IF EXISTS `product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product` (
  `product_id` bigint unsigned NOT NULL,
  `cat_id` int unsigned NOT NULL DEFAULT '0',
  `parent_cat_id` int unsigned NOT NULL DEFAULT '0',
  `brand` text COLLATE utf8mb4_general_ci NOT NULL,
  `ctype_id` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'vegetables_fruits',
  `seq_no` int unsigned DEFAULT '0',
  `start_date` int unsigned NOT NULL DEFAULT '0',
  `is_published` tinyint unsigned NOT NULL DEFAULT '0',
  `is_used` tinyint NOT NULL DEFAULT '0',
  `is_deleted` tinyint NOT NULL DEFAULT '0',
  `in_stock` tinyint unsigned NOT NULL DEFAULT '0',
  `inventory_type` enum('SINGLE','PACK_WISE') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'SINGLE',
  `inventory_unit_type` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'WEIGHT',
  `name` text COLLATE utf8mb4_general_ci NOT NULL,
  `description` text COLLATE utf8mb4_general_ci NOT NULL,
  `display_photo` text COLLATE utf8mb4_general_ci DEFAULT NULL,
  `keywords` text COLLATE utf8mb4_general_ci DEFAULT NULL,
  `spec_params` text COLLATE utf8mb4_general_ci NOT NULL,
  `packs` text COLLATE utf8mb4_general_ci DEFAULT NULL,
  `default_pack_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL DEFAULT ' ',
  `hsn_code` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `gst_percent` decimal(5,2) NOT NULL,
  `offers` text COLLATE utf8mb4_general_ci DEFAULT NULL,
  `cache_txt` mediumtext COLLATE utf8mb4_general_ci DEFAULT NULL,
  `img_last_updated` int unsigned NOT NULL DEFAULT '0',
  `stock` decimal(10,3) DEFAULT NULL,
  `stock_ut_id` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_old`
--

DROP TABLE IF EXISTS `product_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_old` (
  `product_id` bigint unsigned NOT NULL,
  `cat_id` int unsigned NOT NULL DEFAULT '0',
  `parent_cat_id` int unsigned NOT NULL DEFAULT '0',
  `brand` text NOT NULL,
  `ctype_id` varchar(250) NOT NULL DEFAULT 'vegetables_fruits',
  `seq_no` int unsigned DEFAULT '0',
  `start_date` int unsigned NOT NULL DEFAULT '0',
  `is_published` tinyint unsigned NOT NULL DEFAULT '0',
  `is_used` tinyint NOT NULL DEFAULT '0',
  `is_deleted` tinyint NOT NULL DEFAULT '0',
  `in_stock` tinyint unsigned NOT NULL DEFAULT '0',
  `inventory_type` enum('SINGLE','PACK_WISE') NOT NULL DEFAULT 'SINGLE',
  `inventory_unit_type` varchar(255) NOT NULL DEFAULT 'WEIGHT',
  `name` text NOT NULL,
  `description` text NOT NULL,
  `display_photo` text DEFAULT NULL,
  `keywords` text DEFAULT NULL,
  `spec_params` text NOT NULL,
  `packs` text DEFAULT NULL,
  `default_pack_id` varchar(255) NOT NULL DEFAULT ' ',
  `hsn_code` varchar(10) NOT NULL,
  `gst_percent` decimal(5,2) NOT NULL,
  `offers` text DEFAULT NULL,
  `cache_txt` mediumtext DEFAULT NULL,
  `img_last_updated` int unsigned NOT NULL DEFAULT '0',
  `stock` decimal(10,3) DEFAULT NULL,
  `stock_ut_id` varchar(100) DEFAULT NULL,
  `order_limit` int unsigned NOT NULL DEFAULT '0',
  `buffer_limit` int unsigned NOT NULL DEFAULT '0',
  `product_pack_count` int unsigned NOT NULL DEFAULT '0',
  `nop` int unsigned NOT NULL DEFAULT '0',
  `pack_prd_wt` decimal(12,3) DEFAULT NULL,
  `gross_wt_of_pack` decimal(12,3) DEFAULT NULL,
  `gst_tax_type` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`product_id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_product_is_deleted` (`is_deleted`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_photos`
--

DROP TABLE IF EXISTS `product_photos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_photos` (
  `product_id` bigint unsigned NOT NULL DEFAULT '0',
  `photo_id` bigint unsigned NOT NULL,
  `file_location` varchar(250) NOT NULL DEFAULT '0',
  `photo_slug` varchar(10) NOT NULL DEFAULT '0000',
  PRIMARY KEY (`photo_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_purchase`
--

DROP TABLE IF EXISTS `product_purchase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_purchase` (
  `item_id` bigint unsigned NOT NULL,
  `day_id` varchar(20) NOT NULL DEFAULT '01-01-2018',
  `product_id` bigint unsigned NOT NULL DEFAULT '0',
  `quantity` decimal(10,2) unsigned NOT NULL DEFAULT '0.00',
  `unit_id` text NOT NULL,
  `cost` decimal(10,2) NOT NULL DEFAULT '0.00',
  `post_date` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`item_id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `day_id` (`day_id`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_sales_daily`
--

DROP TABLE IF EXISTS `product_sales_daily`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_sales_daily` (
  `sale_date` date NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `total_orders` int unsigned NOT NULL DEFAULT '0',
  `total_quantity` decimal(14,2) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`sale_date`,`product_id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_product_sales_daily_product_id` (`product_id`),
  KEY `idx_product_sales_daily_sale_date` (`sale_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `product_taxes`
--

DROP TABLE IF EXISTS `product_taxes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `product_taxes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `product_id` bigint unsigned NOT NULL,
  `tax_id` bigint unsigned NOT NULL,
  `tax_percent` decimal(5,2) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `product_taxes_product_id_foreign` (`product_id`),
  KEY `product_taxes_tax_id_foreign` (`tax_id`),
  UNIQUE KEY `product_taxes_product_id_tax_id_unique` (`product_id`,`tax_id`),
  KEY `product_taxes_product_id_index` (`product_id`),
  KEY `product_taxes_tax_id_index` (`tax_id`),
  CONSTRAINT `product_taxes_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product_old` (`product_id`) ON DELETE CASCADE,
  CONSTRAINT `product_taxes_tax_id_foreign` FOREIGN KEY (`tax_id`) REFERENCES `taxes` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=336038;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promo`
--

DROP TABLE IF EXISTS `promo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promo` (
  `promo_id` bigint unsigned NOT NULL,
  `title` varchar(250) DEFAULT NULL,
  `description` text DEFAULT NULL,
  `ctype_id` varchar(250) NOT NULL DEFAULT 'all',
  `discount` decimal(10,3) NOT NULL DEFAULT '0.000',
  `max_use` int unsigned NOT NULL DEFAULT '0',
  `from` datetime(6) DEFAULT NULL,
  `to` datetime(6) DEFAULT NULL,
  `status` tinyint NOT NULL DEFAULT '0',
  `promo_data` text NOT NULL COMMENT 'amount, percentage, percentage_up_to, ladder',
  PRIMARY KEY (`promo_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `promo_log`
--

DROP TABLE IF EXISTS `promo_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `promo_log` (
  `log_id` bigint unsigned NOT NULL,
  `order_id` bigint unsigned DEFAULT '0',
  `userid` bigint unsigned DEFAULT '0',
  `promo_id` bigint unsigned DEFAULT '0',
  PRIMARY KEY (`log_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `purchase_order_items`
--

DROP TABLE IF EXISTS `purchase_order_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchase_order_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `purchase_order_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `line_no` int unsigned NOT NULL,
  `unit` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hsn_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` decimal(12,3) NOT NULL,
  `consumed_quantity` decimal(12,3) NOT NULL DEFAULT '0',
  `written_off_quantity` decimal(12,3) NOT NULL DEFAULT '0',
  `remaining_quantity` decimal(12,3) NOT NULL DEFAULT '0',
  `price` decimal(12,2) NOT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `tax_percent` decimal(5,2) DEFAULT NULL,
  `line_total` decimal(14,2) NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `purchase_order_items_purchase_order_id_foreign` (`purchase_order_id`),
  KEY `purchase_order_items_product_id_foreign` (`product_id`),
  KEY `purchase_order_items_purchase_order_id_product_id_index` (`purchase_order_id`,`product_id`),
  KEY `purchase_order_items_hsn_code_index` (`hsn_code`),
  KEY `purchase_order_items_consumed_quantity_index` (`consumed_quantity`),
  KEY `purchase_order_items_remaining_quantity_index` (`remaining_quantity`),
  KEY `purchase_order_items_written_off_quantity_index` (`written_off_quantity`),
  CONSTRAINT `purchase_order_items_purchase_order_id_foreign` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `purchase_order_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product_old` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=210001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `purchase_orders`
--

DROP TABLE IF EXISTS `purchase_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchase_orders` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `po_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `financial_year` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `supplier_id` bigint unsigned NOT NULL,
  `salesman_id` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `department_id` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `doc_date` date NOT NULL,
  `expected_date` date DEFAULT NULL,
  `status` enum('DRAFT','SENT','PARTIALLY_RECEIVED','CLOSED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `narration` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL,
  `total_amount` decimal(14,2) NOT NULL DEFAULT '0',
  `charges_total` decimal(14,2) NOT NULL DEFAULT '0',
  `charges_json` json DEFAULT NULL,
  `total_with_charges` decimal(14,2) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `purchase_orders_supplier_id_foreign` (`supplier_id`),
  KEY `purchase_orders_supplier_id_index` (`supplier_id`),
  KEY `purchase_orders_status_index` (`status`),
  KEY `purchase_orders_doc_date_index` (`doc_date`),
  UNIQUE KEY `purchase_orders_po_number_unique` (`po_number`),
  KEY `purchase_orders_salesman_id_index` (`salesman_id`),
  KEY `purchase_orders_department_id_index` (`department_id`),
  CONSTRAINT `purchase_orders_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=210001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `purchase_return_items`
--

DROP TABLE IF EXISTS `purchase_return_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchase_return_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `purchase_return_id` bigint unsigned NOT NULL,
  `source_purchase_voucher_item_id` bigint unsigned DEFAULT NULL,
  `product_id` bigint unsigned NOT NULL,
  `line_no` int unsigned NOT NULL DEFAULT '1',
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `product_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `alias` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `unit` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `original_quantity` decimal(12,3) NOT NULL DEFAULT '0',
  `returned_quantity` decimal(12,3) NOT NULL DEFAULT '0',
  `unit_price` decimal(12,2) NOT NULL DEFAULT '0',
  `taxable_amount` decimal(14,2) NOT NULL DEFAULT '0',
  `sgst` decimal(12,2) NOT NULL DEFAULT '0',
  `cgst` decimal(12,2) NOT NULL DEFAULT '0',
  `igst` decimal(12,2) NOT NULL DEFAULT '0',
  `cess` decimal(12,2) NOT NULL DEFAULT '0',
  `roff` decimal(12,2) NOT NULL DEFAULT '0',
  `value` decimal(14,2) NOT NULL DEFAULT '0',
  `return_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `remarks` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `purchase_return_items_purchase_return_id_foreign` (`purchase_return_id`),
  KEY `purchase_return_items_source_purchase_voucher_item_id_foreign` (`source_purchase_voucher_item_id`),
  KEY `purchase_return_items_product_id_foreign` (`product_id`),
  KEY `purchase_return_items_purchase_return_id_product_id_index` (`purchase_return_id`,`product_id`),
  KEY `purchase_return_items_source_purchase_voucher_item_id_index` (`source_purchase_voucher_item_id`),
  CONSTRAINT `purchase_return_items_purchase_return_id_foreign` FOREIGN KEY (`purchase_return_id`) REFERENCES `purchase_returns` (`id`) ON DELETE CASCADE,
  CONSTRAINT `purchase_return_items_source_purchase_voucher_item_id_foreign` FOREIGN KEY (`source_purchase_voucher_item_id`) REFERENCES `purchase_voucher_items` (`id`) ON DELETE SET NULL,
  CONSTRAINT `purchase_return_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product_old` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `purchase_returns`
--

DROP TABLE IF EXISTS `purchase_returns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchase_returns` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `doc_no_prefix` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '25-26/',
  `doc_no_number` bigint unsigned NOT NULL,
  `doc_no` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `source_purchase_voucher_id` bigint unsigned DEFAULT NULL,
  `vendor_id` bigint unsigned NOT NULL,
  `doc_date` date NOT NULL,
  `reason` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('DRAFT','POSTED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `items_total` decimal(14,2) NOT NULL DEFAULT '0',
  `charges_total` decimal(14,2) NOT NULL DEFAULT '0',
  `net_total` decimal(14,2) NOT NULL DEFAULT '0',
  `charges_json` json DEFAULT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `purchase_returns_source_purchase_voucher_id_foreign` (`source_purchase_voucher_id`),
  KEY `purchase_returns_vendor_id_foreign` (`vendor_id`),
  KEY `purchase_returns_vendor_id_index` (`vendor_id`),
  KEY `purchase_returns_doc_date_index` (`doc_date`),
  KEY `purchase_returns_doc_no_index` (`doc_no`),
  KEY `purchase_returns_status_index` (`status`),
  UNIQUE KEY `purchase_returns_vendor_id_doc_no_prefix_doc_no_number_unique` (`vendor_id`,`doc_no_prefix`,`doc_no_number`),
  CONSTRAINT `purchase_returns_source_purchase_voucher_id_foreign` FOREIGN KEY (`source_purchase_voucher_id`) REFERENCES `purchase_vouchers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `purchase_returns_vendor_id_foreign` FOREIGN KEY (`vendor_id`) REFERENCES `suppliers` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `purchase_voucher_items`
--

DROP TABLE IF EXISTS `purchase_voucher_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchase_voucher_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `purchase_voucher_id` bigint unsigned NOT NULL,
  `source_purchase_order_id` bigint unsigned DEFAULT NULL,
  `source_purchase_order_item_id` bigint unsigned DEFAULT NULL,
  `source_po_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `product_id` bigint unsigned NOT NULL,
  `line_no` int unsigned NOT NULL DEFAULT '1',
  `product_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `product_code` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hsn_code` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `alias` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `unit` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `quantity` decimal(12,3) NOT NULL DEFAULT '0',
  `overrun_qty` decimal(12,3) NOT NULL DEFAULT '0',
  `writeoff_qty` decimal(12,3) NOT NULL DEFAULT '0',
  `is_overrun_approved` tinyint(1) NOT NULL DEFAULT '0',
  `is_writeoff` tinyint(1) NOT NULL DEFAULT '0',
  `overrun_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `writeoff_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `overrun_approved_by` bigint unsigned DEFAULT NULL,
  `overrun_approved_at` timestamp NULL DEFAULT NULL,
  `unit_price` decimal(12,2) NOT NULL DEFAULT '0',
  `taxable_amount` decimal(14,2) NOT NULL DEFAULT '0',
  `sgst` decimal(12,2) NOT NULL DEFAULT '0',
  `cgst` decimal(12,2) NOT NULL DEFAULT '0',
  `igst` decimal(12,2) NOT NULL DEFAULT '0',
  `cess` decimal(12,2) NOT NULL DEFAULT '0',
  `roff` decimal(12,2) NOT NULL DEFAULT '0',
  `value` decimal(14,2) NOT NULL DEFAULT '0',
  `purchase_account` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `gst_itc_eligibility` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `purchase_voucher_items_purchase_voucher_id_foreign` (`purchase_voucher_id`),
  KEY `purchase_voucher_items_product_id_foreign` (`product_id`),
  KEY `purchase_voucher_items_purchase_voucher_id_product_id_index` (`purchase_voucher_id`,`product_id`),
  KEY `purchase_voucher_items_source_purchase_order_id_index` (`source_purchase_order_id`),
  KEY `purchase_voucher_items_hsn_code_index` (`hsn_code`),
  KEY `purchase_voucher_items_source_purchase_order_item_id_index` (`source_purchase_order_item_id`),
  KEY `purchase_voucher_items_overrun_approved_by_index` (`overrun_approved_by`),
  KEY `purchase_voucher_items_is_writeoff_index` (`is_writeoff`),
  CONSTRAINT `purchase_voucher_items_purchase_voucher_id_foreign` FOREIGN KEY (`purchase_voucher_id`) REFERENCES `purchase_vouchers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `purchase_voucher_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product_old` (`product_id`),
  CONSTRAINT `purchase_voucher_items_source_purchase_order_item_id_foreign` FOREIGN KEY (`source_purchase_order_item_id`) REFERENCES `purchase_order_items` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=180001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `purchase_vouchers`
--

DROP TABLE IF EXISTS `purchase_vouchers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchase_vouchers` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `doc_no_prefix` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '25-26/',
  `doc_no_number` bigint unsigned NOT NULL,
  `doc_no` varchar(80) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `vendor_id` bigint unsigned NOT NULL,
  `purchase_order_id` bigint unsigned DEFAULT NULL,
  `doc_date` date NOT NULL,
  `bill_no` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `bill_date` date DEFAULT NULL,
  `narration` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `do_not_update_inventory` tinyint(1) NOT NULL DEFAULT '0',
  `purchase_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Regular',
  `gst_reverse_charge` varchar(4) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N',
  `purchase_agent_id` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('DRAFT','POSTED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `items_total` decimal(14,2) NOT NULL DEFAULT '0',
  `charges_total` decimal(14,2) NOT NULL DEFAULT '0',
  `net_total` decimal(14,2) NOT NULL DEFAULT '0',
  `charges_json` json DEFAULT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `purchase_vouchers_vendor_id_foreign` (`vendor_id`),
  KEY `purchase_vouchers_purchase_order_id_foreign` (`purchase_order_id`),
  UNIQUE KEY `purchase_vouchers_doc_no_prefix_doc_no_number_unique` (`doc_no_prefix`,`doc_no_number`),
  KEY `purchase_vouchers_vendor_id_index` (`vendor_id`),
  KEY `purchase_vouchers_doc_date_index` (`doc_date`),
  KEY `purchase_vouchers_doc_no_index` (`doc_no`),
  KEY `purchase_vouchers_status_index` (`status`),
  CONSTRAINT `purchase_vouchers_vendor_id_foreign` FOREIGN KEY (`vendor_id`) REFERENCES `suppliers` (`id`),
  CONSTRAINT `purchase_vouchers_purchase_order_id_foreign` FOREIGN KEY (`purchase_order_id`) REFERENCES `purchase_orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=150001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `receive_from_production`
--

DROP TABLE IF EXISTS `receive_from_production`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `receive_from_production` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `status` enum('DRAFT','RECEIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `remarks` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `received_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30002;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `receive_from_production_items`
--

DROP TABLE IF EXISTS `receive_from_production_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `receive_from_production_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `receive_id` bigint unsigned NOT NULL,
  `finished_product_id` bigint unsigned NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `unit_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `receive_from_production_items_receive_id_foreign` (`receive_id`),
  KEY `receive_from_production_items_finished_product_id_foreign` (`finished_product_id`),
  CONSTRAINT `receive_from_production_items_finished_product_id_foreign` FOREIGN KEY (`finished_product_id`) REFERENCES `product_old` (`product_id`),
  CONSTRAINT `receive_from_production_items_receive_id_foreign` FOREIGN KEY (`receive_id`) REFERENCES `receive_from_production` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30003;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `roles_name_unique` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sales_invoices`
--

DROP TABLE IF EXISTS `sales_invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sales_invoices` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `invoice_no` varchar(50) NOT NULL,
  `invoice_prefix` varchar(20) DEFAULT NULL,
  `invoice_number` bigint unsigned DEFAULT NULL,
  `order_id` bigint unsigned NOT NULL,
  `customer_user_id` bigint unsigned DEFAULT NULL,
  `invoice_date` date NOT NULL,
  `due_date` date DEFAULT NULL,
  `invoice_status` enum('DRAFT','ISSUED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
  `payment_status` enum('PENDING','PARTIAL','PAID') NOT NULL DEFAULT 'PENDING',
  `subtotal` decimal(12,2) NOT NULL DEFAULT '0.00',
  `discount_total` decimal(12,2) NOT NULL DEFAULT '0.00',
  `delivery_charge` decimal(12,2) NOT NULL DEFAULT '0.00',
  `tax_total` decimal(12,2) NOT NULL DEFAULT '0.00',
  `grand_total` decimal(12,2) NOT NULL DEFAULT '0.00',
  `notes` text DEFAULT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `sales_invoices_invoice_no_unique` (`invoice_no`),
  UNIQUE KEY `sales_invoices_order_id_unique` (`order_id`),
  KEY `sales_invoices_invoice_date_index` (`invoice_date`),
  KEY `sales_invoices_invoice_status_index` (`invoice_status`),
  KEY `sales_invoices_payment_status_index` (`payment_status`),
  KEY `sales_invoices_customer_user_id_index` (`customer_user_id`),
  CONSTRAINT `sales_invoices_order_id_foreign` FOREIGN KEY (`order_id`) REFERENCES `orders_old` (`order_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `search`
--

DROP TABLE IF EXISTS `search`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `search` (
  `s.no` int NOT NULL,
  `user_id` int NOT NULL,
  `search_text` varchar(200) COLLATE utf8mb4_general_ci NOT NULL,
  `count` int NOT NULL COMMENT 'no. of times this searchText has been used',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`s.no`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint unsigned DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `payload` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_activity` int NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_audit_log`
--

DROP TABLE IF EXISTS `stock_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_audit_log` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `vendor_product_id` int NOT NULL,
  `trigger_pack_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pack_updates` json NOT NULL,
  `reason` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `stock_audit_log_created_at_index` (`created_at`),
  KEY `stock_audit_log_vendor_product_id_created_at_index` (`vendor_product_id`,`created_at`),
  KEY `stock_audit_log_vendor_product_id_index` (`vendor_product_id`),
  KEY `stock_audit_log_trigger_pack_id_index` (`trigger_pack_id`),
  KEY `stock_audit_log_user_id_index` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_count`
--

DROP TABLE IF EXISTS `stock_count`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_count` (
  `id` int NOT NULL,
  `assignment_id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `counted_quantity` double NOT NULL,
  `count_unit` varchar(12) NOT NULL,
  `standard_unit_quantity` decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_assignment` (`assignment_id`),
  KEY `idx_vendor_product` (`vendor_product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_count_assignments`
--

DROP TABLE IF EXISTS `stock_count_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_count_assignments` (
  `id` int NOT NULL,
  `master_session_id` int NOT NULL,
  `counter_user_id` int NOT NULL,
  `category_id` int NOT NULL,
  `status` enum('assigned','in_progress','completed','paused') DEFAULT 'assigned',
  `assigned_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `unique_session_category` (`master_session_id`,`category_id`),
  KEY `idx_counter_user` (`counter_user_id`),
  KEY `idx_master_session` (`master_session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_count_master_session`
--

DROP TABLE IF EXISTS `stock_count_master_session`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_count_master_session` (
  `id` int NOT NULL,
  `supervisor_id` int NOT NULL,
  `status` enum('planning','in_progress','completed','cancelled') DEFAULT 'planning',
  `total_categories` int DEFAULT '0',
  `completed_categories` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_notify`
--

DROP TABLE IF EXISTS `stock_notify`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_notify` (
  `userid` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL COMMENT 'this is vendor prod id',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `userid` (`userid`,`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_voucher`
--

DROP TABLE IF EXISTS `stock_voucher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_voucher` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `voucher_type` enum('IN','OUT') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'IN',
  `status` enum('DRAFT','POSTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `voucher_date` date DEFAULT NULL,
  `remarks` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `posted_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30003;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `stock_voucher_items`
--

DROP TABLE IF EXISTS `stock_voucher_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stock_voucher_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `voucher_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `quantity` decimal(10,3) NOT NULL,
  `unit_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `stock_voucher_items_voucher_id_foreign` (`voucher_id`),
  KEY `stock_voucher_items_product_id_foreign` (`product_id`),
  CONSTRAINT `stock_voucher_items_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product_old` (`product_id`),
  CONSTRAINT `stock_voucher_items_voucher_id_foreign` FOREIGN KEY (`voucher_id`) REFERENCES `stock_voucher` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30003;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `supplier_products`
--

DROP TABLE IF EXISTS `supplier_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `supplier_products` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `supplier_id` bigint unsigned NOT NULL,
  `product_id` bigint unsigned NOT NULL,
  `supplier_sku` varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `supplier_product_name` varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `pack_size` decimal(10,3) DEFAULT NULL,
  `pack_unit` varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `min_order_qty` decimal(12,3) DEFAULT NULL,
  `price` decimal(12,2) DEFAULT NULL,
  `currency` varchar(3) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `tax_percent` decimal(5,2) DEFAULT NULL,
  `discount_percent` decimal(5,2) DEFAULT NULL,
  `lead_time_days` smallint unsigned DEFAULT NULL,
  `last_purchase_price` decimal(12,2) DEFAULT NULL,
  `last_purchase_date` date DEFAULT NULL,
  `is_preferred` tinyint(1) NOT NULL DEFAULT '0',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `notes` text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `supplier_products_supplier_id_supplier_sku_unique` (`supplier_id`,`supplier_sku`),
  KEY `supplier_products_product_id_foreign` (`product_id`),
  UNIQUE KEY `supplier_products_supplier_id_product_id_unique` (`supplier_id`,`product_id`),
  CONSTRAINT `supplier_products_product_id_foreign` FOREIGN KEY (`product_id`) REFERENCES `product_old` (`product_id`),
  CONSTRAINT `supplier_products_supplier_id_foreign` FOREIGN KEY (`supplier_id`) REFERENCES `suppliers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AUTO_INCREMENT=240003;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `suppliers`
--

DROP TABLE IF EXISTS `suppliers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `suppliers` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `supplier_code` varchar(50) COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `supplier_name` varchar(255) COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `short_name` varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `business_type` varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `department` varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `gst_no` varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `pan_no` varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `tan_no` varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `cin_no` varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `vat_no` varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `registration_no` varchar(50) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `fssai_no` varchar(50) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `website` varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `email` varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `phone` varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `alternate_phone` varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `contact_person` varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `contact_person_email` varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `contact_person_phone` varchar(30) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `contact_person_designation` varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `address_line1` varchar(255) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `state` varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `country` varchar(100) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `pincode` varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `bank_name` varchar(150) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `bank_branch` varchar(150) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `bank_account_name` varchar(150) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `bank_account_number` varchar(50) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `ifsc_code` varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `swift_code` varchar(20) COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `payment_terms_days` smallint unsigned DEFAULT NULL,
  `credit_limit` decimal(12,2) DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT NULL,
  `is_preferred` tinyint(1) NOT NULL DEFAULT '0',
  `status` enum('ACTIVE','INACTIVE','SUSPENDED') COLLATE utf8mb4_0900_ai_ci NOT NULL DEFAULT 'ACTIVE',
  `notes` text COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `metadata` json DEFAULT NULL,
  `created_by` bigint unsigned DEFAULT NULL,
  `updated_by` bigint unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `suppliers_supplier_code_unique` (`supplier_code`),
  KEY `suppliers_gstin_index` (`gst_no`),
  KEY `suppliers_pan_index` (`pan_no`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci AUTO_INCREMENT=336564;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `taxes`
--

DROP TABLE IF EXISTS `taxes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `taxes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `tax_category` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tax_sub_category` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tax_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `taxes_tax_category_tax_sub_category_index` (`tax_category`,`tax_sub_category`),
  KEY `idx_tax_category` (`tax_category`),
  KEY `idx_tax_sub_category` (`tax_sub_category`),
  KEY `idx_tax_name` (`tax_name`),
  KEY `idx_tax_is_active` (`is_active`),
  KEY `idx_tax_active_category` (`is_active`,`tax_category`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=120001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `time_slots`
--

DROP TABLE IF EXISTS `time_slots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `time_slots` (
  `slot_id` bigint unsigned NOT NULL,
  `time_slot_group_id` int NOT NULL,
  `area_id` varchar(250) DEFAULT NULL,
  `start_date` int unsigned NOT NULL DEFAULT '1',
  `interval` int unsigned NOT NULL DEFAULT '1',
  `count_limit` int unsigned NOT NULL DEFAULT '3',
  `order_time_end` int unsigned DEFAULT '0',
  `delivery_time_start` int unsigned DEFAULT '0',
  `delivery_time_end` int unsigned DEFAULT '0',
  `display_text` varchar(250) NOT NULL DEFAULT '',
  PRIMARY KEY (`slot_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timing_slot_group_categories`
--

DROP TABLE IF EXISTS `timing_slot_group_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timing_slot_group_categories` (
  `id` int NOT NULL,
  `group_id` int NOT NULL,
  `category_id` int NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `timing_slot_groups`
--

DROP TABLE IF EXISTS `timing_slot_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `timing_slot_groups` (
  `id` int NOT NULL,
  `min_amount` float(10,2) NOT NULL,
  `express_delivery_charge` float(10,2) NOT NULL,
  `delivery_charge` float(10,2) NOT NULL,
  `admin_id` int NOT NULL,
  `is_active` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `admin_id` (`admin_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `transaction_crm`
--

DROP TABLE IF EXISTS `transaction_crm`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transaction_crm` (
  `id` int NOT NULL AUTO_INCREMENT,
  `account_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `transaction_no` int NOT NULL COMMENT 'Visit count for this account',
  `beat_no` int DEFAULT NULL COMMENT 'Beat number (1, 2, 3, etc.)',
  `salesman_id` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `visit_in_time` datetime DEFAULT NULL COMMENT 'Time when salesman visited in',
  `visit_out_time` datetime DEFAULT NULL COMMENT 'Time when salesman visited out',
  `visit_in_latitude` decimal(10,8) DEFAULT NULL COMMENT 'Latitude at visit in',
  `visit_in_longitude` decimal(11,8) DEFAULT NULL COMMENT 'Longitude at visit in',
  `visit_out_latitude` decimal(10,8) DEFAULT NULL COMMENT 'Latitude at visit out',
  `visit_out_longitude` decimal(11,8) DEFAULT NULL COMMENT 'Longitude at visit out',
  `order_funnel` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Order funnel stage selected',
  `notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'General notes',
  `notes_related_to` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Mistake related to (Customer, Salesman, Product, etc.)',
  `merchandise_image_1` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `merchandise_image_2` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `idx_account_id` (`account_id`),
  KEY `idx_salesman_id` (`salesman_id`),
  KEY `idx_visit_in_time` (`visit_in_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=60001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trip_audit_log`
--

DROP TABLE IF EXISTS `trip_audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trip_audit_log` (
  `id` int NOT NULL AUTO_INCREMENT,
  `trip_id` int NOT NULL,
  `order_id` int NOT NULL,
  `item_id` int NOT NULL,
  `vendor_product_id` int NOT NULL,
  `product_id` int NOT NULL,
  `qty_loaded` int NOT NULL,
  `qty_claimed_delivered` int NOT NULL,
  `qty_claimed_returned` int NOT NULL,
  `qty_verified_delivered` int NOT NULL,
  `qty_verified_returned` int NOT NULL,
  `discrepancy_delivered` int GENERATED ALWAYS AS ((`qty_verified_delivered` - `qty_claimed_delivered`)) STORED,
  `discrepancy_returned` int GENERATED ALWAYS AS ((`qty_verified_returned` - `qty_claimed_returned`)) STORED,
  `auditor_deli_id` int NOT NULL COMMENT 'References deli_staff.deli_id (the auditor who verified the trip)',
  `audited_at` datetime NOT NULL,
  `investigation_status` enum('pending','resolved') COLLATE utf8mb4_unicode_ci DEFAULT 'pending',
  `investigator_deli_id` int DEFAULT NULL COMMENT 'References deli_staff.deli_id (the investigator who resolved discrepancies)',
  `investigated_at` datetime DEFAULT NULL,
  `resolution_outcome` enum('stock_loss','stock_recovered') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `resolution_notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `qty_recovered_returned` int DEFAULT NULL,
  `driver_liable` tinyint(1) DEFAULT '0',
  `liability_amount` decimal(10,2) DEFAULT '0.00',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=30018;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trip_card_pincode`
--

DROP TABLE IF EXISTS `trip_card_pincode`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trip_card_pincode` (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL,
  `pincode` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `zone_id` (`zone_id`),
  CONSTRAINT `trip_card_pincode_ibfk_1` FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=240001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trip_cards`
--

DROP TABLE IF EXISTS `trip_cards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trip_cards` (
  `zone_id` int NOT NULL AUTO_INCREMENT,
  `zone_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vehicle_id` int DEFAULT NULL,
  `status` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT 'IDLE',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`zone_id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `zone_name` (`zone_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=150001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `trips`
--

DROP TABLE IF EXISTS `trips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `trips` (
  `trip_id` int NOT NULL,
  `deli_id` int unsigned DEFAULT NULL,
  `status` varchar(30) NOT NULL COMMENT 'unass, ass, ongoing, completed',
  `description` varchar(40) NOT NULL COMMENT 'vehicle number, trip number. || just vehicle number',
  `start_date` varchar(30) NOT NULL,
  `completed_at` varchar(25) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`trip_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `units_master`
--

DROP TABLE IF EXISTS `units_master`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `units_master` (
  `unit_id` int NOT NULL AUTO_INCREMENT,
  `unit_name` varchar(100) NOT NULL,
  `serial_no` int DEFAULT NULL,
  `conversion_rate` decimal(10,4) NOT NULL,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`unit_id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin AUTO_INCREMENT=90002;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `userid` bigint unsigned NOT NULL,
  `email` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT ' ',
  `is_email_verified` tinyint NOT NULL DEFAULT '0',
  `contactno` varchar(250) COLLATE utf8mb4_general_ci NOT NULL,
  `is_contact_verified` tinyint NOT NULL DEFAULT '0',
  `name` text COLLATE utf8mb4_general_ci NOT NULL,
  `account_state` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'incomplete',
  `address` text COLLATE utf8mb4_general_ci NOT NULL,
  `latitude` float(10,6) NOT NULL DEFAULT '0',
  `longitude` float(10,6) NOT NULL DEFAULT '0',
  `dob` text COLLATE utf8mb4_general_ci DEFAULT NULL,
  `register_date` int unsigned NOT NULL DEFAULT '0',
  `shop_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_plot_no` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `user_type` enum('B2C','B2B') COLLATE utf8mb4_general_ci NOT NULL,
  `adhar_card` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_photo` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_licence` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `bussiness_pan_card` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `is_approved` enum('YES','NO','REQUESTED') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'YES',
  `session_id` text COLLATE utf8mb4_general_ci NOT NULL,
  `last_activity` int unsigned NOT NULL DEFAULT '0',
  `push_notif_id` text COLLATE utf8mb4_general_ci NOT NULL,
  `is_first_login` tinyint unsigned NOT NULL DEFAULT '1',
  `has_unread_comments` tinyint unsigned NOT NULL DEFAULT '0',
  `password` varchar(250) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_addresses`
--

DROP TABLE IF EXISTS `user_addresses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_addresses` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `full_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `full_address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `phone_no` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `address` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `pincode` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `lat` double(10,8) NOT NULL,
  `lng` double(11,8) NOT NULL,
  `type` enum('Home','Office') COLLATE utf8mb4_general_ci NOT NULL,
  `city_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `area_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `is_default` enum('0','1') COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_addresses_old`
--

DROP TABLE IF EXISTS `user_addresses_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_addresses_old` (
  `id` int NOT NULL,
  `user_id` int NOT NULL,
  `full_name` varchar(255) DEFAULT NULL,
  `full_address` varchar(255) DEFAULT NULL,
  `phone_no` varchar(255) DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `address` varchar(255) NOT NULL,
  `lat` double(10,8) NOT NULL,
  `lng` double(11,8) NOT NULL,
  `type` enum('Home','Office') NOT NULL,
  `city_id` varchar(255) NOT NULL,
  `area_id` varchar(255) NOT NULL,
  `is_default` enum('0','1') NOT NULL,
  `created_at` datetime NOT NULL,
  `pincode_main` int DEFAULT NULL,
  `mainarea_main` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `user_old`
--

DROP TABLE IF EXISTS `user_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_old` (
  `userid` bigint unsigned NOT NULL,
  `email` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT ' ',
  `is_email_verified` tinyint NOT NULL DEFAULT '0',
  `contactno` varchar(250) COLLATE utf8mb4_general_ci NOT NULL,
  `is_contact_verified` tinyint NOT NULL DEFAULT '0',
  `name` text COLLATE utf8mb4_general_ci NOT NULL,
  `account_state` varchar(250) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'incomplete',
  `address` text COLLATE utf8mb4_general_ci NOT NULL,
  `latitude` float(10,6) NOT NULL DEFAULT '0',
  `longitude` float(10,6) NOT NULL DEFAULT '0',
  `dob` text COLLATE utf8mb4_general_ci DEFAULT NULL,
  `register_date` int unsigned NOT NULL DEFAULT '0',
  `shop_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_address` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_plot_no` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `user_type` enum('B2C','B2B') COLLATE utf8mb4_general_ci NOT NULL,
  `adhar_card` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_photo` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `shop_licence` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `bussiness_pan_card` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `is_approved` enum('YES','NO','REQUESTED') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'YES',
  `session_id` text COLLATE utf8mb4_general_ci NOT NULL,
  `last_activity` int unsigned NOT NULL DEFAULT '0',
  `push_notif_id` text COLLATE utf8mb4_general_ci NOT NULL,
  `is_first_login` tinyint unsigned NOT NULL DEFAULT '1',
  `has_unread_comments` tinyint unsigned NOT NULL DEFAULT '0',
  `password` varchar(250) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `pincode` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `employeeCode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `name` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contactNumber` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `alternativeNumber` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `roleId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `roles` json DEFAULT NULL,
  `departmentId` varchar(10) COLLATE utf8mb4_bin DEFAULT NULL,
  `otp` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `otpExpiry` datetime DEFAULT NULL,
  `lastLogin` datetime DEFAULT NULL,
  `isActive` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `dateOfBirth` datetime DEFAULT NULL,
  `gender` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `image` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `preferredLanguages` json DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pincode` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `country` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `area` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `aadharCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `panCard` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `workStartTime` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '09:00:00',
  `workEndTime` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '18:00:00',
  `latePunchInGraceMinutes` int NOT NULL DEFAULT '45',
  `earlyPunchOutGraceMinutes` int NOT NULL DEFAULT '30',
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `users_employeecode_unique` (`employeeCode`),
  UNIQUE KEY `users_email_unique` (`email`),
  UNIQUE KEY `users_contactnumber_unique` (`contactNumber`),
  KEY `users_roleid_foreign` (`roleId`),
  KEY `users_departmentid_foreign` (`departmentId`),
  CONSTRAINT `users_roleid_foreign` FOREIGN KEY (`roleId`) REFERENCES `roles` (`id`) ON DELETE SET NULL,
  CONSTRAINT `users_departmentid_foreign` FOREIGN KEY (`departmentId`) REFERENCES `Department` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vehicles`
--

DROP TABLE IF EXISTS `vehicles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicles` (
  `vehicle_id` int NOT NULL AUTO_INCREMENT,
  `vehicle_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `capacity_kg` decimal(10,2) NOT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`vehicle_id`) /*T![clustered_index] CLUSTERED */,
  UNIQUE KEY `vehicle_number` (`vehicle_number`),
  KEY `idx_vehicle_capacity` (`capacity_kg`,`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=60001;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_area_categories`
--

DROP TABLE IF EXISTS `vendor_area_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_area_categories` (
  `id` int NOT NULL,
  `admin_id` int NOT NULL,
  `city_id` varchar(255) NOT NULL DEFAULT '',
  `area_id` varchar(255) NOT NULL,
  `category_id` varchar(255) NOT NULL,
  `commisson` int NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_bin;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_products`
--

DROP TABLE IF EXISTS `vendor_products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_products` (
  `id` int NOT NULL,
  `admin_vendor_id` int NOT NULL,
  `product_id` int NOT NULL,
  `packs` text COLLATE utf8mb4_general_ci NOT NULL,
  `default_pack_id` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `status` enum('1','0') COLLATE utf8mb4_general_ci NOT NULL,
  `in_stock` enum('1','0') COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_products_inventory`
--

DROP TABLE IF EXISTS `vendor_products_inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_products_inventory` (
  `id` int NOT NULL AUTO_INCREMENT,
  `vendor_product_id` int NOT NULL,
  `product_id` int NOT NULL,
  `action_type` varchar(255) NOT NULL,
  `pack_id` varchar(255) NOT NULL,
  `vendor_id` int DEFAULT NULL,
  `quantity` double(10,2) NOT NULL,
  `unit_type` varchar(255) NOT NULL,
  `unitquantity` double(10,2) NOT NULL,
  `amount` double(10,2) NOT NULL,
  `wholesale_user_id` int DEFAULT NULL,
  `inv_date` date NOT NULL,
  `inv_type` enum('CREDIT','DEBIT') NOT NULL,
  `note` text NOT NULL,
  `trip_id` int DEFAULT NULL,
  `updated_at` datetime NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin AUTO_INCREMENT=30215;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vendor_products_old`
--

DROP TABLE IF EXISTS `vendor_products_old`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_products_old` (
  `id` int NOT NULL AUTO_INCREMENT,
  `admin_vendor_id` int NOT NULL,
  `product_id` int NOT NULL,
  `packs` text NOT NULL,
  `default_pack_id` varchar(255) NOT NULL,
  `status` enum('1','0') NOT NULL,
  `in_stock` enum('1','0') NOT NULL,
  `created_at` datetime NOT NULL,
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin AUTO_INCREMENT=43799;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `zone_vehicles`
--

DROP TABLE IF EXISTS `zone_vehicles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `zone_vehicles` (
  `id` int NOT NULL AUTO_INCREMENT,
  `zone_id` int NOT NULL,
  `vehicle_id` int NOT NULL,
  `assigned_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`) /*T![clustered_index] CLUSTERED */,
  KEY `zone_id` (`zone_id`),
  KEY `vehicle_id` (`vehicle_id`),
  KEY `is_active` (`is_active`),
  CONSTRAINT `zone_vehicles_ibfk_1` FOREIGN KEY (`zone_id`) REFERENCES `trip_cards` (`zone_id`) ON DELETE CASCADE,
  CONSTRAINT `zone_vehicles_ibfk_2` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`vehicle_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci AUTO_INCREMENT=120001;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-24 18:06:43
