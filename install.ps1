# Define Minecraft server folder
$ServerDirectory = "$env:USERPROFILE\Desktop\server"

# Create server directory
if (-Not (Test-Path -Path $ServerDirectory)) {
    New-Item -ItemType Directory -Path $ServerDirectory\plugins | Out-Null
    Write-Host "Created server directory at $ServerDirectory"
}

# Create plugins directory
$PluginsDirectory = Join-Path -Path $ServerDirectory -ChildPath "plugins"
if (-Not (Test-Path -Path $PluginsDirectory)) {
    New-Item -ItemType Directory -Path $PluginsDirectory | Out-Null
    Write-Host "Created plugins directory at $PluginsDirectory"
}

# Install necessary tools via Chocolatey
Write-Host "Installing required tools via Chocolatey..."
choco install notepadplusplus jq wget -y

# Install Temurin 23 JRE in silent mode
Write-Host "Downloading and installing Temurin 23 JRE..."
$TemurinMsi = "$env:TEMP\temurin23.msi"
wget -O $TemurinMsi "https://api.adoptium.net/v3/installer/latest/23/ga/windows/x64/jre/hotspot/normal/eclipse"
Start-Process msiexec.exe -ArgumentList "/i $TemurinMsi /quiet /norestart" -NoNewWindow -Wait
Remove-Item $TemurinMsi -Force
Write-Host "Temurin 23 JRE installed successfully."

# Get the latest PaperMC build for the specified release
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
    wget -O "$ServerDirectory\server.jar" $PAPERMC_URL
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

# Install plugins

wget -O "$PluginsDirectory\Chunky.jar" "https://cdn.modrinth.com/data/fALzjamp/versions/ytBhnGfO/Chunky-Bukkit-1.4.28.jar"
wget -O "$PluginsDirectory\LoginSecurity.jar" "https://ci.codemc.io/view/Author/job/lenis0012/job/LoginSecurity/lastSuccessfulBuild/artifact/target/LoginSecurity-Spigot-3.3.1-SNAPSHOT.jar"
wget -O "$PluginsDirectory\EssentialsX.jar" "https://ci.ender.zone/job/EssentialsX/lastSuccessfulBuild/artifact/jars/EssentialsX-2.21.0-dev+151-f2af952.jar"
wget -O "$PluginsDirectory\ViaVersion.jar" "https://cdn.modrinth.com/data/P1OZGk5p/versions/jbXugTWc/ViaVersion-5.2.0.jar"
wget -O "$PluginsDirectory\AxShulkers.jar" "https://cdn.modrinth.com/data/TXhCFOgF/versions/3HM03V6K/AxShulkers-1.17.0.jar"
wget -O "$PluginsDirectory\MultiverseCore.jar" "https://cdn.modrinth.com/data/3wmN97b8/versions/jbQopAkk/multiverse-core-4.3.14.jar"
wget -O "$PluginsDirectory\AxiomPaper.jar" "https://cdn.modrinth.com/data/N6n5dqoA/versions/SV5tgbW3/Axiom-4.3.3-for-MC1.21.jar"

# FAWE
$JobUrl = "https://ci.athion.net/job/FastAsyncWorldEdit"

# Get the latest successful build API JSON and save it to a variable
$BuildJson = curl -s "$JobUrl/lastSuccessfulBuild/api/json"

# Extract the artifact containing "Paper" using jq
$ArtifactPath = echo $BuildJson | jq -r '.artifacts[] | select(.fileName | contains("Paper")) | .relativePath'

# Check if a PAPER build is found
if (-not $ArtifactPath) {
    Write-Host "No PAPER build artifact found in the latest successful build."
    exit 1
}

# Construct the download URL
$DownloadUrl = "$JobUrl/lastSuccessfulBuild/artifact/$ArtifactPath"

# Download the artifact using curl
Write-Host "Downloading FAWE Paper build from: $DownloadUrl"
wget -O "$PluginsDirectory\FAWE.jar" $DownloadUrl

Write-Host "Download complete!"

# Completion message
Write-Host "Minecraft server setup completed. Navigate to $ServerDirectory to start the server."
