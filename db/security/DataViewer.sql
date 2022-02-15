CREATE LOGIN [DataViewer] WITH PASSWORD = '$(DataViewerLoginPassword)';
GO

CREATE USER DataViewer FROM LOGIN [DataViewer];
GO

GRANT CONNECT TO DataViewer;
GO


GO


GO

GRANT SELECT ON SCHEMA::etl_config TO DataViewer;
GO

GRANT SELECT ON SCHEMA::etl_audit TO DataViewer;
GO