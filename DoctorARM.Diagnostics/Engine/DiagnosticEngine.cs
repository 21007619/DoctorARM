namespace DoctorARM.Diagnostics.Engine;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Abstractions;
using DoctorARM.Diagnostics.Checks.Database;
using DoctorARM.Diagnostics.Checks.FileSystem;
using DoctorARM.Diagnostics.Checks.Registry;
using DoctorARM.Diagnostics.Checks.Services;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Diagnostics.Runners;

/// <summary>
/// Central diagnostic engine managing registered IDiagnosticCheck instances
/// </summary>
public class DiagnosticEngine
{
    private readonly List<IDiagnosticCheck> _checks = new();

    public IReadOnlyList<IDiagnosticCheck> Checks => _checks.AsReadOnly();

    public DiagnosticEngine()
    {
        // Register default diagnostic suite
        RegisterCheck(new ArmPathExistenceCheck());
        RegisterCheck(new ArmPathPermissionsCheck());
        RegisterCheck(new ArmRegistryConfigCheck());
        RegisterCheck(new ArmServiceCheck());
        RegisterCheck(new ArmDatabaseCheck());
    }

    /// <summary>
    /// Register a new modular check
    /// </summary>
    public void RegisterCheck(IDiagnosticCheck check)
    {
        if (check != null && !_checks.Contains(check))
        {
            _checks.Add(check);
        }
    }

    /// <summary>
    /// Execute all registered diagnostic checks
    /// </summary>
    public async Task<DiagnosticResult> RunAllAsync()
    {
        var result = new DiagnosticResult { Status = DiagnosticStatus.Running, Timestamp = DateTime.Now };

        try
        {
            foreach (var check in _checks)
            {
                var checkResult = await check.RunAsync();
                result.Checks.Add(checkResult);
            }

            bool allPassed = result.Checks.All(c => c.Passed);
            result.Status = allPassed ? DiagnosticStatus.Passed : DiagnosticStatus.Failed;
        }
        catch (Exception ex)
        {
            result.Status = DiagnosticStatus.Error;
            result.Errors.Add($"Diagnostic engine error: {ex.Message}");
        }

        return result;
    }

    /// <summary>
    /// Attempt auto-fix for all failed checks that support fixing
    /// </summary>
    public async Task<List<FixResult>> FixAllAsync(DiagnosticResult currentResult)
    {
        var fixResults = new List<FixResult>();

        if (currentResult?.Checks == null)
            return fixResults;

        var failedCheckNames = currentResult.Checks
            .Where(c => !c.Passed)
            .Select(c => c.CheckName)
            .ToHashSet();

        foreach (var check in _checks)
        {
            if (check.CanFix && failedCheckNames.Contains(check.Name))
            {
                var fixRes = await check.FixAsync();
                fixResults.Add(fixRes);
            }
        }

        return fixResults;
    }
}
