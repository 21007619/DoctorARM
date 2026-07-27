namespace DoctorARM.Diagnostics.Checks.FileSystem;

using System;
using System.IO;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Abstractions;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Diagnostics.Runners;

public class ArmPathExistenceCheck : IDiagnosticCheck
{
    private const string ArmPath = @"C:\Program Files\Active Risk Manager\Server";

    public string Category => "File System";
    public string Name => "ARM Server Path Existence";
    public bool CanFix => false;

    public Task<DiagnosticCheckResult> RunAsync()
    {
        bool exists = Directory.Exists(ArmPath);
        var result = new DiagnosticCheckResult
        {
            Category = Category,
            CheckName = Name,
            Passed = exists,
            Message = exists
                ? $"✓ Server directory exists: {ArmPath}"
                : $"✗ Server directory missing: {ArmPath}"
        };

        return Task.FromResult(result);
    }

    public Task<FixResult> FixAsync()
    {
        return Task.FromResult(new FixResult
        {
            Success = false,
            Message = "Server directory creation requires installation package."
        });
    }
}
