CREATE PROCEDURE [etl_audit].[p_UpdateJob]
	@jobKey		int
, 	@JobStatus	varchar(50)
AS
BEGIN

	/* ===============================================================================================================
	Description:	Update the Job execution with progress
	=============================================================================================================== */

    SET NOCOUNT ON							-- Eliminate any dataset counts

    DECLARE @jobLogKey	int				-- Identity for Job Log Table
    ,		@section	nvarchar(2048)	-- document your steps by setting this variable
	,       @proc		sysname;        -- Name of this procedure
	SET     @proc		= '[etl_audit].[p_UpdateJob]'


	-- Log the start time of the Procedure
    EXEC [etl_audit].[p_InsertJobLog] @procName = @proc, @jobKey = @jobKey, @jobLogKey = @jobLogKey OUTPUT;
	
    BEGIN TRY

		SET @section = 'Update the [etl_audit].[Job] table with JobStatus = ' + @JobStatus;
		EXEC [etl_audit].[p_UpdateJobLog_EndSection] @section = @section, @jobLogKey = @jobLogKey OUTPUT;

			UPDATE	[etl_audit].[Job]
			SET		[JobStatus]			= @JobStatus
			,		[FinishDateTime]	= CASE WHEN @JobStatus IN ('Success', 'Failure')	THEN GETDATE()	ELSE [FinishDateTime]	END
			,		[IsRunning]			= CASE WHEN @JobStatus IN ('Success', 'Failure')	THEN 0			ELSE [IsRunning]		END
			WHERE	[JobKey] = @jobKey
			AND		[IsRunning] = 1;

    END TRY

    BEGIN CATCH

		-- Log error the error and raise it again
		EXECUTE [etl_audit].[p_LogAndRaiseSqlError] @jobLogKey = @jobLogKey;

    END CATCH

    -- Log the end of the Procedure Run, success or otherwise    
	EXEC [etl_audit].[p_UpdateJobLog_EndProcedure] @jobLogKey = @jobLogKey;

END

