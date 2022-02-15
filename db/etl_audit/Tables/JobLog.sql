CREATE TABLE [etl_audit].[JobLog] (
    [JobLogKey]		bigint	IDENTITY(1,1)   NOT NULL,
    [JobKey]		int						NOT NULL,
    [Procedure]		nvarchar(200)				NULL,
    [Section]		nvarchar(2048)				NULL,
    [StepNo]		int							NULL,
    [StartTime]		datetime				NOT NULL,
    [EndTime]		datetime					NULL,
    [Completed]		bit							NULL,
    [ErrorKey]		bigint						NULL,
    CONSTRAINT [PK_JobLog] PRIMARY KEY CLUSTERED ([JobLogKey] ASC)
);