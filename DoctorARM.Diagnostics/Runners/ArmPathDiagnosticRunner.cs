

namespace DoctorARM.Diagnostics.Runners;

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Models;

/// <summary>
/// Legacy diagnostic runner for ARM Server path and permissions
/// </summary>
public class ArmPathDiagnosticRunner
{
    private const string ArmPath = @"C:\Program Files\Active Risk Manager\Server";
    private const string RequiredGroup = "Everyone";

    public async Task<DiagnosticResult> RunAsync()
    {
        return await Task.Run(() =>
        {
            var result = new DiagnosticResult { Status = DiagnosticStatus.Running, Timestamp = DateTime.Now };

            try
            {
                var pathExists = Directory.Exists(ArmPath);
                result.Checks.Add(new DiagnosticCheckResult
                {
                    Category = "File System",
                    CheckName = "Path Existence",
                    Passed = pathExists,
                    Message = pathExists
                        ? $"✓ Path exists: {ArmPath}"
                        : $"✗ Path does not exist: {ArmPath}"
                });

                if (!pathExists)
                {
                    result.Status = DiagnosticStatus.Failed;
                    return result;
                }

                var permissionsCheck = CheckPermissions();
                result.Checks.Add(new DiagnosticCheckResult
                {
                    Category = "File System",
                    CheckName = "Everyone Group Permissions",
                    Passed = permissionsCheck.HasFullControl,
                    Message = permissionsCheck.Message,
                    Permissions = permissionsCheck.Permissions,
                    Details = permissionsCheck.RawAcl
                });

                var allPassed = result.Checks.All(c => c.Passed);
                result.Status = allPassed ? DiagnosticStatus.Passed : DiagnosticStatus.Failed;
            }
            catch (Exception ex)
            {
                result.Status = DiagnosticStatus.Error;
                result.Errors.Add(ex.Message);
            }

            return result;
        });
    }

    private PermissionsCheckResult CheckPermissions()
    {
        try
        {
            if (!Directory.Exists(ArmPath))
            {
                return new PermissionsCheckResult
                {
                    HasFullControl = false,
                    Message = "✗ Path does not exist",
                    Permissions = new List<string>()
                };
            }

            var directoryInfo = new DirectoryInfo(ArmPath);
            var security = directoryInfo.GetAccessControl(AccessControlSections.Access);
            var rules = security.GetAccessRules(true, true, typeof(SecurityIdentifier));

            var worldSid = new SecurityIdentifier(WellKnownSidType.WorldSid, null);

            bool hasFullControl = false;
            var permissionsList = new List<string>();

            foreach (FileSystemAccessRule rule in rules)
            {
                if (rule.IdentityReference.Equals(worldSid) && rule.AccessControlType == AccessControlType.Allow)
                {
                    if ((rule.FileSystemRights & FileSystemRights.FullControl) == FileSystemRights.FullControl)
                    {
                        hasFullControl = true;
                        permissionsList.Add("FULL_CONTROL");
                    }
                }
            }

            return new PermissionsCheckResult
            {
                HasFullControl = hasFullControl,
                Message = hasFullControl ? "✓ Everyone has FULL CONTROL" : "✗ Everyone lacks FULL CONTROL",
                Permissions = permissionsList
            };
        }
        catch (Exception ex)
        {
            return new PermissionsCheckResult { HasFullControl = false, Message = ex.Message };
        }
    }

    public async Task<FixResult> FixPermissionsAsync()
    {
        return await Task.Run(() =>
        {
            try
            {
                if (!Directory.Exists(ArmPath)) return new FixResult { Success = false, Message = "Path does not exist" };

                bool isAdmin = IsCurrentProcessElevated();
                var startInfo = new ProcessStartInfo
                {
                    FileName = "icacls.exe",
                    Arguments = $@"""{ArmPath}"" /grant ""*S-1-1-0:(OI)(CI)(F)"" /T",
                    UseShellExecute = true,
                    CreateNoWindow = !isAdmin
                };

                if (!isAdmin) startInfo.Verb = "runas";

                using var process = Process.Start(startInfo);
                if (process == null) return new FixResult { Success = false, Message = "Could not start elevation process" };
                process.WaitForExit();

                return new FixResult { Success = process.ExitCode == 0, Message = process.ExitCode == 0 ? "Permissions fixed" : "Fix failed" };
            }
            catch (Exception ex)
            {
                return new FixResult { Success = false, Message = ex.Message };
            }
        });
    }

    public static bool IsCurrentProcessElevated()
    {
        try
        {
            using var identity = WindowsIdentity.GetCurrent();
            var principal = new WindowsPrincipal(identity);
            return principal.IsInRole(WindowsBuiltInRole.Administrator);
        }
        catch
        {
            return false;
        }
    }

    private class PermissionsCheckResult
    {
        public bool HasFullControl { get; set; }
        public string Message { get; set; } = string.Empty;
        public List<string> Permissions { get; set; } = new();
        public string RawAcl { get; set; } = string.Empty;
    }
}
