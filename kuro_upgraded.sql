-- KuroPanel Upgraded Database Schema - 4 Role System
-- Version: 2.0
-- Date: 2025-01-29

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `kuropanel_v2`
--
CREATE DATABASE IF NOT EXISTS `kuropanel_v2` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `kuropanel_v2`;

-- --------------------------------------------------------

--
-- Table structure for table `apps`
--

CREATE TABLE `apps` (
  `id_app` int NOT NULL,
  `app_name` varchar(255) NOT NULL,
  `app_description` text,
  `current_version` varchar(50) DEFAULT '1.0.0',
  `status` enum('active','deprecated','maintenance') DEFAULT 'active',
  `maintenance_message` text,
  `developer_id` int NOT NULL,
  `global_maintenance` tinyint(1) DEFAULT '0',
  `global_maintenance_message` text,
  `logo_url` varchar(500),
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `app_versions`
--

CREATE TABLE `app_versions` (
  `id_version` int NOT NULL,
  `app_id` int NOT NULL,
  `version_number` varchar(50) NOT NULL,
  `version_name` varchar(255),
  `download_url` varchar(1000) NOT NULL,
  `patch_notes` text,
  `is_active` tinyint(1) DEFAULT '1',
  `min_required_version` varchar(50),
  `force_update` tinyint(1) DEFAULT '0',
  `file_size` bigint DEFAULT NULL,
  `checksum` varchar(255),
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id_users` int NOT NULL,
  `fullname` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci,
  `level` int DEFAULT '4',
  `saldo` decimal(10,2) DEFAULT '0.00',
  `status` tinyint(1) DEFAULT '1',
  `uplink` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  
  -- Profile fields
  `avatar_url` varchar(500),
  `telegram_username` varchar(100),
  `telegram_channel` varchar(255),
  `telegram_bot_token` varchar(255),
  
  -- Business/Branding fields (for Resellers and Developers)
  `business_name` varchar(255),
  `logo_url` varchar(500),
  `website_url` varchar(500),
  `description` text,
  
  -- Settings
  `timezone` varchar(50) DEFAULT 'UTC',
  `language` varchar(10) DEFAULT 'en',
  `two_factor_enabled` tinyint(1) DEFAULT '0',
  `two_factor_secret` varchar(255),
  
  -- Activity tracking
  `last_login` datetime,
  `login_count` int DEFAULT '0',
  `failed_login_attempts` int DEFAULT '0',
  `locked_until` datetime,
  
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `license_keys`
--

CREATE TABLE `license_keys` (
  `id_key` int NOT NULL,
  `license_key` varchar(100) NOT NULL,
  `app_id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `reseller_id` int DEFAULT NULL,
  `developer_id` int NOT NULL,
  
  -- Key configuration
  `key_type` enum('single','multi') DEFAULT 'single',
  `max_devices` int DEFAULT '1',
  `duration_days` int NOT NULL,
  `price` decimal(10,2) DEFAULT '0.00',
  
  -- Status and dates
  `status` enum('active','expired','suspended','used') DEFAULT 'active',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `activated_at` datetime,
  `expires_at` datetime,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  
  -- Device tracking
  `devices` json DEFAULT NULL,
  `device_count` int DEFAULT '0',
  
  -- Usage tracking
  `last_used` datetime,
  `usage_count` int DEFAULT '0',
  
  -- Notes and metadata
  `notes` text,
  `metadata` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `reseller_apps`
--

CREATE TABLE `reseller_apps` (
  `id` int NOT NULL,
  `reseller_id` int NOT NULL,
  `app_id` int NOT NULL,
  `developer_id` int NOT NULL,
  `invite_code` varchar(100) NOT NULL,
  `assigned_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `status` enum('active','suspended','revoked') DEFAULT 'active',
  
  -- Reseller specific settings for this app
  `custom_pricing` decimal(10,2),
  `commission_rate` decimal(5,2) DEFAULT '0.00',
  `maintenance_mode` tinyint(1) DEFAULT '0',
  `maintenance_message` text,
  
  -- Branding for this app
  `custom_logo_url` varchar(500),
  `custom_description` text,
  
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `invite_codes`
--

CREATE TABLE `invite_codes` (
  `id_invite` int NOT NULL,
  `code` varchar(100) NOT NULL,
  `created_by` int NOT NULL,
  `app_id` int DEFAULT NULL,
  `target_role` enum('developer','reseller','user') NOT NULL,
  `max_uses` int DEFAULT '1',
  `used_count` int DEFAULT '0',
  `expires_at` datetime,
  `status` enum('active','expired','disabled') DEFAULT 'active',
  `metadata` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `invite_code_usage`
--

CREATE TABLE `invite_code_usage` (
  `id` int NOT NULL,
  `invite_code_id` int NOT NULL,
  `used_by` int NOT NULL,
  `used_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(45),
  `user_agent` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id_transaction` int NOT NULL,
  `user_id` int NOT NULL,
  `transaction_type` enum('deposit','withdrawal','purchase','refund','commission') NOT NULL,
  `amount` decimal(10,2) NOT NULL,
  `balance_before` decimal(10,2) NOT NULL,
  `balance_after` decimal(10,2) NOT NULL,
  `description` varchar(500),
  `reference_id` varchar(100),
  `reference_type` enum('license_key','app','system') DEFAULT NULL,
  `status` enum('pending','completed','failed','cancelled') DEFAULT 'pending',
  `payment_method` varchar(100),
  `payment_reference` varchar(255),
  `metadata` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id_log` int NOT NULL,
  `user_id` int,
  `action` varchar(100) NOT NULL,
  `description` text,
  `ip_address` varchar(45),
  `user_agent` text,
  `reference_type` varchar(100),
  `reference_id` int,
  `metadata` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `hwid_resets`
--

CREATE TABLE `hwid_resets` (
  `id_reset` int NOT NULL,
  `license_key_id` int NOT NULL,
  `user_id` int NOT NULL,
  `old_hwid` varchar(255),
  `new_hwid` varchar(255),
  `reason` text,
  `cost` decimal(10,2) DEFAULT '0.00',
  `status` enum('pending','approved','rejected','completed') DEFAULT 'pending',
  `requested_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `processed_at` datetime,
  `processed_by` int,
  `metadata` json DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `system_settings`
--

CREATE TABLE `system_settings` (
  `id` int NOT NULL,
  `setting_key` varchar(100) NOT NULL,
  `setting_value` text,
  `setting_type` enum('string','integer','boolean','json') DEFAULT 'string',
  `category` varchar(50) DEFAULT 'general',
  `description` text,
  `is_public` tinyint(1) DEFAULT '0',
  `updated_by` int,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id_notification` int NOT NULL,
  `user_id` int NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `type` enum('info','success','warning','error') DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT '0',
  `action_url` varchar(500),
  `metadata` json DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `read_at` datetime
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Legacy table compatibility (keeping for migration)
--

CREATE TABLE `history` (
  `id_history` int NOT NULL,
  `keys_id` varchar(33) DEFAULT NULL,
  `user_do` varchar(33) DEFAULT NULL,
  `info` mediumtext NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

CREATE TABLE `referral_code` (
  `id_reff` int NOT NULL,
  `code` varchar(128) DEFAULT NULL,
  `set_saldo` int DEFAULT NULL,
  `used_by` varchar(66) DEFAULT NULL,
  `created_by` varchar(66) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

-- --------------------------------------------------------

--
-- Indexes for all tables
--

ALTER TABLE `apps`
  ADD PRIMARY KEY (`id_app`),
  ADD KEY `developer_id` (`developer_id`),
  ADD KEY `status` (`status`),
  ADD KEY `global_maintenance` (`global_maintenance`);

ALTER TABLE `app_versions`
  ADD PRIMARY KEY (`id_version`),
  ADD KEY `app_id` (`app_id`),
  ADD KEY `version_number` (`version_number`),
  ADD KEY `is_active` (`is_active`);

ALTER TABLE `users`
  ADD PRIMARY KEY (`id_users`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `level` (`level`),
  ADD KEY `status` (`status`),
  ADD KEY `uplink` (`uplink`);

ALTER TABLE `license_keys`
  ADD PRIMARY KEY (`id_key`),
  ADD UNIQUE KEY `license_key` (`license_key`),
  ADD KEY `app_id` (`app_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `reseller_id` (`reseller_id`),
  ADD KEY `developer_id` (`developer_id`),
  ADD KEY `status` (`status`),
  ADD KEY `expires_at` (`expires_at`);

ALTER TABLE `reseller_apps`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `reseller_app_unique` (`reseller_id`,`app_id`),
  ADD UNIQUE KEY `invite_code` (`invite_code`),
  ADD KEY `developer_id` (`developer_id`),
  ADD KEY `app_id` (`app_id`);

ALTER TABLE `invite_codes`
  ADD PRIMARY KEY (`id_invite`),
  ADD UNIQUE KEY `code` (`code`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `app_id` (`app_id`),
  ADD KEY `target_role` (`target_role`),
  ADD KEY `status` (`status`);

ALTER TABLE `invite_code_usage`
  ADD PRIMARY KEY (`id`),
  ADD KEY `invite_code_id` (`invite_code_id`),
  ADD KEY `used_by` (`used_by`);

ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id_transaction`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `transaction_type` (`transaction_type`),
  ADD KEY `status` (`status`),
  ADD KEY `reference_id` (`reference_id`,`reference_type`);

ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id_log`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `action` (`action`),
  ADD KEY `reference_type` (`reference_type`,`reference_id`);

ALTER TABLE `hwid_resets`
  ADD PRIMARY KEY (`id_reset`),
  ADD KEY `license_key_id` (`license_key_id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `status` (`status`);

ALTER TABLE `system_settings`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `setting_key` (`setting_key`),
  ADD KEY `category` (`category`);

ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id_notification`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `is_read` (`is_read`),
  ADD KEY `type` (`type`);

ALTER TABLE `history`
  ADD PRIMARY KEY (`id_history`);

ALTER TABLE `referral_code`
  ADD PRIMARY KEY (`id_reff`);

-- --------------------------------------------------------

--
-- AUTO_INCREMENT for all tables
--

ALTER TABLE `apps`
  MODIFY `id_app` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `app_versions`
  MODIFY `id_version` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `users`
  MODIFY `id_users` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `license_keys`
  MODIFY `id_key` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `reseller_apps`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `invite_codes`
  MODIFY `id_invite` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `invite_code_usage`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `transactions`
  MODIFY `id_transaction` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `activity_logs`
  MODIFY `id_log` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `hwid_resets`
  MODIFY `id_reset` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `system_settings`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `notifications`
  MODIFY `id_notification` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `history`
  MODIFY `id_history` int NOT NULL AUTO_INCREMENT;

ALTER TABLE `referral_code`
  MODIFY `id_reff` int NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------

--
-- Foreign key constraints
--

ALTER TABLE `apps`
  ADD CONSTRAINT `apps_developer_fk` FOREIGN KEY (`developer_id`) REFERENCES `users` (`id_users`) ON DELETE CASCADE;

ALTER TABLE `app_versions`
  ADD CONSTRAINT `app_versions_app_fk` FOREIGN KEY (`app_id`) REFERENCES `apps` (`id_app`) ON DELETE CASCADE;

ALTER TABLE `license_keys`
  ADD CONSTRAINT `license_keys_app_fk` FOREIGN KEY (`app_id`) REFERENCES `apps` (`id_app`) ON DELETE CASCADE,
  ADD CONSTRAINT `license_keys_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_users`) ON DELETE SET NULL,
  ADD CONSTRAINT `license_keys_reseller_fk` FOREIGN KEY (`reseller_id`) REFERENCES `users` (`id_users`) ON DELETE SET NULL,
  ADD CONSTRAINT `license_keys_developer_fk` FOREIGN KEY (`developer_id`) REFERENCES `users` (`id_users`) ON DELETE CASCADE;

ALTER TABLE `reseller_apps`
  ADD CONSTRAINT `reseller_apps_reseller_fk` FOREIGN KEY (`reseller_id`) REFERENCES `users` (`id_users`) ON DELETE CASCADE,
  ADD CONSTRAINT `reseller_apps_app_fk` FOREIGN KEY (`app_id`) REFERENCES `apps` (`id_app`) ON DELETE CASCADE,
  ADD CONSTRAINT `reseller_apps_developer_fk` FOREIGN KEY (`developer_id`) REFERENCES `users` (`id_users`) ON DELETE CASCADE;

ALTER TABLE `invite_codes`
  ADD CONSTRAINT `invite_codes_creator_fk` FOREIGN KEY (`created_by`) REFERENCES `users` (`id_users`) ON DELETE CASCADE,
  ADD CONSTRAINT `invite_codes_app_fk` FOREIGN KEY (`app_id`) REFERENCES `apps` (`id_app`) ON DELETE CASCADE;

ALTER TABLE `invite_code_usage`
  ADD CONSTRAINT `invite_usage_code_fk` FOREIGN KEY (`invite_code_id`) REFERENCES `invite_codes` (`id_invite`) ON DELETE CASCADE,
  ADD CONSTRAINT `invite_usage_user_fk` FOREIGN KEY (`used_by`) REFERENCES `users` (`id_users`) ON DELETE CASCADE;

ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_users`) ON DELETE CASCADE;

ALTER TABLE `activity_logs`
  ADD CONSTRAINT `activity_logs_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_users`) ON DELETE SET NULL;

ALTER TABLE `hwid_resets`
  ADD CONSTRAINT `hwid_resets_key_fk` FOREIGN KEY (`license_key_id`) REFERENCES `license_keys` (`id_key`) ON DELETE CASCADE,
  ADD CONSTRAINT `hwid_resets_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_users`) ON DELETE CASCADE,
  ADD CONSTRAINT `hwid_resets_processor_fk` FOREIGN KEY (`processed_by`) REFERENCES `users` (`id_users`) ON DELETE SET NULL;

ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users` (`id_users`) ON DELETE CASCADE;

-- --------------------------------------------------------

--
-- Insert default system settings
--

INSERT INTO `system_settings` (`setting_key`, `setting_value`, `setting_type`, `category`, `description`, `is_public`) VALUES
('site_name', 'KuroPanel', 'string', 'general', 'Site name', 1),
('site_description', 'License Management System', 'string', 'general', 'Site description', 1),
('maintenance_mode', '0', 'boolean', 'general', 'Global maintenance mode', 0),
('registration_enabled', '1', 'boolean', 'general', 'Allow new registrations', 0),
('telegram_bot_token', '', 'string', 'telegram', 'Main Telegram bot token', 0),
('telegram_notifications', '1', 'boolean', 'telegram', 'Enable Telegram notifications', 0),
('hwid_reset_cost', '5.00', 'string', 'licensing', 'Cost for HWID reset', 0),
('default_license_duration', '30', 'integer', 'licensing', 'Default license duration in days', 0),
('commission_rate', '10.00', 'string', 'financial', 'Default commission rate for resellers', 0),
('currency_symbol', '$', 'string', 'financial', 'Currency symbol', 1),
('min_balance_deposit', '1.00', 'string', 'financial', 'Minimum balance deposit', 0);

-- --------------------------------------------------------

--
-- Insert default admin user
--

INSERT INTO `users` (`fullname`, `username`, `email`, `level`, `saldo`, `status`, `password`, `created_at`) VALUES
('System Administrator', 'admin', 'admin@kuropanel.local', 1, 1000.00, 1, '$2y$08$/CsSVgrGgCqVcievCuR2COPnlMIpRz6kA.hzItBD/xd1Cx0hj0kMK', NOW());

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
