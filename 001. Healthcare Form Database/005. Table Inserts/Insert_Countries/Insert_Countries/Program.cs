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
            var fileName = Path.GetFullPath(@"C:\Users\Sam\Music\PatientEnrollment\Enrollment DB\005. Table Inserts\all Countries.xlsx");

            if (fileName is null)
            {
                Console.WriteLine("where is the file");
            }
            else
            {
                Console.WriteLine("found file");
            }

            using (var doc = new SLDocument(fileName))
            {
                SLWorksheetStatistics count = doc.GetWorksheetStatistics();

                string Country = "";
                string Alpha2Code = "";
                string Alpha3Code = "";
                string Numeric = "";
                string isActive = "0";
                DateTime datetime = DateTime.Now;
                string message = "";

                if (count.NumberOfColumns is 0)
                {

                }
                for (int rowIndex = 3; rowIndex < count.EndRowIndex + 1; rowIndex++)
                {
                    Country = doc.GetCellValueAsString(rowIndex, 1);
                    Alpha2Code = doc.GetCellValueAsString(rowIndex, 2);
                    Alpha3Code = doc.GetCellValueAsString(rowIndex, 3);
                    Numeric = doc.GetCellValueAsString(rowIndex, 4);

                    using (SqlConnection conn = new SqlConnection("Server=localhost,8080;Database=PatientEnrollment;User Id=sa;Password=111GkiPQ25af;"))
                    {
                        //Console.WriteLine("Connected to sql");
                        SqlCommand command = new SqlCommand("Location.spInsertCountries", conn);
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.Add(new SqlParameter("@Country", Country));
                        command.Parameters.Add(new SqlParameter("@Alpha2Code", Alpha2Code));
                        command.Parameters.Add(new SqlParameter("@Alpha3Code", Alpha3Code));
                        command.Parameters.Add(new SqlParameter("@Numeric", Numeric));
                        command.Parameters.Add(new SqlParameter("@IsActive", isActive));
                        command.Parameters.Add(new SqlParameter("@UpdateDate", datetime));
                        command.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;

                        conn.Open();
                        command.ExecuteNonQuery();
                        if (Convert.ToString(command.Parameters["@Message"].Value) != "")
                        {
                            Console.WriteLine(Convert.ToString(command.Parameters["@Message"].Value));
                        }

                        conn.Close();
                    }

                }
            }
        }
    }
}
