USE [master]
GO
/****** Object:  Database [PatientEnrollment]    Script Date: 16-Feb-22 06:19:29 PM ******/
CREATE DATABASE [PatientEnrollment]
-- CONTAINMENT = NONE
-- ON  PRIMARY 
--( NAME = N'PatientEnrollment', FILENAME = N'/var/opt/mssql/data/PatientEnrollment.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
-- LOG ON 
--( NAME = N'PatientEnrollment_log', FILENAME = N'/var/opt/mssql/data/PatientEnrollment_log.ldf' , SIZE = 139264KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
-- WITH CATALOG_COLLATION = DATABASE_DEFAULT
GO
ALTER DATABASE [PatientEnrollment] SET COMPATIBILITY_LEVEL = 150
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [PatientEnrollment].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [PatientEnrollment] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [PatientEnrollment] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [PatientEnrollment] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [PatientEnrollment] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [PatientEnrollment] SET ARITHABORT OFF 
GO
ALTER DATABASE [PatientEnrollment] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [PatientEnrollment] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [PatientEnrollment] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [PatientEnrollment] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [PatientEnrollment] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [PatientEnrollment] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [PatientEnrollment] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [PatientEnrollment] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [PatientEnrollment] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [PatientEnrollment] SET  ENABLE_BROKER 
GO
ALTER DATABASE [PatientEnrollment] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [PatientEnrollment] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [PatientEnrollment] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [PatientEnrollment] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [PatientEnrollment] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [PatientEnrollment] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [PatientEnrollment] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [PatientEnrollment] SET RECOVERY FULL 
GO
ALTER DATABASE [PatientEnrollment] SET  MULTI_USER 
GO
ALTER DATABASE [PatientEnrollment] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [PatientEnrollment] SET DB_CHAINING OFF 
GO
ALTER DATABASE [PatientEnrollment] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [PatientEnrollment] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [PatientEnrollment] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [PatientEnrollment] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
EXEC sys.sp_db_vardecimal_storage_format N'PatientEnrollment', N'ON'
GO
ALTER DATABASE [PatientEnrollment] SET QUERY_STORE = OFF
GO
USE [PatientEnrollment]
GO
/****** Object:  Schema [Auth]    Script Date: 16-Feb-22 06:19:29 PM ******/
CREATE SCHEMA [Auth]
GO
/****** Object:  Schema [Contacts]    Script Date: 16-Feb-22 06:19:29 PM ******/
CREATE SCHEMA [Contacts]
GO
/****** Object:  Schema [Insurance]    Script Date: 16-Feb-22 06:19:29 PM ******/
CREATE SCHEMA [Insurance]
GO
/****** Object:  Schema [Location]    Script Date: 16-Feb-22 06:19:29 PM ******/
CREATE SCHEMA [Location]
GO
/****** Object:  Schema [Profile]    Script Date: 16-Feb-22 06:19:29 PM ******/
CREATE SCHEMA [Profile]
GO
/****** Object:  Table [Auth].[DB_Errors]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Auth].[DB_Errors](
	[ErrorID] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [varchar](100) NULL,
	[ErrorSchema] [varchar](100) NULL,
	[ErrorProcedure] [varchar](max) NULL,
	[ErrorNumber] [int] NULL,
	[ErrorState] [int] NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorLine] [int] NULL,
	[ErrorMessage] [varchar](max) NULL,
	[ErrorDateTime] [datetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [Contacts].[Emails]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contacts].[Emails](
	[EmailId] [uniqueidentifier] NOT NULL,
	[Email] [varchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmailId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Contacts].[EmergencyContacts]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contacts].[EmergencyContacts](
	[EmergencyId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[PhoneNumber][varchar](250)NOT NULL,
	[Relationship] [varchar](250) NOT NULL,
	[DateOfBirth] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmergencyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Contacts].[Phones]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Contacts].[Phones](
	[PhoneId] [uniqueidentifier] NOT NULL,
	[PhoneNumber] [varchar](15) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PhoneId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Location].[Address]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Location].[Address](
	[AddressId] [uniqueidentifier] NOT NULL,
	[Line1] [varchar](250) NOT NULL,
	[Line2] [varchar](250) NOT NULL,
	[CityIDFK] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[AddressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Location].[Cities]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Location].[Cities](
	[CityId] [int] IDENTITY(1,1) NOT NULL,
	[CityName] [varchar](250) NOT NULL,
	[ProvinceIDFK] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CityId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Location].[Countries]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Location].[Countries](
	[CountryId] [int] IDENTITY(1,1) NOT NULL,
	[CountryName] [varchar](250) NOT NULL,
	[Alpha2Code] [varchar](5) NOT NULL,
	[Alpha3Code] [varchar](5) NOT NULL,
	[Numeric] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CountryId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Location].[Provinces]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Location].[Provinces](
	[ProvinceId] [int] IDENTITY(1,1) NOT NULL,
	[ProvinceName] [varchar](250) NOT NULL,
	[CountryIDFK] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ProvinceId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Profile].[Gender]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Profile].[Gender](
	[GenderId] [int] IDENTITY(1,1) NOT NULL,
	[GenderDescription] [varchar](250) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[GenderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Profile].[MaritalStatus]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Profile].[MaritalStatus](
	[MaritalStatusId] [int] IDENTITY(1,1) NOT NULL,
	[MaritalStatusDescription] [varchar](50) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[UpdateDate] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MaritalStatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [Profile].[Patient]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Profile].[Patient](
	[PatientId] [uniqueidentifier] NOT NULL,
	[FirstName] [varchar](250) NOT NULL,
	[LastName] [varchar](250) NOT NULL,
	[ID_Number] [varchar](250)NOT NULL,
	[DateOfBirth] [datetime] NOT NULL,
	[GenderIDFK] [int] NOT NULL,
	[MedicationList] [varchar](250) NOT NULL,
	[EmailIDFK] [uniqueidentifier] NOT NULL,
	[PhoneIDFK] [uniqueidentifier] NOT NULL,
	[AddressIDFK] [uniqueidentifier] NOT NULL,
	[MaritalStatusIDFK] [int] NOT NULL,
	[EmergencyIDFK] [uniqueidentifier] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[PatientId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [Contacts].[Emails] ADD  DEFAULT (newid()) FOR [EmailId]
GO
ALTER TABLE [Contacts].[EmergencyContacts] ADD  DEFAULT (newid()) FOR [EmergencyId]
GO
ALTER TABLE [Contacts].[Phones] ADD  DEFAULT (newid()) FOR [PhoneId]
GO
ALTER TABLE [Location].[Address] ADD  DEFAULT (newid()) FOR [AddressId]
GO
ALTER TABLE [Profile].[Patient] ADD  DEFAULT (newid()) FOR [PatientId]
GO
ALTER TABLE [Location].[Address]  WITH CHECK ADD FOREIGN KEY([CityIDFK])
REFERENCES [Location].[Cities] ([CityId])
GO
ALTER TABLE [Location].[Cities]  WITH CHECK ADD FOREIGN KEY([ProvinceIDFK])
REFERENCES [Location].[Provinces] ([ProvinceId])
GO
ALTER TABLE [Location].[Provinces]  WITH CHECK ADD FOREIGN KEY([CountryIDFK])
REFERENCES [Location].[Countries] ([CountryId])
GO
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([AddressIDFK])
REFERENCES [Location].[Address] ([AddressId])
GO
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([EmailIDFK])
REFERENCES [Contacts].[Emails] ([EmailId])
GO
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([EmergencyIDFK])
REFERENCES [Contacts].[EmergencyContacts] ([EmergencyId])
GO
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([GenderIDFK])
REFERENCES [Profile].[Gender] ([GenderId])
GO
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([MaritalStatusIDFK])
REFERENCES [Profile].[MaritalStatus] ([MaritalStatusId])
GO
ALTER TABLE [Profile].[Patient]  WITH CHECK ADD FOREIGN KEY([PhoneIDFK])
REFERENCES [Contacts].[Phones] ([PhoneId])
GO
/****** Object:  StoredProcedure [Auth].[Exception]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [Auth].[Exception]
(
	@UserName VARCHAR(200),
	@ErrorSchema VARCHAR(200),
	@ErrorProc VARCHAR(200),
	@ErrorNumber INT,
	@ErrorState INT,
	@ErrorSeverity INT,
	@ErrorLine INT,
	@ErrorMessage VARCHAR(200),
	@ErrorDateTime DATETIME
)
AS
BEGIN
	--SET	@UserName = SUSER_SNAME()
	--SET	@ErrorSchema = SCHEMA_NAME()
	--SET @ErrorProc = ERROR_PROCEDURE()
	--SET @ErrorNumber = ERROR_NUMBER()
	--SET @ErrorState = ERROR_STATE()
	--SET @ErrorSeverity = ERROR_SEVERITY()
	--SET @ErrorLine = ERROR_LINE()
	--SET @ErrorMessage = ERROR_MESSAGE()
	--SET @ErrorDateTime = GETDATE()

	INSERT INTO Auth.DB_Errors
	(
		UserName, 
		ErrorSchema, 
		ErrorProcedure, 
		ErrorNumber, 
		ErrorState, 
		ErrorSeverity, 
		ErrorLine, 
		ErrorMessage, 
		ErrorDateTime
	)
	VALUES(@UserName,@ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState, @ErrorSeverity, @ErrorLine, @ErrorMessage, @ErrorDateTime )

END
GO

/****** Object:  StoredProcedure [Location].[spGetCities]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [Location].[spGetCities]
(
	@CityId INT = 0,
	@CityName VARCHAR(250) = '' 
)
AS
BEGIN
SET NOCOUNT ON

	SELECT 
		CAST(CityId AS VARCHAR(250)) AS CityId, 
		CityName 
	FROM Location.Cities WITH(NOLOCK)

SET NOCOUNT OFF
END
GO
/****** Object:  StoredProcedure [Location].[spGetCountries]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [Location].[spGetCountries]
(
	@CountryId INT = 0,
	@CountryName VARCHAR(250) = ''
)
AS
BEGIN

SET NOCOUNT ON

	SELECT 
		CAST(CountryId AS VARCHAR(250)) AS CountryId, 
		CountryName 
	FROM Location.Countries 

SET NOCOUNT OFF

END
GO
/****** Object:  StoredProcedure [Location].[spGetProvinces]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [Location].[spGetProvinces]
(
	@ProvinceId INT = '',
	@ProvinceName VARCHAR(250) = ''
)
AS
BEGIN
SET NOCOUNT ON
	
	SELECT CAST(ProvinceId AS VARCHAR(250)) AS ProvinceId , ProvinceName
	FROM  Location.Provinces WITH (NOLOCK)

SET NOCOUNT OFF
END
GO
/****** Object:  StoredProcedure [Location].[spInsertCountries]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [Location].[spInsertCountries]
(
	@Country VARCHAR(250), 
	@Alpha2Code VARCHAR(250),
	@Alpha3Code VARCHAR(250),
	@Numeric VARCHAR(250), 
	@IsActive BIT,
	@UpdateDate DATETIME,
	@Message VARCHAR(250) OUTPUT 
)
AS
BEGIN

SET NOCOUNT ON

	IF NOT EXISTS(SELECT 1 FROM Location.Countries WHERE CountryName = @Country)
	BEGIN

		INSERT INTO Location.Countries
		(
			CountryName, 
			Alpha2Code, 
			Alpha3Code, 
			Numeric, 
			IsActive, 
			UpdateDate
		)
		VALUES(@Country, @Alpha2Code, @Alpha3Code, @Numeric, @IsActive, @UpdateDate)
	
		SET @Message = ''

	END ELSE
	BEGIN
		
		SET @Message = 'please check xlsx doc Duplicate found '

	END

SET NOCOUNT OFF

END
GO
/****** Object:  StoredProcedure [Location].[spInsertSouthAfrican_Cities]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [Location].[spInsertSouthAfrican_Cities]
(
	@CityName VARCHAR(250),
	@Province VARCHAR(250),
	@IsActive BIT,
	@UpdateDate DATETIME,
	@Message VARCHAR(250) OUTPUT
)
AS
BEGIN
	
	
		INSERT INTO Location.Cities
		(
			CityName, 
			ProvinceIDFK, 
			IsActive, 
			UpdateDate
		)
		VALUES(@CityName, (SELECT ProvinceId FROM Location.Provinces WHERE ProvinceName = @Province), @IsActive, @UpdateDate)
		
		SET @Message = ''
	
END
GO
/****** Object:  StoredProcedure [Profile].[spAddPatientProfile]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [Profile].[spAddPatientProfile]
(
	@FirstName VARCHAR(250) = '',
	@LastName VARCHAR(250) = '',
	@DateOfBirth DATETIME,
	@GenderDescription VARCHAR(250) = '',
	@PhoneNumber VARCHAR(250) = '',
	@PhoneTypeIDFK INT = 0,
	@Email VARCHAR(250) = '',
	@EmailTypeIDFK INT = 0,
	@Line1 VARCHAR(250) = '',
	@Line2 VARCHAR(250) = '',
	@CityIDFK INT = 0,
	@ProvinceIDFK INT = 0,
	@CountryIDFK INT = 0,
	@MaritalStatusIDFK INT = 0,
	@MedicationList VARCHAR(MAX) = '',
	@EmergencyName VARCHAR(250) = '',
	@EmergencyLastName VARCHAR(250) = '',
	@Relationship VARCHAR(250) = '',
	@RelationshipDateOfBirth DATETIME,
	@PrimaryCarrierName VARCHAR(250) = '',
	@FPolicyHolderPhoneNumber VARCHAR(250) = '',
	@FPolicyHolderName VARCHAR(250) = '',
	@FPolicyHolderDateOfBirth DATETIME,
	@FPolicyHolderRelationship VARCHAR(250) = '',
	@FPolicyHolderGenderIDFK INT = 0,
	@SecondaryCarrierName VARCHAR(250) = '',
	@SPolicyHolderPhoneNumber VARCHAR(250) = '',
	@SPolicyHolderName VARCHAR(250) = '',
	@SPolicyHolderDateOfBirth DATETIME,
	@SPolicyHolderRelationship VARCHAR(250) = '',
	@SPolicyHolderGenderIDFK INT = 0,
	@Message VARCHAR(250) OUTPUT
)
AS
BEGIN
	
	DECLARE @IsActive BIT = 0,
			@DefaultDate DATETIME = GETDATE(),
			@GenderIDFK INT,
			@PrimaryCarrierIDFK UNIQUEIDENTIFIER = NEWID(),
			@SecondaryCarrierIDFK UNIQUEIDENTIFIER = NEWID(),
			@EmailIDFK UNIQUEIDENTIFIER = NEWID(),
			@PhoneIDFK UNIQUEIDENTIFIER = NEWID(),
			@AddressIDFK UNIQUEIDENTIFIER = NEWID(),
			@EmergencyIDFK UNIQUEIDENTIFIER = NEWID(),
			@UserName VARCHAR(200),
			@ErrorSchema VARCHAR(200),
			@ErrorProc VARCHAR(200),
			@ErrorNumber INT,
			@ErrorState INT,
			@ErrorSeverity INT,
			@ErrorLine INT,
			@ErrorMessage VARCHAR(200),
			@ErrorDateTime DATETIME

SET NOCOUNT ON
	
	/*Summary*/
	/*Insert all the details into the Patient table */

	/*Email is the main patient authantification */

	BEGIN TRY
	
	BEGIN TRAN

		IF NOT EXISTS(SELECT 1 FROM Contacts.Emails WITH(NOLOCK) WHERE Email = @Email)
		BEGIN
			
			SET @IsActive = 1

			--INSERT INTO EMAILS TABLE 
			INSERT INTO Contacts.Emails
			(
				Email, 
				EmailTypeIDFK, 
				IsActive, 
				UpdateDate
			)
			VALUES(@Email, @EmailTypeIDFK, @IsActive, @DefaultDate)

			--INSERT INTO PHONES TABLE
			INSERT INTO Contacts.Phones
			(
				PhoneNumber, 
				PhoneTypeIDFK, 
				IsActive, 
				UpdateDate
			)
			VALUES(@PhoneNumber, @PhoneTypeIDFK, @IsActive, @DefaultDate)

			--INSERT INTO ADDRESS TABLE 
			INSERT INTO Location.Address
			(
				Line1, 
				Line2, 
				CityIDFK
			)
			VALUES(@Line1, @Line2, @CityIDFK)

			--INSERT INTO EMERGENCY CONTACTS TABLE
			INSERT INTO Contacts.EmergencyContacts
			(
				FirstName, 
				LastName, 
				Relationship, 
				DateOfBirth, 
				IsActive, 
				UpdateDate
			)
			VALUES(@EmergencyName, @EmergencyLastName, @Relationship, @RelationshipDateOfBirth, @IsActive, @DefaultDate)


			--INSERT INTO PRIMARY CARRIER TABLE 
			INSERT INTO Insurance.CarrierPhoneNumber
			(
				CarrierPhoneNumber, 
				IsActive, 
				UpdateDate
			)
			VALUES(@PhoneNumber, @IsActive, @DefaultDate)
		
			INSERT INTO Insurance.PrimaryCarrier
			(
				PrimaryCarrierName, 
				PrimaryCarrierPhoneNumberIDFK, 
				Primary_PH_Name, 
				Primary_PH_DateOfBirth, 
				Primary_PH_Relationship, 
				Primary_PH_GenderIDFK
			)
			VALUES(@PrimaryCarrierName, @FPolicyHolderPhoneNumber, @FPolicyHolderName, @FPolicyHolderDateOfBirth, @FPolicyHolderRelationship, @FPolicyHolderGenderIDFK)


			--INSERT INTO CARRIER TABLE
			INSERT INTO Insurance.CarrierPhoneNumber
			(
				CarrierPhoneNumber, 
				IsActive, 
				UpdateDate
			)
			VALUES(@PhoneNumber, @IsActive, @DefaultDate)
		
			INSERT INTO Insurance.SecondaryCarrier
			(
				SecondaryCarrierName, 
				CarrierPhoneNumberIDFK, 
				Secondary_PH_Name, 
				Secondary_PH_DateOfBirth, 
				Secondary_PH_Relationship, 
				Secondary_PH_GenderIDFK
			)
			VALUES(@SecondaryCarrierName, @SPolicyHolderPhoneNumber, @SPolicyHolderName, @SPolicyHolderDateOfBirth, @SPolicyHolderRelationship, @SPolicyHolderGenderIDFK )
			

			--INSERT PATIENT TABLE
			INSERT INTO Profile.Patient
			(
				FirstName, 
				LastName, 
				DateOfBirth, 
				GenderIDFK, 
				MedicationList, 
				EmailIDFK, 
				PhoneIDFK, 
				AddressIDFK, 
				MaritalStatusIDFK, 
				EmergencyIDFK, 
				PrimaryCarrier, 
				SecondaryCarrier
			)
			VALUES(@FirstName, @LastName, @DateOfBirth, @GenderIDFK, @MedicationList, @EmailIDFK, @PhoneIDFK, @AddressIDFK, @MaritalStatusIDFK, @EmergencyIDFK, @PrimaryCarrierIDFK, @SecondaryCarrierIDFK)

			COMMIT TRAN

		END ELSE 
		BEGIN
			
			ROLLBACK TRAN

			SET	@FirstName  = ''
			SET @LastName = ''
			SET @DateOfBirth = GETDATE()
			SET @GenderDescription = ''
			SET @PhoneNumber = ''
			SET @PhoneTypeIDFK = 0
			SET @Email = ''
			SET @EmailTypeIDFK = 0
			SET @Line1 = ''
			SET @Line2 = ''
			SET @CityIDFK = 0
			SET @ProvinceIDFK = 0
			SET @CountryIDFK = 0
			SET @MaritalStatusIDFK = 0
			SET @MedicationList = ''
			SET @EmergencyName = ''
			SET @EmergencyLastName = ''
			SET @Relationship = ''
			SET @RelationshipDateOfBirth = GETDATE()
			SET @PrimaryCarrierName = ''
			SET @FPolicyHolderPhoneNumber = ''
			SET @FPolicyHolderName = ''
			SET @FPolicyHolderDateOfBirth = GETDATE()
			SET @FPolicyHolderRelationship = ''
			SET @FPolicyHolderGenderIDFK = 0
			SET @SecondaryCarrierName = ''
			SET @SPolicyHolderPhoneNumber = ''
			SET @SPolicyHolderName = ''
			SET @SPolicyHolderDateOfBirth = GETDATE()
			SET @SPolicyHolderRelationship = ''
			SET @SPolicyHolderGenderIDFK = 0
			SET @Message = 'Sorry User email: '+ @Email + ' already exists'

		END
	END TRY 
	BEGIN CATCH
		
		
		SET	@UserName = SUSER_SNAME()
		SET	@ErrorSchema = SCHEMA_NAME()
		SET @ErrorProc = ERROR_PROCEDURE()
		SET @ErrorNumber = ERROR_NUMBER()
		SET @ErrorState = ERROR_STATE()
		SET @ErrorSeverity = ERROR_SEVERITY()
		SET @ErrorLine = ERROR_LINE()
		SET @ErrorMessage = ERROR_MESSAGE()
		SET @ErrorDateTime = GETDATE()

		EXEC [Auth].[Exception] @UserName,@ErrorSchema, @ErrorProc, @ErrorNumber, @ErrorState, @ErrorSeverity, @ErrorLine, @ErrorMessage, @ErrorDateTime

	END CATCH

SET NOCOUNT OFF
END
GO
/****** Object:  StoredProcedure [Profile].[spGetMaritalStatus]    Script Date: 16-Feb-22 06:19:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [Profile].[spGetMaritalStatus]
(
	@MaritalStatusId INT = 0,
	@MaritalStatusDescription VARCHAR(250) = ''
)
AS
BEGIN
SET NOCOUNT ON

	SELECT CAST(MaritalStatusId AS VARCHAR(250)) AS MaritalStatusId, MaritalStatusDescription 
	FROM Profile.MaritalStatus 
	WITH(NOLOCK) 

SET NOCOUNT OFF

END
GO
USE [master]
GO
ALTER DATABASE [PatientEnrollment] SET  READ_WRITE 
GO
