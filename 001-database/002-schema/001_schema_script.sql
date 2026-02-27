USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	02/09/2021
--	Description:	Create database schemas for logical table organization
--	TFS Task:		Database schema initialization
--================================================================================================

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Location Schema: Geographic and address information
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Location')
  EXEC('CREATE SCHEMA Location')
GO

-- Profile Schema: Patient demographic and personal information
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Profile')
  EXEC('CREATE SCHEMA Profile')
GO

-- Contacts Schema: Communication contact details (phone, email, emergency contacts)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Contacts')
  EXEC('CREATE SCHEMA Contacts')
GO

-- Auth Schema: Authentication, authorization, and error logging
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Auth')
  EXEC('CREATE SCHEMA Auth')
GO

-- Exceptions Schema: Exception and error tracking
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Exceptions')
  EXEC('CREATE SCHEMA Exceptions')
GO

-- Lookup Schema: Reference data for allergies, medications, etc. (added per inline master)
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'Lookup')
  EXEC('CREATE SCHEMA Lookup')
GO

--================================================================================================
-- Schema Usage Guide
--================================================================================================
/*
Location Schema Tables:
  - Countries
  - Provinces
  - Cities
  - Address

Profile Schema Tables:
  - Patient
  - Gender (lookup)
  - MaritalStatus (lookup)

Contacts Schema Tables:
  - Phones
  - Emails
  - EmergencyContacts
  - PatientPhones (junction)
  - PatientEmails (junction)

Auth Schema Tables:
  - AuditLog (compliance tracking)
  - DB_Errors (error logging)

Exceptions Schema Tables:
  - Errors (system error tracking)
*/
