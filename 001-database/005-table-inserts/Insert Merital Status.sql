USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert marital status lookup values
--	TFS Task:		Initialize marital status lookup table
--================================================================================================

DECLARE @ActiveStatus BIT = 1,
		@DefaultDate DATETIME = GETDATE()

INSERT INTO Profile.MaritalStatus (MaritalStatusDescription, IsActive, UpdateDate, CreatedDate, CreatedBy)
VALUES	('Single', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Married', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Widowed', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Divorced', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Separated', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Domestic Partnership', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM')

GO

PRINT 'Marital status lookup table populated successfully'
GO