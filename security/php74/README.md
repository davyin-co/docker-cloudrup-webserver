# PHP 7.4 emergency package update

This keeps Drupal 8.9.20 on PHP 7.4. It upgrades the installed PHP packages from the image's existing authenticated Ondrej PPA. It does not upgrade Drupal or deploy to a production server.

The inspected base image is Ubuntu 22.04 / amd64, despite the root README describing Ubuntu 20.04. The original package revision was `1:7.4.33-13+ubuntu22.04.1+deb.sury.org+1`. The first fixed PPA revision is `1:7.4.33-31+ubuntu22.04.1+deb.sury.org+1`, published on 21 October 2026. The short PHP version remains `7.4.33`.

The supplier's source changelog explicitly lists both CVEs, and `debian/patches/0164-Avoid-state-corruption-via-bailout.patch` carries the PHP project's EOL mitigation:

- Official commit: https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2
- Source package index: https://ppa.launchpadcontent.net/ondrej/php/ubuntu/dists/jammy/main/source/Sources.gz
- Supplier source archive: https://ppa.launchpadcontent.net/ondrej/php/ubuntu/pool/main/p/php7.4/php7.4_7.4.33-31+ubuntu22.04.1+deb.sury.org+1.debian.tar.xz

## Build from the existing published image

Run from the repository root:

```sh
docker build --pull --no-cache --platform linux/amd64 \
  -f security/php74/Dockerfile \
  -t cloudrup-webserver:7.4-cve20261022 .
```

The default base is pinned to the inspected Aliyun image digest. Override it only with the existing cloudrup PHP 7.4 image you intend to update:

```sh
docker build --no-cache --platform linux/amd64 \
  --build-arg BASE_IMAGE=your-registry/cloudrup-webserver:7.4 \
  -f security/php74/Dockerfile \
  -t cloudrup-webserver:7.4-cve20261022 .
```

This requires reachable Ubuntu repositories and the Ondrej PHP PPA. A stale package candidate, mixed PHP package revisions, wrong package vendor, missing CVE changelog entries or failed smoke check causes the build to fail. The image preserves existing conffiles and upgrades installed PHP 7.4 packages together, including Apache, CLI, CGI, OPcache and the packaged extensions.

## Normal repository build

`7.4/Dockerfile` includes the same package upgrade and verification after the existing package installation. `update.sh` preserves them when regenerating Dockerfiles. Use `--pull --no-cache` to refresh package installation layers on subsequent security rebuilds.

```sh
docker build --pull --no-cache --platform linux/amd64 \
  -f 7.4/Dockerfile -t cloudrup-webserver:7.4-cve20261022 .
```

The OCI8 derivative must be rebuilt FROM the newly fixed 7.4 image after it exists. The existing CI builds parent and OCI8 images in parallel; a successful OCI8 build alone does not establish that it used the patched parent. This change does not rewrite that separate pipeline.

## Verify and deploy

```sh
docker run --rm --platform linux/amd64 --entrypoint sh \
  cloudrup-webserver:7.4-cve20261022 /usr/local/bin/verify-php74-cve
```

An isolated Apache HTTP smoke test is also available (requires host Python 3 and Docker):

```sh
python3 security/php74/test-http.py cloudrup-webserver:7.4-cve20261022
```

It binds an ephemeral localhost port, mounts only temporary test files, checks regular requests and multipart upload, confirms native session upload progress remains disabled even when its INI flag is enabled, confirms OOM skips the shutdown callback, then removes its test container. It never mounts the actual Drupal site or database. The unpatched base fails the OOM assertion.

The check verifies package revisions, PHP module loading, immediate OOM exit with and without configured extensions, absence of shutdown callbacks on OOM, Apache syntax and the loaded PHP module. `max_multipart_body_parts` is only an additional sanity check: older supplier packages already have that setting, so its presence alone proves nothing. The upload-progress INI entries remain visible even though the callback is disabled by the patch.

Before production, test a staging copy of the actual Drupal site: database connectivity, login, content editing, upload, image styles, cache rebuild, cron and the site's Composer-managed Drush. Check custom shutdown handlers and upload-progress features. The patch exits immediately on OOM and disables native session upload progress. Keep a finite PHP memory limit once the fixed runtime has passed validation.

After staging passes, publish under a new tag, record the resulting digest and recreate all web/cron/worker containers using that image. Merely pulling or restarting the old container does not replace its runtime. Keep the previous image digest and database/files backup; reverting to an unpatched image reintroduces exposure, so isolate it if rollback is required.

PHP 7.4 and Drupal 8 remain EOL. These smoke checks are not an exploit test or a Drupal compatibility certification, and the EOL mitigation is not equivalent to ongoing security support.
