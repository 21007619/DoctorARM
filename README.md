# DoctorARM

Diagnostic and error-fixing application for ARM (Active Risk Manager) local development. Built with .NET 10 WPF GUI.

## Overview

DoctorARM diagnoses configuration issues and detects faults in ARM application setup through an intuitive Windows desktop application.

## Current Features

✅ **Desktop GUI** — Modern WPF interface with real-time diagnostics  
✅ **ARM Server Path Check** — Verifies `C:\Program Files\Active Risk Manager\Server` exists  
✅ **Permission Validation** — Checks if `Everyone` group has full permissions (FULL_CONTROL)  
✅ **Auto-Fix** — Attempts to grant permissions automatically (requires admin)  
✅ **Real-Time Status** — Shows detailed diagnostic results with color-coded indicators

## Project Structure

```
DoctorARM/
├── DoctorARM.sln                          # Solution file
├── DoctorARM.Diagnostics/
│   ├── DoctorARM.Diagnostics.csproj
│   ├── Models/
│   │   └── DiagnosticResult.cs            # Diagnostic data models
│   └── Runners/
│       └── ArmPathDiagnosticRunner.cs     # Diagnostic logic
└── DoctorARM.Gui/
    ├── DoctorARM.Gui.csproj               # WPF application
    ├── App.xaml                           # Application startup
    ├── ViewModels/
    │   └── MainViewModel.cs               # MVVM viewmodel
    ├── Views/
    │   └── MainWindow.xaml                # Main UI
    ├── ValueConverters.cs                 # XAML value converters
    └── Resources/                         # App resources
```

## Requirements

- **Windows OS** (for NTFS permission checks)
- **.NET 10 SDK** or higher
- **Visual Studio 2022** or VS Code with C# Dev Kit (recommended)
- **Admin privileges** (for fixing permissions)

## Getting Started

### Build

```bash
dotnet build DoctorARM.sln
```

### Run

```bash
dotnet run --project DoctorARM.Gui
```

Or open the solution in Visual Studio and press **F5**.

## Usage

1. **Launch the application**
2. Click **"Run Diagnostics"** to scan for issues
3. View results for each diagnostic check:
   - ✓ Green = Check passed
   - ✗ Red = Check failed
4. Click **"Fix Issues"** to automatically fix permission problems
5. Diagnostics re-run automatically to verify fixes

## Diagnostic Checks

### ARM Server Path & Permissions
- **Check 1**: Verifies path exists: `C:\Program Files\Active Risk Manager\Server`
- **Check 2**: Validates `Everyone` group has **FULL CONTROL** permissions
- **Auto-fix**: Attempts to grant full permissions using `icacls` command

### Status Indicators
- **✓ Passed** — All checks successful (green background)
- **✗ Failed** — One or more checks failed (red background)
- **⏳ Running** — Diagnostics in progress (yellow banner)

## UI Design

The application features a professional diagnostic interface:

- **Header** — Branding and app title
- **Status Section** — Overall result, timestamp, and action buttons
- **Diagnostic Checks** — Scrollable list of checks with color-coded results
- **Errors Section** — Displays detailed error messages if needed
- **Loading Indicator** — Shows progress while running diagnostics
- **Footer** — Status bar

## Development

### Project Architecture

**MVVM Pattern:**
- `Views/` — XAML UI components
- `ViewModels/` — Logic and data binding
- `Diagnostics/` — Core diagnostic runners (business logic)

**Async/Await:**
- All operations are async to keep UI responsive
- Long-running diagnostics don't freeze the interface

### Adding New Diagnostics

1. Create a new diagnostic runner in `DoctorARM.Diagnostics/Runners/`
2. Implement async methods following `ArmPathDiagnosticRunner` pattern
3. Return `DiagnosticResult` with check details
4. Integrate into `MainViewModel`

Example:
```csharp
public class NewDiagnosticRunner
{
    public async Task<DiagnosticResult> RunAsync()
    {
        var result = new DiagnosticResult { Status = DiagnosticStatus.Running };
        // Implement diagnostic logic
        result.Status = DiagnosticStatus.Passed; // or Failed
        return result;
    }
}
```

## Future Enhancements

- [ ] Database storage for diagnostic history
- [ ] Export diagnostics to PDF/CSV
- [ ] Scheduled automatic diagnostics
- [ ] Network diagnostics
- [ ] Configuration validation
- [ ] Multi-language support
- [ ] Plugin system for custom diagnostics

## License

MIT

## Contributing

Contributions welcome! Please ensure code follows the existing patterns and includes proper documentation.

