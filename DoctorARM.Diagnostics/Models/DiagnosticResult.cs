namespace DoctorARM.Diagnostics.Models;

using System;
using System.Collections.Generic;

/// <summary>
/// Result of an automated fix attempt
/// </summary>
public class FixResult
{
    public bool Success { get; set; }
    public string Message { get; set; } = string.Empty;
}

/// <summary>
/// Represents a single diagnostic check result
/// </summary>
public class DiagnosticCheckResult
{
    public string Category { get; set; } = "General";
    public string CheckName { get; set; } = string.Empty;
    public bool Passed { get; set; }
    public string Message { get; set; } = string.Empty;
    public List<string> Permissions { get; set; } = new();
    public string Details { get; set; } = string.Empty;
}

/// <summary>
/// Overall diagnostic result status
/// </summary>
public enum DiagnosticStatus
{
    Unknown,
    Running,
    Passed,
    Failed,
    Error
}

/// <summary>
/// Complete diagnostic result
/// </summary>
public class DiagnosticResult
{
    public DiagnosticStatus Status { get; set; } = DiagnosticStatus.Unknown;
    public List<DiagnosticCheckResult> Checks { get; set; } = new();
    public List<string> Errors { get; set; } = new();
    public DateTime Timestamp { get; set; } = DateTime.Now;

    public bool IsSuccessful => Status == DiagnosticStatus.Passed && Errors.Count == 0;
}
