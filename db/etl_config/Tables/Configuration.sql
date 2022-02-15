CREATE TABLE [etl_config].[Configuration] (
	[ConfigurationKey]		smallint IDENTITY(1,1)	NOT NULL,
	[TruncateDataWarehouse]	varchar(3)				NOT NULL,
	[CalendarStartDate]		date					NOT NULL,
    [CreatedJobKey]			int						NOT NULL,
	CONSTRAINT [PK_Configuration] PRIMARY KEY CLUSTERED ([ConfigurationKey] ASC),
	CONSTRAINT [CK_Configuration_ConfigurationKey] CHECK ([ConfigurationKey] < = 1)
)
