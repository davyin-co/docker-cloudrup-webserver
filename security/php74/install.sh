#!/bin/sh
set -eu
export DEBIAN_FRONTEND=noninteractive

# Upgrade only installed PHP 7.4 packages. Do not replace Apache, switch SAPIs,
# install PHP 8, or discard the image's additional extensions and configuration.
packages=$(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' \
    | awk '$1 == "ii" && ($2 ~ /^php7[.]4($|-)/ || $2 == "libapache2-mod-php7.4") {print $2}')
test -n "$packages"
# Refresh only the existing PHP PPA: this emergency overlay does not need to
# upgrade Ubuntu or download unrelated (large) restricted/multiverse indices.
ppa_list=$(grep -l '^deb .*ondrej/php/ubuntu' /etc/apt/sources.list.d/*.list)
test "$(printf '%s\n' "$ppa_list" | wc -l)" -eq 1
apt-get -o Acquire::Retries=2 -o Acquire::https::Timeout=30 \
    -o Dir::Etc::sourcelist="$ppa_list" -o Dir::Etc::sourceparts=- update
# Refuse a stale mirror before installing anything.
for package in $packages; do
    candidate=$(apt-cache policy "$package" | awk '/Candidate:/ {print $2}')
    dpkg --compare-versions "$candidate" ge '1:7.4.33-31'
done
# Package names come from dpkg, not user-supplied shell text.
apt-get install -y --only-upgrade --no-install-recommends \
    -o Dpkg::Options::=--force-confold $packages
sh /usr/local/bin/verify-php74-cve
mkdir -p /usr/local/share/cloudrup-php74-cve
dpkg-query -W 'php7.4*' libapache2-mod-php7.4 \
    > /usr/local/share/cloudrup-php74-cve/packages.txt
printf '%s\n' '712e60f9edfd03f0960fc4fc3c2c375f42b90aa2' \
    > /usr/local/share/cloudrup-php74-cve/upstream-commit.txt
rm -rf /var/lib/apt/lists/*
