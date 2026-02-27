using SpreadsheetLight;
using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;

namespace InsertCities
{
    class Program
    {
        static void Main(string[] args)
        {
            var connectionString = Environment.GetEnvironmentVariable("PATIENT_ENROLLMENT_SQL_CONNECTION_STRING")
                ?? Environment.GetEnvironmentVariable("MSSQL_CONNECTION_STRING");

            if (string.IsNullOrWhiteSpace(connectionString))
            {
                Console.WriteLine("Missing DB connection string. Set PATIENT_ENROLLMENT_SQL_CONNECTION_STRING or MSSQL_CONNECTION_STRING.");
                return;
            }

            var fileNameInput = args.Length > 0
                ? args[0]
                : Environment.GetEnvironmentVariable("INSERT_PATIENTENROLLMENT_CITIES_FILE")
                    ?? @"C:\Users\Sam\Music\PatientEnrollment\Enrollment DB\005. Table Inserts\SouthAfricanCities.xlsx";
            var fileName = Path.GetFullPath(fileNameInput);

            if (!File.Exists(fileName))
            {
                Console.WriteLine($"Input file not found: {fileName}");
                Console.WriteLine("Pass the Excel file path as arg[0] or set INSERT_PATIENTENROLLMENT_CITIES_FILE.");
                return;
            }

            Console.WriteLine($"Using input file: {fileName}");

            using (var doc = new SLDocument(fileName))
            {
                SLWorksheetStatistics count = doc.GetWorksheetStatistics();

                string CityName = "";
                string Province = "";
                bool isActive = false;
                DateTime datetime = DateTime.Now;

                if (count.NumberOfColumns is 0)
                {

                }
                for (int rowIndex = 2; rowIndex < count.EndRowIndex + 1; rowIndex++)
                {
                    CityName = doc.GetCellValueAsString(rowIndex, 1);
                    Province = doc.GetCellValueAsString(rowIndex, 2);

                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        SqlCommand command = new SqlCommand(@"
SET NOCOUNT ON;

DECLARE @ProvinceKey INT;
SELECT TOP (1) @ProvinceKey = ProvinceId
FROM Location.Provinces
WHERE ProvinceName = @Province
   OR CAST(ProvinceId AS VARCHAR(50)) = @Province;

IF @ProvinceKey IS NULL
BEGIN
    THROW 50001, 'Province not found for city insert.', 1;
END;

IF NOT EXISTS (
    SELECT 1
    FROM Location.Cities
    WHERE CityName = @CityName
      AND ProvinceIDFK = @ProvinceKey
)
BEGIN
    INSERT INTO Location.Cities
    (
        CityName,
        ProvinceIDFK,
        IsActive,
        UpdateDate
    )
    VALUES
    (
        @CityName,
        @ProvinceKey,
        @IsActive,
        @UpdateDate
    );
END;", conn);
                        command.CommandType = CommandType.Text;

                        command.Parameters.Add(new SqlParameter("@CityName", CityName));
                        command.Parameters.Add(new SqlParameter("@Province", Province));
                        command.Parameters.Add(new SqlParameter("@IsActive", isActive));
                        command.Parameters.Add(new SqlParameter("@UpdateDate", datetime));

                        conn.Open();
                        command.ExecuteNonQuery();
                        conn.Close();
                    }

                }
            }
        }
    }
}
