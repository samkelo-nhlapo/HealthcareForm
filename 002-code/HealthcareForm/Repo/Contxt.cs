using Microsoft.Extensions.Configuration;

namespace HealthcareForm.Repo
{
    public class Contxt
    {
        private readonly IConfiguration _configuration;

        public Contxt(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string GetConnectionString()
        {
            return _configuration.GetConnectionString("HealthcareEntity");
        }
    }
}
