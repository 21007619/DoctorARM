# Import the IIS Module
Import-Module WebAdministration
Import-Module IISAdministration

######CREATE ARMFramework WEBSITE#####
# Define website parameters
$siteName = "ARMFramework"
$physicalPath = "C:\inetpub\wwwroot"
$appPool = "ARMAppPool"
$bindingIP = "*"
$port = "59400"
$hostHeader = ""

# Check if the website already exists
if (!(Test-Path "IIS:\Sites\$siteName")) {
    Write-Host "Website '$siteName' does not exist. Creating..."
    
    # Create the physical directory if it doesn't exist
    if (!(Test-Path $physicalPath)) {
        New-Item -ItemType Directory -Path $physicalPath -Force
        Write-Host "Created physical directory: $physicalPath"
    }
    
    # Create application pool if it doesn't exist
    if (!(Test-Path "IIS:\AppPools\$appPool")) {
        New-WebAppPool -Name $appPool
        Set-ItemProperty "IIS:\AppPools\$appPool" -Name managedRuntimeVersion -Value "v4.0"
        Set-ItemProperty "IIS:\AppPools\$appPool" -Name managedPipelineMode -Value "Integrated"
        Write-Host "Created application pool: $appPool"
    }
    
    # Create the website
    New-Website -Name $siteName `
                -PhysicalPath $physicalPath `
                -ApplicationPool $appPool `
                -IPAddress $bindingIP `
                -Port $port `
                -HostHeader $hostHeader `
                -Force
    
    Write-Host "Website '$siteName' has been created successfully!"
    
    # Start the website
    Start-Website -Name $siteName
    Write-Host "Website '$siteName' has been started."
} else {
    Write-Host "Website '$siteName' already exists."
}

# Display website status
Get-Website -Name $siteName | Select-Object Name, State, PhysicalPath, @{n='Bindings';e={$_.Bindings.Collection}}


##### CREATE ARMFramework ARM APP######
$siteName = "ARMFramework"
$appName = "ARM"
$physicalPath = "c:\projects\arm\arm\user interface\arm"
$appPool = "ARMPool"

# Check if the application already exists
$appPath = "IIS:\Sites\$siteName\$appName"
if (!(Test-Path $appPath)) {
    Write-Host "Application '$appName' does not exist. Creating..."
    
    # Create the physical directory if it doesn't exist
    if (!(Test-Path $physicalPath)) {
        New-Item -ItemType Directory -Path $physicalPath -Force
        Write-Host "Created physical directory: $physicalPath"
    }
    
    # Create application pool if it doesn't exist
    if (!(Test-Path "IIS:\AppPools\$appPool")) {
        New-WebAppPool -Name $appPool
        Set-ItemProperty "IIS:\AppPools\$appPool" -Name managedRuntimeVersion -Value "v4.0"
        Set-ItemProperty "IIS:\AppPools\$appPool" -Name managedPipelineMode -Value "Integrated"

         # Set to NetworkService
        Set-ItemProperty "IIS:\AppPools\$appPool" -Name "processModel.identityType" -Value "NetworkService"
        Write-Host "Created application pool: $appPool"
    }
    
    # Create the application
    New-WebApplication -Name $appName `
                      -Site $siteName `
                      -PhysicalPath $physicalPath `
                      -ApplicationPool $appPool `
                      -Force
    
    Write-Host "Application '$appName' has been created successfully!"
    
    # Configure application settings
    Set-ItemProperty $appPath -Name enabledProtocols -Value "http"
    Write-Host "Application protocols configured."
    
} else {
    Write-Host "Application '$appName' already exists."
}


Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name enabled -Value false -PSPath "IIS:\Sites\$siteName" -force
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication" -Name enabled -Value true -PSPath "IIS:\Sites\$siteName"

Clear-WebConfiguration -Filter "/system.web/authorization" -PSPath $appPath
  $config = Get-WebConfiguration -Filter "/system.web/authorization" -PSPath $appPath
    if ($null -eq $config) {
        Add-WebConfiguration -Filter "/system.web" -PSPath $appPath -Value @{name='authorization'}
    }
    
    # Add allow anonymous rule
    Add-WebConfiguration -Filter "/system.web/authorization" -PSPath $appPath -Value @{
        users='?'  # Question mark represents anonymous users
        roles=''
        verbs=''
        access='Allow'
    }

# Display application status
$app = Get-WebApplication -Site $siteName -Name $appName
Write-Host "`nApplication Details:"
Write-Host "Name: $($app.path)"
Write-Host "Physical Path: $($app.physicalPath)"
Write-Host "Application Pool: $($app.applicationPool)"
Write-Host "Enabled Protocols: $($app.enabledProtocols)"

#####UPDATE ARM App Pool#####

# Define parameters
$siteName = "Default Web Site"
$appName = "ARM"
$newAppPool = "ArmAppPoolArmApp"
$newPhysicalPath = "c:\projects\arm\arm\user interface\app\src\activerisk.arm.app"

# Verify the application exists
$appPath = "IIS:\Sites\$siteName\$appName"
if (!(Test-Path $appPath)) {
    Write-Host "Error: Application '$appName' does not exist on '$siteName'."
    exit
}

# Create or configure the application pool for .NET Core with NetworkService
if (!(Test-Path "IIS:\AppPools\$newAppPool")) {
    Write-Host "Application Pool '$newAppPool' does not exist. Creating with .NET Core settings and NetworkService identity..."
    New-WebAppPool -Name $newAppPool
    
    # Configure for .NET Core
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name managedRuntimeVersion -Value ""  # No managed runtime version for .NET Core
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name managedPipelineMode -Value "Integrated"
    
    # Set to NetworkService
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "processModel.identityType" -Value "NetworkService"
    
    # Additional recommended settings for .NET Core
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "startMode" -Value "AlwaysRunning"
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "processModel.idleTimeout" -Value ([TimeSpan]::FromMinutes(0))
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "recycling.periodicRestart.time" -Value ([TimeSpan]::FromMinutes(0))
    
    Write-Host "Created .NET Core application pool with NetworkService identity: $newAppPool"
} else {
    Write-Host "Application Pool '$newAppPool' exists. Updating with .NET Core settings and NetworkService identity..."
    # Stop the app pool if it's running to allow identity change
    if ((Get-WebAppPoolState -Name $newAppPool).Value -eq 'Started') {
        Stop-WebAppPool -Name $newAppPool
    }
    
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name managedRuntimeVersion -Value ""
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name managedPipelineMode -Value "Integrated"
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "processModel.identityType" -Value "NetworkService"
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "startMode" -Value "AlwaysRunning"
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "processModel.idleTimeout" -Value ([TimeSpan]::FromMinutes(0))
    Set-ItemProperty "IIS:\AppPools\$newAppPool" -Name "recycling.periodicRestart.time" -Value ([TimeSpan]::FromMinutes(0))
    
    # Start the app pool again
    Start-WebAppPool -Name $newAppPool
}

Remove-WebApplication -Name "$appName/app" -Site $siteName
Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication" -Name enabled -Value true -PSPath "$appPath"

$SM = Get-IISServerManager
$hostConfig = $SM.GetApplicationHostConfiguration()


foreach ($locationPath in $hostConfig.GetLocationPaths()){
    if($locationPath.StartsWith("Default Web Site/ARM")){
      $hostConfig.RemoveLocationPath($locationPath)
 }
}

$SM.CommitChanges()

# Get the current app pool
$currentAppPool = Get-ItemProperty $appPath -Name applicationPool
Write-Host "Current application pool: $currentAppPool"

# Set the new application pool
Set-ItemProperty $appPath -Name applicationPool -Value $newAppPool

#set path 
Set-ItemProperty $appPath -Name physicalPath -Value $newPhysicalPath
Write-Host "Updated application pool to: $newAppPool"

# Display the configuration
Write-Host "`nApplication Pool Configuration:"
$appPoolPath = "IIS:\AppPools\$newAppPool"
$appPoolSettings = Get-ItemProperty $appPoolPath
Write-Host "Name: $($appPoolSettings.name)"
Write-Host "Runtime Version: $($appPoolSettings.managedRuntimeVersion)"
Write-Host "Pipeline Mode: $($appPoolSettings.managedPipelineMode)"
Write-Host "Identity: $($appPoolSettings.processModel.identityType)"
Write-Host "Start Mode: $($appPoolSettings.startMode)"
Write-Host "Idle Timeout: $($appPoolSettings.processModel.idleTimeout)"
Write-Host "Periodic Restart: $($appPoolSettings.recycling.periodicRestart.time)"

# Verify the application pool state
$poolState = Get-WebAppPoolState -Name $newAppPool
Write-Host "`nApplication Pool State: $($poolState.Value)"

# Verify the application pool assignment
$updatedAppPool = Get-ItemProperty $appPath -Name applicationPool
Write-Host "`nFinal Verification:"
Write-Host "Application: $appName"
Write-Host "Website: $siteName"
Write-Host "New Application Pool: $updatedAppPool"