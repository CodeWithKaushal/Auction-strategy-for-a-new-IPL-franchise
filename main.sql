COPY IPL_Ball FROM 'C:/Program Files/PostgreSQL/16/data/Data_Copy/IPL_Ball.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE ipl_ball (
    id integer,
    inning integer,
    over integer,
    ball integer,
    batsman text,
    non_striker text,
    bowler text,
    batsman_runs integer,
    extra_runs integer,
    total_runs integer,
    is_wicket boolean,
    dismissal_kind text,
    player_dismissed text,
    fielder text,
    extras_type text,
    batting_team text,
    bowling_team text
);

select * from ipl_ball;



CREATE TABLE IPL_matches (
    id integer,
    city varchar,
    date date,
    player_of_match varchar,
    venue varchar,
    neutral_venue varchar,
    team1 varchar,
    team2 varchar,
    toss_winner varchar,
    toss_decision varchar,
    winner varchar,
    result varchar,
    result_margin varchar,
    eliminator varchar,
    method varchar,
    umpire1 varchar,
    umpire2 varchar
);

COPY ipl_ball  FROM 'C:/Program Files/PostgreSQL/16/data/Data_Copy/ipl_ball.csv' DELIMITER ',' CSV HEADER;

select * from IPL_matches;




--1] *******************************************************************


SELECT 
    batsman AS BATSMAN, 
    ROUND((SUM(batsman_runs)*1.0 / COUNT(ball)) * 100, 2) AS Batting_Strike_Rate
FROM 
    ipl_ball
WHERE
    extras_type != 'wides'
GROUP BY
    batsman
HAVING
    COUNT(ball) > 500
ORDER BY
    Batting_Strike_Rate DESC
LIMIT 10;

-- 2]*******************************************************************



SELECT 
    batsman,
    SUM(batsman_runs) AS runs,
    ROUND(SUM(batsman_runs) * 1.0 / SUM(CASE WHEN is_wicket THEN 1 ELSE 0 END), 2) AS average
FROM ipl_ball
GROUP BY
    batsman
HAVING
    SUM(CASE WHEN is_wicket THEN 1 ELSE 0 END) > 0 
    AND COUNT(DISTINCT id) > 28
ORDER BY
    average DESC
LIMIT 10;


--3] *****************************************************************************************************

SELECT 
    batsman,
    ROUND(SUM(CASE WHEN batsman_runs IN (4, 6) THEN batsman_runs ELSE 0 END) * 1.0 / SUM(batsman_runs) * 100, 2) AS boundary_percentage,
    SUM(batsman_runs) AS total_runs,
	SUM(CASE WHEN batsman_runs IN (4) THEN batsman_runs ELSE 0 END) AS runs_in_boundaries,
	COUNT(CASE WHEN batsman_runs IN (4) THEN 1 END) AS boundaries
FROM ipl_ball
WHERE extras_type NOT IN ('wides')
GROUP BY
    batsman
HAVING
    COUNT(DISTINCT id) > 28
ORDER BY
    boundary_percentage DESC
LIMIT 10;

SELECT 
batsman, 
ROUND(SUM(CASE WHEN batsman_runs in(4,6) THEN batsman_runs else 0 END)*1.0 / SUM(batsman_runs)*100,2) AS boundary_percentage
FROM ipl_ball
WHERE
extras_type NOT IN ('wides')
GROUP BY
batsman
HAVING
COUNT(DISTINCT id) > 28
ORDER BY
boundary_percentage DESC
LIMIT 10;

-- 4] *****************************************************************************

SELECT 
	bowler,
	ROUND(SUM(total_runs)/(COUNT(bowler)/6.0), 2) 
	as economy
FROM ipl_ball
GROUP BY
	bowler
HAVING
	COUNT(bowler) > 500
ORDER BY
	economy
LIMIT 10;


-- 5] ***********************************************************************************


WITH BowlerStats AS (
    SELECT
        bowler,
        COUNT(*) AS balls_bowled,
        SUM(CASE WHEN is_wicket THEN 1 ELSE 0 END) AS total_wickets
    FROM
        ipl_ball
    GROUP BY
        bowler
    HAVING
        COUNT(*) >= 500
)
SELECT
    bowler,
    balls_bowled,
    total_wickets,
    ROUND(balls_bowled * 1.0 / NULLIF(total_wickets, 0), 2) AS strike_rate
FROM
    BowlerStats
ORDER BY
    strike_rate
LIMIT 10;


-- 6] ******************************************************************************************	
	
CREATE TABLE batting_sr AS
SELECT
    batsman,
    COUNT(*) AS balls_faced,
    SUM(batsman_runs) AS total_runs,
    ROUND(SUM(batsman_runs) * 100.0 / COUNT(*), 2) AS batting_sr
FROM
    ipl_ball
WHERE
    is_wicket = FALSE -- Exclude balls where wickets were taken
GROUP BY
    batsman
HAVING
    COUNT(*) >= 500; -- Filter for at least 500 balls faced








-- Now, we can retrieve the top all-rounders based on the criteria
SELECT
    a.batsman AS all_rounder,
    a.batting_sr,
    b.bowling_sr
FROM
    batting_sr a
INNER JOIN
    bowling_sr b ON a.batsman = b.bowler
ORDER BY
    a.batting_sr DESC,
    b.bowling_sr ASC
LIMIT 10;









-- =====================================================================================


-- Additional Question *****************************************************************

-- 1] 

SELECT COUNT(DISTINCT city) AS cities_count
FROM ipl_matches;

-- 2] 
CREATE TABLE deliveries_v02 AS
SELECT *,
    CASE 
        WHEN total_runs >= 4 THEN 'boundary'
        WHEN total_runs = 0 THEN 'dot'
        ELSE 'other'
    END AS ball_result
FROM ipl_ball;


-- 3] 
SELECT 
    ball_result,
    COUNT(*) AS count
FROM 
    deliveries_v02
WHERE 
    ball_result IN ('boundary', 'dot')
GROUP BY 
    ball_result;

-- 4] 
SELECT 
    batting_team,
    COUNT(*) AS total_boundaries
FROM 
    deliveries_v02
WHERE 
    ball_result = 'boundary'
GROUP BY 
    batting_team
ORDER BY 
    total_boundaries DESC;


-- 5] 
SELECT 
    bowling_team,
    COUNT(*) AS total_dot_balls
FROM 
    deliveries_v02
WHERE 
    ball_result = 'dot'
GROUP BY 
    bowling_team
ORDER BY 
    total_dot_balls DESC;


-- 6] 9495
SELECT dismissal_kind, COUNT(*) AS total_dismissals
FROM ipl_ball
WHERE dismissal_kind != 'NA'
GROUP BY dismissal_kind;


-- 7] 
SELECT 
    bowler,
    SUM(extra_runs) AS total_extra_runs
FROM 
    deliveries_v02
GROUP BY 
    bowler
ORDER BY 
    total_extra_runs DESC
LIMIT 5;


-- 8] 
CREATE TABLE deliveries_v03 AS
SELECT d.*, m.venue, m.date AS match_date
FROM deliveries_v02 AS d
JOIN ipl_matches AS m ON d.id = m.id;


-- 9] 

SELECT 
    venue,
    SUM(total_runs) AS total_runs_scored
FROM 
    deliveries_v03
GROUP BY 
    venue
ORDER BY 
    total_runs_scored DESC;
	
-- 10] 
SELECT 
    EXTRACT(YEAR FROM match_date) AS year,
    SUM(total_runs) AS total_runs_scored
FROM 
    deliveries_v03
WHERE 
    venue = 'Eden Gardens'
GROUP BY 
    year
ORDER BY 
    total_runs_scored DESC;

