using HealthcareForm.Models;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace HealthcareForm.Controllers
{
    public class GetPatientController : Controller
    {
        public ActionResult index()
        {
            MainModel model = new MainModel();
            return View("Index", model);
        }

        // Return patient data from the database through (ID number)
        [HttpGet]
        public JsonResult GetPatient(string IDnumber = "")
        {
            // Use GetPatient model instance 
            GetPatientModel locationModel = new GetPatientModel();

            string conn = ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString;

            using (SqlConnection connection = new SqlConnection(conn))
            {
                SqlCommand cmd = new SqlCommand("Profile.spGetPatient", connection);
                cmd.CommandType = CommandType.StoredProcedure;

                //input 
                cmd.Parameters.Add(new SqlParameter("@IDNumber", IDnumber));

                //output
                cmd.Parameters.Add(new SqlParameter("@FirstName", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@LastName", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@ID_Number", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@DateOfBirth", SqlDbType.DateTime)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@GenderIDFK", SqlDbType.Int)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@PhoneNumber", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@Email", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@Line1", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@Line2", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@CityIDFK", SqlDbType.Int)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@ProvinceIDFK", SqlDbType.Int)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@CountryIDFK", SqlDbType.Int)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", SqlDbType.Int)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@MedicationList", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@EmergencyName", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@EmergencyLastName", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@EmergencyPhoneNumber", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@Relationship", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@EmergancyDateOfBirth", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;
                cmd.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;

                connection.Open();
                cmd.ExecuteNonQuery();

                if (Convert.ToString(cmd.Parameters["@Message"].Value) == "")
                {
                    //Store output parameter value in variables
                    locationModel.IDNumber = Convert.ToString(cmd.Parameters["@IDNumber"].Value);
                    locationModel.FirstName = Convert.ToString(cmd.Parameters["@FirstName"].Value);
                    locationModel.LastName = Convert.ToString(cmd.Parameters["@LastName"].Value);
                    locationModel.ID_Number = Convert.ToString(cmd.Parameters["@ID_Number"].Value);
                    locationModel.DateOfBirth = Convert.ToDateTime(cmd.Parameters["@DateOfBirth"].Value);
                    locationModel.GenderIDFK = Convert.ToInt32(cmd.Parameters["@GenderIDFK"].Value);
                    locationModel.PhoneNumber = Convert.ToString(cmd.Parameters["@PhoneNumber"].Value);
                    locationModel.Email = Convert.ToString(cmd.Parameters["@Email"].Value);
                    locationModel.Line1 = Convert.ToString(cmd.Parameters["@Line1"].Value);
                    locationModel.Line2 = Convert.ToString(cmd.Parameters["@Line2"].Value);
                    locationModel.CityIDFK = Convert.ToInt32(cmd.Parameters["@CityIDFK"].Value);
                    locationModel.ProvinceIDFK = Convert.ToInt32(cmd.Parameters["@ProvinceIDFK"].Value);
                    locationModel.CountryIDFK = Convert.ToInt32(cmd.Parameters["@CountryIDFK"].Value);
                    locationModel.MaritalStatusIDFK = Convert.ToInt32(cmd.Parameters["@MaritalStatusIDFK"].Value);
                    locationModel.MedicationList = Convert.ToString(cmd.Parameters["@MedicationList"].Value);
                    locationModel.EmergencyName = Convert.ToString(cmd.Parameters["@EmergencyName"].Value);
                    locationModel.EmergencyLastName = Convert.ToString(cmd.Parameters["@EmergencyLastName"].Value);
                    locationModel.EmergencyPhoneNumber = Convert.ToString(cmd.Parameters["@EmergencyPhoneNumber"].Value);
                    locationModel.Relationship = Convert.ToString(cmd.Parameters["@Relationship"].Value);
                    locationModel.EmergancyDateOfBirth = Convert.ToDateTime(cmd.Parameters["@EmergancyDateOfBirth"].Value);

                    locationModel.Message = "";

                }
                else
                {
                    locationModel.Message = Convert.ToString(cmd.Parameters["@Message"].Value);

                    locationModel.IDNumber = IDnumber;
                    locationModel.FirstName = "";
                    locationModel.LastName = "";
                    locationModel.ID_Number = "";
                    locationModel.DateOfBirth = DateTime.Now;
                    locationModel.GenderIDFK = 0;
                    locationModel.PhoneNumber = "";
                    locationModel.Email = "";
                    locationModel.Line1 = "";
                    locationModel.Line2 = "";
                    locationModel.CityIDFK = 0;
                    locationModel.ProvinceIDFK = 0;
                    locationModel.CountryIDFK = 0;
                    locationModel.MaritalStatusIDFK = 0;
                    locationModel.MedicationList = "";
                    locationModel.EmergencyName = "";
                    locationModel.EmergencyLastName = "";
                    locationModel.EmergencyPhoneNumber = "";
                    locationModel.Relationship = "";
                    locationModel.EmergancyDateOfBirth = DateTime.Now;
                }

                connection.Close();

            }

            return new JsonResult { Data = locationModel, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
        }
    }
}