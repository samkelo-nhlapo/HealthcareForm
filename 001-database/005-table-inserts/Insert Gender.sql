USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert gender lookup values
--	TFS Task:		Initialize gender lookup table
--================================================================================================

DECLARE @ActiveStatus BIT = 1,
		@DefaultDate DATETIME = GETDATE()

INSERT INTO Profile.Gender (GenderDescription, IsActive, UpdateDate, CreatedDate, CreatedBy)
VALUES	('Male', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Female', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Other', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM'),
		('Prefer Not to Say', @ActiveStatus, @DefaultDate, @DefaultDate, 'SYSTEM')

GO

PRINT 'Gender lookup table populated successfully'
GO