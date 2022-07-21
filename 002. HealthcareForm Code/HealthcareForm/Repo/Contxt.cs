using System.Data.Entity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace HealthcareForm.Repo
{
    public class Contxt : DbContext
    {
        public Contxt() : base("name = EnrollmentEntity"){  }
    }
}