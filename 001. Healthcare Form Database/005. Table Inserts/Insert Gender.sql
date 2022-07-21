USE HealthcareForm
GO
DECLARE @ActiveStatus BIT = 0

INSERT INTO Profile.Gender(GenderDescription, IsActive, UpdateDate)
VALUES('Male', @ActiveStatus , GETDATE()),
('Female', @ActiveStatus , GETDATE()),
('Other', @ActiveStatus , GETDATE())