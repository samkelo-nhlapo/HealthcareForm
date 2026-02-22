using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Optimization;

namespace HealthcareForm.Views.Shared
{
    public class BundleConfig
    {
        public static void RegisterBundles(BundleCollection bundles) 
        {
            // Wildcard for version so that irrestpective if the version the file will be selected
            bundles.Add(new ScriptBundle("~/bundles/jquery").Include("~/Scripts/jquery-{version}.js"));

            // Wildcard to select all files that start with prefix jquery.validate
            bundles.Add(new ScriptBundle("~/bundles/jqueryval").Include("~/Scripts/jquery.validate*"));
        }

    }
}