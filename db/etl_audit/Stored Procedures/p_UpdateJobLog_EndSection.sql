CREATE PROCEDURE [etl_audit].[p_UpdateJobLog_EndSection]
   @section   varchar(255)
,  @jobLogKey int OUT
AS
BEGIN

	/* ===============================================================================================================
	Description:	Stored procedure to update audit table as one section finishes and the next starts
	=============================================================================================================== */

	SET NOCOUNT ON                        -- Eliminate any dataset counts

	-- Identify the JobKey
	DECLARE @newJobLogKey int
	
	-- Update the existing JobStep to be complete
	UPDATE   [etl_audit].[JobLog]
	SET      [EndTime] = GETDATE()
	,        [Completed] = 1
	WHERE    [JobLogKey] = @jobLogKey
		
	-- Create a new JobStep
	INSERT INTO [etl_audit].[JobLog]
	(		[JobKey]
	,		[Procedure]
	,		[Section]
	,		[StepNo]
	,		[StartTime]
	)	
	SELECT	jl.[JobKey]
	,       jl.[Procedure]
	,		@section		AS [Section]
	,		jl.[StepNo]	+ 1	AS [StepNo]
	,		GETDATE()		AS [StartTime]
	FROM	[etl_audit].[JobLog] jl
	WHERE	jl.[JobLogKey] = @jobLogKey

	-- Return the @jobLogKey in the output parameter
	SET @jobLogKey = SCOPE_IDENTITY()

END