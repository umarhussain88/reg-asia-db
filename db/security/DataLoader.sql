CREATE LOGIN [DataLoader] WITH PASSWORD = '$(DataLoaderLoginPassword)';
GO

CREATE USER DataLoader FROM LOGIN [DataLoader];
GO

GRANT CONNECT TO DataLoader;
GO

EXEC sp_addrolemember 'db_datareader', 'DataLoader';
GO

EXEC sp_addrolemember 'db_datawriter', 'DataLoader';
GO

EXEC sp_addrolemember 'db_ddladmin', 'DataLoader';
GO

GRANT EXECUTE ON SCHEMA::etl_audit TO DataLoader;
GO

GRANT EXECUTE ON SCHEMA::etl_util TO DataLoader;
GO

GRANT EXECUTE ON SCHEMA::etl TO DataLoader;
GO

GRANT EXECUTE ON SCHEMA::stg_survey_monkey TO DataLoader;
GO
