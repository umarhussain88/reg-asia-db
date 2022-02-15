CREATE PROCEDURE [etl_audit].[p_InsertJobLog]
	@jobKey		int
,	@procName	sysname 
,	@jobLogKey	int OUT
AS
BEGIN

	/* ===============================================================================================================
	Description:	Insert records into audit table during each transformation
	=============================================================================================================== */
	
	SET NOCOUNT ON                        -- Eliminate any dataset counts

	-- Create a new entry
	INSERT INTO [etl_audit].[JobLog]
	(           [JobKey]
	,           [Procedure]
	,           [Section]
	,           [StepNo]
	,           [StartTime]
	)
	SELECT      @jobKey			AS [JobKey]
	,           @procName		AS [Procedure]
	,           'Starting'		AS [Section]
	,           1				AS [StepNo]
	,           GETDATE()		AS [StartTime]

	-- Get the IDENTITY value 
	SET @jobLogKey = SCOPE_IDENTITY()

END