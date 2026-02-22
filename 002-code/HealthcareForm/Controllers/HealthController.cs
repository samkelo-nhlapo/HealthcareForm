using Microsoft.AspNetCore.Mvc;
using System.Data.SqlClient;

namespace HealthcareForm.Controllers
{
    [ApiController]
    [Route("api/health")]
    public class HealthController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<HealthController> _logger;
        private readonly IWebHostEnvironment _environment;

        public HealthController(
            IConfiguration configuration,
            ILogger<HealthController> logger,
            IWebHostEnvironment environment)
        {
            _configuration = configuration;
            _logger = logger;
            _environment = environment;
        }

        [HttpGet("live")]
        public IActionResult Live()
        {
            return Ok(new
            {
                status = "ok",
                utc = DateTime.UtcNow
            });
        }

        [HttpGet]
        [HttpGet("db")]
        public async Task<IActionResult> Db()
        {
            var connectionString = _configuration.GetConnectionString("HealthcareEntity");
            if (string.IsNullOrWhiteSpace(connectionString))
            {
                return StatusCode(StatusCodes.Status500InternalServerError, new
                {
                    status = "error",
                    error = "Connection string 'HealthcareEntity' is missing."
                });
            }

            try
            {
                await using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                await using var command = new SqlCommand("SELECT DB_NAME()", connection);
                _ = Convert.ToString(await command.ExecuteScalarAsync());

                return Ok(new
                {
                    status = "ok",
                    utc = DateTime.UtcNow
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database health check failed.");
                if (_environment.IsDevelopment())
                {
                    return StatusCode(StatusCodes.Status503ServiceUnavailable, new
                    {
                        status = "error",
                        error = "Database connection failed.",
                        details = ex.Message
                    });
                }

                return StatusCode(StatusCodes.Status503ServiceUnavailable, new
                {
                    status = "error",
                    error = "Database connection failed."
                });
            }
        }
    }
}
