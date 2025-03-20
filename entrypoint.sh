#!/bin/bash

function configure_qbt {

	QBT_HOST="${QBT_HOST:-localhost}"
	QBT_PORT="${QBT_PORT:-80}"
	QBT_USERNAME="${QBT_USERNAME:-admin}"

	# WEBUI_SSL=y enables SSL on WEB_UI and --insecure on kiwix-seeder
	if [[ "${WEBUI_SSL}" = "y" ]]; then
		websslvalue="true"
		webuischeme="https"
		export QBT_INSECURE=y
		export QBT_SCHEME=https
	else
		webuischeme="http"
		websslvalue="false"
		export QBT_SCHEME=http
	fi
	QBT_CONFIG_FILE=/root/.config/qBittorrent/qBittorrent.conf

	# configure qbittorrent-cli (qbt)
	QBT_CLI_CONFIG_FILE=/root/.qbt/settings.json
	if [ ! -f "$QBT_CLI_CONFIG_FILE" ]; then
		qbt settings set url "http://${QBT_HOST}:${QBT_PORT}"
		qbt settings set username "${QBT_USERNAME}"
		echo "${QBT_PASSWORD}" | qbt settings set password -y
	fi

	if [ -f "$QBT_CONFIG_FILE" ] ; then
		echo "Found existing qBittorrent config file at $QBT_CONFIG_FILE"
		echo "Assuming persistent installation ; skipping configuration."
		return
	fi

	QBT_TORRENTING_PORT="${QBT_TORRENTING_PORT:-6901}"

	QBT_MAX_CONNECTIONS="${QBT_MAX_CONNECTIONS:-500}"
	QBT_MAX_CONNECTIONS_PER_TORRENT="${QBT_MAX_CONNECTIONS_PER_TORRENT:-100}"
	QBT_MAX_UPLOADS="${QBT_MAX_UPLOADS:-20}"
	QBT_MAX_UPLOADS_PER_TORRENT="${QBT_MAX_UPLOADS_PER_TORRENT:-5}"
	QBT_MAX_ACTIVE_CHECKING_TORRENTS="${QBT_MAX_ACTIVE_CHECKING_TORRENTS:-1}"

	if [ "x${QBT_PASSWORD}" = "x" ]; then
		QBT_PASSWORD=$(gen-password)
		echo "Generated web-ui password: ${QBT_PASSWORD}"
	fi
	PKBF2_PASSWORD=$(get-pbkdf2 "${QBT_PASSWORD}")

	mkdir -p $(dirname $QBT_CONFIG_FILE)

	cat <<EOF > $QBT_CONFIG_FILE
[BitTorrent]
MergeTrackersEnabled=true
Session\DefaultSavePath=/data
Session\AddExtensionToIncompleteFiles=true
Session\MaxConnections=${QBT_MAX_CONNECTIONS}
Session\MaxConnectionsPerTorrent=${QBT_MAX_CONNECTIONS_PER_TORRENT}
Session\MaxUploads=${QBT_MAX_UPLOADS}
Session\MaxUploadsPerTorrent=${QBT_MAX_UPLOADS_PER_TORRENT}
Session\Port=${QBT_TORRENTING_PORT}
Session\Preallocation=true
Session\QueueingSystemEnabled=false
Session\SSL\Port=30154
Session\MaxActiveCheckingTorrents=${QBT_MAX_ACTIVE_CHECKING_TORRENTS}

[LegalNotice]
Accepted=true

[Meta]
MigrationVersion=8

[Preferences]
General\Locale=en
WebUI\Enabled=true
WebUI\HTTPS\Enabled=${websslvalue}
WebUI\HTTPS\CertificatePath=${WEBUI_SSL_CERT}
WebUI\HTTPS\KeyPath=${WEBUI_SSL_KEY}
WebUI\Port=${QBT_PORT}
WebUI\Username=${QBT_USERNAME}
WebUI\Password_PBKDF2="@ByteArray(${PKBF2_PASSWORD})"
WebUI\LocalHostAuth=true
WebUI\HostHeaderValidation=false
WebUI\CSRFProtection=false

[Core]
AutoDeleteAddedTorrentFile=Always

[Application]
FileLogger\Age=5
FileLogger\AgeType=0
FileLogger\Backup=true
FileLogger\DeleteOld=true
FileLogger\Enabled=true
FileLogger\MaxSizeBytes=1048576
FileLogger\Path=/data/log
GUI\Notifications\TorrentAdded=false

EOF

	# configure qbittorrent-cli (qbt)
	if [[ "${WEBUI_SSL}" = "y" ]]; then
		qbt network settings --ignore-certificate-errors TRUE
	fi
	qbt settings set url "${webuischeme}://${QBT_HOST}:${QBT_PORT}/"
	qbt settings set username "${QBT_USERNAME}"
	echo "${QBT_PASSWORD}" | qbt settings set password -y

}


if [ "x${NO_QBT}" = "x" ]; then
	configure_qbt
	qbt_command="/usr/bin/qbittorrent-nox --daemon"

	echo "Starting a qbittorrent-nox process (set NO_QBT if you dont want to)"

	$qbt_command

	# start a monit daemon to check and restart qbittorrent automatically
	# should it crash
cat <<EOF > /etc/monitrc
# nb of seconds between checks
set daemon  30
set log /dev/stdout
set ssl options { verify: disable }

CHECK PROCESS qbittorrent MATCHING qbittorrent-nox
    start = "${qbt_command}" with timeout 20 seconds
    if failed
		host ${QBT_HOST}
		port ${QBT_PORT}
		protocol ${webuischeme} and request "/"
	then start


EOF
	chmod 700 /etc/monitrc
	/usr/bin/monit -c /etc/monitrc
	# given a few seconds to qBittorrent to start before staring the loop
	# as the loop has no fancy retry mechanism ATM and will wait sleep_interval (long)
	# before re-trying
	sleep 3
fi


exec "$@"
