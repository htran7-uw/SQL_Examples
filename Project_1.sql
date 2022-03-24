/*When was the first complaint received? i.e. When did we start collecting complaints? */
SELECT 
    complaint_id,
    date_received,
    company_name,
    product,
    issue
FROM 
    `bigquery-public-data.cfpb_complaints.complaint_database`
ORDER BY 
    date_received ASC 
LIMIT 1;

/* What is the percent increase in complaints year-over-year */
/* Use a CTE to get the total # of complaints for each year,
    then use the subquery to get the previous year complaints since we can't use the window function for another column in the main query */
WITH total_complaints AS (SELECT 
    EXTRACT(YEAR FROM date_received) as year,
    COUNT(complaint_id) as num_complaints
FROM 
    `bigquery-public-data.cfpb_complaints.complaint_database`
GROUP BY 
    year
ORDER BY 
    year)
SELECT 
    year,
    /*prev_year_complaints,*/
    current_year_complaints,
    CASE
        WHEN current_year_complaints - prev_year_complaints >= 0 THEN 
        ROUND((current_year_complaints - prev_year_complaints)/prev_year_complaints * 100,2)
        ELSE 0
        END AS pct_increase
FROM 
(
SELECT 
    year,
    LAG(num_complaints) OVER (
        ORDER BY year ASC
    ) AS prev_year_complaints,
    num_complaints AS current_year_complaints,
FROM 
    total_complaints
ORDER BY 
    year);

-- What financial products are we getting the most complaints about? Is it crypto? 
SELECT 
    product,
    COUNT(complaint_id) AS total_complaints
FROM 
    `bigquery-public-data.cfpb_complaints.complaint_database`
GROUP BY
    product
ORDER BY 
    total_complaints DESC;

/* For open complaints, can we get a sense of how long they have been open?*/
SELECT
    complaint_id,
    product,
    issue,
    UPPER(company_name) AS Company,
    ROUND(DATE_DIFF(CURRENT_DATE(), date_received, DAY),0) AS days_since_open_complaint_received
FROM 
    `bigquery-public-data.cfpb_complaints.complaint_database`
WHERE
    company_response_to_consumer LIKE "%In progress%"
ORDER BY 
    days_since_open_complaint_received DESC;

/* What companies are poor in providing timely responses to complaints? */
SELECT
    UPPER(company_name) as company,
    COUNT(complaint_id) as total_complaints_untimely 
FROM 
    `bigquery-public-data.cfpb_complaints.complaint_database`
WHERE
    company_response_to_consumer = "Untimely response"
GROUP BY 
    company
ORDER BY 
    total_complaints_untimely DESC;
