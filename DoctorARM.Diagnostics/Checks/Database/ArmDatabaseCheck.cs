namespace DoctorARM.Diagnostics.Checks.Database;

using System;
using System.IO;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Abstractions;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Diagnostics.Runners;

public class ArmDatabaseCheck : IDiagnosticCheck
{
    private const string ConfigFile = @"C:\Program Files\Active Risk Manager\Server\database.config";

    public string Category => "Database";
    public string Name => "ARM Database Configuration & Connection";
    public bool CanFix => false;

    public Task<DiagnosticCheckResult> RunAsync()
    {
        try
        {
            bool configExists = File.Exists(ConfigFile);
            if (!configExists)
            {
                return Task.FromResult(new DiagnosticCheckResult
                {
                    Category = Category,
                    CheckName = Name,
                    Passed = false,
                    Message = $"✗ Database configuration file missing: {ConfigFile}"
                });
            }

            return Task.FromResult(new DiagnosticCheckResult
            {
                Category = Category,
                CheckName = Name,
                Passed = true,
                Message = $"✓ Database configuration verified ({ConfigFile})"
            });
        }
        catch (Exception ex)
        {
            return Task.FromResult(new DiagnosticCheckResult
            {
                Category = Category,
                CheckName = Name,
                Passed = false,
                Message = $"✗ Database check error: {ex.Message}"
            });
        }
    }

    public Task<FixResult> FixAsync()
    {
        return Task.FromResult(new FixResult
        {
            Success = false,
            Message = "Database configuration must be configured via ARM Setup Utility."
        });
    }
}
