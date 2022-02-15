CREATE TABLE [dim].[Calendar]
(	[DateKey]				int				NOT NULL
,	[ActualDate]			date			NOT NULL
,	[DisplayDate]			nvarchar(20)	NOT NULL
,	[WeekDayNumber]			tinyint			NOT NULL
,	[WeekDayNameShort]		char(3)			NOT NULL
,	[WeekDayNameFull]		varchar(10)		NOT NULL
,	[WeekNumber]			tinyint			NOT NULL
,	[WeekKey]				int				NOT NULL
,	[WeekKeyName]			char(10)		NOT NULL
,	[WeekdayStatus]			bit				NOT NULL
,	[WeekdayStatusName]		varchar(10)		NOT NULL
,	[MonthDayNumber]		tinyint			NOT NULL
,	[MonthNumber]			tinyint			NOT NULL
,	[MonthKey]				int				NOT NULL
,	[MonthNameShort]		char(3)			NOT NULL
,	[MonthNameFull]			varchar(10)		NOT NULL
,	[MonthKeyName]			varchar(6)		NOT NULL
,	[QuarterNumber]			tinyint			NOT NULL
,	[QuarterKey]			smallint		NOT NULL
,	[QuarterName]			char(2)			NOT NULL
,	[QuarterKeyCode]		char(6)			NOT NULL
,	[QuarterKeyName]		char(7)			NOT NULL
,	[YearNumber]			smallint		NOT NULL
,	[YearNameShort]			char(2)			NOT NULL
,	[YearNameFull]			char(4)			NOT NULL
,	[OffsetWeekCount]		smallint		NOT NULL
,	[OffsetMonthCount]		smallint		NOT NULL
,	[OffsetQuarterCount]	smallint		NOT NULL
,	[OffsetYearCount]		smallint		NOT NULL
,	[ChangeHash]			binary (64)     NOT NULL
,	[CreatedJobKey]			int				NOT NULL
,	[UpdatedJobKey]			int					NULL
,	CONSTRAINT [PK_DW_Calendar] PRIMARY KEY CLUSTERED ([DateKey])
);
GO
CREATE UNIQUE NONCLUSTERED INDEX UNCI_DW_Calendar_DateKey ON [dim].[Calendar] ([DateKey]) INCLUDE ([ActualDate]);
GO
CREATE UNIQUE NONCLUSTERED INDEX UNCI_DW_Calendar_ActualDate ON [dim].[Calendar] ([ActualDate]) INCLUDE ([DateKey]);
GO
CREATE UNIQUE NONCLUSTERED INDEX UNCI_DW_Calendar_YMD ON [dim].[Calendar] ([ActualDate]) INCLUDE ([YearNumber], [MonthKey], [DateKey]);
GO
CREATE NONCLUSTERED INDEX NCI_DW_Calendar_QTR ON [dim].[Calendar] ([QuarterKeyCode]) INCLUDE ([DateKey]);
GO
