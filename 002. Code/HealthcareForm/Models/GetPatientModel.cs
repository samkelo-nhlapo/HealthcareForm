using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.Linq;
using System.Web;

namespace HealthcareForm.Models
{
    public class GetPatientModel
    {
        
        public string IDNumber { get; set; }

        //Country
        public int CountryIDFK { get; set; }

        //Province
        public int ProvinceIDFK { get; set; }

        //Cities
        public int CityIDFK { get; set; }

        //MaritalStatus
        public int MaritalStatusIDFK { get; set; }

        //Gender
        public int GenderIDFK { get; set; }

        //Patient
        [DataType(DataType.Text)]
        [Required(ErrorMessage = "Please enter name"), MaxLength(30)]
        public string FirstName { get; set; }

        [DataType(DataType.Text)]
        [Required(ErrorMessage = "Please enter Last Name"),MaxLength(30)]
        public string LastName { get; set; }

        [Required(ErrorMessage ="Please enter Id number"),MaxLength(13),MinLength(13)]
        public string ID_Number { get; set; }

        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString = "{0:dd-MM-yyyy}", ApplyFormatInEditMode = true)]
        [Required(ErrorMessage ="Please enter id date of birth")]
        public DateTime DateOfBirth { get; set; }

        [DataType(DataType.PhoneNumber)]
        [RegularExpression(@"^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$", ErrorMessage = "Not a valid Phone number")]
        [Required(ErrorMessage ="Please enter Phone number")]
        public string PhoneNumber { get; set; }

        [RegularExpression(@"^[\w -\._\+%] +@(?:[\w -] +\.)+[\w]{2,6}$", ErrorMessage = "Please enter a valid email address")]
        [DataType(DataType.EmailAddress)]
        [Required(ErrorMessage = "Enter your Email Address")]
        public string Email { get; set; }

        [Required(ErrorMessage ="Please enter address")]
        public string Line1 { get; set; }

        [Required(ErrorMessage = "Please enter address")]
        public string Line2 { get; set; }
        
        [Required(ErrorMessage ="Please enter name")]
        public string EmergencyName { get; set; }

        [Required(ErrorMessage = "Please enter last name")]
        public string EmergencyLastName { get; set; }

        [DataType(DataType.PhoneNumber)]
        [RegularExpression(@"^\(?([0-9]{3})\)?[-. ]?([0-9]{3})[-. ]?([0-9]{4})$", ErrorMessage = "Not a valid Phone number")]
        public string EmergencyPhoneNumber { get; set; }

        [Required(ErrorMessage ="Please enter relationship description")]
        public string Relationship { get; set; }

        [DataType(DataType.Date)]
        [DisplayFormat(DataFormatString = "{0:dd-MM-yyyy}", ApplyFormatInEditMode = true)]
        public DateTime EmergancyDateOfBirth { get; set; }
        

        public string MedicationList { get; set; }

        public string Message { get; set; }
    }
}