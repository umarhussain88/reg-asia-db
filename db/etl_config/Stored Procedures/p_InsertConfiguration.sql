CREATE PROCEDURE [etl_config].[p_InsertConfiguration] @jobKey int
AS
BEGIN

  /* ==================================================================================================================
  Description:	Rebuilds the configuration table with static data
  ================================================================================================================== */

  SET NOCOUNT ON -- Eliminate any Configuration counts

  DECLARE @jobLogKey int -- Identity for Job Log Table
    , @section nvarchar(2048) -- document your steps by setting this variable
    , @proc sysname; -- Name of this procedure
  SET @proc = '[etl_config].[p_InsertConfiguration]';

  -- Log the start time of the Procedure
  EXEC [etl_audit].[p_InsertJobLog] @procName = @proc, @jobKey = @jobKey, @jobLogKey = @jobLogKey OUTPUT;

  BEGIN TRY

    SET @section = 'Create a new table based on the static data'
    EXEC [etl_audit].[p_UpdateJobLog_EndSection] @section = @section, @jobLogKey = @jobLogKey OUTPUT;

    -- Identify the source dataset
    WITH src AS (
                  SELECT val.[TruncateDataWarehouse]
                       , val.[CalendarStartDate]
                  FROM (
                         -- Minimum configuration to operate
                         SELECT 'No', '1 Jan 2018'
                  ) val ([TruncateDataWarehouse], [CalendarStartDate])
    )

    INSERT
    INTO [etl_config].[Configuration]
    ( [TruncateDataWarehouse]
    , [CalendarStartDate]
    , [CreatedJobKey])
      -- Cast all the new fields to maintain data types
    SELECT ISNULL(CAST(new.[TruncateDataWarehouse] AS varchar(3)), '') AS [TruncateDataWarehouse]
         , ISNULL(CAST(new.[CalendarStartDate] AS date), '1 jan 2018') AS [CalendarStartDate]
         , ISNULL(CAST(new.[CreatedJobKey] AS int), -1)                AS [CreatedJobKey]
    FROM (
           SELECT [TruncateDataWarehouse]
                , [CalendarStartDate]
                , @jobKey AS [CreatedJobKey]
           FROM src
    ) new
    WHERE
      NOT EXISTS(SELECT 1 FROM [etl_config].[Configuration]);

  END TRY
  BEGIN CATCH

    -- Log the error and raise it again
    EXEC [etl_audit].[p_LogAndRaiseSqlError] @jobLogKey = @jobLogKey;

  END CATCH

  -- Log the end of the Procedure Run, success or otherwise
  EXEC [etl_audit].[p_UpdateJobLog_EndProcedure] @jobLogKey = @jobLogKey;

END