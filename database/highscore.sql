CREATE TABLE highscore (
   map_id int NOT NULL,
   game_mode int NOT NULL,
   version VARCHAR (16) NOT NULL,
   username VARCHAR (256) NOT NULL,
   steam_id VARCHAR (256) NOT NULL,
   difficulty int NOT NULL,
   score int NOT NULL
);