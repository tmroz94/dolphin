using Microsoft.AspNetCore.HttpLogging;

var builder = WebApplication.CreateBuilder(args);

// Controllers
builder.Services.AddControllers();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Health Checks
builder.Services.AddHealthChecks();

// CORS
builder.Services.AddCors(options =>
{
  options.AddDefaultPolicy(policy =>
  {
    policy.WithOrigins(builder.Configuration.GetSection("AllowedOrigins").Get<string[]>() ?? [])
            .WithMethods("GET", "HEAD")
            .AllowAnyHeader()
            .AllowCredentials();
  });
});

// Request/Response Logging
builder.Services.AddHttpLogging(logging =>
{
  logging.LoggingFields = HttpLoggingFields.All;
});

// Application
var app = builder.Build();

// Development
if (app.Environment.IsDevelopment())
{
  app.UseSwagger();
  app.UseSwaggerUI();
}

// Request/Response Logging
app.UseHttpLogging();

// CORS
app.UseCors();

// Error Handling
app.UseExceptionHandler(errorApp =>
{
  errorApp.Run(async context =>
  {
    context.Response.StatusCode = 500;
    context.Response.ContentType = "application/json";
    await context.Response.WriteAsJsonAsync(new
    {
      error = "An internal server error occurred.",
      requestId = context.TraceIdentifier
    });
  });
});

// Controllers
app.MapControllers();

// Health Check
app.MapHealthChecks("/health");

// Run
app.Run();