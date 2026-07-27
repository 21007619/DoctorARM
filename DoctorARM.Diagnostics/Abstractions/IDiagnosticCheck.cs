namespace DoctorARM.Diagnostics.Abstractions;

using System.Threading.Tasks;
using DoctorARM.Diagnostics.Models;

/// <summary>
/// Abstraction for a single modular diagnostic check
/// </summary>
public interface IDiagnosticCheck
{
    /// <summary>
    /// Category of the diagnostic check (e.g. "File System", "Registry", "Services", "Database")
    /// </summary>
    string Category { get; }

    /// <summary>
    /// Descriptive name of the check
    /// </summary>
    string Name { get; }

    /// <summary>
    /// Indicates whether this check supports automated fixing
    /// </summary>
    bool CanFix { get; }

    /// <summary>
    /// Run the diagnostic check asynchronously
    /// </summary>
    Task<DiagnosticCheckResult> RunAsync();

    /// <summary>
    /// Attempt to fix any issues identified by this check
    /// </summary>
    Task<FixResult> FixAsync();
}
