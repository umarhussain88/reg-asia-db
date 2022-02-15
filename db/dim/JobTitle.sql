CREATE TABLE [dim].[JobTitle]
(
  [job_title_key] BIGINT IDENTITY (1, 1) NOT NULL,
  [job_title]     VARCHAR(255)           NOT NULL,
  [ChangeHash]    BINARY(64)             NOT NULL,
  [CreatedJobKey] INT                    NOT NULL,
  [UpdatedJobKey] INT                    NOT NULL,

  CONSTRAINT [job_title_key] PRIMARY KEY CLUSTERED ([job_title_key] ASC)
);