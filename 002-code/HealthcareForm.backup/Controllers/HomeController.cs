using HealthcareForm.Models;
using HealthcareForm.Repo;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace HealthcareForm.Controllers
{
    public class HomeController : Controller
    {
        public ActionResult Index()
        {
            MainModel model = new MainModel();
            return View("Index", model);
        }

        public ActionResult About()
        {
            return View();
        }

        public ActionResult Contact()
        {
            return View();
        }

        public static Contxt GetContxt()
        {
            return new Contxt();
        }
    }
}