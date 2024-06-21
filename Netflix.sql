# Create tables and import csv files

USE netflix;

CREATE TABLE titles (
	id VARCHAR(50) NOT NULL,
	title VARCHAR(250) NOT NULL,
	type VARCHAR(20) NOT NULL,	
    description VARCHAR(2500) NULL,
	release_year YEAR NULL,
	age_certification VARCHAR(20) NULL,
	runtime VARCHAR(50) NULL,
	production_countries VARCHAR(50) NULL,
	seasons VARCHAR(50) NULL,
	imdb_id VARCHAR(50) NULL,
	imdb_score VARCHAR(50) NULL,
    imdb_votes VARCHAR(50) NULL,
	tmdb_popularity VARCHAR(50) NULL,
	tmdb_score VARCHAR(50) NULL,
    genre1 VARCHAR(20) NULL,
	genre2	VARCHAR(20) NULL,
    genre3	VARCHAR(20) NULL
);

LOAD DATA INFILE 'titles_final.csv'
INTO TABLE titles
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;


CREATE TABLE credits (
	person_id VARCHAR(50) NOT NULL,
    id VARCHAR(50) NOT NULL,
    name VARCHAR(100) NOT NULL,
    character_played VARCHAR(500) NULL,
    role VARCHAR(50) NOT NULL
);

LOAD DATA INFILE 'credits_final.csv'
INTO TABLE credits
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

ALTER TABLE titles
MODIFY COLUMN imdb_votes INT DEFAULT NULL;


-- Exploratory analysis

SELECT * FROM titles;

SELECT * FROM titles 
ORDER BY release_year;

SELECT type, count(type) AS count
FROM titles
GROUP BY type;

SELECT * FROM titles 
ORDER BY imdb_score DESC;


# Controversial (Biggest difference in IMDB and TMDB ratings)

SELECT id, title, type, imdb_score, tmdb_score, ABS(ROUND((CAST(imdb_score AS float) - CAST(tmdb_score AS float)), 1)) AS difference
FROM titles
WHERE imdb_score > 0 and tmdb_score > 0 
ORDER BY difference DESC
LIMIT 10;

# Actors/directors that have been active for the longest time (biggest difference in release year)

SELECT 
	name, 
    role, 
    MIN(release_year) AS FirstRelease, 
    MAX(release_year) AS MostRecentRelease, 
    (MAX(release_year) - min(release_year)) AS ActiveYears
FROM titles t
JOIN credits c ON t.id = c.id
GROUP BY name, role
ORDER BY ActiveYears DESC;

# Actors in the most movies
SELECT name, 
	count(name) AS count
FROM titles t
JOIN credits c ON t.id = c.id
WHERE role = 'actor'
GROUP BY name, role
ORDER BY count DESC;

# Most voted on shows/movies

SELECT * FROM titles
ORDER BY CAST(imdb_votes AS float) DESC;


# Highest rated films according to IMDb

SELECT * 
FROM titles
ORDER BY imdb_score DESC;

# Highest scored films according to IMDb (votes * score)

SELECT  title, name, role, ROUND((CAST(imdb_votes AS float) * CAST(imdb_score AS float)), 0) AS TotalPoints FROM titles t
JOIN credits c ON t.id = c.id 
WHERE role = "director"
ORDER BY CAST(imdb_votes AS float) DESC;

-- Genres
# Highest rated show/movie by genre

SELECT genre1, count(*) AS Count
FROM titles
WHERE genre1 <> ' '
GROUP BY genre1
ORDER BY Count DESC;

SELECT genre1, type, count(*) AS Count
FROM titles
WHERE genre1 <> ''
GROUP BY genre1, type
ORDER BY type, Count DESC;

-- Most active actors on Netflix in US production
SELECT c.name, count(c.name) AS count
FROM credits c
JOIN titles t ON t.id = c.id 
WHERE c.role = 'actor' AND t.production_countries = 'US'
GROUP BY c.name
ORDER BY count DESC;	

;

-- Average Score by genere
SELECT 
	genre1, 
	ROUND((SUM(imdb_score)+SUM(tmdb_score))/(count(*)*2), 1) AS AverageScore
FROM titles
WHERE imdb_score <> '' and tmdb_score <> '' and genre1 <> ''
GROUP BY genre1
ORDER BY AverageScore DESC;

SELECT release_year
FROM titles
ORDER BY release_year 
LIMIT 5;

-- Number of highly rated titles (at least 8.0 avg between IMDb and TMDb) before and after 2000s

SELECT title, ROUND((imdb_score+tmdb_score)/2, 1) AS AverageScore,
CASE 
WHEN release_year >= 2000 THEN "2000s"
WHEN release_year < 2000 THEN "1900s"
END AS century
FROM titles
WHERE imdb_score <> '' and tmdb_score <> ''
;


-- Best decade for film (Percentage of highly rated titles by decade on Netflix)

WITH byDecade AS (
  SELECT 
    title, 
    release_year, 
    imdb_score, 
    tmdb_score, 
    ROUND((imdb_score + tmdb_score)/2, 1) AS AverageScore,
    CASE 
      WHEN release_year >= 1950 AND release_year < 1960 THEN '1950s'
      WHEN release_year >= 1960 AND release_year < 1970 THEN '1960s'
      WHEN release_year >= 1970 AND release_year < 1980 THEN '1970s'
      WHEN release_year >= 1980 AND release_year < 1990 THEN '1980s'
      WHEN release_year >= 1990 AND release_year < 2000 THEN '1990s'
      WHEN release_year >= 2000 AND release_year < 2010 THEN '2000s'
      WHEN release_year >= 2010 AND release_year < 2020 THEN '2010s'
      WHEN release_year >= 2020 THEN '2020s'
    END AS Decade
  FROM 
    titles
  WHERE 
    imdb_score <> '' AND tmdb_score <> ''
)
SELECT 
  Decade, 
  COUNT(*) AS TotalTitles,
  SUM(CASE WHEN AverageScore >= 8 THEN 1 ELSE 0 END) AS HighlyRatedTitles,
  ROUND(ROUND(SUM(CASE WHEN AverageScore >= 8 THEN 1 ELSE 0 END) / COUNT(*), 4), 4) AS RatioOfHighlyRated
FROM byDecade
GROUP BY Decade
ORDER BY Decade;

    
