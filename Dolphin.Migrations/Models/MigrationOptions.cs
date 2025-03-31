namespace Dolphin.Migrations.Models;

internal class MigrationOptions
{
  public string? MigrationName { get; set; }
  public bool Revert { get; set; }
}