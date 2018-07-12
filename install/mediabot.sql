SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";

CREATE TABLE `ACTIONS_LOG` (
  `id_actions_log` bigint(20) NOT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `id_user` bigint(20) DEFAULT NULL,
  `id_channel` bigint(20) DEFAULT NULL,
  `hostmask` varchar(255) NOT NULL,
  `action` varchar(255) NOT NULL,
  `args` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `ACTIONS_QUEUE` (
  `id_actions_queue` bigint(20) NOT NULL,
  `ts` datetime NOT NULL,
  `command` varchar(255) NOT NULL,
  `params` varchar(255) NOT NULL,
  `result1` varchar(255) DEFAULT NULL,
  `result2` varchar(255) DEFAULT NULL,
  `result3` varchar(255) DEFAULT NULL,
  `result4` varchar(255) DEFAULT NULL,
  `result5` varchar(255) DEFAULT NULL,
  `result6` varchar(255) DEFAULT NULL,
  `status` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `CHANNEL` (
  `id_channel` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `creation_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `description` varchar(255) DEFAULT NULL,
  `key` varchar(255) DEFAULT NULL,
  `chanmode` varchar(255) DEFAULT NULL,
  `auto_join` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `CHANNEL_LOG` (
  `id_channel_log` bigint(20) NOT NULL,
  `id_channel` bigint(20) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `event_type` varchar(255) CHARACTER SET latin1 NOT NULL,
  `nick` varchar(255) CHARACTER SET latin1 NOT NULL,
  `userhost` varchar(255) NOT NULL,
  `publictext` varchar(255) CHARACTER SET latin1 DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `CHANNEL_PURGED` (
  `id_channel_purged` bigint(20) NOT NULL,
  `id_channel` bigint(20) NOT NULL,
  `name` varchar(255) NOT NULL,
  `purge_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `description` varchar(255) DEFAULT NULL,
  `key` varchar(255) DEFAULT NULL,
  `chanmode` varchar(255) DEFAULT NULL,
  `auto_join` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `CONSOLE` (
  `id_console` bigint(20) NOT NULL,
  `id_parent` bigint(20) DEFAULT NULL,
  `position` int(11) NOT NULL DEFAULT '1',
  `level` int(11) NOT NULL DEFAULT '0',
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `url` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `NETWORK` (
  `id_network` bigint(20) NOT NULL,
  `network_name` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `PUBLIC_COMMANDS` (
  `id_public_commands` bigint(20) NOT NULL,
  `id_user` bigint(20) DEFAULT NULL,
  `id_public_commands_category` bigint(20) NOT NULL,
  `creation_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `command` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `description` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `action` varchar(255) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
  `hits` bigint(20) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `PUBLIC_COMMANDS` (`id_public_commands`, `id_user`, `id_public_commands_category`, `creation_date`, `command`, `description`, `action`) VALUES
(1, NULL, 1, '2018-02-04 06:04:42', 'slap', 'Slap a user', 'ACTION %c slaps %n around a bit with a large trout'),
(2, NULL, 1, '2018-02-04 06:06:55', 'dice', 'Play dice', 'PRIVMSG %c plays dice... Result : %d');

CREATE TABLE `PUBLIC_COMMANDS_CATEGORY` (
  `id_public_commands_category` bigint(20) NOT NULL,
  `description` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `PUBLIC_COMMANDS_CATEGORY` (`id_public_commands_category`, `description`) VALUES
(1, 'General');

CREATE TABLE `SERVERS` (
  `id_server` bigint(20) NOT NULL,
  `id_network` bigint(20) NOT NULL,
  `server_hostname` varchar(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `USER` (
  `id_user` bigint(20) NOT NULL,
  `creation_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `hostmasks` varchar(255) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `nickname` varchar(255) CHARACTER SET latin1 NOT NULL DEFAULT '',
  `password` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `username` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `id_user_level` bigint(20) NOT NULL,
  `info1` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `info2` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `last_login` timestamp NULL DEFAULT NULL,
  `auth` int(11) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `USER_CHANNEL` (
  `id_user_channel` bigint(20) NOT NULL,
  `id_user` bigint(20) NOT NULL,
  `id_channel` bigint(20) NOT NULL,
  `level` bigint(20) NOT NULL DEFAULT '0',
  `greet` varchar(255) CHARACTER SET latin1 DEFAULT NULL,
  `automode` varchar(255) CHARACTER SET latin1 NOT NULL DEFAULT 'NONE'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `USER_LEVEL` (
  `id_user_level` bigint(20) NOT NULL,
  `level` int(11) NOT NULL,
  `description` varchar(255) CHARACTER SET latin1 NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO `USER_LEVEL` (`id_user_level`, `level`, `description`) VALUES
(1, 0, 'Owner'),
(2, 1, 'Master'),
(3, 2, 'Administrator'),
(4, 3, 'User');

CREATE TABLE `WEBLOG` (
  `id_weblog` bigint(20) NOT NULL,
  `login_date` datetime NOT NULL,
  `nickname` varchar(255) NOT NULL,
  `password` varchar(255) DEFAULT NULL,
  `ip` varchar(255) NOT NULL,
  `hostname` varchar(255) DEFAULT NULL,
  `logresult` tinyint(1) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


ALTER TABLE `ACTIONS_LOG`
  ADD PRIMARY KEY (`id_actions_log`);

ALTER TABLE `CHANNEL`
  ADD PRIMARY KEY (`id_channel`),
  ADD UNIQUE KEY `name` (`name`);

ALTER TABLE `CHANNEL_LOG`
  ADD PRIMARY KEY (`id_channel_log`),
  ADD KEY `ts` (`ts`),
  ADD KEY `nick` (`nick`),
  ADD KEY `userhost` (`userhost`),
  ADD KEY `ts_2` (`ts`);

ALTER TABLE `CHANNEL_PURGED`
  ADD PRIMARY KEY (`id_channel_purged`);

ALTER TABLE `CONSOLE`
  ADD PRIMARY KEY (`id_console`);

ALTER TABLE `NETWORK`
  ADD PRIMARY KEY (`id_network`),
  ADD UNIQUE KEY `network_name` (`network_name`);

ALTER TABLE `PUBLIC_COMMANDS`
  ADD PRIMARY KEY (`id_public_commands`),
  ADD UNIQUE KEY `command` (`command`);

ALTER TABLE `PUBLIC_COMMANDS_CATEGORY`
  ADD PRIMARY KEY (`id_public_commands_category`);

ALTER TABLE `SERVERS`
  ADD PRIMARY KEY (`id_server`);

ALTER TABLE `USER`
  ADD PRIMARY KEY (`id_user`),
  ADD UNIQUE KEY `nickname` (`nickname`);

ALTER TABLE `USER_CHANNEL`
  ADD PRIMARY KEY (`id_user_channel`);

ALTER TABLE `USER_LEVEL`
  ADD PRIMARY KEY (`id_user_level`);

ALTER TABLE `WEBLOG`
  ADD PRIMARY KEY (`id_weblog`);


ALTER TABLE `ACTIONS_LOG`
  MODIFY `id_actions_log` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `CHANNEL`
  MODIFY `id_channel` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `CHANNEL_LOG`
  MODIFY `id_channel_log` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `CHANNEL_PURGED`
  MODIFY `id_channel_purged` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `CONSOLE`
  MODIFY `id_console` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `NETWORK`
  MODIFY `id_network` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `PUBLIC_COMMANDS`
  MODIFY `id_public_commands` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `PUBLIC_COMMANDS_CATEGORY`
  MODIFY `id_public_commands_category` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `SERVERS`
  MODIFY `id_server` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `USER`
  MODIFY `id_user` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `USER_CHANNEL`
  MODIFY `id_user_channel` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `USER_LEVEL`
  MODIFY `id_user_level` bigint(20) NOT NULL AUTO_INCREMENT;

ALTER TABLE `WEBLOG`
  MODIFY `id_weblog` bigint(20) NOT NULL AUTO_INCREMENT;
COMMIT;
