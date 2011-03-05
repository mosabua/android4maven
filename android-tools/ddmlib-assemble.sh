#!/bin/bash

# CONFIGURATION

pomVersion=r10

mydroidLocation=/home/ladicek/work/mydroid-mvn

# PATHS

myDir=`readlink -f $(dirname $0)`                       # dir with this script
sdkLocation=$mydroidLocation/sdk                        # SDK in AOSP source
ddmlibLocation=$sdkLocation/ddms/libs/ddmlib/           # ddmlib in the SDK
pomLocation=$myDir/ddmlib-pom.xml                       # POM template
projectRoot=$myDir/project-ddmlib-$pomVersion           # Maven project (to be created)
projectSrc=$projectRoot/src/main/java
projectTest=$projectRoot/src/test/java

# REAL WORK

gitBranch="tools_$pomVersion"

echo "Checking out $gitBranch"
cd $sdkLocation
git checkout --quiet korg/$gitBranch
cd $myDir

echo "Removing $projectRoot"
rm -rf $projectRoot

echo "Setting up Maven project structure"
mkdir -p $projectSrc
mkdir -p $projectTest

echo "Copying source files to $projectSrc"
cp -r $ddmlibLocation/src/com $projectSrc

echo "Copying test files to $projectTest"
cp -r $ddmlibLocation/tests/src/com $projectTest

gitCommit=`git --git-dir=$sdkLocation/.git rev-parse HEAD`

echo "Copying in pom file ($pomLocation)"
cp $pomLocation $projectRoot/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $projectRoot/pom.xml
perl -pi -e "s/\@GIT_BRANCH\@/$gitBranch/" $projectRoot/pom.xml
perl -pi -e "s/\@GIT_COMMIT\@/$gitCommit/" $projectRoot/pom.xml

cd $projectRoot
mvn clean install
#mvn clean source:jar javadoc:jar package repository:bundle-create
