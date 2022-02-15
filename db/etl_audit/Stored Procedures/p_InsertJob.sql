CREATE PROCEDURE [etl_audit].[p_InsertJob]
	@DatasetName			varchar(50)
,	@ActivityName			varchar(50)
,	@jobKey					int OUT
AS
BEGIN

	/* ===============================================================================================================
	Description:	Creates a new Job execution
	=============================================================================================================== */

    SET NOCOUNT ON							-- Eliminate any dataset counts

    DECLARE @jobLogKey		int				-- Identity for Job Log Table
    ,		@stepNo			int = 1			-- unique step counter 
    ,		@section		nvarchar(2048)	-- document your steps by setting this variable

	-- Log the start time of the Procedure
    --EXEC [etl_audit].[p_InsertJobLog] @procId = @@PROCID, @jobKey = @jobKey OUTPUT, @jobLogKey = @jobLogKey OUTPUT;
	
    BEGIN TRY
	
		SET @section = 'Ensure there are no other active Job records';

			UPDATE	[etl_audit].[Job]
			SET		[JobStatus] = 'Aborted'
			,		[IsRunning] = 0
			,		[FinishDateTime] = GETDATE()
			WHERE	[DatasetName] = @DatasetName
			AND  	[IsRunning] != 0;
		
		SET @section = 'Create a new job record';
	
			INSERT INTO [etl_audit].[Job]
			(		[JobStatus]		
			,		[IsRunning]
			,		[DatasetName]	
			,		[ActivityName]
			,		[StartDateTime]
			)
			SELECT	'Running'
			,		1
			,		@DatasetName
			,		@ActivityName
			,		GETDATE();

			-- Get the IDENTITY value 
			SELECT	@jobKey = SCOPE_IDENTITY()

		SET @section = 'Return the new JobKey';

			SELECT	@jobKey AS [JobKey]       

		SET @section = 'Tidy up the job log';

			DELETE 
			FROM	[etl_audit].[JobLog]
			WHERE	DATEDIFF(DAY, [EndTime], GETDATE()) >  (SELECT	60 AS [JobLogRetentionDays])

    END TRY

    BEGIN CATCH

		-- Log error the error and raise it again
		EXECUTE [etl_audit].[p_LogAndRaiseSqlError] @jobLogKey = @jobLogKey;

    END CATCH

END

