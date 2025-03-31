using Dolphin.Commands.Infrastructure;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Dolphin.Migrations.Services;

internal class MigrationService : IHostedService
{
  private readonly DolphinContext _context;
  private readonly MigrationOptions _options;
  private readonly ILogger<MigrationService> _logger;

  public MigrationService(
      DolphinContext context,
      MigrationOptions options,
      ILogger<MigrationService> logger)
  {
    _context = context ?? throw new ArgumentNullException(nameof(context));
    _options = options ?? throw new ArgumentNullException(nameof(options));
    _logger = logger ?? throw new ArgumentNullException(nameof(logger));
  }

  public async Task StartAsync(CancellationToken cancellationToken)
  {
    try
    {
      await _context.Database.CanConnectAsync(cancellationToken);
      _logger.LogInformation("Successfully connected to database");

      if (_options.Revert)
      {
        await HandleRevertMigration(cancellationToken);
      }
      else
      {
        await HandleApplyMigration(cancellationToken);
      }
    }
    catch (OperationCanceledException)
    {
      _logger.LogWarning("Migration operation was cancelled");
      throw;
    }
    catch (Exception ex)
    {
      _logger.LogError(ex, "Error occurred while running migrations");
      throw;
    }
  }

  private async Task HandleRevertMigration(CancellationToken cancellationToken)
  {
    if (string.IsNullOrEmpty(_options.MigrationName))
    {
      _logger.LogInformation("Reverting last migration");

      var migrations = await _context.Database.GetAppliedMigrationsAsync(cancellationToken);

      var lastMigration = migrations.LastOrDefault();
      if (lastMigration != null)
      {
        await _context.Database.MigrateAsync(lastMigration, cancellationToken);

        _logger.LogInformation("Successfully reverted last migration");
      }
      else
      {
        _logger.LogInformation("No migrations to revert");
      }
    }
    else
    {
      _logger.LogInformation("Reverting to migration: {MigrationName}", _options.MigrationName);

      var migrations = await _context.Database.GetAppliedMigrationsAsync(cancellationToken);

      var targetMigration = migrations.FirstOrDefault(m => m == _options.MigrationName);
      if (targetMigration == null)
      {
        throw new InvalidOperationException($"Migration '{_options.MigrationName}' not found in applied migrations");
      }

      await _context.Database.MigrateAsync(targetMigration, cancellationToken);

      _logger.LogInformation("Successfully reverted to migration: {MigrationName}", _options.MigrationName);
    }
  }

  private async Task HandleApplyMigration(CancellationToken cancellationToken)
  {
    if (string.IsNullOrEmpty(_options.MigrationName))
    {
      _logger.LogInformation("Applying all pending migrations");

      await _context.Database.MigrateAsync(cancellationToken);

      _logger.LogInformation("Successfully applied all pending migrations");
    }
    else
    {
      _logger.LogInformation("Applying migration: {MigrationName}", _options.MigrationName);

      var pendingMigrations = await _context.Database.GetPendingMigrationsAsync(cancellationToken);

      var targetMigration = pendingMigrations.FirstOrDefault(m => m == _options.MigrationName);
      if (targetMigration == null)
      {
        throw new InvalidOperationException($"Migration '{_options.MigrationName}' not found in pending migrations");
      }

      var migrationsToApply = pendingMigrations.TakeWhile(m => m != targetMigration)
          .Concat(new[] { targetMigration });
      foreach (var migration in migrationsToApply)
      {
        _logger.LogInformation("Applying migration: {MigrationName}", migration);

        await _context.Database.MigrateAsync(migration, cancellationToken);
      }

      _logger.LogInformation("Successfully applied migration: {MigrationName}", _options.MigrationName);
    }
  }

  public Task StopAsync(CancellationToken cancellationToken)
  {
    return Task.CompletedTask;
  }
}