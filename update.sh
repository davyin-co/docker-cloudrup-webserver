#!/bin/bash
### https://blog.dockbit.com/templating-your-dockerfile-like-a-boss-2a84a67d28e9
render() {
    sedStr="
    s/%%PHP_VERSION%%/$version/g;
    "
    sed -e "$sedStr" $1
}

versions=(7.1 7.2 7.3 7.4)
for version in ${versions[*]}; do
  if [ ! -d ${version} ]; then
    mkdir ${version}
  fi
  render Dockerfile.template > ${version}/Dockerfile
  ##OCI8
  if [ ! -d ${version}/oci8 ]; then
    mkdir ${version}/oci8
  fi
  render Dockerfile-oci8.template > $version/oci8/Dockerfile
  ## https://php.watch/versions/8.0/xmlrpc
  if [ "$version" = "8.0" ]; then
    sed -i "s/php\$PHP_VERSION-json/php-json/g" $version/Dockerfile
    sed -i "s/php\$PHP_VERSION-xmlrpc//g" $version/Dockerfile
  fi
done
