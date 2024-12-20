# Define variables
$PaperProject = "paper"
$MinecraftVersion = "1.20.1"  # Replace with the desired Minecraft version
$ServerDir = "$env:USERPROFILE\Desktop\server"
$TempDir = "$env:TEMP\minecraft_setup"
$TemurinMsiUrl = "https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jre_x64_windows_hotspot_23.0.1_11.msi"
$SevenZipPath = "C:\Program Files\7-Zip\7z.exe"  # Update if your 7-Zip path differs

# Ensure directories exist
New-Item -ItemType Directory -Force -Path $ServerDir
New-Item -ItemType Directory -Force -Path $TempDir

# Install Temurin JRE
$TemurinMsiPath = "$TempDir\temurin.msi"
Invoke-WebRequest -Uri $TemurinMsiUrl -OutFile $TemurinMsiPath
Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$TemurinMsiPath`" /quiet /norestart" -Wait
Remove-Item -Path $TemurinMsiPath -Force

# Fetch the latest PaperMC build using curl
$PaperApiUrl = "https://api.papermc.io/v2/projects/$PaperProject/versions/$MinecraftVersion/builds"
$LatestBuild = (curl.exe -s $PaperApiUrl | ConvertFrom-Json).builds | Sort-Object | Select-Object -Last 1
if ($null -ne $LatestBuild) {
    $JarName = "$PaperProject-$MinecraftVersion-$LatestBuild.jar"
    $PaperDownloadUrl = "https://api.papermc.io/v2/projects/$PaperProject/versions/$MinecraftVersion/builds/$LatestBuild/downloads/$JarName"
    & curl.exe -o "$ServerDir\server.jar" $PaperDownloadUrl
    if (Test-Path "$ServerDir\server.jar") {
        Write-Host "PaperMC server.jar downloaded successfully."
    } else {
        Write-Host "Failed to download PaperMC server.jar."
        exit 1
    }
} else {
    Write-Host "No stable build found for Minecraft version $MinecraftVersion."
    exit 1
}

# Create start.bat
$StartBatContent = """
@echo off

:start
java -Xms9216M -Xmx9216M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true -jar server.jar nogui 

echo Server restarting...
echo Press CTRL + C to stop.
goto :start
"""
$StartBatPath = "$ServerDir\start.bat"
Set-Content -Path $StartBatPath -Value $StartBatContent -Force

# Cleanup
Remove-Item -Recurse -Force -Path $TempDir

Write-Host "Minecraft server setup completed successfully at $ServerDir."
