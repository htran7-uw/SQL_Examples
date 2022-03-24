/* Create the tables for analysis of San Francisco Police Department Information */
CREATE TABLE sfpd_dates (
  date_id int NOT NULL,
  exact_date date,
  day_of_week char(20),
  holiday int,
  PRIMARY KEY (date_id)
);

DROP TABLE IF EXISTS sfpd_incidents;

CREATE TABLE sfpd_incidents (
  incident_id int NOT NULL,
  category varchar(50),
  description varchar(256),
  resolution varchar(50),
  longitude decimal(8),
  latitude decimal(8),
  exact_timestamp timestamp,
  date_id int
);

/* Load information from private s3 bucket */
COPY dev.public.sfpd_dates 
FROM 's3://homework4-htran/sfpd-dates.csv' 
IAM_ROLE 'arn:aws:iam::963729989617:role/LabRole' 
FORMAT AS CSV DELIMITER ',' QUOTE '"' REGION AS 'us-east-1' IGNOREHEADER 1 DATEFORMAT 'MM/DD/YYYY';

SELECT * FROM sfpd_dates;

COPY dev.public.sfpd_incidents
FROM 's3://homework4-htran/sfpd-incidents.csv' 
IAM_ROLE 'arn:aws:iam::963729989617:role/LabRole' 
FORMAT AS CSV DELIMITER ',' QUOTE '"' REGION AS 'us-east-1' IGNOREHEADER 1 TIMEFORMAT 'MM/DD/YYYY HH:MI';

/* Perform analyses */

-- 10 most common types of incidents?
SELECT 
	category,
	COUNT(incident_id) as total
FROM
	sfpd_incidents
GROUP BY
	category
ORDER BY
	total DESC
LIMIT 10;

-- What % of issues had no resolution?
WITH total_none AS (SELECT 
	count(incident_id) AS total_incidents_none
FROM
	sfpd_incidents
WHERE
	resolution = 'NONE'),
  
total_all AS (SELECT
  	count(incident_id) AS total_incidents_all
FROM
  	sfpd_incidents)
    
SELECT
	total_incidents_none,
    total_incidents_all,
    ROUND(CAST(total_incidents_none AS DECIMAL)/CAST(total_incidents_all AS DECIMAL) * 100,2) AS pct_none
FROM
	total_none,
    total_all;
	
-- Do more incidents happen on the weekend?
WITH weekend_indicate AS (SELECT 
	i.incident_id,
    d.day_of_week,
    CASE WHEN d.day_of_week = 'Friday' OR d.day_of_week = 'Saturday' OR d.day_of_week = 'Sunday' THEN 1
    	ELSE 0 END AS weekend
FROM
	sfpd_incidents i 
JOIN 
	sfpd_dates d ON i.date_id = d.date_id),
    
    weekend_count AS (SELECT
      count(incident_id) AS weekend_total
      FROM weekend_indicate
      WHERE weekend = 1),
      
    weekday_count AS (SELECT
      count(incident_id) AS weekday_total
      FROM weekend_indicate
      WHERE weekend = 0)

SELECT * FROM weekend_count, weekday_count;