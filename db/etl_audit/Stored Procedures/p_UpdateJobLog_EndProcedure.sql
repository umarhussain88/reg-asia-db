CREATE PROCEDURE [etl_audit].[p_UpdateJobLog_EndProcedure]
   @jobLogKey int OUT
AS
BEGIN

	/* ===============================================================================================================
	Description:	Stored procedure to update audit table as procedure finishes
	=============================================================================================================== */

	SET NOCOUNT ON                        -- Eliminate any dataset counts
   
	-- Deal with the finishing up of the procedure
	UPDATE   [etl_audit].[JobLog]
	SET      [EndTime] = GETDATE()
	,        [Completed] = 1
	WHERE    [JobLogKey] = @jobLogKey
	AND      [EndTime] IS NULL

END
