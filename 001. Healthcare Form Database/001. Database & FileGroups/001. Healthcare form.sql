USE master;
GO
-- Create the database with the default data
-- filegroup, filestream filegroup and a log file. Specify the
-- growth increment and the max size for the
-- primary data file.
CREATE DATABASE HealthcareForm
ON PRIMARY
  ( NAME='MyDB_Primary',
    FILENAME=
       'D:\DB BackUp\HealthcareForm_FILEGROUPS\MyDB_Prm.mdf',
    SIZE=5MB,
    MAXSIZE=10MB,
    FILEGROWTH=1MB),
FILEGROUP MyDB_FG1
  ( NAME = 'MyDB_FG1_Dat1',
    FILENAME =
       'D:\DB BackUp\HealthcareForm_FILEGROUPS\MyDB_FG1_1.ndf',
    SIZE = 1MB,
    MAXSIZE=10MB,
    FILEGROWTH=1MB),
  ( NAME = 'MyDB_FG1_Dat2',
    FILENAME =
       'D:\DB BackUp\HealthcareForm_FILEGROUPS\MyDB_FG1_2.ndf',
    SIZE = 1MB,
    MAXSIZE=10MB,
    FILEGROWTH=1MB),
FILEGROUP FileStreamGroup1 CONTAINS FILESTREAM
  ( NAME = 'MyDB_FG_FS',
    FILENAME = 'c:\Data\filestream1')
LOG ON
  ( NAME='MyDB_log',
    FILENAME =
       'D:\DB BackUp\HealthcareForm_FILEGROUPS\MyDB.ldf',
    SIZE=1MB,
    MAXSIZE=10MB,
    FILEGROWTH=1MB);
GO
ALTER DATABASE HealthcareForm 
  MODIFY FILEGROUP MyDB_FG1 DEFAULT;
GO

-- Create a table in the user-defined filegroup.
USE HealthcareForm;
CREATE TABLE MyTable
  ( column_a int PRIMARY KEY,
    column_b char(8) )
ON MyDB_FG1;
GO

-- Create a table in the filestream filegroup
CREATE TABLE MyFSTable
(
	column_a int PRIMARY KEY,
  column_b VARBINARY(MAX) FILESTREAM NULL
)
GO