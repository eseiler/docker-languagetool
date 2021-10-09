#!/bin/bash

####################
##    Preamble    ##
####################
# Exit when any command fails.
set -e
# Only execute on the arm64 architecture.
if [[ $(dpkg --print-architecture) != "arm64" ]]; then
    exit;
fi
# Make `wget` more robust by passing retry flags.
alias wget="wget --retry-connrefused --waitretry=30 --read-timeout=30 --timeout=30 --tries=20"
# Set java environment.
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-arm64"

# Install dependencies.
apt-get install --yes build-essential \
                      mercurial \
                      wget \
                      zip
apt-get clean

####################
##  BridJ setup   ##
####################
while ! git clone --depth 1 https://github.com/nativelibs4java/BridJ /BridJ; do sleep 5; done
cd /BridJ
git apply ../bridj.patch
wget https://dyncall.org/r1.1/dyncall-1.1.tar.gz
tar xf dyncall-1.1.tar.gz
rm dyncall-1.1.tar.gz
mv dyncall-1.1 dyncall
cd /BridJ/dyncall
hg init

####################
##  BridJ build   ##
####################
cd /BridJ
./BuildNative
mvn clean install -DskipTests -Dmaven.install.skip=true -e

####################
## Postprocessing ##
####################
cd /BridJ/target
mv bridj-0.7.1-SNAPSHOT.jar bridj.jar
# Extract desired `libbridj.so`. Will create the directory tree, too.
unzip bridj.jar org/bridj/lib/linux_aarch64/libbridj.so
# We do not need the `linux_aarch64` folder
zip -d bridj.jar org/bridj/lib/linux_aarch64
# Rename the extracted folder to `linux_x64`.
mv org/bridj/lib/linux_aarch64 org/bridj/lib/linux_x64
# Replace the `libbridj.so` inside the jar with the arm64 one.
zip bridj.jar org/bridj/lib/linux_x64/libbridj.so

mv bridj.jar /dist/LanguageTool/libs/bridj.jar