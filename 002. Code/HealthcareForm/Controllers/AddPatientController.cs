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
    public class AddPatientController : Controller
    {
        // GET: AddPatient
        public ActionResult Index()
        {
            MainModel model = new MainModel();
            return View("index", model);
        }

        // Send patient data to the database 
        [HttpPost]
        public JsonResult AddPatient(MainModel locationModel)
        {
            // Database connection string instance 
            string connection = ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString;

            using (SqlConnection conn = new SqlConnection(connection))
            {

                SqlCommand cmd = new SqlCommand("Profile.spAddPatient", conn);
                cmd.CommandType = CommandType.StoredProcedure;

                //Sending parameters values to the stored procedure 
                cmd.Parameters.Add(new SqlParameter("@FirstName", locationModel.FirstName));
                cmd.Parameters.Add(new SqlParameter("@LastName", locationModel.LastName));
                cmd.Parameters.Add(new SqlParameter("@ID_Number", locationModel.ID_Number));
                cmd.Parameters.Add(new SqlParameter("@DateOfBirth", locationModel.DateOfBirth));
                cmd.Parameters.Add(new SqlParameter("@GenderIDFK", Int32.Parse(locationModel.GenderIDFK)));
                cmd.Parameters.Add(new SqlParameter("@PhoneNumber", locationModel.PhoneNumber));
                cmd.Parameters.Add(new SqlParameter("@Email", locationModel.Email));
                cmd.Parameters.Add(new SqlParameter("@Line1", locationModel.Line1));
                cmd.Parameters.Add(new SqlParameter("@Line2", locationModel.Line2));
                cmd.Parameters.Add(new SqlParameter("@CityIDFK", Int32.Parse(locationModel.CityIDFK)));
                cmd.Parameters.Add(new SqlParameter("@ProvinceIDFK", Int32.Parse(locationModel.ProvinceIDFK)));
                cmd.Parameters.Add(new SqlParameter("@CountryIDFK", Int32.Parse(locationModel.CountryIDFK)));
                cmd.Parameters.Add(new SqlParameter("@MaritalStatusIDFK", Int32.Parse(locationModel.MaritalStatusIDFK)));
                cmd.Parameters.Add(new SqlParameter("@MedicationList", locationModel.MedicationList));
                cmd.Parameters.Add(new SqlParameter("@EmergencyName", locationModel.EmergencyName));
                cmd.Parameters.Add(new SqlParameter("@EmergencyLastName", locationModel.EmergencyLastName));
                cmd.Parameters.Add(new SqlParameter("@EmergencyPhoneNumber", locationModel.EmergencyPhoneNumber));
                cmd.Parameters.Add(new SqlParameter("@Relationship", locationModel.Relationship));
                cmd.Parameters.Add(new SqlParameter("@EmergancyDateOfBirth", locationModel.EmergancyDateOfBirth));
                cmd.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;

                conn.Open();
                cmd.ExecuteNonQuery();

                if (Convert.ToString(cmd.Parameters["@Message"].Value) == "")
                {
                    locationModel.Message = "";
                }
                else
                {
                    locationModel.Message = Convert.ToString(cmd.Parameters["@Message"].Value);
                }
                conn.Close();
            }
            return new JsonResult { Data = locationModel, JsonRequestBehavior = JsonRequestBehavior.AllowGet };

        }

    }
    
}