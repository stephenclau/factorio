![Docker Image Version](https://img.shields.io/docker/v/slautomaton/factorio?arch=amd64&style=plastic&logo=docker&label=Image%20Version)
![Docker Image Size](https://img.shields.io/docker/image-size/slautomaton/factorio?arch=amd64&style=plastic&logo=docker&label=Image%20Size) \
![Factorio Version](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/slauth82/factorio/master/.github/badges/factorio-version.json)
![Static Badge](https://img.shields.io/badge/Debian-13?style=plastic&logo=debian&label=Base%20Image&color=orange)
![GitHub License](https://img.shields.io/github/license/slauth82/factorio?style=plastic&logo=github&lable=License)
![GitHub last commit](https://img.shields.io/github/last-commit/slauth82/factorio?style=plastic&logo=github&label=Last%20Commit)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/slauth82/factorio/01.yml?style=plastic&logo=github&label=Build) \
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/slauth82/factorio/02.yml?style=plastic&logo=google&label=OSV%20Scan%20Check)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/slauth82/factorio/04.yml?style=plastic&logo=trivy&label=Trivy%20CVE)

# Containerized Factorio Space Age Dedicated Server
This repository contains a Docker container image that hosts a Factorio Space Age dedicated server for users with maps they already previewed or started locally. This image completely ignores server-sided map gen commandline, because I believe everyone will want to use the GUI to preview their map seeds and adjust difficulty sliders as its faster to get started. 

## Thematically...
### Starting a New Game for MP
1. Use your Factorio game client to preview map gen settings.
2. Use your Factorio game client to preview, download, and install mods you want you use.
3. Navigate through your Factorio game client's directory, find **`map.zip`** and **`/mods`**, and then copy your map and mods into **`host/path/to/saves`** and **`host/path/to/mods`** on your container host, which are mounted to **`/opt/factorio/saves`** and **`/opt/factorio`**, respectively via your **`docker-compose.yml`** file. 
4. Remote into your host, either create a **`workdir`**, or use your home directory and from your **`workdir`**, author your **`.secrets`** and **`docker-compose.yml`**. FACTORIO_USERNAME, FACTORIO_PASSWORD or FACTORIO_TOKEN are PREREQUISITES for your server to be included on the official Factorio server browser. You can leave these blank if you intend to be LAN only. 
5. Use **`docker compose up -d`** to run the server.
6. Use **`docker compose down`**  to kill the server.
7. When making changes to ENV variables within the **`docker-compose.yml`**, you MUST use a **`docker compose down/up`** cycle.

### Loading a Pre-existing Game for MP
Skip steps 1 and 2 above and begin with step 3. 

## Environmental Variables
| ENV Var| Description| Default Value|
|--------|------------|--------------|
|SERVER_NAME| Name of the game as it will appear in the game listing.
|SERVER_DESCRIPTION| Description of the game that will appear in the listing. (Do not use contractions. An apostrophe will throw an error as an invalid escape param)
|TAGS| Tags!
|LOAD_LATEST_SAVE| NOT OPTIONAL - Tells runfactorio.sh to load the map named specified under SAVE_NAME. | true 
|SAVE_NAME| NOT OPTIONAL - Name of map file e.g. map.zip  
|MAX_PLAYERS| Maximum number of players. 0 means unlimited.| 0
|IS_PUBLIC| Game will be published on the official Factorio matching server. | false
|IS_LAN| Game will be broadcast on LAN. | true
|REQUIRE_USER_VERIFICATION| Requres players to have a valid account with Factorio.com. |true 
|ALLOWCOMMANDS| Possible values are, true, false and admins-only. |admins-only
|AUTOSAVE_INTERVAL| Autosave interval in MINUTES. | 10
|AUTOSAVE_SLOTS| Server autosave slots, it is cycled through when the server autosaves. | 5
|UID| NOT OPTIONAL - Nonroot user UID on the host. | 845
|GID| NOT OPTIONAL - Nonroot user GID on the host. | 845
|TZINFO| Timezone for container for logs. | America/Los_Angeles
|AUTOSAVE_SERVER_ONLY| Whether autosaves should be saved only on server or also on all connected clients. |true
|AFK_AUTOKICK_INTERVAL|How many minutes until someone is kicked when doing nothing, 0 for never. | 0
|AUTO_PAUSE| Whether should the server be paused when no players are present. | true
|AUTO_PAUSE_WHEN_PLAYERS_CONNECT|Whether should the server be paused when someone is connecting to the server. | false
|ONLY_ADMINS_CAN_PAUSE| Self Explanatory| true
|IGNORE_PLAYER_LIMIT_FOR_RETURNING_PLAYERS| Players that played on this map already can join even when the max player limit was reached. Non-admin players have to wait for a spot to open upon return.| false

## Getting Started

1. Understand where your map and mods are located. E.g mine are at: 
```bash
U:\Users\%USERNAME%\AppData\Roaming\Factorio\saves\map.zip 
U:\Users\%USERNAME%\AppData\Roaming\Factorio\mods
```
2. Remote into your host using a nonroot user with sudoers privileges and create a new nonroot user. E.g sudo useradd -m factorio
3. Grab the UID/GID of the nonroot user you just created. If you didn't grab it earlier, use **`sudo cat /etc/passwd`**, find your nonroot user name, and grab the ID numbers - should look like 123:123. 
4. Switch to the new nonroot user you just made and make a working directory for your compose and secrets, or use your home directory. 
5. For secrets, **`mkdir .secrets && cd .secrets`**. Then **`echo "whatever you want" > FACTORIO_USERNAME.txt`** to create a secrets file. The name of the secrets file should EQUAL the secrets variable name specified within the DOCKERFILE. E.g my DOCKERFILE will have secrets for FACTORIO_USERNAME, FACTORIO_TOKEN, FACTORIO_GAME_PASSWORD, and RCON_PASSWORD; therefore, I will need txt files foreach of the variables I just named. Your **`docker-compose.yml`** and **`.secrets`** folder must be in the same root directory for your secrets to be read from within **`docker-compose.yml`**.  
6. Create your **`path/to/saves`** and upload your **`map.zip`** into the host. 
7. Create your **`path/to/mods`** and upload your individual mods here. Be wary not to copy mods from your source into mods folder i.e. mods/mods. 
8. From your root working directory, create your **`docker-compose.yml`** file. See example below. Make sure to set the UID/GID env vars to the nonroot user you created earlier. Set the SAVE_NAME to the name of the map.zip you just uploaded to the host.
9. run **`docker compose up -d && docker compose logs -tf factorio`**

## Example docker-compose.yml
```yaml
services:
  factorio:
    container_name: factorio
    image: slautomaton/factorio:stable
    hostname: factorio-dedicated
    init: true
    restart: "unless-stopped"
    ports:
      - 34197:34197/udp
      - 27015:27015/tcp
    volumes:
      - /home/factorio/mods:/opt/factorio/mods
      - /home/factorio/scenarios:/opt/factorio/scenarios
      - /home/factorio/saves:/opt/factorio/saves
    secrets:
      - FACTORIO_USERNAME
      - FACTORIO_TOKEN
      - FACTORIO_GAME_PASSWORD
      - RCON_PASSWORD
    environment:
      - SERVER_NAME=My Awesome Factorio Server
      - SERVER_DESCRIPTION=Some description here. ##do not use contractions.(') will throw an error in the shell script.
      - TAGS=game,factorio,dedicated,server,spaceage,modded
      - LOAD_LATEST_SAVE=true ##This is my custom variable tells the runfactorio.sh entrypoint scrip to look map named as SAVE_NAME to load.
      - SAVE_NAME=map.zip
      - MAX_PLAYERS=10
      - IS_PUBLIC=true
      - IS_LAN=true
      - REQUIRE_USER_VERIFICATION=true
      - ALLOWCOMMANDS=admins-only
      - AUTOSAVE_INTERVAL=10
      - AUTOSAVE_SLOTS=5
      - UID=123 #Nonroot user UID on the host
      - GID=123 #Nonroot user GID on the host
      - TZINFO=America/Los_Angeles
      - AUTOSAVE_SERVER_ONLY=false 
      - AFK_AUTOKICK_INTERVAL=0 
      - AUTO_PAUSE=false 
      - AUTO_PAUSE_WHEN_PLAYERS_CONNECT=false 
      - ONLY_ADMINS_CAN_PAUSE=true 
      - IGNORE_PLAYER_LIMIT_FOR_RETURNING_PLAYERS=false 
secrets:
  FACTORIO_USERNAME:
    file: path/to/secrets/FACTORIO_USERNAME.txt
  FACTORIO_TOKEN:
    file: path/to/secrets/FACTORIO_TOKEN.txt
  FACTORIO_GAME_PASSWORD:
    file: path/to/secrets/FACTORIO_GAME_PASSWORD.txt
  RCON_PASSWORD:
    file: path/to/secrets/RCON_PASSWORD.txt
```
