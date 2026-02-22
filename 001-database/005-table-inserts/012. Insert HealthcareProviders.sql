USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date:	14/02/2026
--	Description:	Insert healthcare provider reference data
--	TFS Task:		Initialize healthcare providers
--================================================================================================

DECLARE @DefaultDate DATETIME = GETDATE(),
		@CountryId INT = (SELECT CountryId FROM Location.Countries WHERE CountryCode = 'ZA'),
		@CityId_JNB INT = (SELECT CityId FROM Location.Cities WHERE CityName = 'Johannesburg'),
		@CityId_CPT INT = (SELECT CityId FROM Location.Cities WHERE CityName = 'Cape Town'),
		@CityId_DBN INT = (SELECT CityId FROM Location.Cities WHERE CityName = 'Durban')

-- Insert sample healthcare providers
INSERT INTO HealthcareServices.HealthcareProviders (ProviderName, ProviderType, SpecializationCode, LicenseNumber, ContactPhone, ContactEmail, 
													 CityIdFK, IsActive, CreatedDate, CreatedBy)
VALUES	
	('Dr. Thabo Mthembu', 'GENERAL_PRACTITIONER', 'GP', 'ZA-MP-0012345', '+27 11 234 5678', 'dr.mthembu@email.com', @CityId_JNB, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Naledi Johnson', 'CARDIOLOGIST', 'CARDIOLOGY', 'ZA-MP-0054321', '+27 11 345 6789', 'dr.johnson@email.com', @CityId_JNB, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Amira Hassan', 'NEUROLOGIST', 'NEUROLOGY', 'ZA-MP-0098765', '+27 21 456 7890', 'dr.hassan@email.com', @CityId_CPT, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Kevin Smith', 'ORTHOPEDIC_SURGEON', 'ORTHOPEDICS', 'ZA-MP-0011111', '+27 21 567 8901', 'dr.smith@email.com', @CityId_CPT, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Patricia Ndlovu', 'PEDIATRICIAN', 'PEDIATRICS', 'ZA-MP-0022222', '+27 31 678 9012', 'dr.ndlovu@email.com', @CityId_DBN, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Michael Chen', 'PSYCHIATRIST', 'PSYCHIATRY', 'ZA-MP-0033333', '+27 31 789 0123', 'dr.chen@email.com', @CityId_DBN, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Sarah Botha', 'ENDOCRINOLOGIST', 'ENDOCRINOLOGY', 'ZA-MP-0044444', '+27 11 890 1234', 'dr.botha@email.com', @CityId_JNB, 1, @DefaultDate, 'SYSTEM'),
	('Dr. James Okafor', 'PULMONOLOGIST', 'PULMONOLOGY', 'ZA-MP-0055555', '+27 21 901 2345', 'dr.okafor@email.com', @CityId_CPT, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Kavya Patel', 'GASTROENTEROLOGIST', 'GASTROENTEROLOGY', 'ZA-MP-0066666', '+27 31 012 3456', 'dr.patel@email.com', @CityId_DBN, 1, @DefaultDate, 'SYSTEM'),
	('Dr. Robert Mendes', 'UROLOGIST', 'UROLOGY', 'ZA-MP-0077777', '+27 11 123 4567', 'dr.mendes@email.com', @CityId_JNB, 1, @DefaultDate, 'SYSTEM')

GO

PRINT 'Healthcare providers inserted successfully'
GO
