namespace DoctorARM.Diagnostics.Checks.Registry;

using System;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Abstractions;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Diagnostics.Runners;
using Microsoft.Win32;

public class ArmRegistryConfigCheck : IDiagnosticCheck
{
    private const string RegistryKeyPath = @"SOFTWARE\Active Risk Manager";

    public string Category => "Registry";
    public string Name => "ARM HKLM Registry Configuration";
    public bool CanFix => true;

    public Task<DiagnosticCheckResult> RunAsync()
    {
        try
        {
            using var key = Microsoft.Win32.Registry.LocalMachine.OpenSubKey(RegistryKeyPath);
            bool exists = key != null;

            return Task.FromResult(new DiagnosticCheckResult
            {
                Category = Category,
                CheckName = Name,
                Passed = exists,
                Message = exists
                    ? $"✓ Registry key found: HKLM\\{RegistryKeyPath}"
                    : $"✗ Missing registry key: HKLM\\{RegistryKeyPath}"
            });
        }
        catch (Exception ex)
        {
            return Task.FromResult(new DiagnosticCheckResult
            {
                Category = Category,
                CheckName = Name,
                Passed = false,
                Message = $"✗ Registry check failed: {ex.Message}"
            });
        }
    }

    public Task<FixResult> FixAsync()
    {
        try
        {
            using var key = Microsoft.Win32.Registry.LocalMachine.CreateSubKey(RegistryKeyPath);
            if (key != null)
            {
                key.SetValue("Installed", 1, RegistryValueKind.DWord);
                return Task.FromResult(new FixResult
                {
                    Success = true,
                    Message = $"✓ Created registry key: HKLM\\{RegistryKeyPath}"
                });
            }

            return Task.FromResult(new FixResult { Success = false, Message = "✗ Failed to create registry key." });
        }
        catch (Exception ex)
        {
            return Task.FromResult(new FixResult { Success = false, Message = $"✗ Registry fix error: {ex.Message}" });
        }
    }
}
