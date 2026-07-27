namespace DoctorARM.Diagnostics.Checks.FileSystem;

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Security.AccessControl;
using System.Security.Principal;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Abstractions;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Diagnostics.Runners;

public class ArmPathPermissionsCheck : IDiagnosticCheck
{
    private const string ArmPath = @"C:\Program Files\Active Risk Manager\Server";

    public string Category => "File System";
    public string Name => "Everyone Group NTFS Permissions";
    public bool CanFix => true;

    public async Task<DiagnosticCheckResult> RunAsync()
    {
        return await Task.Run(() =>
        {
            try
            {
                if (!Directory.Exists(ArmPath))
                {
                    return new DiagnosticCheckResult
                    {
                        Category = Category,
                        CheckName = Name,
                        Passed = false,
                        Message = "✗ Path does not exist"
                    };
                }

                var directoryInfo = new DirectoryInfo(ArmPath);
                var security = directoryInfo.GetAccessControl(AccessControlSections.Access);
                var rules = security.GetAccessRules(true, true, typeof(SecurityIdentifier));

                var worldSid = new SecurityIdentifier(WellKnownSidType.WorldSid, null);

                bool hasFullControl = false;
                bool hasModify = false;
                var permissionsList = new List<string>();

                foreach (FileSystemAccessRule rule in rules)
                {
                    if (rule.IdentityReference.Equals(worldSid) && rule.AccessControlType == AccessControlType.Allow)
                    {
                        var rights = rule.FileSystemRights;

                        if ((rights & FileSystemRights.FullControl) == FileSystemRights.FullControl)
                        {
                            hasFullControl = true;
                            if (!permissionsList.Contains("FULL_CONTROL"))
                                permissionsList.Add("FULL_CONTROL");
                        }
                        else if ((rights & FileSystemRights.Modify) == FileSystemRights.Modify)
                        {
                            hasModify = true;
                            if (!permissionsList.Contains("MODIFY"))
                                permissionsList.Add("MODIFY");
                        }
                    }
                }

                string message = hasFullControl
                    ? "✓ Everyone group has FULL CONTROL"
                    : hasModify
                        ? "⚠ Everyone group has MODIFY, but lacks FULL CONTROL"
                        : "✗ Everyone group lacks required permissions";

                return new DiagnosticCheckResult
                {
                    Category = Category,
                    CheckName = Name,
                    Passed = hasFullControl,
                    Message = message,
                    Permissions = permissionsList
                };
            }
            catch (Exception ex)
            {
                return new DiagnosticCheckResult
                {
                    Category = Category,
                    CheckName = Name,
                    Passed = false,
                    Message = $"✗ Permission inspection failed: {ex.Message}"
                };
            }
        });
    }

    public async Task<FixResult> FixAsync()
    {
        return await Task.Run(() =>
        {
            try
            {
                if (!Directory.Exists(ArmPath))
                {
                    return new FixResult { Success = false, Message = "✗ Path does not exist." };
                }

                bool isAdmin = ArmPathDiagnosticRunner.IsCurrentProcessElevated();

                var startInfo = new ProcessStartInfo
                {
                    FileName = "icacls.exe",
                    Arguments = $@"""{ArmPath}"" /grant ""*S-1-1-0:(OI)(CI)(F)"" /T",
                    UseShellExecute = true,
                    CreateNoWindow = !isAdmin
                };

                if (!isAdmin)
                {
                    startInfo.Verb = "runas";
                }

                using var process = Process.Start(startInfo);
                if (process == null) return new FixResult { Success = false, Message = "✗ Could not start elevation process." };

                process.WaitForExit();

                return process.ExitCode == 0
                    ? new FixResult { Success = true, Message = "✓ Granted FULL CONTROL to Everyone group" }
                    : new FixResult { Success = false, Message = $"✗ Fix failed with exit code {process.ExitCode}" };
            }
            catch (System.ComponentModel.Win32Exception ex) when (ex.NativeErrorCode == 1223)
            {
                return new FixResult { Success = false, Message = "✗ Fix cancelled by user (UAC declined)." };
            }
            catch (Exception ex)
            {
                return new FixResult { Success = false, Message = $"✗ Fix failed: {ex.Message}" };
            }
        });
    }
}
