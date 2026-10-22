#!/bin/sh
set -eu

php7.4 -v
modules=$(php7.4 -m 2>&1)
printf '%s\n' "$modules"
if printf '%s\n' "$modules" | grep -Eq 'PHP (Warning|Fatal)|Unable to load'; then
    echo 'PHP module loading failed' >&2
    exit 1
fi
test "$(php7.4 -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;')" = 7.4
# -31 is the first Ondrej revision carrying both fixes. PHP's short version
# remains 7.4.33; it is not sufficient evidence of remediation.
packages=$(dpkg-query -W -f='${db:Status-Abbrev} ${Package}\n' \
    | awk '$1 == "ii" && ($2 ~ /^php7[.]4($|-)/ || $2 == "libapache2-mod-php7.4") {print $2}')
expected_version=$(dpkg-query -W -f='${Version}' php7.4-cli)
for package in $packages; do
    version=$(dpkg-query -W -f='${Version}' "$package")
    dpkg --compare-versions "$version" ge '1:7.4.33-31'
    test "$version" = "$expected_version"
    case "$version" in *deb.sury.org*) ;; *) echo "Unexpected package origin: $version" >&2; exit 1 ;; esac
    printf '%s %s\n' "$package" "$version"
done
changelog=/usr/share/doc/php7.4-common/changelog.Debian.gz
zcat "$changelog" | grep -q 'CVE-2026-109618'
zcat "$changelog" | grep -q 'CVE-2026-109619'

# With the EOL patch, OOM exits immediately with status 1, without callbacks.
check_oom() {
    mode=$1
    set +e
    if [ "$mode" = minimal ]; then
        output=$(php7.4 -n -d memory_limit=4M -r \
            'register_shutdown_function(function () { echo "SHUTDOWN-RAN\n"; }); str_repeat("x", 64 * 1024 * 1024);' 2>&1)
    else
        output=$(php7.4 -d opcache.enable_cli=1 -d memory_limit=4M -r \
            'register_shutdown_function(function () { echo "SHUTDOWN-RAN\n"; }); str_repeat("x", 64 * 1024 * 1024);' 2>&1)
    fi
    status=$?
    set -e
    printf '%s\n' "$output"
    test "$status" -eq 1
    if printf '%s\n' "$output" | grep -q SHUTDOWN-RAN; then exit 1; fi
    printf '%s\n' "$output" | grep -q 'Allowed memory size'
}
check_oom minimal
check_oom configured

# The EOL patch introduces this directive. Upload-progress INI entries still
# exist, but the callback ignores them; ini_get() cannot test that mitigation.
php7.4 -r 'if (ini_get("max_multipart_body_parts") === false) { exit(1); }'
apache2ctl -t
apache2ctl -M 2>&1 | grep -q 'php7_module'
echo 'PHP 7.4 EOL mitigation smoke checks passed (not an exploit or Drupal test).'
