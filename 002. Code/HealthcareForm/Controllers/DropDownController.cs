using HealthcareForm.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc; 

namespace HealthcareForm.Controllers
{
    public class DropDownController : Controller
    {
        // GET: DropDown
        public ActionResult Index()
        {
            MainModel model = new MainModel();
            return View("index", model);
        }

        // Get gender list 
        public JsonResult GetGender()
        {
            using (var db = HomeController.GetContxt())
            {
                var eventGender = db.Database.SqlQuery<MainModel>(string.Format("Profile.spGetGender")).ToList();
                return new JsonResult { Data = eventGender, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
        }

        // get Merital status list 
        public JsonResult GetMeritalStatus()
        {
            using (var db = HomeController.GetContxt())
            {
                var eventMerital = db.Database.SqlQuery<MainModel>(String.Format("Profile.spGetMaritalStatus")).ToList();

                return new JsonResult { Data = eventMerital, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
        }

        // Get Country list 
        public JsonResult GetCountries()
        {
            using (var db = HomeController.GetContxt())
            {
                var eventCountries = db.Database.SqlQuery<MainModel>(String.Format("Location.spGetCountries")).ToList();

                return new JsonResult { Data = eventCountries, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
        }

        // Get Provincial list 
        public JsonResult GetProvinces()
        {
            using (var db = HomeController.GetContxt())
            {
                var eventProvinces = db.Database.SqlQuery<MainModel>(String.Format("Location.spGetProvinces")).ToList();

                return new JsonResult { Data = eventProvinces, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }
        }

        // Get cities list 
        public JsonResult GetCities()
        {
            using (var db = HomeController.GetContxt())
            {
                var eventCities = db.Database.SqlQuery<MainModel>(String.Format("Location.spGetCities")).ToList();

                return new JsonResult { Data = eventCities, JsonRequestBehavior = JsonRequestBehavior.AllowGet };
            }

        }
    }
}