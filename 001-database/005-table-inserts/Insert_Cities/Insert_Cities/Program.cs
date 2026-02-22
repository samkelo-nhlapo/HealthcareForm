using SpreadsheetLight;
using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;

namespace Insert_Cities
{
    class Program
    {
        static void Main(string[] args)
        {
            var fileName = Path.GetFullPath(@"C:\Users\Sam\Music\PatientEnrollment\001. Enrollment DB\005. Table Inserts\XML files\za.xlsx");

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
                string ProvinceId = "";
                string isActive = "0";
                DateTime datetime = DateTime.Now;
                string message = "";

                if (count.NumberOfColumns is 0)
                {

                }
                for (int rowIndex = 3; rowIndex < count.EndRowIndex + 1; rowIndex++)
                {
                    CityName = doc.GetCellValueAsString(rowIndex, 1);
                    ProvinceId = doc.GetCellValueAsString(rowIndex, 2);

                    using (SqlConnection conn = new SqlConnection("Server=localhost,1433;Database=HealthcareForm;User Id=sa;Password=111GkiPQ25af; "))
                    {
                        //Console.WriteLine("Connected to sql");
                        SqlCommand command = new SqlCommand("Location.spInsertSouthAfrican_Cities", conn);
                        command.CommandType = CommandType.StoredProcedure;

                        command.Parameters.Add(new SqlParameter("@CityName", CityName));
                        command.Parameters.Add(new SqlParameter("@Province", ProvinceId));
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
