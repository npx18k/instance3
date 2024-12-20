# Define Minecraft version
$MinecraftVersion = "1.21.1"  # Replace with the desired Minecraft version
$ServerDirectory = "$env:USERPROFILE\Desktop\server"

# Create server directory
if (-Not (Test-Path -Path $ServerDirectory)) {
    New-Item -ItemType Directory -Path $ServerDirectory | Out-Null
    Write-Host "Created server directory at $ServerDirectory"
}

# Install jq
Write-Host "Installing jq via Chocolatey..."
choco install jq -y

# Install Temurin 23 JRE in silent mode
Write-Host "Downloading and installing Temurin 23 JRE..."
$TemurinMsi = "$env:TEMP\temurin23.msi"
Invoke-WebRequest -Uri "https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jre_x64_windows_hotspot_23.0.1_11.msi" -OutFile $TemurinMsi
Start-Process msiexec.exe -ArgumentList "/i $TemurinMsi /quiet /norestart" -NoNewWindow -Wait
Remove-Item $TemurinMsi -Force
Write-Host "Temurin 23 JRE installed successfully."

# Get the latest PaperMC build
$PROJECT = "paper"
$MINECRAFT_VERSION = "1.21.1"

# Fetch the builds JSON using curl
$response = curl -s "https://api.papermc.io/v2/projects/$PROJECT/versions/$MINECRAFT_VERSION/builds"

# Parse JSON using jq to get the latest build with the "default" channel
$LATEST_BUILD = echo $response | jq -r '.builds | map(select(.channel == "default") | .build) | .[-1]'

if ($LATEST_BUILD -ne "null") {
    $JAR_NAME = "${PROJECT}-${MINECRAFT_VERSION}-${LATEST_BUILD}.jar"
    $PAPERMC_URL = "https://api.papermc.io/v2/projects/$PROJECT/versions/$MINECRAFT_VERSION/builds/$LATEST_BUILD/downloads/$JAR_NAME"

    # Download the latest Paper version using curl
    curl -o "server.jar" $PAPERMC_URL
    Write-Host "Download completed"
} else {
    Write-Host "No stable build for version $MINECRAFT_VERSION found :("
}


# Create start.bat
Write-Host "Creating start.bat file..."
$StartBatContent = "@echo off

:start
java -Xms9216M -Xmx9216M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true -jar server.jar nogui

echo Server restarting...
echo Press CTRL + C to stop.
goto :start"
Set-Content -Path "$ServerDirectory\start.bat" -Value $StartBatContent -Force
Write-Host "start.bat created successfully."

# Completion message
Write-Host "Minecraft server setup completed. Navigate to $ServerDirectory to start the server."
