CREATE TABLE [etl_audit].[Error] (	
    [ErrorKey]			bigint	IDENTITY(1,1)   NOT NULL,
    [ErrorNumber]		int					        NULL,
    [ErrorMessage]		nvarchar(4000)		        NULL,
    [ErrorState]		int					        NULL,
    [ErrorSeverity]		int					        NULL,
    [UserName]			nvarchar(128)		        NULL,
    [DateCreated]		smalldatetime		        NULL,
    CONSTRAINT [PK_Error] PRIMARY KEY CLUSTERED ([ErrorKey] ASC)	
);