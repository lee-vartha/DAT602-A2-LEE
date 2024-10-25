use gamedb;
-- THE BACKEND --
SET SQL_SAFE_UPDATES = 0;

-- getting the user
DROP TABLE IF EXISTS tblGetUser;
CREATE TABLE tblGetUser( 	
	PlayerID INT AUTO_INCREMENT PRIMARY KEY,
   UserName VARCHAR(50),
   `Password` VARCHAR(50) NOT NULL,
   Attempts INT DEFAULT 0,
   LOCKED_OUT BOOL DEFAULT FALSE,
   IsAdmin BOOLEAN DEFAULT FALSE,
   `Status` VARCHAR(255) DEFAULT 'OFFLINE' -- others could include 'ONLINE, LOCKED_OUT' etc.
);

-- logging in 
DROP PROCEDURE IF EXISTS Login;
DELIMITER $$
CREATE PROCEDURE Login(IN pUserName VARCHAR(50), IN pPassword VARCHAR(50))
BEGIN
    DECLARE numAttempts INT DEFAULT NULL;
    DECLARE isLockedOut BOOL DEFAULT FALSE;
	DECLARE dbIsAdmin BOOL DEFAULT FALSE;
    
    -- Check if the user exists and fetch attempts and locked status
    SELECT Attempts, LOCKED_OUT, IsAdmin
    INTO numAttempts, isLockedOut, dbIsAdmin
    FROM tblGetUser
    WHERE UserName = pUserName;

    -- If the user doesn't exist
    IF numAttempts IS NULL THEN
        SELECT 'User not found' AS Message, FALSE AS IsAdmin;

    -- Check if the account is locked
    ELSEIF isLockedOut = TRUE THEN
        SELECT 'Locked Out.' AS Message, dbIsAdmin AS IsAdmin;
        

    -- Validate username and password
    ELSEIF EXISTS (
        SELECT * FROM tblGetUser
        WHERE UserName = pUserName AND Password = pPassword
    ) THEN
        -- Reset attempts after successful login
        UPDATE tblGetUser
        SET Attempts = 0, Status = 'ONLINE'
        WHERE UserName = pUserName;

        SELECT 'Logged In' AS Message, IsAdmin AS IsAdmin
        FROM tblGetUser
        WHERE UserName = pUserName;

    -- Incorrect password, increment attempts
    ELSE
        SET numAttempts = numAttempts + 1;

        -- If the user exceeds the maximum allowed attempts, lock the account
        IF numAttempts >= 5 THEN
            UPDATE tblGetUser
            SET LOCKED_OUT = TRUE
            WHERE UserName = pUserName;
            SELECT 'Locked out. Contact support.' AS Message, FALSE AS IsAdmin;

        ELSE
            -- Update the number of attempts in the database
            UPDATE tblGetUser
            SET Attempts = numAttempts
            WHERE UserName = pUserName;

            SELECT CONCAT('Wrong username or password. ', (5 - numAttempts), ' attempts left.') AS Message, isAdmin AS IsAdmin;
        END IF;
    END IF;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS AddUserName;
-- creating a new user (whether its an admin doing it or a user doing it themselves
DELIMITER $$
CREATE PROCEDURE AddUserName(IN pUserName VARCHAR(50), IN pPassword VARCHAR(50))
BEGIN
    IF EXISTS (SELECT * 
               FROM tblGetUser
               WHERE UserName = pUserName) THEN
        SELECT 'This name already exists!' AS Message;
    ELSE 
        INSERT INTO tblGetUser (UserName, Password) VALUES (pUserName, pPassword);
        SELECT 'You have successfully registered into the game - Lets play!' AS Message;
    END IF;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS GetAllPlayers;
-- getting a list of all players
DELIMITER $$
CREATE PROCEDURE GetAllPlayers()
BEGIN
	SELECT UserName
    FROM tblGetUser ;
END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS DeleteUser;
-- deleting a user (whether its an admin doing it or a user themselves
DELIMITER $$
CREATE PROCEDURE DeleteUser(IN pUserName VARCHAR(50))
BEGIN
	DECLARE userExists INT;

	SELECT COUNT(*) INTO userExists FROM tblGetUser WHERE UserName = pUserName;
    
    IF userExists > 0 THEN    
	DELETE FROM tblGetUser
    WHERE UserName = pUserName;
    
		SELECT 'Deleted User' AS Message;
    ELSE
            SELECT CONCAT('Cannot find the user: ', (pUserName), '.. good luck') AS Message;
    END IF;

END$$
DELIMITER ;


DROP PROCEDURE IF EXISTS UpdateUser;
DELIMITER $$
CREATE PROCEDURE UpdateUser(IN pUserName VARCHAR(50), pPassword VARCHAR(50))
BEGIN
	    UPDATE tblGetUser
    SET Name = pPlayerName, Password = pPassword
    WHERE
        Name = pUserName;
        
    SELECT 'Updated player' as Message;

END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS Logout;
DELIMITER $$
CREATE PROCEDURE Logout(IN pUserName VARCHAR(50))
BEGIN
	SELECT pUserName AS DebugUserName;
    
    -- Set user status to 'OFFLINE'
    UPDATE tblGetUser
    SET Status = 'OFFLINE'
    WHERE UserName = pUserName;
END$$
DELIMITER ;



-- inserting users so that everytime i run/execute this script, there will always be users for usage
INSERT INTO tblGetUser (UserName, `Password`)
VALUES ('admin', 'admin'), ('user', 'password');

-- setting the 'admin' user to have admin privileges (setting isAdmin to 'true')
UPDATE tblGetUser
SET IsAdmin = TRUE
WHERE UserName = 'admin';  

-- getting the list of users
SELECT * FROM tblGetUser;




DROP PROCEDURE IF EXISTS NewGame;
DELIMITER $$
CREATE PROCEDURE NewGame(IN pMapID INT, pCurrentUsername VARCHAR(50))
BEGIN
	DECLARE PlayerID INT;
    DECLARE GameID INT;
        
    SELECT PlayerID INTO PlayerID 
    FROM tblGetUser
    WHERE Username = pCurrentUsername;
    
    IF PlayerID IS NULL THEN
		SELECT 'User not found or wrong username' AS Message;
	ELSE
		INSERT INTO Game (MapID, `Status`) VALUES (pMapID, 'In Progress');
		SET GameID = LAST_INSERT_ID();
	
		INSERT INTO PlayerGame(PlayerID, GameID)
		VALUES (PlayerID, GameID);
			
		UPDATE Player
		SET `Status` = 'IN PROGRESS'
		WHERE `Username` = pCurrentUsername;
		
		SELECT 'Game is created' AS Message;
	END IF;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS GetActiveGames;
DELIMITER $$
CREATE PROCEDURE GetActiveGames()
BEGIN
	SELECT GameID, MapID, `Status`
    FROM Game
    WHERE `Status` = 'Active';
END $$
DELIMITER ;



DROP PROCEDURE IF EXISTS UpdateUser;
DELIMITER $$
CREATE PROCEDURE UpdateUser (pUsername VARCHAR(255),
														   pPassword VARCHAR(255),
                                                           pAttempts INT,
                                                           pLockedOut BOOL
                                                           )
-- (_name,_password,_attempts,_locked_out)
BEGIN

	-- Needs to check if the tile is occupied!
    UPDATE tblGetUser
    SET Name = pUsername, Password = pPassword, Attempts = pAttempts, LOCKED_OUT = pLockedOut
    WHERE
        Name = pUsername;
        
    SELECT 'Updated player' as Message;
    
END$$
DELIMITER ;



