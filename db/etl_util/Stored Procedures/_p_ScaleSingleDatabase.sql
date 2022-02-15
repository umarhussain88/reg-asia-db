CREATE PROCEDURE [etl_util].[p_ScaleSingleDatabase] @JobKey int
, @scaleStr VARCHAR(5)
, @DbName VARCHAR(35)
AS
BEGIN

  /*================================================================================
  Scales DB up / down according to provided scale.
  DEBUG:
      EXEC [etl_util].[p_ScaleSingleDatabase] @JobKey = 1 @ScaleStr = 'S2', 'dBName = 'yourdb'
  ================================================================================*/

  SET NOCOUNT ON

  DECLARE @JobLogKey int
    , @Section nvarchar(2048)
    , @proc sysname
    , @statement NVARCHAR(MAX);
  SET @proc = '[stg_shipstation].[p_ScaleSingleDatabase]'

  SET @statement = FORMATMESSAGE('ALTER DATABASE [%s] MODIFY (SERVICE_OBJECTIVE = ''%s'')', @DbName, @scaleStr)


  EXEC [etl_audit].[p_InsertJobLog] @procName = @proc, @jobKey = @jobKey, @jobLogKey = @jobLogKey OUTPUT;

  BEGIN TRY

    SET @section = FORMATMESSAGE('Scaling dB to %s', @DbName)
    EXEC [etl_audit].[p_UpdateJobLog_EndSection] @section = @section, @jobLogKey = @jobLogKey OUTPUT;


    EXEC sp_executesql @statement


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