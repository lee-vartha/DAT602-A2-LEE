DROP DATABASE IF EXISTS gamedb;
CREATE DATABASE gamedb;
USE gamedb; -- this is the database name

SELECT 'Connected to the database gamedb' AS STATUS;

DELIMITER $$
CREATE PROCEDURE TableSetup()
BEGIN
-- dropping any existing tables
DROP TABLE IF EXISTS Chat_Player, Item_Inventory, Item_Tile, Flower, Chat, Player, Item, Game, Map, Tile;

-- creating the 'player' table
	CREATE TABLE Player(
		PlayerID INT AUTO_INCREMENT PRIMARY KEY,
        Username VARCHAR(255) UNIQUE NOT NULL,
        Email VARCHAR(255) NOT NULL,
        PasswordHash VARCHAR(255) NOT NULL,
        `Status` VARCHAR(255) DEFAULT 'OFFLINE', -- others could include 'ONLINE, LOCKED_OUT' etc.
        LoginAttempts INT DEFAULT 0,
        IsAdmin BOOLEAN
    );
    
    
-- creating the 'game' table
	CREATE TABLE Game(
		GameID INT AUTO_INCREMENT PRIMARY KEY, -- primary key
        `Status` VARCHAR(255) DEFAULT 'IN_PROGRESS', -- others could include 'COMPLETED, CANCELLED' etc.
        Player1ID INT, -- foreign key
        Player2ID INT, -- foreign key
        StartTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        EndTime TIMESTAMP NULL,
        ScoreRecord INT,
        FOREIGN KEY (Player1ID) REFERENCES Player(PlayerID), -- foreign key referencing
        FOREIGN KEY (Player1ID) REFERENCES Player(PlayerID) -- foreign key referencing
    );
    
-- creating the 'map' table
	CREATE TABLE Map (
		MapID INT AUTO_INCREMENT PRIMARY KEY, -- primary key
        GameID INT, -- foreign key
        TotalTiles INT,
        BoardSize VARCHAR(255), -- so that i can do '15x15'
        FOREIGN KEY (GameID) REFERENCES Game(GameID) -- foreign key referencing
    );
    
-- creating the 'tile' table
	CREATE TABLE Tile (
		TileID INT AUTO_INCREMENT PRIMARY KEY, -- primary key
        MapID INT, -- foreign key
        TileNumber INT UNIQUE, 
        XCoordinate INT,
        YCoordinate INT,
        HasItem BOOLEAN DEFAULT FALSE,
        IsOccupied BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (MapID) REFERENCES Map(MapID) -- foreign key referencing
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
    
    CREATE TABLE PlayerGame (
		PlayerID INT,
        GameID INT,
        PRIMARY KEY (PlayerID, GameID),
        FOREIGN KEY (PlayerID) REFERENCES Player(PlayerID),
        FOREIGN KEY (GameID) REFERENCES Game(GameID)
    );
    
-- INSERTS:
-- inserting the data into the Player table
	INSERT INTO Player (Username, Email, PasswordHash, `Status`, IsAdmin)
    VALUES
    ('Player123', 'player1@gmail.com', 'hash1', 'OFFLINE', FALSE),
    ('Player321', 'player2@gmail.com', 'hash2', 'ONLINE', FALSE);
    
-- inserting the data into the Game table
	INSERT INTO Game (`Status`, Player1ID, Player2ID)
    VALUES
    ('IN_PROGRESS', 1, 2),
    ('COMPLETED', 1, 2);

-- inserting the data into the Map table
	INSERT INTO Map (GameID, TotalTiles, BoardSize) 
    VALUES
    (1, 30, '15x15');

-- inserting the data into the Tile table
	INSERT INTO Tile (MapID, TileNumber, XCoordinate, YCoordinate, HasItem, IsOccupied)
    VALUES
    (1, 2, 20, 30, 1, 0),
    (1, 5, 13, 20, 0, 0);

-- inserting the data into the Item table
	INSERT INTO Item (GameID, ItemName, ItemType, Effect, Duration) 
    VALUES
    (1, 'Pollen Armor', 'Shield Defenses', 'Protects from attacks', 10),
    (1, 'Nectar Rush', 'Speed', 'Increases speed', 10),
    (1, 'Honey Trap', 'Trap', 'Slows down other opponent', 5),
    (1, 'Bees Knees', 'Attack', 'Stings other opponent', 5);

-- inserting data into the Flower table
	INSERT INTO Flower (TileID, FlowerType, `Status`)
    VALUES
    (2, 'Small Flower', 'Drained'), -- means that the flower has all their pollen drained
    (5, 'Big Flower', 'Bloomed'); -- means that the flower is fresh to harvest pollen from
    
-- inserting data into the Chat table
	INSERT INTO Chat (GameID, PlayerID, Message) VALUES
    (1, 2, 'I am about to win!'),
    (1, 1, 'I dont want to lose!!!');
    
-- INDEXES
-- creating the indexes
	CREATE INDEX idx_player_username ON Player(Username);
    CREATE INDEX idx_flower_tile ON Flower(TileID);
    CREATE INDEX idx_tile_map ON Tile(MapID);
	CREATE INDEX idx_item_game ON Item(GameID);
    
END $$
DELIMITER ;

CALL TableSetup();













