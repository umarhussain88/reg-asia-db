CREATE PROCEDURE [stg_survey_monkey].[p_InsertDimCustomers] @JobKey int
AS
BEGIN

  /*================================================================================
  Creates a Customer table from survey monkey data
  DEBUG:
      EXEC [stg_survey_monkey].[p_InsertDimCustomers] @JobKey = @JobKey
  ================================================================================*/

  SET NOCOUNT ON

  DECLARE @JobLogKey int
    , @Section nvarchar(2048)
    , @proc sysname;
  SET @proc = '[stg_survey_monkey].[p_InsertDimCustomers]'


  EXEC [etl_audit].[p_InsertJobLog] @procName = @proc, @jobKey = @jobKey, @jobLogKey = @jobLogKey OUTPUT;

  BEGIN TRY

    SET @section = 'Rebuild the dimension'
    EXEC [etl_audit].[p_UpdateJobLog_EndSection] @section = @section, @jobLogKey = @jobLogKey OUTPUT;


    WITH dat AS (
      SELECT [First Name]                  AS first_name
           , [Last Name]                   AS last_name
           , [Email Address]               AS email
           , ISNULL(job_title_key, 2117)   AS job_title_key
           , [Company Name]                AS company_name
           , Country                       AS country
           , Position                      AS position
           , [Subscription Options]        AS subscription_option
           , [Internal Coding]             AS internal_code
           , Phone                         AS customer_phone_number
           , [Site Subscriber]             AS site_subscriber_status
           , Geographies                   AS geographies
           , MEMBER_RATING                 AS member_rating
           , OPTIN_TIME                    AS optin_time
           , OPTIN_IP                      AS optin_ip
           , CONFIRM_TIME                  AS confirm_time
           , CONFIRM_IP                    AS confirm_ip
           , LATITUDE                      AS latitude
           , LONGITUDE                     AS longitude
           , GMTOFF                        AS gmtoff
           , DSTOFF                        AS dstoff
           , TIMEZONE                      AS timezone
           , CC                            AS cc
           , REGION                        AS region
           , LAST_CHANGED                  AS last_changed
           , LEID                          AS leid
           , EUID                          AS euid
           , NOTES                         AS notes
           , TAGS                          AS tags

           -- probably belong on another table - will add them to the dimension table for now.
           , [Area of Activity]            AS [area_of_activity]
           , [Primary Market of Operation] AS [primary_market_of_operation]
           , [Company Revenue]             AS [company_revenue]
      FROM [stg_survey_monkey].[survey_monkey_enriched] cst
        LEFT JOIN dim.JobTitle                          jt
          ON cst.[Job Title] = jt.job_title


      )

      , src AS (

      SELECT email
           , first_name
           , last_name
           , job_title_key
           , company_name
           , country
           , position
           , subscription_option
           , internal_code
           , customer_phone_number
           , site_subscriber_status
           , geographies
           , member_rating
           , optin_time
           , optin_ip
           , confirm_time
           , confirm_ip
           , latitude
           , longitude
           , gmtoff
           , dstoff
           , timezone
           , cc
           , region
           , last_changed
           , leid
           , euid
           , notes
           , tags
           , [area_of_activity]
           , [primary_market_of_operation]
           , [company_revenue]
           , ch.[ChangeHash]

      FROM dat

        CROSS APPLY (
                      SELECT CAST(HASHBYTES('SHA2_512'
                        , ISNULL(CAST(dat.[email] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[first_name] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[last_name] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[job_title_key] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[company_name] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[country] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[position] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[subscription_option] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[internal_code] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[customer_phone_number] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[site_subscriber_status] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[geographies] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[member_rating] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[optin_time] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[optin_ip] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[confirm_time] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[confirm_ip] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[latitude] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[longitude] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[gmtoff] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[dstoff] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[timezone] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[cc] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[region] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[last_changed] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[leid] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[euid] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[notes] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[tags] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[area_of_activity] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[primary_market_of_operation] AS nvarchar), '')
                                              + ISNULL(CAST(dat.[company_revenue] AS nvarchar), '')
                        ) AS binary(64)
                               ) AS [ChangeHash]
      ) ch
      )
      MERGE [dim].[Customer] AS tgt
    USING src
    ON tgt.[email] = src.[email]

    WHEN MATCHED AND tgt.[ChangeHash] != src.[ChangeHash]
      THEN
      UPDATE
      SET [first_name]                  = src.[first_name]
        , [last_name]                   = src.[last_name]
        , [job_title_key]               = src.[job_title_key]
        , [company_name]                = src.[company_name]
        , [country]                     = src.[country]
        , [position]                    = src.[position]
        , [subscription_option]         = src.[subscription_option]
        , [internal_code]               = src.[internal_code]
        , [customer_phone_number]       = src.[customer_phone_number]
        , [site_subscriber_status]      = src.[site_subscriber_status]
        , [geographies]                 = src.[geographies]
        , [member_rating]               = src.[member_rating]
        , [optin_time]                  = src.[optin_time]
        , [optin_ip]                    = src.[optin_ip]
        , [confirm_time]                = src.[confirm_time]
        , [confirm_ip]                  = src.[confirm_ip]
        , [latitude]                    = src.[latitude]
        , [longitude]                   = src.[longitude]
        , [gmtoff]                      = src.[gmtoff]
        , [dstoff]                      = src.[dstoff]
        , [timezone]                    = src.[timezone]
        , [cc]                          = src.[cc]
        , [region]                      = src.[region]
        , [last_changed]                = src.[last_changed]
        , [leid]                        = src.[leid]
        , [euid]                        = src.[euid]
        , [notes]                       = src.[notes]
        , [tags]                        = src.[tags]
        , [area_of_activity]            = src.[area_of_activity]
        , [primary_market_of_operation] = src.[primary_market_of_operation]
        , [company_revenue]             = src.[company_revenue]
        , [ChangeHash]                  = src.[ChangeHash]
        , [UpdatedJobKey]               = @jobKey

    WHEN NOT MATCHED THEN
      INSERT
      ( [email]
      , [first_name]
      , [last_name]
      , [job_title_key]
      , [company_name]
      , [country]
      , [position]
      , [subscription_option]
      , [internal_code]
      , [customer_phone_number]
      , [site_subscriber_status]
      , [geographies]
      , [member_rating]
      , [optin_time]
      , [optin_ip]
      , [confirm_time]
      , [confirm_ip]
      , [latitude]
      , [longitude]
      , [gmtoff]
      , [dstoff]
      , [timezone]
      , [cc]
      , [region]
      , [last_changed]
      , [leid]
      , [euid]
      , [notes]
      , [tags]
      , [area_of_activity]
      , [primary_market_of_operation]
      , [company_revenue]
      , [ChangeHash]
      , [CreatedJobKey]
      , [UpdatedJobKey])

      VALUES ( src.[email]
             , src.[first_name]
             , src.[last_name]
             , src.[job_title_key]
             , src.[company_name]
             , src.[country]
             , src.[position]
             , src.[subscription_option]
             , src.[internal_code]
             , src.[customer_phone_number]
             , src.[site_subscriber_status]
             , src.[geographies]
             , src.[member_rating]
             , src.[optin_time]
             , src.[optin_ip]
             , src.[confirm_time]
             , src.[confirm_ip]
             , src.[latitude]
             , src.[longitude]
             , src.[gmtoff]
             , src.[dstoff]
             , src.[timezone]
             , src.[cc]
             , src.[region]
             , src.[last_changed]
             , src.[leid]
             , src.[euid]
             , src.[notes]
             , src.[tags]
             , src.[area_of_activity]
             , src.[primary_market_of_operation]
             , src.[company_revenue]
             , src.[ChangeHash]
             , @jobKey
             , @jobKey)

    WHEN NOT MATCHED BY SOURCE THEN
      UPDATE
      SET [ChangeHash]    = CAST('' AS binary(64))
        , [UpdatedJobKey] = @jobKey;

  END TRY
  BEGIN CATCH

    -- Log the error and raise it again
    EXEC [etl_audit].[p_LogAndRaiseSqlError] @jobLogKey = @jobLogKey;
    EXEC [etl_audit].[p_UpdateJob] @jobKey = @JobKey, @JobStatus = 'Failure'

  END CATCH

  -- Log the end of the Procedure Run, success or otherwise
  EXEC [etl_audit].[p_UpdateJobLog_EndProcedure] @jobLogKey = @jobLogKey;
  EXEC [etl_audit].[p_UpdateJob] @jobKey = @JobKey, @JobStatus = 'Success'

END