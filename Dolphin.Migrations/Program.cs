using Dolphin.Commands.Infrastructure;
using Dolphin.Migrations.Exceptions;
using Dolphin.Migrations.Models;
using Dolphin.Migrations.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Dolphin.Migrations;

public class Program
{
  private const int DefaultTimeoutSeconds = 60;

  public static async Task Main(string[] args)
  {
    try
    {
      var builder = Host.CreateDefaultBuilder(args)
          .ConfigureAppConfiguration(config =>
          {
            config.AddCommandLine(args);
          })
          .ConfigureLogging(logging =>
          {
            logging.ClearProviders();
            logging.AddConsole();
          })
          .ConfigureServices((ctx, services) =>
          {
            var config = ctx.Configuration;
            ValidateConfiguration(config);

            readonly string server = config["server"]!;
            readonly string database = config["database"]!;
            readonly string username = config["username"]!;
            readonly string password = config["password"]!;

            readonly string connectionString = $"Server={server};Database={database};User Id={username};Password={password};TrustServerCertificate=True";

            var migrationOptions = new MigrationOptions
            {
              MigrationName = config["migration-name"],
              Revert = bool.Parse(config["revert"] ?? "false")
            };

            services.AddSingleton(migrationOptions);
            services.AddDbContext<DolphinContext>(options =>
                            options.UseSqlServer(connectionString));

            services.AddHostedService<MigrationService>();
          });

      using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(DefaultTimeoutSeconds));
      try
      {
        await builder.RunConsoleAsync(cts.Token);
      }
      catch (OperationCanceledException)
      {
        Console.Error.WriteLine($"Operation timed out after {DefaultTimeoutSeconds} seconds");
        return 1;
      }
    }
    catch (ConfigurationValidationException ex)
    {
      Console.Error.WriteLine($"Configuration error: {ex.Message}");
      return 1;
    }
    catch (Exception ex)
    {
      Console.Error.WriteLine($"Unexpected error: {ex.Message}");
      return 1;
    }

    return 0;
  }

  private static void ValidateConfiguration(IConfiguration config)
  {
    var requiredSettings = new[] { "server", "database", "username", "password" };
    var missingSettings = requiredSettings.Where(setting => string.IsNullOrEmpty(config[setting])).ToList();

    if (missingSettings.Any())
    {
      throw new ConfigurationValidationException(
          $"Missing required configuration settings: {string.Join(", ", missingSettings)}");
    }
  }
}
