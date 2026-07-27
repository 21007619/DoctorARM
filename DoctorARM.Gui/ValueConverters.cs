using System;
using System.Globalization;
using System.Windows;
using System.Windows.Data;
using System.Windows.Media;
using DoctorARM.Diagnostics.Models;

namespace DoctorARM.Gui;

/// <summary>
/// Collection of value converters for XAML bindings
/// </summary>
public class ValueConverters : ResourceDictionary
{
    public ValueConverters()
    {
        this["BoolToVisibilityConverter"] = new BoolToVisibilityConverter();
        this["InverseBooleanConverter"] = new InverseBooleanConverter();
        this["CountToVisibilityConverter"] = new CountToVisibilityConverter();
        this["PassedToIconConverter"] = new PassedToIconConverter();
        this["StatusToBrushConverter"] = new StatusToBrushConverter();
    }
}

/// <summary>
/// Converts boolean to Visibility
/// </summary>
public class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        return value is true ? Visibility.Visible : Visibility.Collapsed;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        return value is Visibility.Visible;
    }
}

/// <summary>
/// Converts boolean to inverted boolean
/// </summary>
public class InverseBooleanConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        return value is bool b ? !b : true;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        return value is bool b ? !b : true;
    }
}

/// <summary>
/// Converts count to Visibility (shows only if count > 0)
/// </summary>
public class CountToVisibilityConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        if (value is int count)
        {
            return count > 0 ? Visibility.Visible : Visibility.Collapsed;
        }

        return Visibility.Collapsed;
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// Converts Passed boolean to check/cross icon
/// </summary>
public class PassedToIconConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        return value is true ? "✓" : "✗";
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        throw new NotImplementedException();
    }
}

/// <summary>
/// Converts DiagnosticStatus or boolean to Brush
/// </summary>
public class StatusToBrushConverter : IValueConverter
{
    public object Convert(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        if (value is DiagnosticStatus status)
        {
            return status switch
            {
                DiagnosticStatus.Passed => new SolidColorBrush(Color.FromRgb(0x28, 0xA7, 0x45)),
                DiagnosticStatus.Failed => new SolidColorBrush(Color.FromRgb(0xDC, 0x35, 0x45)),
                DiagnosticStatus.Running => new SolidColorBrush(Color.FromRgb(0xD9, 0x9B, 0x00)),
                DiagnosticStatus.Error => new SolidColorBrush(Color.FromRgb(0xDC, 0x35, 0x45)),
                _ => new SolidColorBrush(Color.FromRgb(0x6C, 0x75, 0x7D))
            };
        }

        if (value is bool passed)
        {
            return passed
                ? new SolidColorBrush(Color.FromRgb(0x28, 0xA7, 0x45))
                : new SolidColorBrush(Color.FromRgb(0xDC, 0x35, 0x45));
        }

        return new SolidColorBrush(Color.FromRgb(0x6C, 0x75, 0x7D));
    }

    public object ConvertBack(object? value, Type targetType, object? parameter, CultureInfo? culture)
    {
        throw new NotImplementedException();
    }
}
