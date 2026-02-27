using SpreadsheetLight;
using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;

namespace Insert_Countries
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
                : Environment.GetEnvironmentVariable("INSERT_PATIENTENROLLMENT_COUNTRIES_FILE")
                    ?? @"C:\Users\Sam\Music\PatientEnrollment\Enrollment DB\005. Table Inserts\all Countries.xlsx";
            var fileName = Path.GetFullPath(fileNameInput);

            if (!File.Exists(fileName))
            {
                Console.WriteLine($"Input file not found: {fileName}");
                Console.WriteLine("Pass the Excel file path as arg[0] or set INSERT_PATIENTENROLLMENT_COUNTRIES_FILE.");
                return;
            }

            Console.WriteLine($"Using input file: {fileName}");

            using (var doc = new SLDocument(fileName))
            {
                SLWorksheetStatistics count = doc.GetWorksheetStatistics();

                string Country = "";
                string Alpha2Code = "";
                string Alpha3Code = "";
                string Numeric = "";
                bool isActive = false;
                DateTime datetime = DateTime.Now;

                if (count.NumberOfColumns is 0)
                {

                }
                for (int rowIndex = 3; rowIndex < count.EndRowIndex + 1; rowIndex++)
                {
                    Country = doc.GetCellValueAsString(rowIndex, 1);
                    Alpha2Code = doc.GetCellValueAsString(rowIndex, 2);
                    Alpha3Code = doc.GetCellValueAsString(rowIndex, 3);
                    Numeric = doc.GetCellValueAsString(rowIndex, 4);

                    using (SqlConnection conn = new SqlConnection(connectionString))
                    {
                        SqlCommand command = new SqlCommand(@"
SET NOCOUNT ON;

IF NOT EXISTS (
    SELECT 1
    FROM Location.Countries
    WHERE CountryName = @Country
)
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
    VALUES
    (
        @Country,
        @Alpha2Code,
        @Alpha3Code,
        @Numeric,
        @IsActive,
        @UpdateDate
    );
END;", conn);
                        command.CommandType = CommandType.Text;

                        command.Parameters.Add(new SqlParameter("@Country", Country));
                        command.Parameters.Add(new SqlParameter("@Alpha2Code", Alpha2Code));
                        command.Parameters.Add(new SqlParameter("@Alpha3Code", Alpha3Code));
                        command.Parameters.Add(new SqlParameter("@Numeric", Numeric));
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
