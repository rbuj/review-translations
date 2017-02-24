CREATE DATABASE IF NOT EXISTS dbaskbot DEFAULT CHARACTER SET UTF8 COLLATE utf8_general_ci;
GRANT ALL PRIVILEGES ON dbaskbot.* TO dbaskbotuser@localhost IDENTIFIED BY 'dbaskbotpassword';
