use gamedb;

-- tile script:


DROP TABLE IF EXISTS tblBoard, tblTile;
CREATE TABLE tblBoard(
	BoardID INT AUTO_INCREMENT PRIMARY KEY,
    max_row INT NOT NULL DEFAULT 10,
    max_col INT NOT NULL DEFAULT 10
);

CREATE TABLE tblTile(
	ID INT AUTO_INCREMENT PRIMARY KEY,
    `ROW` INT NOT NULL, -- X COORDINATE
    COL INT NOT NULL, -- Y COORDINATE
	flower INT DEFAULT 10,
    rock INT DEFAULT -10,
	BoardID INT NOT NULL,
	TileType INT NOT NULL DEFAULT 0, 
    FOREIGN KEY (BoardID) REFERENCES tblBoard(BoardID)
);


DROP FUNCTION IF EXISTS get_tile_type;
delimiter $$
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

DROP PROCEDURE IF EXISTS make_a_board;
DELIMITER $$
CREATE PROCEDURE make_a_board(pMaxRow INT, pMaxCol INT)
BEGIN
	DECLARE new_board_id INT;
    DECLARE current_row INT DEFAULT 0;
    DECLARE current_col INT DEFAULT 0;
    DECLARE tile_type INT DEFAULT 0;
    
	INSERT INTO tblBoard(max_row,max_col)
    VALUE (pMaxRow,pMaxCol);
    
    SET new_board_id = LAST_INSERT_ID();
    
    WHILE current_row < pMaxRow DO
		WHILE current_col < pMaxCol DO
           SET tile_type = get_tile_type();
           
            IF tile_type <> 0 then 
			  INSERT INTO tblTile(BoardID, `ROW`, COL, TileType)
              VALUE (new_board_id, current_row, current_col,tile_type);
			END IF;
			SET current_col = current_col + 1;
        END WHILE;
        
		SET current_col = 0;
        SET current_row = current_row + 1;
        
    END WHILE;
    
    #SELECT 'Added a board.' AS MESSAGE;
END$$
DELIMITER ;

CALL make_a_board(10,10);


DROP PROCEDURE IF EXISTS GetAllTiles;
DELIMITER $$
CREATE PROCEDURE GetAllTiles()
BEGIN
    SELECT id, `row`, col, flower, rock, tileType FROM tblTile; 
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
    TRUNCATE TABLE tblTile;
    
    INSERT INTO tblBoard(max_row, max_col) VALUES (pMaxRow, pMaxCol);
    SET new_board_id = LAST_INSERT_ID();
    
    -- Build the board
    WHILE current_row < pMaxRow DO
        WHILE current_col < pMaxCol DO
            INSERT INTO tblTile(`row`, `col`, flower, rock, BoardID, TileType)
            VALUES (current_row, current_col, RandPlusOrMinus(20), RandPlusOrMinus(20), new_board_id, 0);
            SET current_col = current_col + 1;
        END WHILE;
        SET current_col = 0;
        SET current_row = current_row + 1;
    END WHILE;
END $$
DELIMITER ;	

call `MakeGameData`(10,10);
SELECT * FROM tblBoard;
SELECT * from tblTile;


