# Build from the repository root. This preserves the existing cloudrup stack.
ARG BASE_IMAGE=registry.cn-hangzhou.aliyuncs.com/davyin/cloudrup-webserver:7.4@sha256:d3a8a1e7e63ebee1dda4b989b690319a1ad71dff708ef7f43e1e957f685844da
FROM ${BASE_IMAGE}
COPY security/php74/install.sh /usr/local/bin/install-php74-cve
COPY security/php74/verify.sh /usr/local/bin/verify-php74-cve
RUN sh /usr/local/bin/install-php74-cve
LABEL com.cloudrup.php74-cve.upstream-commit="712e60f9edfd03f0960fc4fc3c2c375f42b90aa2"
