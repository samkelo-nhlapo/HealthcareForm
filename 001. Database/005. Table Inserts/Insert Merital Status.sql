USE HealthcareForm
GO

-- This insert query inserts marital status into [Profile].[MeritalStatus] Table

DECLARE @ActiveStatus BIT = 0,
		@DefaultDate DATETIME = GETDATE()

INSERT INTO Profile.MaritalStatus(MaritalStatusDescription, IsActive, UpdateDate)
VALUES('Single', @ActiveStatus , @DefaultDate),
	  ('Married', @ActiveStatus , @DefaultDate),
	  ('Widowed', @ActiveStatus , @DefaultDate),
	  ('Devorced', @ActiveStatus , @DefaultDate),
	  ('Separated ', @ActiveStatus , @DefaultDate)