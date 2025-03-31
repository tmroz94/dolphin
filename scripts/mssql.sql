PRINT 'Initializing...';

-- Add database $(DatabaseName) if not exists
PRINT 'Checking if database $(DatabaseName) exists...';

IF NOT EXISTS (SELECT name
FROM sys.databases
WHERE name = '$(DatabaseName)')
BEGIN
  PRINT 'Creating database $(DatabaseName)...';
  CREATE DATABASE [$(DatabaseName)];
END
GO

-- Change scope to $(DatabaseName) database
USE [$(DatabaseName)];
GO

-- Add $(Username) login if not exists
PRINT 'Checking if login $(Username) exists...';

IF NOT EXISTS (SELECT name
FROM sys.sql_logins
WHERE name = '$(Username)')
BEGIN
  PRINT 'Creating login $(Username)...';
  CREATE LOGIN [$(Username)]
  WITH PASSWORD = '$(Password)';
END
GO

-- Add $(Username) user if not exists
PRINT 'Checking if user $(Username) exists...';

IF NOT EXISTS (SELECT name
FROM sys.database_principals
WHERE name = '$(Username)')
BEGIN
  PRINT 'Creating user $(Username)...';
  CREATE USER [$(Username)] FOR LOGIN [$(Username)];
END
GO

-- Add $(Username) to db_owner role of $(DatabaseName) database if not exists
PRINT 'Checking if user $(Username) is a member of db_owner role of $(DatabaseName)...';

IF NOT EXISTS (SELECT *
FROM sys.database_role_members
WHERE role_principal_id = USER_ID('db_owner') AND member_principal_id = USER_ID('$(Username)'))
BEGIN
  PRINT 'Adding user $(Username) to db_owner role of $(DatabaseName)...';
  ALTER ROLE db_owner ADD MEMBER [$(Username)];
END
GO

PRINT 'Initialization completed.';