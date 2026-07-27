namespace DoctorARM.Tests;

using System.Threading.Tasks;
using DoctorARM.Diagnostics.Engine;
using DoctorARM.Diagnostics.Models;
using Xunit;

public class DiagnosticEngineTests
{
    [Fact]
    public void DefaultEngine_RegistersMultipleCategories()
    {
        // Arrange & Act
        var engine = new DiagnosticEngine();

        // Assert
        Assert.NotEmpty(engine.Checks);
        Assert.Contains(engine.Checks, c => c.Category == "File System");
        Assert.Contains(engine.Checks, c => c.Category == "Registry");
        Assert.Contains(engine.Checks, c => c.Category == "Services");
        Assert.Contains(engine.Checks, c => c.Category == "Database");
    }

    [Fact]
    public async Task RunAllAsync_ExecutesAllRegisteredChecks()
    {
        // Arrange
        var engine = new DiagnosticEngine();

        // Act
        var result = await engine.RunAllAsync();

        // Assert
        Assert.NotNull(result);
        Assert.NotEqual(DiagnosticStatus.Unknown, result.Status);
        Assert.Equal(engine.Checks.Count, result.Checks.Count);
    }
}
