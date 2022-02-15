CREATE TABLE [etl_audit].[Job]
(	[JobKey]					int	IDENTITY(1,1)	NOT NULL
,	[JobStatus]					varchar(50)			NOT NULL
,	[IsRunning]					bit					NOT NULL
,	[DatasetName]				varchar(50)			NOT NULL
,	[ActivityName]				varchar(50)			NOT NULL
,	[StartDateTime]				datetime2(2)		NOT NULL
,	[FinishDateTime]			datetime2(2)			NULL
,   CONSTRAINT [PK_Job] PRIMARY KEY CLUSTERED ([JobKey] ASC)
)
GO
CREATE UNIQUE NONCLUSTERED INDEX [UNCI_Job_IsRunning] ON [etl_audit].[Job] ([IsRunning], [JobKey]) WHERE [IsRunning] = 1;
GO