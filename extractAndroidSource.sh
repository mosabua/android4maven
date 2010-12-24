#! /bin/bash  

# Author: Rob Manning 
# Last Modified: 12/20/2010
#
# A little documentation:
#
# This script builds the android.jar / sdk using Google tools, then extracts the source code required to 
# build the maven artifact, and places it into several newly created maven projects. It supports one
# optional argument: "-skipCompile".  When "-skipCompile" is given as an argument, this script will not
# attempt to build android (which can take hours), but assumes it has already been built and proceeds
# to collect the source and resource files from the droidFolder tree.
#
# This script produces two versions of the android sdk jar.  One version is identical to the actual 
# android sdk jar that is distributed with the SDK.  This artifact has mainly stubbed out methods that
# simply throw RuntimeExceptions with the text "Stub!".  For compilation purposes this is adequate but
# hardly enough to a runtime environment.  So, there is an attempt to provide an "impl" version using 
# the source code that is sprinkled throughout the source tree.  However, in order to get this version
# to compile, many "patched" versions of third-party libraries have been integrated into the source 
# tree (Apache Harmony, Apache Commons, Apache HttpClient, Sun Java runtime, etc.)  
# This is unfortunate, since it means that the only place where this source can be compiled is
# within the android source tree.  This also means that as long as this code is reliant on internal 
# patched versions of third-party libraries, this artifact cannot be made available on Maven Central 
# since all artifacts deployed there must only refer to other artifacts available there as well.  And
# since these Google-patched versions are unlikely to make their way back upstream to the originating
# projects, it is unlikely that this version of the jar will ever make it into Maven Central.
#
# 
#

# Begin Configuration

# branchtag is the tag that was used during git sync.  Ideally, there will be a directory in the user's
# home directory that contains the result of the git sync and is named according to the branch tag with
# the form of "mydroid-$branchtag".
#
# The key tags by platform (see source.properties in the Android SDK) are:
#
#    Platform    Branch Tag         Release Name
#    =========   ==========       ================
#    android-3 : android-1.5_r4
#    android-4 : android-1.6_r2       cupcake
#    android-6 : android-2.0.1_r1
#    android-7 : android-2.1_r1        eclair
#    android-8 : android-2.2_r1.1      froyo
#    android-9	: android-2.3_r1     gingerbread
#
# Release name is the dessert-themed label that Google decided to market their releases under.
#
export releasename=gingerbread
export androidplatform=android-9
export branchtag=android-2.3_r1


# It was difficult to reconcile what the engineers at Google thought made great branch tags and 
# the version that users of Maven Central would be able to understand.  In the end we decided on
# the following scheme:
# 
# <-------- Google's choice ------->.<--Our Choice-->
# majorversion.minorversion.revision.packagingversion
#
# So, for branch tag android-2.3_r1, we would use 2.3.1.  If we have to release another artifact
# before Google issues another release we would use 2.3.1.1.  If Google then decides to release 
# something called android-2.3_r1.1, we increment our packagingversion (i.e. 2.3.1.2).
# If then Google decides to release android-2.3_r2, then we go with 2.3.2.  Yea, it's not
# perfect, but compromises never are.
#
export pomVersion=2.3.1

# Where was the android repo created and sync'd
export droidFolder=/home/manningr/mydroid-$branchtag

export projectsFolder=`pwd`/target-$pomVersion
export androidProjectFolder=$projectsFolder/android-$pomVersion
export androidImplProjectFolder=$projectsFolder/android-impl-$pomVersion
export junitProjectFolder=$projectsFolder/android-junit-$pomVersion
export khronosProjectFolder=$projectsFolder/khronos-$pomVersion
export androidTestProjectFolder=$projectsFolder/android-test-$pomVersion
export androidTestImplProjectFolder=$projectsFolder/android-test-impl-$pomVersion
export droidOutFolder=$droidFolder/out
export androidSrcFolder=$androidProjectFolder/src/main/java
export androidResourcesFolder=$androidProjectFolder/src/main/resources
export androidImplSrcFolder=$androidImplProjectFolder/src/main/java
export androidImplResourcesFolder=$androidImplProjectFolder/src/main/resources
export junitSrcFolder=$junitProjectFolder/src/main/java
export junitResourcesFolder=$junitProjectFolder/src/main/resources
export khronosSrcFolder=$khronosProjectFolder/src/main/java
export androidTestSrcFolder=$androidTestProjectFolder/src/main/java
export androidTestImplSrcFolder=$androidTestImplProjectFolder/src/main/java

export droidSrcFolder=$droidFolder/out/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/src
export frameworkOutFolder=$droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src
export androidPomfile=`pwd`/android-pom.xml
export junitPomFile=`pwd`/junit-pom.xml
export khronosPomFile=`pwd`/khronos-pom.xml
export androidTestPomFile=`pwd`/android-test-pom.xml
export androidImplPomfile=`pwd`/android-impl-pom.xml


function copyResources {
	resourcesFolder=$1
	echo "Copying resources files to $resourcesFolder"
	cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/res $resourcesFolder
	cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/assets $resourcesFolder
	cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/resources.arsc $resourcesFolder

	platform=`ls $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms`
	cp -r $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms/"$platform"/data/res/drawable-hdpi $resourcesFolder/res
	cp -r $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms/"$platform"/data/res/drawable-land-hdpi $resourcesFolder/res
	cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/AndroidManifest.xml $resourcesFolder

	mkdir -p $resourcesFolder/res/drawable-en-hdpi
	cp $droidFolder/frameworks/base/core/res/res/drawable-en-hdpi/* $resourcesFolder/res/drawable-en-hdpi/
}


# BEGIN

echo "Removing $projectsFolder"
rm -rf $projectsFolder

echo "Setting up Android Maven project folders"
mkdir -p $androidSrcFolder
mkdir -p $androidResourcesFolder

echo "Setting up Android Implementation Maven project folders"
mkdir -p $androidImplSrcFolder
mkdir -p $androidImplResourcesFolder


echo "Setting up Android Test Maven project folders"
mkdir -p $androidTestSrcFolder/android

echo "Setting up Android Test Implementation Maven project folders"
mkdir -p $androidTestImplSrcFolder/android


echo "Setting up Android-JUnit Maven project folders"
mkdir -p $junitSrcFolder
mkdir -p $junitResourcesFolder

echo "Setting up Javax-Crypto Maven project folder"
mkdir -p $khronosSrcFolder/javax


if [ "$1" != "-skipCompile" ]; then
	cd $droidFolder
        rm -rf out
	. ./build/envsetup.sh
	mm sdk
else
    echo "Rebuilding tag=$branchtag"
fi;



echo "Copying source files to $androidSrcFolder"
cp -r $droidSrcFolder/android $androidSrcFolder
rm -rf $androidSrcFolder/android/test
cp -r $droidSrcFolder/android/test $androidTestSrcFolder/android
cp -r $droidSrcFolder/com $androidSrcFolder
cp -r $droidSrcFolder/dalvik $androidSrcFolder
cp -r $droidSrcFolder/junit $junitSrcFolder

# At some point these should also be split out like JUnit.
#cp -r $droidSrcFolder/java $androidSrcFolder
#cp -r $droidSrcFolder/javax $androidSrcFolder
# These packages are included in the JDK
rm -rf $androidSrcFolder/javax/crypto
rm -rf $androidSrcFolder/javax/microedition
rm -rf $androidSrcFolder/javax/net
rm -rf $androidSrcFolder/javax/sql
rm -rf $androidSrcFolder/javax/security
rm -rf $androidSrcFolder/javax/xml

cp -r $droidSrcFolder/javax/microedition $khronosSrcFolder/javax

# Android Impl (For now, just trying to get a build that compiles - there are many 3rd-party sources being included)
cp -r $droidFolder/frameworks/base/core/java/* $androidImplSrcFolder/
rm -rf $androidImplSrcFolder/com/android/os
cp -r $droidFolder/frameworks/base/core/config/sdk/* $androidImplSrcFolder/
#cp -r $droidFolder/frameworks/base/core/java/android $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/graphics/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/keystore/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/location/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/media/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/sax/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/telephony/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/wifi/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/voip/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/location/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/ex/common/java/* $androidImplSrcFolder/

cp -r $droidFolder/packages/apps/QuickSearchBox/src/* $androidImplSrcFolder/
cp $droidFolder/out/target/common/R/com/android/quicksearchbox/R.java $androidImplSrcFolder/com/android/quicksearchbox

# android.* (auto-generated interfaces) and com.android.internal.*
cp -r $frameworkOutFolder/core/java/* $androidImplSrcFolder/

# android.net.sip.*
cp -r $frameworkOutFolder/voip/java/* $androidImplSrcFolder/

# com.ibm.icu4jni.util
cp -r $droidFolder/dalvik/libcore/icu/src/main/java/com $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/luni-kernel/src/main/java/* $androidImplSrcFolder/
# java.text
cp -r $droidFolder/dalvik/libcore/text/src/main/java/* $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/x-net/src/main/java/org $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/xml/src/main/java/org/apache $androidImplSrcFolder/org/
cp -r $droidFolder/dalvik/libcore/xml/src/main/java/org/kxml2 $androidImplSrcFolder/org/
# Google's org.w3c.dom.Node doesn't have an abstract getUserData; Java 1.5 ships a org.w3c.dom.Node that does.  
cp -r $droidFolder/libcore/luni/src/main/java/com $androidImplSrcFolder/
cp -r $droidFolder/libcore/luni/src/main/java/java $androidImplSrcFolder/
cp -r $droidFolder/libcore/luni/src/main/java/org $androidImplSrcFolder/

# libcore.*
cp -r $droidFolder/libcore/luni/src/main/java/libcore $androidImplSrcFolder/

# org.kxml2.io.* (Google's org.kxml2.io.KXmlParser has keepNamespaceAttributes method that doesn't appear in 
# net.sf.kxml:kxml2:*
cp -r $droidFolder/libcore/xml/src/main/java/org $androidImplSrcFolder/


# Patched version of Java API classes 
cp -r $droidFolder/dalvik/libcore/luni/src/main/java/java $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/nio/src/main/java/* $androidImplSrcFolder/

cp -r $droidFolder/libcore/dalvik/src/main/java/* $androidImplSrcFolder/

mkdir -p $androidImplSrcFolder/com/android/internal
cp -r $droidFolder/out/target/common/R/com/android/internal/R.java $androidImplSrcFolder/com/android/internal

cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/telephony/java/com $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/location/java/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/media/java/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/wifi/java/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/APPS/QuickSearchBox_intermediates/src/src/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/APPS/framework-res_intermediates/src/android $androidImplSrcFolder/

# This is org.apache.harmony and org.bouncycastle which appear to be patched versions of the same
cp -r $droidFolder/external/bouncycastle/src/main/java/org $androidImplSrcFolder/

# This is org.apache.http which is a patched version of httpcomponents 4.0-beta1
cp -r $droidFolder/external/apache-http/src/org $androidImplSrcFolder/

cp -r $droidFolder/external/gdata/src/* $androidImplSrcFolder/

cp -r $droidFolder/external/guava/src/* $androidImplSrcFolder/

# javax.annotation.*
cp -r $droidFolder/external/jsr305/ri/src/main/java/* $androidImplSrcFolder/

# javax.sip.*
cp -r $droidFolder/external/nist-sip/java/javax $androidImplSrcFolder/

# gov.nist.javax.sip.*
cp -r $droidFolder/external/nist-sip/java/gov $androidImplSrcFolder/

find $androidImplSrcFolder -name "*.aidl" | xargs rm 
find $androidImplSrcFolder -name "*.P" | xargs rm 

echo "Copying resources files to android"
copyResources $androidResourcesFolder
copyResources $androidImplResourcesFolder

echo "Copying in pom files ($androidPomfile and $junitPomFile)"
cp $androidPomfile $androidProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $androidProjectFolder/pom.xml
perl -pi -e "s/\@RELEASENAME\@/$releasename/" $androidProjectFolder/pom.xml
perl -pi -e "s/\@PLATFORM\@/$androidplatform/" $androidProjectFolder/pom.xml
perl -pi -e "s/\@BRANCHTAG\@/$branchtag/" $androidProjectFolder/pom.xml

cp $androidTestPomFile $androidTestProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $androidTestProjectFolder/pom.xml
perl -pi -e "s/\@RELEASENAME\@/$releasename/" $androidTestProjectFolder/pom.xml
perl -pi -e "s/\@PLATFORM\@/$androidplatform/" $androidTestProjectFolder/pom.xml
perl -pi -e "s/\@BRANCHTAG\@/$branchtag/" $androidTestProjectFolder/pom.xml

cp $androidImplPomfile $androidImplProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $androidImplProjectFolder/pom.xml
perl -pi -e "s/\@RELEASENAME\@/$releasename/" $androidImplProjectFolder/pom.xml
perl -pi -e "s/\@PLATFORM\@/$androidplatform/" $androidImplProjectFolder/pom.xml
perl -pi -e "s/\@BRANCHTAG\@/$branchtag/" $androidImplProjectFolder/pom.xml

cp $junitPomFile $junitProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $junitProjectFolder/pom.xml
perl -pi -e "s/\@RELEASENAME\@/$releasename/" $junitProjectFolder/pom.xml
perl -pi -e "s/\@PLATFORM\@/$androidplatform/" $junitProjectFolder/pom.xml
perl -pi -e "s/\@BRANCHTAG\@/$branchtag/" $junitProjectFolder/pom.xml

cp $khronosPomFile $khronosProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $khronosProjectFolder/pom.xml
perl -pi -e "s/\@RELEASENAME\@/$releasename/" $khronosProjectFolder/pom.xml
perl -pi -e "s/\@PLATFORM\@/$androidplatform/" $khronosProjectFolder/pom.xml
perl -pi -e "s/\@BRANCHTAG\@/$branchtag/" $khronosProjectFolder/pom.xml


cd $junitProjectFolder
mvn clean install

cd $khronosProjectFolder
mvn clean install

cd $androidProjectFolder
mvn clean install

cd $androidTestProjectFolder
mvn clean install

cd $androidImplProjectFolder
mvn clean install
