
--The total number of shows in netfix:

SELECT
  netflix_titles.type,
  COUNT(DISTINCT show_id)
FROM netflix_titles
WHERE show_id IS NOT NULL
GROUP BY netflix_titles.type

--Top 5 countries that produce highest number of shows:

SELECT TOP 5
  country,
  COUNT(show_id) AS ShowCount
FROM netflix_titles_countries
GROUP BY country
ORDER BY ShowCount DESC

--Top 10 Directors who made highest number of shows

SELECT TOP 10
  director,
  COUNT(show_id) ShowCount
FROM netflix_titles_directors
GROUP BY director
ORDER BY ShowCount DESC

--Category wise Percentage Contribution of shows out of total number of shows: 

SELECT DISTINCT
  listed_in,
  COUNT(show_id) OVER (PARTITION BY listed_in) AS Cat_total_Count,
  COUNT(show_id) OVER () AS total_Count,
  (COUNT(show_id) OVER (PARTITION BY listed_in) * 1.0) / (COUNT(show_id) OVER ()) * 100 AS PercOfTotal
FROM netflix_titles_category
ORDER BY PercOfTotal DESC

--Percentage Share of each actor to the total number of shows in netflix

SELECT DISTINCT
  (cast),
  COUNT(show_ID) AS ShowCount,
  (SELECT
    COUNT(DISTINCT show_id) AS TotalShows
  FROM netflix_titles),
  COUNT(Show_ID) * 1.0 / (SELECT
    COUNT(DISTINCT show_id) AS TotalShows
  FROM netflix_titles)
FROM netflix_titles_cast
GROUP BY cast
ORDER BY ShowCount DESC

--Year that has most number of movies and TV shows released.

SELECT
  *
FROM (SELECT TOP 1
  type,
  release_year,
  COUNT(*) AS ShowCount
FROM netflix_titles
WHERE type = 'Movie'
GROUP BY type,
         release_year
ORDER BY ShowCount DESC) MC
UNION
SELECT
  *
FROM (SELECT TOP 1
  type,
  release_year,
  COUNT(*) AS ShowCount
FROM netflix_titles
WHERE type = 'TV Show'
GROUP BY type,
         release_year
ORDER BY ShowCount DESC) TC


--Year that has most number of shows added on netflix:

SELECT
  YEAR(date_added) AS YearAdded,
  COUNT(show_ID) ShowCount
FROM netflix_titles
GROUP BY YEAR(date_added)
ORDER BY YearAdded

--Rolling Count of number of shows added each year

SELECT DISTINCT
  (YEAR(date_added)) AS YearAdded,
  COUNT(show_id) OVER (PARTITION BY YEAR(date_added)),
  COUNT(show_id) OVER (ORDER BY YEAR(date_added))
FROM netflix_titles
WHERE date_added IS NOT NULL
ORDER BY YearAdded


--use of CTE(Common Table Expression)

WITH cte_cat_title (category, total_count, cat_count)
AS (SELECT DISTINCT
  listed_in,
  COUNT(title.show_id) OVER () AS total_count,
  COUNT(title.show_id) OVER (PARTITION BY listed_in) AS cat_count
--,(total_count/cat_count)*100 as cat_percent
FROM netflix_titles title
JOIN netflix_titles_category cat
  ON title.show_id = cat.show_id)
SELECT
  *,
  ROUND((cat_count * 1.0 / total_count) * 100, 2) AS cat_percent
FROM cte_cat_title


--use of #Temp table

drop table if exists #temp_RatingWiseDurationDirectorsCount

CREATE TABLE #temp_RatingWiseDurationDirectorsCount (
  Rating nvarchar(40),
  Viewing_Hours int,
  Director_Count int
)

INSERT INTO #temp_RatingWiseDurationDirectorsCount
  SELECT DISTINCT
    title.rating,
    SUM(title.duration_minutes) OVER (ORDER BY title.rating) AS total_minutes,
    COUNT(dir.director) OVER (PARTITION BY rating) AS directors_count
  FROM netflix_titles title
  JOIN netflix_titles_directors dir
    ON title.show_id = dir.show_id

SELECT
  *
FROM #temp_RatingWiseDurationDirectorsCount
WHERE Viewing_Hours > (SELECT
  AVG(viewing_Hours)
FROM #temp_RatingWiseDurationDirectorsCount)


--Using Stored Procedures:

CREATE PROCEDURE
StProc_CountryWiseShowsDistribution
AS
BEGIN
  SELECT
    ctry.country,
    COUNT(ctry.show_id) AS ctry_shows,
    (SELECT
      COUNT(DISTINCT show_id) AS total_ctry_shows
    FROM netflix_titles)
  FROM netflix_titles title
  JOIN netflix_titles_countries ctry
    ON title.show_id = ctry.show_id
  GROUP BY ctry.country
  ORDER BY ctry_shows DESC
END

  EXEC StProc_CountryWiseShowsDistribution

--Stored Procedure with parameter passing:

CREATE PROCEDURE StProc_ShowsCountAsPerSeasons @duration_seasons int
AS
BEGIN
  SELECT
    duration_seasons,
    COUNT(title) AS No_Of_Shows
  FROM netflix_titles
  WHERE duration_seasons IS NOT NULL
  AND duration_seasons > @duration_seasons
  GROUP BY duration_seasons,
           type
  ORDER BY duration_seasons
END

EXEC StProc_ShowsCountAsPerSeasons @duration_seasons = 10


--StoredProcedure with multiple parameter passing:

CREATE PROCEDURE StProc_CountryWiseActorsShows @Num_Of_Actors int,
@Num_Of_Shows int
--,@Country nvarchar(50)
AS
BEGIN
  SELECT DISTINCT
    country,
    COUNT(DISTINCT cast.cast) AS Num_Of_Actors,
    COUNT(title.show_id) AS Num_Of_Shows
  FROM netflix_titles title
  JOIN netflix_titles_cast cast
    ON title.show_id = cast.show_id
  JOIN netflix_titles_countries country
    ON title.show_id = country.show_id
  GROUP BY country
  HAVING COUNT(DISTINCT cast.cast) > @Num_Of_Actors
  AND COUNT(title.show_id) > @Num_Of_Shows
END

  EXEC StProc_CountryWiseActorsShows 100,
                                     100