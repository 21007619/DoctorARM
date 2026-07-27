namespace DoctorARM.Tests;

using System;
using System.Threading.Tasks;
using DoctorARM.Diagnostics.Models;
using DoctorARM.Gui.ViewModels;
using Xunit;

public class MainViewModelTests
{
    [Fact]
    public void InitialState_IsCorrect()
    {
        // Arrange & Act
        var vm = new MainViewModel();

        // Assert
        Assert.False(vm.IsRunning);
        Assert.Equal("Ready", vm.StatusMessage);
        Assert.Equal(DiagnosticStatus.Unknown, vm.CurrentResult.Status);
        Assert.Empty(vm.CheckResults);
    }

    [Fact]
    public void ComputerName_DetectsLocalMachineName()
    {
        // Arrange & Act
        var vm = new MainViewModel();

        // Assert
        Assert.False(string.IsNullOrWhiteSpace(vm.ComputerName));
        Assert.Equal(Environment.MachineName, vm.ComputerName);
    }

    [Fact]
    public void FixPermissionsCommand_CanExecute_OnlyWhenFailed()
    {
        // Arrange
        var vm = new MainViewModel();

        // Case 1: Status Unknown -> CanExecute should be false
        Assert.False(vm.FixPermissionsCommand.CanExecute(null));

        // Case 2: Status Passed -> CanExecute should be false
        vm.CurrentResult = new DiagnosticResult { Status = DiagnosticStatus.Passed };
        Assert.False(vm.FixPermissionsCommand.CanExecute(null));

        // Case 3: Status Failed -> CanExecute should be true
        vm.CurrentResult = new DiagnosticResult { Status = DiagnosticStatus.Failed };
        Assert.True(vm.FixPermissionsCommand.CanExecute(null));

        // Case 4: IsRunning true -> CanExecute should be false
        vm.IsRunning = true;
        Assert.False(vm.FixPermissionsCommand.CanExecute(null));
    }

    [Fact]
    public async Task RunDiagnosticsAsync_UpdatesStateAndResults()
    {
        // Arrange
        var vm = new MainViewModel();

        // Act
        await vm.RunDiagnosticsAsync();

        // Assert
        Assert.False(vm.IsRunning);
        Assert.NotEqual(DiagnosticStatus.Unknown, vm.CurrentResult.Status);
        Assert.NotEmpty(vm.CheckResults);
    }
}
