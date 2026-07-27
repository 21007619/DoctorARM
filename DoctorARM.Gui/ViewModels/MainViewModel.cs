using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Input;
using DoctorARM.Diagnostics.Engine;
using DoctorARM.Diagnostics.Models;

namespace DoctorARM.Gui.ViewModels;

/// <summary>
/// ViewModel for the main diagnostic window managing DiagnosticEngine
/// </summary>
public class MainViewModel : INotifyPropertyChanged
{
    private readonly DiagnosticEngine _engine;
    private DiagnosticResult _currentResult;
    private bool _isRunning;
    private string _statusMessage = "Ready";

    public ObservableCollection<DiagnosticCheckResult> CheckResults { get; } = new();

    /// <summary>
    /// Gets the detected local computer name
    /// </summary>
    public string ComputerName => Environment.MachineName;

    public DiagnosticResult CurrentResult
    {
        get => _currentResult;
        set
        {
            if (_currentResult != value)
            {
                _currentResult = value;
                OnPropertyChanged();
                UpdateCheckResults();
                CommandManager.InvalidateRequerySuggested();
            }
        }
    }

    public bool IsRunning
    {
        get => _isRunning;
        set
        {
            if (_isRunning != value)
            {
                _isRunning = value;
                OnPropertyChanged();
                CommandManager.InvalidateRequerySuggested();
            }
        }
    }

    public string StatusMessage
    {
        get => _statusMessage;
        set
        {
            if (_statusMessage != value)
            {
                _statusMessage = value;
                OnPropertyChanged();
            }
        }
    }

    public ICommand RunDiagnosticsCommand { get; }
    public ICommand FixPermissionsCommand { get; }

    /// <summary>
    /// Parameterless constructor for WPF XAML
    /// </summary>
    public MainViewModel() : this(null)
    {
    }

    /// <summary>
    /// Overload for custom DiagnosticEngine injection
    /// </summary>
    public MainViewModel(DiagnosticEngine? engine)
    {
        _engine = engine ?? new DiagnosticEngine();
        _currentResult = new DiagnosticResult { Status = DiagnosticStatus.Unknown };

        RunDiagnosticsCommand = new AsyncRelayCommand(
            async () => await RunDiagnosticsAsync(),
            () => !IsRunning
        );

        FixPermissionsCommand = new AsyncRelayCommand(
            async () => await FixPermissionsAsync(),
            () => !IsRunning && CurrentResult?.Status == DiagnosticStatus.Failed
        );
    }

    public async Task RunDiagnosticsAsync()
    {
        IsRunning = true;
        StatusMessage = "Running full diagnostic suite...";

        DispatchToUI(() => CheckResults.Clear());

        try
        {
            var result = await _engine.RunAllAsync();
            DispatchToUI(() => CurrentResult = result);

            StatusMessage = result.Status switch
            {
                DiagnosticStatus.Passed => $"All checks passed at {result.Timestamp:HH:mm:ss}",
                DiagnosticStatus.Failed => $"Diagnostics failed at {result.Timestamp:HH:mm:ss}",
                DiagnosticStatus.Error => "An error occurred during diagnostics execution",
                _ => "Ready"
            };
        }
        catch (Exception ex)
        {
            StatusMessage = $"Diagnostic error: {ex.Message}";
        }
        finally
        {
            IsRunning = false;
        }
    }

    public async Task FixPermissionsAsync()
    {
        if (CurrentResult?.Status != DiagnosticStatus.Failed)
            return;

        IsRunning = true;
        StatusMessage = "Applying automated fixes...";

        try
        {
            var fixResults = await _engine.FixAllAsync(CurrentResult);
            int successCount = fixResults.Count(f => f.Success);

            StatusMessage = $"Applied {successCount} fix(es). Verifying...";

            var refreshed = await _engine.RunAllAsync();
            DispatchToUI(() => CurrentResult = refreshed);

            StatusMessage = refreshed.Status == DiagnosticStatus.Passed
                ? $"Fixes applied & verified at {refreshed.Timestamp:HH:mm:ss}"
                : $"Re-run completed. Some checks still require attention.";
        }
        catch (Exception ex)
        {
            StatusMessage = $"Failed to apply fixes: {ex.Message}";
        }
        finally
        {
            IsRunning = false;
        }
    }

    private void UpdateCheckResults()
    {
        DispatchToUI(() =>
        {
            CheckResults.Clear();
            if (CurrentResult?.Checks != null)
            {
                foreach (var check in CurrentResult.Checks)
                {
                    CheckResults.Add(check);
                }
            }
        });
    }

    private static void DispatchToUI(Action action)
    {
        if (Application.Current?.Dispatcher != null && !Application.Current.Dispatcher.CheckAccess())
        {
            Application.Current.Dispatcher.Invoke(action);
        }
        else
        {
            action();
        }
    }

    public event PropertyChangedEventHandler? PropertyChanged;

    protected void OnPropertyChanged([CallerMemberName] string? name = null)
    {
        PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(name));
    }
}

/// <summary>
/// Async Relay Command implementation with proper CanExecute handling and UI feedback
/// </summary>
public class AsyncRelayCommand : ICommand
{
    private readonly Func<Task> _executeAsync;
    private readonly Func<bool>? _canExecute;

    public AsyncRelayCommand(Func<Task> executeAsync, Func<bool>? canExecute = null)
    {
        _executeAsync = executeAsync ?? throw new ArgumentNullException(nameof(executeAsync));
        _canExecute = canExecute;
    }

    public event EventHandler? CanExecuteChanged
    {
        add { CommandManager.RequerySuggested += value; }
        remove { CommandManager.RequerySuggested -= value; }
    }

    public bool CanExecute(object? parameter) => _canExecute?.Invoke() ?? true;

    public async void Execute(object? parameter)
    {
        try
        {
            await _executeAsync();
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine($"Command execution error: {ex}");
            if (Application.Current != null)
            {
                MessageBox.Show($"Error: {ex.Message}", "Execution Error",
                    MessageBoxButton.OK,
                    MessageBoxImage.Error);
            }
        }
    }
}
