CREATE PROCEDURE [etl_audit].[p_LogAndRaiseSqlError]
    @jobLogKey	int
AS
BEGIN

	/* ===============================================================================================================
	Description:	Log and raise SQL errors
	=============================================================================================================== */
    
    DECLARE  @errorMessage  nvarchar(4000)
    ,        @errorSeverity int
    ,        @errorKey      int

    SET @errorMessage = ERROR_MESSAGE()
    SET @errorSeverity = ERROR_SEVERITY()

    INSERT INTO	[etl_audit].[Error]
    (       [ErrorNumber]
    ,       [ErrorMessage]
    ,       [ErrorState]
    ,       [ErrorSeverity]
    ,       [UserName]
    ,       [DateCreated]
    )     
    SELECT  ERROR_NUMBER()     AS [ErrorNumber]
	,       @errorMessage      AS [ErrorMessage]
	,       ERROR_STATE()      AS [ErrorState]
	,       @errorSeverity     AS [ErrorSeverity]
	,       SYSTEM_USER        AS [UserName]
	,       GETDATE()          AS [DateCreated]
    
    -- Get the IDENTITY value 
    SET @errorKey = SCOPE_IDENTITY()
    
    UPDATE   [etl_audit].[JobLog]
    SET      [EndTime] = GETDATE()
    ,        [ErrorKey] = @errorKey
    WHERE    [JobLogKey] = @jobLogKey
    
    -- Propagate the error up
    SET @errorSeverity = ISNULL(@errorSeverity, 1)
    RAISERROR ( '%s',@errorSeverity,1,@errorMessage)

END