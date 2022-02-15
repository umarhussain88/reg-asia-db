CREATE PROCEDURE [stg_survey_monkey].[p_InsertDimJobTitle] @JobKey int
AS
BEGIN

  /*================================================================================
  Creates a Tag table from ship station active users.
  DEBUG:
      EXEC [stg_survey_monkey].[p_InsertDimJobTitle] @JobKey = @JobKey
  ================================================================================*/

  SET NOCOUNT ON

  DECLARE @JobLogKey int
    , @Section nvarchar(2048)
    , @proc sysname;
  SET @proc = '[stg_survey_monkey].[p_InsertDimJobTitle]'


  EXEC [etl_audit].[p_InsertJobLog] @procName = @proc, @jobKey = @jobKey, @jobLogKey = @jobLogKey OUTPUT;

  BEGIN TRY

    SET @section = 'Rebuild the dimension'
    EXEC [etl_audit].[p_UpdateJobLog_EndSection] @section = @section, @jobLogKey = @jobLogKey OUTPUT;


    WITH dat AS (
      SELECT DISTINCT [Job Title] AS job_title
      FROM stg_survey_monkey.survey_monkey_enriched
      WHERE
        [Job Title] NOT IN ('''-', '.', '0', 'aa')


      )

      , src AS (

      SELECT job_title
           , ch.[ChangeHash]

      FROM dat

        CROSS APPLY (
                      SELECT CAST(HASHBYTES('SHA2_512'
                        , ISNULL(CAST(dat.[job_title] AS nvarchar), '')
                        ) AS binary(64)
                               ) AS [ChangeHash]
      ) ch
      )
      MERGE [dim].[JobTitle] AS tgt
    USING src
    ON tgt.[job_title] = src.[job_title]

    WHEN MATCHED AND tgt.[ChangeHash] != src.[ChangeHash]
      THEN
      UPDATE
      SET [job_title]     = src.[job_title]

        , [ChangeHash]    = src.[ChangeHash]
        , [UpdatedJobKey] = @jobKey

    WHEN NOT MATCHED THEN
      INSERT
      ( [job_title]
      , [ChangeHash]
      , [CreatedJobKey]
      , [UpdatedJobKey])

      VALUES ( src.[job_title]
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