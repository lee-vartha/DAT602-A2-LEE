DROP DATABASE IF EXISTS gamedb;
CREATE DATABASE gamedb;
USE gamedb; -- this is the database

SET SQL_SAFE_UPDATES = 0;

DELIMITER $$
CREATE PROCEDURE TableSetup()
BEGIN
-- dropping any existing tables
DROP TABLE IF EXISTS Chat_Player, Item_Inventory, PlayerGame, Item_Tile, Flower, Chat, Player, Item, Game, Map, Board, Tile;

CREATE TABLE Player( 	
   PlayerID INT AUTO_INCREMENT PRIMARY KEY NOT NULL,
   Username VARCHAR(50),
   `Password` VARCHAR(50),
   Attempts INT DEFAULT 0,
   LOCKED_OUT BOOL DEFAULT FALSE,
   IsAdmin BOOLEAN DEFAULT FALSE,
   `Status` VARCHAR(255) DEFAULT 'OFFLINE' -- others could include 'ONLINE, LOCKED_OUT' etc.
);


    -- creating the 'map' table
	CREATE TABLE Map (
		MapID INT AUTO_INCREMENT PRIMARY KEY, -- primary key
        TotalTiles INT,
        BoardSize VARCHAR(255) -- so that i can do '15x15'
    );
    
-- creating the 'game' table
	CREATE TABLE Game(
		GameID INT AUTO_INCREMENT PRIMARY KEY NOT NULL, -- primary key
        `Status` VARCHAR(255) DEFAULT 'IN_PROGRESS', -- others could include 'COMPLETED, CANCELLED' etc.
        Player1ID INT, -- foreign key
        Player2ID INT, -- foreign key
        StartTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        EndTime TIMESTAMP NULL,
        ScoreRecord INT,
        MapID INT,
        FOREIGN KEY (Player1ID) REFERENCES Player(PlayerID), -- foreign key referencing
        FOREIGN KEY (Player2ID) REFERENCES Player(PlayerID), -- foreign key referencing
        FOREIGN KEY (MapID) REFERENCES Map(MapID)
    );
    
	CREATE TABLE PlayerGame (
		PlayerID INT NOT NULL,
		GameID INT NOT NULL,
		PRIMARY KEY (PlayerID, GameID),
		FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID) ON DELETE CASCADE,
		FOREIGN KEY (GameID) REFERENCES Game(GameID) ON DELETE CASCADE
	);


	CREATE TABLE Board(
		BoardID INT AUTO_INCREMENT PRIMARY KEY,
		max_row INT NOT NULL DEFAULT 10,
		max_col INT NOT NULL DEFAULT 10
	);

	CREATE TABLE Tile(
		TileID INT AUTO_INCREMENT PRIMARY KEY,
        MapID INT,
		`ROW` INT NOT NULL, -- X COORDINATE
		COL INT NOT NULL, -- Y COORDINATE
		flower INT DEFAULT 10,
		rock INT DEFAULT -10,
		BoardID INT NOT NULL,
		TileType INT NOT NULL DEFAULT 0, 
		FOREIGN KEY (BoardID) REFERENCES Board(BoardID),
        FOREIGN KEY (MapID) REFERENCES Map(MapID)
	);
    
-- creating the 'item' table
	CREATE TABLE Item (
		ItemID INT AUTO_INCREMENT PRIMARY KEY, -- primary key
        GameID INT, -- foreign key
        ItemName VARCHAR(255),
        ItemType VARCHAR(255),
        Effect VARCHAR(255),
        Duration INT,
        FOREIGN KEY (GameID) REFERENCES Game(GameID) -- foreign key referencing
    );
    
-- creating the 'flower' table
	CREATE TABLE Flower (
		FlowerID INT AUTO_INCREMENT PRIMARY KEY, -- primary key
        TileID INT, -- foreign key
        FlowerType VARCHAR(255),
        `Status` VARCHAR(255) DEFAULT 'BLOOMED',
        FOREIGN KEY (TileID) REFERENCES Tile(TileID) -- foreign key referencing
    );
    
-- creating the 'chat' table
	CREATE TABLE Chat (
		ChatID INT AUTO_INCREMENT PRIMARY KEY,
        GameID INT, -- foreign key
        PlayerID INT, -- foreign key
        Message VARCHAR(255),
        `Timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (GameID) REFERENCES Game(GameID), -- foreign key referencing
        FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID) -- foreign key referencing
	);
    
    
-- creating the 'item_tile' table join
	CREATE TABLE Item_Tile (
		ItemID INT, -- primary key, foreign key
		TileID INT, -- primary key, foreign key
		PRIMARY KEY (ItemID, TileID),
		FOREIGN KEY (ItemID) REFERENCES Item(ItemID), -- foreign key referencing
		FOREIGN KEY (TileID) REFERENCES Tile(TileID) -- foreign key referencing
	);
    
-- creating the 'chat_player' table join
	CREATE TABLE Chat_Player(
		ChatID INT, -- primary key, foreign key
        PlayerID INT, -- primary key, foreign key
        PRIMARY KEY (ChatID, PlayerID),
        FOREIGN KEY (ChatID) REFERENCES Chat(ChatID), -- foreign key referencing
        FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID) -- foreign key referencing
    );
    
-- creating the 'item_inventory' table join
	CREATE TABLE Item_Inventory (
		ItemID INT, -- primary key, foreign key
        PlayerID INT, -- primary key, foreign key
        PRIMARY KEY (ItemID, PlayerID), 
        FOREIGN KEY (ItemID) REFERENCES Item(ItemID),
        FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID)
    );
    
   
    
-- INSERTS:

-- inserting for the player data
	INSERT INTO Player (Username, `Password`)
	VALUES ('admin', 'admin'), ('user', 'password');

    -- inserting the data into the Map table
	INSERT INTO Map (MapID, TotalTiles, BoardSize) 
    VALUES
    (1, 30, '15x15');
	
-- inserting the data into the Game table
	INSERT INTO Game (`Status`, Player1ID, Player2ID, GameID)
    VALUES
    ('IN_PROGRESS', 1, 2, 1),
    ('COMPLETED', 1, 2, 2);

-- inserting the data into the Item table
	INSERT INTO Item (GameID, ItemName, ItemType, Effect, Duration) 
    VALUES
    (1, 'Pollen Armor', 'Shield Defenses', 'Protects from attacks', 10),
    (1, 'Nectar Rush', 'Speed', 'Increases speed', 10),
    (1, 'Honey Trap', 'Trap', 'Slows down other opponent', 5),
    (1, 'Bees Knees', 'Attack', 'Stings other opponent', 5);

-- inserting data into the Flower table
	INSERT INTO Flower (FlowerType, `Status`)
    VALUES
    ('Small Flower', 'Drained'), -- means that the flower has all their pollen drained
    ('Big Flower', 'Bloomed'); -- means that the flower is fresh to harvest pollen from
    
-- inserting data into the Chat table
	INSERT INTO Chat (GameID, PlayerID, Message) VALUES
    (1, 2, 'I am about to win!'),
    (1, 1, 'I dont want to lose!!!');
    
    INSERT INTO PlayerGame (GameID, PlayerID) VALUES 
	(1, 1),
	(2, 2);



-- INDEXES
-- creating the indexes
	CREATE INDEX idx_player_username ON Player(Username);
    CREATE INDEX idx_flower_tile ON Flower(TileID);
    CREATE INDEX idx_tile_map ON Tile(MapID);
	CREATE INDEX idx_item_game ON Item(GameID);
    
END $$
DELIMITER ;

CALL TableSetup();



-- CODE TO LOGIN TO THE SYSTEM - 4 MARKS
DROP PROCEDURE IF EXISTS Login;
DELIMITER $$
CREATE PROCEDURE Login(IN pUsername VARCHAR(50), IN pPassword VARCHAR(50))
BEGIN
    DECLARE numAttempts INT DEFAULT NULL;
    DECLARE isLockedOut BOOL DEFAULT FALSE;
	DECLARE dbIsAdmin BOOL DEFAULT FALSE;
    
    -- Check if the user exists and fetch attempts and locked status
    SELECT Attempts, LOCKED_OUT, IsAdmin
    INTO numAttempts, isLockedOut, dbIsAdmin
    FROM Player
    WHERE Username = pUsername;

    -- If the user doesn't exist
    IF numAttempts IS NULL THEN
        SELECT 'User not found' AS Message, FALSE AS IsAdmin;

    -- Check if the account is locked
    ELSEIF isLockedOut = TRUE THEN
        SELECT 'Locked Out.' AS Message, dbIsAdmin AS IsAdmin;
        

    -- Validate username and password
    ELSEIF EXISTS (
        SELECT * FROM Player
        WHERE Username = pUsername AND Password = pPassword
    ) THEN
        -- Reset attempts after successful login
        UPDATE Player
        SET Attempts = 0, Status = 'ONLINE'
        WHERE Username = pUsername;

        SELECT 'Logged In' AS Message, IsAdmin AS IsAdmin
        FROM Player
        WHERE Username = pUsername;

    -- Incorrect password, increment attempts
    ELSE
        SET numAttempts = numAttempts + 1;

        -- If the user exceeds the maximum allowed attempts, lock the account
        IF numAttempts >= 5 THEN
            UPDATE Player
            SET LOCKED_OUT = TRUE
            WHERE Username = pUsername;
            SELECT 'Locked out. Contact support.' AS Message, FALSE AS IsAdmin;

        ELSE
            -- Update the number of attempts in the database
            UPDATE Player
            SET Attempts = numAttempts
            WHERE Username = pUsername;

            SELECT CONCAT('Wrong username or password. ', (5 - numAttempts), ' attempts left.') AS Message, isAdmin AS IsAdmin;
        END IF;
    END IF;
END$$
DELIMITER ;





-- CODE TO CREATE A NEW USER (EITHER IF ADMIN IS DOING IT OR IF USER THEMSELVES ARE DOING IT) - 4 MARKS
DROP PROCEDURE IF EXISTS AddUsername;
DELIMITER $$
CREATE PROCEDURE AddUsername(IN pUsername VARCHAR(50), IN pPassword VARCHAR(50))
BEGIN
    IF EXISTS (SELECT * 
               FROM Player
               WHERE Username = pUsername) THEN
        SELECT 'This name already exists!' AS Message;
    ELSE 
        INSERT INTO Player (Username, Password) VALUES (pUsername, pPassword);
        SELECT 'You have successfully registered into the game - Lets play!' AS Message;
    END IF;
END$$
DELIMITER ;





-- setting the 'admin' user to have admin privileges (setting isAdmin to 'true') 
	UPDATE Player
	SET IsAdmin = TRUE
	WHERE Username = 'admin';  

	-- getting the list of users
	SELECT * FROM Player;
    
SELECT PlayerID FROM Player;





-- CODE TO LOGOUT OF THE SYSTEM
DROP PROCEDURE IF EXISTS Logout;
DELIMITER $$
CREATE PROCEDURE Logout(IN pCurrentUsername VARCHAR(50))
BEGIN
    
    -- Set user status to 'OFFLINE'
    UPDATE Player
    SET Status = 'OFFLINE'
    WHERE Username = pCurrentUsername;
    SELECT 'user OFFLINE' AS Message;
END$$
DELIMITER ;





-- CODE TO CREATE A NEW GAME 
DROP PROCEDURE IF EXISTS NewGame;
DELIMITER $$
CREATE PROCEDURE NewGame(IN MapID INT, IN pCurrentUsername VARCHAR(50))
BEGIN
    DECLARE localPlayerID INT;
    DECLARE newGameID INT;

    SELECT PlayerID INTO localPlayerID FROM Player WHERE Username = pCurrentUsername; -- getting the ID of the current user 

    -- Check if the player was found
    IF localPlayerID IS NOT NULL THEN
        -- Insert new game with MapID and retrieve the new GameID
        INSERT INTO Game (MapID, `Status`) VALUES (MapID, 'ACTIVE');
        SET newGameID = LAST_INSERT_ID();

        -- Insert into PlayerGame only if this PlayerID-GameID combination doesn't already exist
        IF NOT EXISTS (SELECT * FROM PlayerGame WHERE PlayerID = localPlayerID AND GameID = newGameID) THEN
            INSERT INTO PlayerGame (PlayerID, GameID) VALUES (localPlayerID, newGameID);
            SELECT 'Game is created' AS Message;
        ELSE
            SELECT 'This player is already associated with this game.' AS Message;
        END IF;
    ELSE
        SELECT 'Player not found' AS Message;
    END IF;
END$$
DELIMITER ;


-- GETTING THE TILE TYPE 
DROP FUNCTION IF EXISTS get_tile_type;
DELIMITER $$
CREATE FUNCTION get_tile_type()  RETURNS INT
DETERMINISTIC
BEGIN
  IF ROUND(RAND() * 20) = 9 THEN
    RETURN 1;
  ELSEIF ROUND(RAND() * 10) = 9 THEN
     RETURN 2 ;
  ELSE 
     RETURN 0;
  END IF;
END$$
DELIMITER ; 


-- CODE TO MAKE A BOARD - 4 MARKS
DROP PROCEDURE IF EXISTS make_a_board; 
DELIMITER $$
CREATE PROCEDURE make_a_board(pMaxRow INT, pMaxCol INT)
BEGIN
	DECLARE new_board_id INT;
    DECLARE current_row INT DEFAULT 0;
    DECLARE current_col INT DEFAULT 0;
    DECLARE tile_type INT DEFAULT 0;
    
	INSERT INTO Board(max_row,max_col) 
    VALUES (pMaxRow,pMaxCol);
    
    SET new_board_id = LAST_INSERT_ID();
    
    WHILE current_row < pMaxRow DO
    SET current_col = 0;
		WHILE current_col < pMaxCol DO
           SET tile_type = get_tile_type();
           
		
			INSERT INTO Tile(BoardID, `ROW`, COL, TileType)
              VALUE (new_board_id, current_row, current_col, tile_type);
			SET current_col = current_col + 1;
            END WHILE;
            SET current_row = current_row +1;
        END WHILE;
END$$
DELIMITER ;





-- CODE TO PLACE AN ITEM ON A TILE








-- CODE FOR PLAYER MOVEMENT








-- CODE FOR PLAYER SCORING








-- CODE FOR ACQUIRING INVENTORY








-- CODE FOR MOVING AN ITEM (NPC EFFECT)








-- CODE TO DELETE/KILL AN EXISTING GAME (FOR ADMIN) - 4 MARKS
DROP PROCEDURE IF EXISTS DeleteGame;
DELIMITER $$
CREATE PROCEDURE DeleteGame(IN pGameID INT)
BEGIN
	DECLARE result VARCHAR(50); -- result of deletion
    
    IF EXISTS (SELECT 1 FROM Game WHERE GameID = pGameID) THEN
    DELETE FROM Game WHERE GameID = pGameID;
    SET result = CONCAT('Game ', pGameID, ' has been deleted successfully');
ELSE
	SET result = CONCAT('The game with the ID: ', pGameID, 'hasnt been found');
END IF;

SELECT result AS Message;
END $$
DELIMITER ;





-- CODE TO UPDATE THE DETAILS OF AN EXISTING USER - 4 MARKS
DROP PROCEDURE IF EXISTS UpdateUser;
DELIMITER $$
CREATE PROCEDURE UpdateUser(IN pUsername VARCHAR(50), pPassword VARCHAR(50))
BEGIN
	    UPDATE Player
    SET Username = pUsername, Password = pPassword
    WHERE
        Username = pUsername;
        
    SELECT 'Updated user' as Message;

END$$
DELIMITER ;





-- CODE TO DELETE A USER (WHETHER ITS ADMIN DELETING A USER OR IF A  USER IS DELETING THEMSELVES) - 4 MARKS
DROP PROCEDURE IF EXISTS DeleteUser;
DELIMITER $$
CREATE PROCEDURE DeleteUser(IN pUsername VARCHAR(50))
BEGIN
	DECLARE userExists INT;

	SELECT COUNT(*) INTO userExists FROM Player WHERE Username = pUsername;
    
    IF userExists > 0 THEN    
	DELETE FROM Player
    WHERE Username = pUsername;
    
		SELECT 'Deleted User' AS Message;
    ELSE
            SELECT CONCAT('Cannot find the user: ', (pUsername), '.. good luck') AS Message;
    END IF;

END$$
DELIMITER ;





-- CODE TO GET A LIST OF ALL THE ACTIVE GAMES
DROP PROCEDURE IF EXISTS GetActiveGames;
DELIMITER $$
CREATE PROCEDURE GetActiveGames()
BEGIN
	SELECT GameID, MapID, `Status`
    FROM Game
    WHERE `Status` = 'Active';
END $$
DELIMITER ;

-- CODE TO GET A LIST OF ALL PLAYERS
DROP PROCEDURE IF EXISTS GetAllPlayers;
DELIMITER $$
CREATE PROCEDURE GetAllPlayers()
BEGIN
	SELECT Username
    FROM Player ;
END$$
DELIMITER ;


-- CODE TO GET ALL TILES
DROP PROCEDURE IF EXISTS GetAllTiles;
DELIMITER $$
CREATE PROCEDURE GetAllTiles()
BEGIN
    SELECT TileID, `ROW`, COL, flower, rock, tileType FROM Tile; 
END $$
DELIMITER ;





-- from tutorial
DROP FUNCTION IF EXISTS RandPlusOrMinus;
DELIMITER $$
CREATE FUNCTION `RandPlusOrMinus`(pRange int) RETURNS int
    DETERMINISTIC
BEGIN
	return round(rand() * pRange)- (pRange/2);
END$$
DELIMITER ;






DROP PROCEDURE IF EXISTS MakeGameData;
DELIMITER $$
CREATE PROCEDURE `MakeGameData`(pMaxRow int, pMaxCol int)
BEGIN
    DECLARE current_row INT DEFAULT 0;
    DECLARE current_col INT DEFAULT 0;
    DECLARE new_board_id INT;
    
    -- Clear existing data
    TRUNCATE TABLE Tile;
    
    INSERT INTO Board(max_row, max_col) VALUES (pMaxRow, pMaxCol);
    SET new_board_id = LAST_INSERT_ID();
    
    -- Build the board
    WHILE current_row < pMaxRow DO
        WHILE current_col < pMaxCol DO
            INSERT INTO Tile(`row`, `col`, flower, rock, BoardID, TileType)
            VALUES (current_row, current_col, RandPlusOrMinus(20), RandPlusOrMinus(20), new_board_id, 0);
            SET current_col = current_col + 1;
        END WHILE;
        SET current_col = 0;
        SET current_row = current_row + 1;
    END WHILE;
END $$
DELIMITER ;	


