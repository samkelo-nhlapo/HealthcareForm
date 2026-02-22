USE HealthcareForm
GO

--================================================================================================
--	Author:		Samkelo Nhlapo
--	Create date	22/01/2022
--	Description	Phone number Function
--	TFS Task	Ensure Phone number format has - between numbers
--================================================================================================

CREATE OR ALTER FUNCTION Contacts.FormatPhoneNumber
(
	@PhoneNumber VARCHAR(10)
)
RETURNS 
	VARCHAR(12)
BEGIN
    RETURN SUBSTRING(@PhoneNumber, 1, 3) + '-' + 
           SUBSTRING(@PhoneNumber, 4, 3) + '-' + 
           SUBSTRING(@PhoneNumber, 7, 4)
END
