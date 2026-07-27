namespace DoctorARM.Tests;

using System.Threading.Tasks;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Diagnostics.Runners;
using Xunit;

public class ArmPathDiagnosticRunnerTests
{
    [Fact]
    public async Task RunAsync_ReturnsValidDiagnosticResult()
    {
        // Arrange
        var runner = new ArmPathDiagnosticRunner();

        // Act
        var result = await runner.RunAsync();

        // Assert
        Assert.NotNull(result);
        Assert.NotEqual(DiagnosticStatus.Unknown, result.Status);
        Assert.NotEqual(DiagnosticStatus.Running, result.Status);
        Assert.NotEmpty(result.Checks);
        Assert.Equal("Path Existence", result.Checks[0].CheckName);
    }
}
