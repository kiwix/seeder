# Kiwix Seeder

`kiwix-seeder` is a simple tool that allows one to manage a Bittorrent seeder for Kiwix Catalog's ZIMs effortlessly.

[![CodeFactor](https://www.codefactor.io/repository/github/kiwix/seeder/badge)](https://www.codefactor.io/repository/github/kiwix/seeder)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![codecov](https://codecov.io/gh/kiwix/seeder/branch/main/graph/badge.svg)](https://codecov.io/gh/kiwix/seeder)
![PyPI - Python Version](https://img.shields.io/badge/python-3.12+-blue)
[![Docker](https://ghcr-badge.egpl.dev/kiwix/bittorrent-seeder/latest_tag?label=docker&ignore=)](https://ghcr.io/kiwix/bittorrent-seeder/)

It is composed of a script that you run periodically and which consists mostly in:

- Downloading the Kiwix OPDS Catalog
- Matching its entries with your defined filters
- Communicating with your qBittorrent instance (via HTTP)
  - Removing unwanted (not matching or out of Catalog) ZIMs from qBittorrent and filesystem
  - Adding new matching ZIM to qBittorrent

Its goal is thus to command your qBittorrent instance to download new torrents (any
new ZIM in the Catalog matching the filters) and remove old ones (previously
added torrents that dont match current filters or are not in Catalog anymore)

**Key features:**

- Very easy to use
- Very flexible filters so you can precisely select what to download and seed
- Compatible with your existing qBittorrent (doesn't mess with your stuff)

## Requirements

- A running <a href="https://www.qbittorrent.org/">qBittorrent</a>.
- WebUI must be enabled and configured (If you are using the Desktop version of qBittorrent, go to the *Options* panel then select *WebUI* on the sidebar. Then you need to enable *Web User Interface*. Make sure you know the address, port and credentials to use.)
- The machine running `kiwix-seeder` must be able to communicate with qBittorrent WebUI URL.

Check that you can make an HTTP request from `kiwix-seeder` machine to qBittorent URL using curl to ensure WebUI is working, reachable and the credentials are correct:

```sh
❯ curl -X POST -d 'username=XXXX&password=XXXX' ${QBT_URL}/api/v2/auth/login
Ok.
```

Make sure your Bittorrent settings are working (port for incoming connection) otherwise this will be quite useless.

## Usage

> [!CAUTION]
> The parameters/config passed to `kiwix-seeder` is an indication of the new requested state.
> Say you were using it and are seeding 20 torrents, if you relaunch it with filters that match only a single ZIM, **it won't add this ZIM to your list**, it will **remove all the others** (see `--keep` below) and then add it (it replaces everything based on the passed filters).
>
> Use `--dry-run` option to work on your filters

```sh
❯ export QBT_URL="http://admin:mypass@nas.local:8080"
❯ kiwix-seeder --lang bam --max-storage 1GB
```

```
2026-09-01 15:17:13,326 INFO | Starting super-seeder with filters:
2026-09-01 15:17:13,326 INFO | Filenames: all
2026-09-01 15:17:13,326 INFO | Languages: bam
2026-09-01 15:17:13,326 INFO | Categories: all
2026-09-01 15:17:13,326 INFO | Flavours: all
2026-09-01 15:17:13,326 INFO | Tags: all
2026-09-01 15:17:13,326 INFO | Authors: all
2026-09-01 15:17:13,326 INFO | Publishers: all
2026-09-01 15:17:13,326 INFO | Size: all
2026-09-01 15:17:13,326 INFO | Checking qBittorrent connection…
2026-09-01 15:17:13,374 DEBUG | Login successful
2026-09-01 15:17:13,375 INFO | > Connected to qBittorrent v5.2.3 ; fetching data…
2026-09-01 15:17:13,376 INFO | Fetching catalog…
2026-09-01 15:17:13,810 DEBUG | refreshing catalog via https://opds.library.kiwix.org/catalog/v2
2026-09-01 15:17:17,113 DEBUG | refreshed on 2026-09-01 15:17:17.113119+00:00
2026-09-01 15:17:17,114 INFO | Catalog contains 3624 ZIMs
2026-09-01 15:17:17,117 INFO | Filters matches 3 ZIMs
2026-09-01 15:17:17,117 DEBUG | * openZIM:voa_bm_all: @ 2024-12-04 (310.13 MiB)
2026-09-01 15:17:17,117 DEBUG | * openZIM:wikipedia_bm_all:maxi @ 2026-07-20 (17.06 MiB)
2026-09-01 15:17:17,117 DEBUG | * openZIM:wikipedia_bm_all:nopic @ 2026-07-20 (1.47 MiB)
2026-09-01 15:17:17,117 DEBUG | Catalog size: 328.66 MiB
2026-09-01 15:17:17,117 INFO | Querying qBittorrent state…
2026-09-01 15:17:17,119 INFO | There are 2 torrents in kiwix-seeder
2026-09-01 15:17:17,120 DEBUG | * voa_bm_all_2024-12.zim @ 7a2dbe119b0a8737aa9fcde2a910036c27494b9d (310.13 MiB)
2026-09-01 15:17:17,121 DEBUG | * wikipedia_bm_all_maxi_2026-07.zim @ fe51eb1305cc94f7fdf1a1d5cdf1c565569fef7b (17.06 MiB)
2026-09-01 15:17:17,121 INFO | Checking for existing torrents removal…
2026-09-01 15:17:17,121 INFO | > None
2026-09-01 15:17:17,121 INFO | Reconciling books and torrents (may require btih endpoint requests)
2026-09-01 15:17:17,124 INFO | Checking overall storage needs:
2026-09-01 15:17:17,124 DEBUG | - Existing torrents: 327.19 MiB
2026-09-01 15:17:17,124 DEBUG | - Requested new torrents: 1.47 MiB
2026-09-01 15:17:17,124 INFO | - Total torrents: 328.66 MiB <= 953.67 MiB (max storage)
2026-09-01 15:17:17,124 INFO | Adding 1 torrents…
2026-09-01 15:17:17,679 INFO | 0. Added openZIM:wikipedia_bm_all:nopic @ 2026-07-20 (1.47 MiB)
2026-09-01 15:17:17,679 INFO | kiwix-seeder has 3 torrents
```

See the `kiwix-seeder` usage for details on the options

```sh
kiwix-seeder --help
```

> [!NOTE]
> There's a `kiwix-server-loop` script available that runs it at periodic (`SLEEP_INTERVAL=1d`) interval.


## Installation

### Standalone binary

Uses latest release

```sh
❯ curl -o /usr/local/bin/kiwix-seeder https://mirror.download.kiwix.org/release/kiwix-seeder/kiwix_seeder_{platform}-{arch} && chmod +x /usr/local/bin/kiwix-seeder

# set your qBittorrent URL so you can use kiwix-seeder binary without passing your credentials
❯ export QBT_URL="http://admin:mypass@nas.local:8080"
kiwix-seeder --help
```

### Docker

Assuming you have [Podman](https://podman.io/) or a compatible alternative installed. You can also use `:develop` tag for unreleased version.

```sh
docker run -it \
	-e "QBT_URL=http://admin:password@someip:someport"
	-e LANGUAGES=bam
	-e MAX_SIZE=100MiB
	ghcr.io/kiwix/seeder:latest kiwix-seeder
```

### Source (Python)

Assuming you have [`uv`](https://docs.astral.sh/uv/) installed

```sh
git clone https://github.com/kiwix/seeder.git --depth 1
cd seeder/
uv run kiwix-seeder --help
# also avail:
# uv run kiwix-seeder-loop
```


## Uninstalling

Getting rid of the torrents/ZIM is easy because all torrents are within category `kiwix-seeder` and can be done by tweaking the configuration:

- Set a filter that matchs nothing (`--max-file-size 1b`)
- Set the keep-period very low (`--keep 1m`)

Then when running, `kiwix-seeder` will remove all the torrents and their associated files.

You can also do it outside of the tool, using qBittorrent UI or WebUI. Simply right-click on the `kiwix-seeder` category and select *Remove torrents*. You'll be prompted to confirm and whether you want to delete the associated files.


If you're using the Docker version, stop it and maybe remove the container and image.

