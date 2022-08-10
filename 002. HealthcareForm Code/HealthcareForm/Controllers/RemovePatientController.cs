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
    public class RemovePatientController : Controller
    {
        // GET: RemovePatient
        public ActionResult Index()
        {
            return View();
        }

        [HttpPost]
        public JsonResult RemovePatient(MainModel locationModel)
        {
            var connectionEntity = ConfigurationManager.ConnectionStrings["HealthcareEntity"].ConnectionString;

            using(SqlConnection conn = new SqlConnection(connectionEntity))
            {
                SqlCommand cmd = new SqlCommand("Profile.spDeletePatient", conn);
                cmd.CommandType = CommandType.StoredProcedure;

                cmd.Parameters.Add(new SqlParameter("@IDNumber", locationModel.IDNumber));
                cmd.Parameters.Add(new SqlParameter("@Message", SqlDbType.VarChar, 250)).Direction = ParameterDirection.Output;

                conn.Open();
                cmd.ExecuteNonQuery();

                if (Convert.ToString(cmd.Parameters["@Message"].Value) == "")
                {
                    locationModel.Message = "";
                    ModelState.Clear();
                    
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