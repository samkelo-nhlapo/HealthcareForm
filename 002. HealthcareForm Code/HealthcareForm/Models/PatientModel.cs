using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.ComponentModel.DataAnnotations;

namespace PatientEnrollmentVS.Models
{
    public class PatientModel
    {
        public string IDNumber { get; set; }

        //Country
        public string CountryIDFK { get; set; }
        public string CountryName { get; set; }

        //Province
        public string ProvinceIDFK { get; set; }
        public string ProvinceName { get; set; }

        //Cities
        public string CityIDFK { get; set; }
        public string CityName { get; set; }

        //MaritalStatus
        public string MaritalStatusIDFK { get; set; }
        public string MaritalStatusDescription { get; set; }

        //Gender
        public string GenderIDFK { get; set; }
        public string GenderDescription { get; set; }

        //Patient
        [Required(ErrorMessage = "Enter Your Name")]
        public string FirstName { get; set; }
        [Required(ErrorMessage = "Enter Your Last Name")]
        public string LastName { get; set; }
        public string ID_Number { get; set; }
        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString = "{0:dd-MM-yyyy}", ApplyFormatInEditMode = true)]
        public DateTime DateOfBirth { get; set; }
        [DataType(DataType.PhoneNumber)]
        [RegularExpression(@"^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$", ErrorMessage = "Not a valid Phone number")]
        public string PhoneNumber { get; set; }
        [Required(ErrorMessage = "Enter your Email Address")]
        [RegularExpression(@"^[\w -\._\+%] +@(?:[\w -] +\.)+[\w]{2,6}$", ErrorMessage = "Please enter a valid email address")]
        public string Email { get; set; }
        public string Line1 { get; set; }
        public string Line2 { get; set; }
        public string MedicationList { get; set; }
        public string EmergencyName { get; set; }
        public string EmergencyLastName { get; set; }
        [DataType(DataType.PhoneNumber)]
        [RegularExpression(@"^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$", ErrorMessage = "Not a valid Phone number")]
        public string EmergencyPhoneNumber { get; set; }
        public string Relationship { get; set; }
        public DateTime EmergancyDateOfBirth { get; set; }

        //public string LocationMessage { get; set; }
        public string Message { get; set; }

    }
}
//[DataType(DataType.Date)]
//[DisplayFormat(DataFormatString ="{0:dd-MM-yyyy}", ApplyFormatInEditMode =true)]