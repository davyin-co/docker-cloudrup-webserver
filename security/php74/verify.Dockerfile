
# The PPA package revision must contain the October 2026 EOL mitigation.
COPY security/php74/install.sh /usr/local/bin/install-php74-cve
COPY security/php74/verify.sh /usr/local/bin/verify-php74-cve
RUN sh /usr/local/bin/install-php74-cve
LABEL com.cloudrup.php74-cve.upstream-commit="712e60f9edfd03f0960fc4fc3c2c375f42b90aa2"
