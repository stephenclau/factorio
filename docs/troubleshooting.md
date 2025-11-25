# Troubleshooting
A list of common issues and solutions to get you and your team underway to the shattered planet.

## Common Issues

### 1. SERVER IS NOT DISCOVERABLE ON MY LAN
**Solution:** Use direct connection with <yourlanip:27015> or <yourlanip:34197> to connect via LAN. Ensure that IS_LAN is set to true within your **`docker-compose.yml`** file. Verify that your container ports are exposed on the host.  Additionally, verify that your host's firewall allows UDP traffic on port 34197. \
***Why?*** Docker NAT is known to conflict with how the game broadcasts itself over 27015. The container is broadcasting its internal container IP (172.17.0.1) rather than a host's public IP or LAN IP, UDP broadcast/multicast doesn't traverse Docker NAT bridges well, and/or UPnP port mapping doesn't always work through Docker bridges. It's like double NAT'ting.

### 2. SERVER IS NOT APPEARING ON THE OFFICIAL FACTORIO SERVER BROWSER
**Solution:** Set the IS_PUBLIC to true.  Ensure that FACTORIO_USERNAME and FACTORIO_TOKEN or FACTORIO_PASSWORD secrets are correctly created and mapped within your **`docker-compose.yml`** file. Ensure that your .secrets directory and **`docker-compose.yml`** are in the same directory; otherwise, check your relative paths. You can use either FACTORIO_TOKEN or FACTORIO_PASSWORD, not both.  Use docker compose logs -tf factorio | grep FACTORIO_TOKEN to see if the script read logs from Docker Secrets or defaulted to a blank one. Also, FACTORIO_USERNAME is your gamertag, NOT the login email you inputted into the login form.

### 3. INVALID STRING ESCAPE AT opt/factorio/data/server-settings.json:number
**Solution:** Remove the apostrophe/use of contractions in ENV variables meant to capture strings i.e. SERVERNAME, SERVERDESCRIPTION, etc. I don't think it supports "\" for line breaks either, best remove that as well.

### 4. PERMISSION DENIED ERRORS WHEN THE CONTAINER TRIES TO WRITE TO MOUNTED VOLUMES
**Solution:** Ensure that the UID/GID env vars within your **`docker-compose.yml`** file match the nonroot user you created on the host. Ensure that the nonroot user has read/write/execute permissions to the mounted volumes on the host. You can use **`sudo chown -R UID:GID /path/to/saves`** to recursively set ownership to your nonroot user on the host. Use sudo cat /etc/passwd on the host to find the UID/GID of the host user you created for this container. \
***Why?*** The container user, with UID 845, is trying to do stuff on the host volume that was created with a different UID. Can't do that unless the UIDs/GIDs are matching across host and container users. Usernames can be different between host and container because linux permissions rely on UID/GID.  The script will change the container user's ownership from the default 845 to the host UID/GID you specified to solve this issue.

### 5. CANNOT START SERVER/VOLUME IS EMPTY
**Solution:** Remove any mounts to the container's **`opt/factorio/data`** folder. \
***Why?*** This folder contains all the core files of the game, settings, and logs. Mounting an empty folder on your host to the **`opt/factorio/data`** folder will not have the container write to your host. On the contrary, at run time, the mount statements will override your containers instructions to read from an empty folder on your host, despite unpacking the server binaries to **`opt/factorio/data`** within the container itself.  

## See Something? Say Something!
Open an [issue](https://github.com/slauth82/factorio/issues), and I'll respond as soon as I can. 
