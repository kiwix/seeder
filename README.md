# Kiwix Seeder

`kiwix-seeder` is a simple tool that allows one to manage a Bittorrent seeder for Kiwix Catalog's ZIMs effortlessly.

[![CodeFactor](https://www.codefactor.io/repository/github/kiwix/seeder/badge)](https://www.codefactor.io/repository/github/kiwix/seeder)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![codecov](https://codecov.io/gh/kiwix/seeder/branch/main/graph/badge.svg)](https://codecov.io/gh/kiwix/seeder)
![PyPI - Python Version](https://img.shields.io/badge/python-3.12+-blue)
[![Docker](https://ghcr-badge.egpl.dev/kiwix/bittorrent-seeder/latest_tag?label=docker&ignore=)](https://ghcr.io/kiwix/bittorrent-seeder/)

It's composed of a script that runs periodically and which consists mostly in:

- Downloading the Kiwix OPDS Catalog
- Matching its entries with your defined filters
- Communicates with your qBittorrent instance (via HTTP)
  - Removes unwanted (not matching or out of Catalog) ZIMs from qBittorrent and filesystem
  - Adds new matching ZIM to qBittorrent

It's goal is thus to command the qBittorrent instance to download new torrents (any
new ZIM in the Catalog matching the filters) and remove old ones (previously
added torrents that dont match current filters or are not in Catalog anymore)

**Key features:**

- Very easy to use
- Very flexible filters so you can precisely select what to download and seed
- Compatible with your existing qBittorrent (doesn't mess with your stuff)

## Usage

> [!CAUTION]
> The parameters/config passed to `kiwix-seeder` is an indication of the new requested state.
> Say you were using it and are seeding 20 torrents, if you relaunch it with filters that match only a single ZIM, **it won't add this ZIM to your list**, it will **remove all the others** (see `--keep` below) and then add it (it replaces everything based on the passed filters).
>
> Use `--dry-run` option to work on your filters

### Standalone version

This version depends on a reachable qBittorrent instance. You call it to update your qBittorrent's list of ZIMs to seed.

```sh
❯ export QBT_URL="http://admin:mypass@nas.local:8080"
❯ kiwix-seeder --lang bam --max-storage 1GB
```

### Docker version

The Docker version includes qBittorrent so it's meant to run forever (uses `--daemon`).

The `seeder-start-restart` assistant script starts it from your config file and periodically runs the `kiwix-seeder` script to manage the list of torrents.

```sh
# start the long-lasting container
❯ seeder-start-restart

# stop the container
❯ docker stop seeder
```

You can also run it without the helper script using image `ghcr.io/kiwix/bittorrent-seeder:latest`. You'll have to sort out volume mounting, port forwarding and configuration. Use the helper script as documentation!

#### Monitoring

You can monitor what's hapenning via Docker logs

```sh
❯ docker logs -n 10 -f seeder
2025-01-17 11:52:57,324 INFO | 1279. Added openZIM:wikipedia_lt_all:maxi @ 2024-06-14 (2.2 GiB)
2025-01-17 11:53:01,852 INFO | 1280. Added openZIM:wikipedia_lt_all:mini @ 2024-06-13 (294.03 MiB)
2025-01-17 11:53:06,376 INFO | 1281. Added openZIM:wikipedia_lt_all:nopic @ 2024-06-14 (669.17 MiB)
2025-01-17 11:53:10,772 INFO | 1282. Added openZIM:wikisource_lt_all:maxi @ 2024-06-16 (7.85 MiB)
2025-01-17 11:53:15,370 INFO | 1283. Added openZIM:wikisource_lt_all:nopic @ 2024-06-16 (7.13 MiB)
2025-01-17 11:53:19,845 INFO | 1284. Added openZIM:wiktionary_lt_all:maxi @ 2024-05-11 (704.35 MiB)
2025-01-17 11:53:24,353 INFO | 1285. Added openZIM:wiktionary_lt_all:nopic @ 2024-05-11 (687.87 MiB)
2025-01-17 11:53:29,308 INFO | 1286. Added openZIM:wikibooks_lt_all:nopic @ 2024-06-26 (100.94 MiB)
2025-01-17 11:53:34,094 INFO | 1287. Added openZIM:wikibooks_lt_all:maxi @ 2024-06-26 (107.22 MiB)
2025-01-17 11:53:38,544 INFO | 1288. Added openZIM:wikiquote_lt_all:nopic @ 2024-06-16 (6.12 MiB)
```

You can also query information from the qBittorrent instance using bundled qbittorrent-cli (`qbt` binary)

```sh
❯ docker exec -it seeder qbt global info
Download speed:       382,456,016 bytes/s
Downloaded data:      1,407,643,708,964 bytes
Download speed limit: 0 bytes/s
Upload speed:         13,972,949 bytes/s
Uploaded data:        551,473,671,864 bytes
Upload speed limit:   0 bytes/s
DHT nodes:            366
Connection status:    Connected
```

## Installation

There are two main ways to use it; choose what's best for you:

| Mode | Target | Reason |
| ---  | -------| --- |
| Standalone Binary | If you already have a running qBittorrent instance. | Lightweight and flexible |
| Docker Image      | All in one docker image that runs both the script and qBittorrent. | Simplest  |

The Docker version obviously depends on Docker being installed and running.

### Docker version

This version is intended for those who want a setup-and-forget solution. It comes with qbittorrent. There's a good number of options but it's tailored for a kiwix-seeder only usage so it's not as flexible (although you can change any settings via the WebUI)

```sh
# 1. Make sure Docker is installed, running and you have rights over it
❯ docker ps

# 1. Create a config file, mentioning where to store torrents and ZIM into.
❯ mkdir -p /data/seeder
❯ cat <<EOF > /etc/seeder.config

# where to store all data (ZIMs, cache, qBittorrent profile)
DATA_PATH=/data/seeder

# webui password used by 
# - script to communicate with qBittorrent
# - user (you) via remote webui (see WEBUI_PORT below)
QBT_PASSWORD="Choose this one"

# BT port to use/announce.
# **must** be manually forwarded on your Internet-connected router to your local IP
# /!\ uPNP cannot work accross docker routing so it cannot automatically work
QBT_TORRENTING_PORT=6901

# port on host to map webui (for remote access, optional)
WEBUI_PORT=8080

# max storage size to use in DATA_PATH for ZIMs (stops if reached)
MAX_STORAGE="10TiB"

# interval between kiwix-seeder invocations (catalog refresh, ZIM addition/removal)
SLEEP_INTERVAL="1d"
EOF

# 2. Download the helper script
❯ curl -L -o /usr/local/bin/seeder-start-restart https://github.com/kiwix/container-images/raw/refs/heads/main/bittorrent-seeder/seeder-start-restart.sh
❯ chmod +x /usr/local/bin/seeder-start-restart
```

That's it. You can now start it as show above (`seeder-start-restart`).

If you created the config file in a different place, edit the helper script to load it properly.


### Standalone binary

> [!IMPORTANT]
> Standalone version requires you to run and configure qBittorrent yourself (see below)

Simply download and invoke it

```sh
❯ curl -o /usr/local/bin/kiwix-seeder https://TBD && chmod +x /usr/local/bin/kiwix-seeder

# set your qBittorrent URL so you can use kiwix-seeder binary without passing your credentials
❯ export QBT_URL="http://admin:mypass@nas.local:8080"
```

#### qBittorrent requirements

- qBittorrent must be running when using `kiwix-seeder`. Once invocation of kiwix-server has completed, qBittorrent can be stopped/started at your convenience.
- WebUI must be enabled and configured (see below)
- The machine running `kiwix-seeder` must be able to communicate with qBittorrent WebUI URL.

Check that you can make an HTTP request from `kiwix-seeder` machine to qBittorent URL using curl to ensure WebUI is working, reachable and the credentials are correct:


```sh
❯ curl -X POST -d 'username=XXXX&password=XXXX' ${QBT_URL}/api/v2/auth/login
Ok.
```

Make sure your Bittorrent settings are working (port for incoming connection) otherwise this will be quite useless.

##### Enabling WebUI

If you are using the Desktop version of qBittorrent, go to the *Options* panel then select *WebUI* on the sidebar. Then you need to enable *Web User Interface*.
Make sure you know the address, port and credentials to use.

## Uninstalling

Getting rid of the torrents/ZIM is easy because all torrents are within category `kiwix-seeder` and can be done by tweaking the configuration:

- Set a filter that matchs nothing (`--max-file-size 1b`)
- Set the keep-period very low (`--keep 1m`)

Then when running, `kiwix-seeder` will remove all the torrents and their associated files.

You can also do it outside of the tool, using qBittorrent UI or WebUI. Simply right-click on the `kiwix-seeder` category and select *Remove torrents*. You'll be prompted to confirm and whether you want to delete the associated files.


If you're using the Docker version, stop it and maybe remove the container, image and your config file.

## Configuration

See the `kiwix-seeder` usage for details on the options

```sh
kiwix-seeder --help
```

If using the Docker version, check the first lines of the `seeder-start-restart` script for exposed variables.

