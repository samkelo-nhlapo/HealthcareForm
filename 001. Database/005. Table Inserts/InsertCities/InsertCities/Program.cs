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
            var fileName = Path.GetFullPath(@"C:\Users\Sam\Music\PatientEnrollment\Enrollment DB\005. Table Inserts\SouthAfricanCities.xlsx");

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

                string CityName = "";
                string Province = "";
                string isActive = "0";
                DateTime datetime = DateTime.Now;
                string message = "";

                if (count.NumberOfColumns is 0)
                {

                }
                for (int rowIndex = 2; rowIndex < count.EndRowIndex + 1; rowIndex++)
                {
                    CityName = doc.GetCellValueAsString(rowIndex, 1);
                    Province = doc.GetCellValueAsString(rowIndex, 2);

                    using (SqlConnection conn = new SqlConnection("Server=localhost,8080;Database=PatientEnrollment;User Id=sa;Password=111GkiPQ25af;"))
                    {
                        //Console.WriteLine("Connected to sql");
                        SqlCommand command = new SqlCommand("Location.spInsertSouthAfrican_Cities", conn);
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.Add(new SqlParameter("@CityName", CityName));
                        command.Parameters.Add(new SqlParameter("@Province", Province));
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
