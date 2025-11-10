CREATE TABLE IF NOT EXISTS `ghost_shop_wallet` (
  `identifier` varchar(60) NOT NULL,
  `coins` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
