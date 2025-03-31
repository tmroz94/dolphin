namespace Dolphin.Migrations.Exceptions;

internal class ConfigurationValidationException : Exception
{
  public ConfigurationValidationException(string message) : base(message)
  {
  }
}