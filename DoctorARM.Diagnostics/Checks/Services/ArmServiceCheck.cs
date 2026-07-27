namespace DoctorARM.Diagnostics.Checks.Services;

using System;
using System.ServiceProcess;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Abstractions;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Diagnostics.Runners;

public class ArmServiceCheck : IDiagnosticCheck
{
    private const string ServiceName = "ARMService";

    public string Category => "Services";
    public string Name => "ARM Windows Service State";
    public bool CanFix => true;

    public Task<DiagnosticCheckResult> RunAsync()
    {
        try
        {
            using var sc = new ServiceController(ServiceName);
            var status = sc.Status;
            bool isRunning = status == ServiceControllerStatus.Running;

            return Task.FromResult(new DiagnosticCheckResult
            {
                Category = Category,
                CheckName = Name,
                Passed = isRunning,
                Message = isRunning
                    ? $"✓ Service '{ServiceName}' is RUNNING"
                    : $"⚠ Service '{ServiceName}' status is {status}"
            });
        }
        catch (InvalidOperationException)
        {
            return Task.FromResult(new DiagnosticCheckResult
            {
                Category = Category,
                CheckName = Name,
                Passed = false,
                Message = $"✗ Service '{ServiceName}' is not installed"
            });
        }
        catch (Exception ex)
        {
            return Task.FromResult(new DiagnosticCheckResult
            {
                Category = Category,
                CheckName = Name,
                Passed = false,
                Message = $"✗ Service status check error: {ex.Message}"
            });
        }
    }

    public Task<FixResult> FixAsync()
    {
        try
        {
            using var sc = new ServiceController(ServiceName);
            if (sc.Status != ServiceControllerStatus.Running)
            {
                sc.Start();
                sc.WaitForStatus(ServiceControllerStatus.Running, TimeSpan.FromSeconds(5));
                return Task.FromResult(new FixResult { Success = true, Message = $"✓ Started service '{ServiceName}'" });
            }

            return Task.FromResult(new FixResult { Success = true, Message = $"✓ Service '{ServiceName}' is already running" });
        }
        catch (Exception ex)
        {
            return Task.FromResult(new FixResult { Success = false, Message = $"✗ Could not start service: {ex.Message}" });
        }
    }
}
