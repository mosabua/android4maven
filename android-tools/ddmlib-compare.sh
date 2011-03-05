#!/bin/bash

# CONFIGURATION

# sadly, there is no way to get older SDK Tools libraries, so we can only compare with those installed
# (which are likely to be the newest, r10 at the time of this writing)
pomVersion=r10
installedSdkLocation=/home/ladicek/work/android-sdk-linux_x86

# PATHS

myDir=`readlink -f $(dirname $0)`
originalDdmlibJar=$installedSdkLocation/tools/lib/ddmlib.jar
originalDdmlibJarExtracted=$myDir/original-ddmlib-extracted
assembledDdmlibJar=$myDir/project-ddmlib-$pomVersion/target/ddmlib-$pomVersion.jar
assembledDdmlibJarExtracted=$myDir/assembled-ddmlib-extracted

diffList=diff.list

# REAL WORK

rm -rf $originalDdmlibJarExtracted
mkdir $originalDdmlibJarExtracted
cd $originalDdmlibJarExtracted
jar -xf $originalDdmlibJar
cd $myDir

rm -rf $assembledDdmlibJarExtracted
mkdir $assembledDdmlibJarExtracted
cd $assembledDdmlibJarExtracted
jar -xf $assembledDdmlibJar
cd $myDir

diff -r $originalDdmlibJarExtracted $assembledDdmlibJarExtracted > $diffList

rm -rf $originalDdmlibJarExtracted
rm -rf $assembledDdmlibJarExtracted
