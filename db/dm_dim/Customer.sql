CREATE VIEW dm_dim.customer
AS 
SELECT c.first_name      AS [First Name]
     , c.last_name       AS [Last Name]
     , c.email           AS [Email Address]
     , c.company_name    AS [Company Name]
     , c.company_revenue AS [Known Company Revenue]
     , c.position        AS [Position]
     , c.internal_code   AS [Internal Code]
     , job_title         AS [Job Title]

FROM dim.Customer         c
  INNER JOIN dim.JobTitle jt
    ON jt.job_title_key = c.job_title_key