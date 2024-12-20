import os
import subprocess
import requests
import shutil
from pathlib import Path

# Constants
USER_HOME = Path.home()
SERVER_DIR = USER_HOME / "Desktop/server"
TEMURIN_URL = "https://github.com/adoptium/temurin23-binaries/releases/download/jdk-23.0.1%2B11/OpenJDK23U-jre_x64_windows_hotspot_23.0.1_11.msi"
TEMP_DIR = Path("C:/temp")
MINECRAFT_VERSION = "1.21.1"  # Set the desired Minecraft version
PAPER_PROJECT = "paper"
PAPER_API = f"https://api.papermc.io/v2/projects/{PAPER_PROJECT}/versions/{MINECRAFT_VERSION}/builds"

START_BAT_CONTENT = """\
@echo off

:start
java -Xms9216M -Xmx9216M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -Dcom.mojang.eula.agree=true -jar server.jar nogui

echo Server restarting...
echo Press CTRL + C to stop.
goto :start
"""

# Ensure directories
SERVER_DIR.mkdir(parents=True, exist_ok=True)
TEMP_DIR.mkdir(parents=True, exist_ok=True)

def download_file(url, dest):
    print(f"Downloading {url}...")
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(dest, 'wb') as f:
            shutil.copyfileobj(r.raw, f)
    print(f"Downloaded {dest}")

def install_temurin():
    temurin_path = TEMP_DIR / "temurin.msi"
    download_file(TEMURIN_URL, temurin_path)
    print("Installing Temurin JRE...")
    subprocess.run(["msiexec", "/i", str(temurin_path), "/quiet", "/norestart"], check=True)
    print("Temurin JRE installed.")
    os.remove(temurin_path)

def get_latest_papermc_build():
    print("Fetching the latest PaperMC build...")
    response = requests.get(PAPER_API)
    response.raise_for_status()
    builds = response.json()["builds"]
    default_builds = [b for b in builds if b["channel"] == "default"]
    latest_build = default_builds[-1]["build"] if default_builds else None
    if latest_build:
        return latest_build
    else:
        raise Exception("No stable build found.")

def download_papermc():
    latest_build = get_latest_papermc_build()
    jar_name = f"{PAPER_PROJECT}-{MINECRAFT_VERSION}-{latest_build}.jar"
    papermc_url = f"https://api.papermc.io/v2/projects/{PAPER_PROJECT}/versions/{MINECRAFT_VERSION}/builds/{latest_build}/downloads/{jar_name}"
    dest = SERVER_DIR / "server.jar"
    download_file(papermc_url, dest)

def create_start_bat():
    print("Creating start.bat...")
    start_bat_path = SERVER_DIR / "start.bat"
    with open(start_bat_path, "w") as f:
        f.write(START_BAT_CONTENT)
    print("start.bat created.")

def main():
    try:
        install_temurin()
        download_papermc()
        create_start_bat()
        print("Minecraft server setup completed successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
