#! /bin/bash  

#
# This script builds the android.jar / sdk using Google tools, then extracts the source code required to 
# build the maven artifact, and places it into several newly created maven projects. It supports one
# optional argument: "-skipCompile".  When "-skipCompile" is given as an argument, this script will not
# attempt to build android (which can take hours), but assumes it has already been built and proceeds
# to collect the source and resource files from the droidFolder tree.
#


# This is the only version that needs to be manually set, based on the tag that was used during git sync
# The key tags by platform (see source.properties in the Android SDK) are:
#
#    android-3 : 1.5_r4
#    android-4 : 1.6_r2
#    android-6 : 2.0.1_r1
#    android-7 : 2.1_r1
export pomVersion=2.2_r1.1

# Where was the android repo created and sync'd
export droidFolder=/home/manningr/mydroid-$pomVersion

export branchVersion=$pomVersion
export isOneDotFive=`echo pomVersion | grep 1.5 | wc -l`

# Google is a bit inconsistent with their git repo tags, so here we remove the "_", but 
# only if the branch version was a "1.5" release. All others follow a convention which 
# places and underscore (_) between the major version and what is presumably the 
# maintenance release number.  In any case, we want the pom version to have an underscore 
# between the major version (e.g. 1.5) and the maintenance release (r4)
if [ $isOneDotFive = "1" ]; then
	$branchVersion=`echo 1.5_r4 | sed s/_//`
fi

export branchtag=android-$branchVersion

export projectsFolder=`pwd`/target-$pomVersion
export androidProjectFolder=$projectsFolder/android-$branchtag
export androidImplProjectFolder=$projectsFolder/android-impl-$branchtag
export junitProjectFolder=$projectsFolder/android-junit-$branchtag
export khronosProjectFolder=$projectsFolder/khronos-$branchtag
export androidTestProjectFolder=$projectsFolder/android-test-$branchtag
export androidTestImplProjectFolder=$projectsFolder/android-test-impl-$branchtag
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
export androidPomfile=`pwd`/android-pom.xml
export junitPomFile=`pwd`/junit-pom.xml
export khronosPomFile=`pwd`/khronos-pom.xml
export androidTestPomFile=`pwd`/android-test-pom.xml
export androidImplPomfile=`pwd`/android-impl-pom.xml


function copyResources {
	resourcesFolder=$1
	echo "Copying resources files to $resourcesFolder"
	cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/res $resourcesFolder
	rm -rf $resourcesFolder/res/raw-ar
	rm -rf $resourcesFolder/res/raw-da
	rm -rf $resourcesFolder/res/raw-fi
	rm -rf $resourcesFolder/res/raw-hu
	rm -rf $resourcesFolder/res/raw-iw
	rm -rf $resourcesFolder/res/raw-pt-BR
	rm -rf $resourcesFolder/res/raw-th
	rm -rf $resourcesFolder/res/raw-tr

	cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/assets $resourcesFolder
	cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/resources.arsc $resourcesFolder

	platform=`ls $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms`
	cp -r $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms/"$platform"/data/res/drawable-hdpi $resourcesFolder/res
	cp -r $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms/"$platform"/data/res/drawable-land-hdpi $resourcesFolder/res
	cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/AndroidManifest.xml $resourcesFolder
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
cp -r $droidFolder/frameworks/base/common/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/core/config/sdk/* $androidImplSrcFolder/
#cp -r $droidFolder/frameworks/base/core/java/android $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/graphics/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/keystore/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/location/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/media/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/sax/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/telephony/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/wifi/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/base/location/java/* $androidImplSrcFolder/
cp -r $droidFolder/frameworks/ex/common/java/* $androidImplSrcFolder/

cp -r $droidFolder/packages/apps/QuickSearchBox/src/* $androidImplSrcFolder/
cp $droidFolder/out/target/common/R/com/android/quicksearchbox/R.java $androidImplSrcFolder/com/android/quicksearchbox


cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/core/java/* $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/dalvik/src/main/java/org $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/dalvik/src/main/java/dalvik $androidImplSrcFolder/
# com.ibm.icu4jni.util
cp -r $droidFolder/dalvik/libcore/icu/src/main/java/com $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/luni-kernel/src/main/java/* $androidImplSrcFolder/
# java.text
cp -r $droidFolder/dalvik/libcore/text/src/main/java/* $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/x-net/src/main/java/org $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/xml/src/main/java/org/apache $androidImplSrcFolder/org/
cp -r $droidFolder/dalvik/libcore/xml/src/main/java/org/kxml2 $androidImplSrcFolder/org/
# Google's org.w3c.dom.Node doesn't have an abstract getUserData; Java 1.5 ships a org.w3c.dom.Node that does.  
cp -r $droidFolder/dalvik/libcore/xml/src/main/java/org/w3c $androidImplSrcFolder/org/
cp -r $droidFolder/dalvik/libcore/luni/src/main/java/org $androidImplSrcFolder/
# Patched version of Java API classes 
cp -r $droidFolder/dalvik/libcore/luni/src/main/java/java $androidImplSrcFolder/
cp -r $droidFolder/dalvik/libcore/nio/src/main/java/* $androidImplSrcFolder/

mkdir -p $androidImplSrcFolder/com/android/internal
cp -r $droidFolder/out/target/common/R/com/android/internal/R.java $androidImplSrcFolder/com/android/internal

cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/telephony/java/com $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/location/java/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/media/java/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/JAVA_LIBRARIES/framework_intermediates/src/wifi/java/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/APPS/QuickSearchBox_intermediates/src/src/* $androidImplSrcFolder/
cp -r $droidFolder/out/target/common/obj/APPS/framework-res_intermediates/src/android $androidImplSrcFolder/

# This is org.apache.harmony and org.bouncycastle which appear to be patched versions of the same
cp -r $droidFolder/dalvik/libcore/security/src/main/java/org $androidImplSrcFolder/

# This is org.apache.http which is a patched version of httpcomponents 4.0-beta1
cp -r $droidFolder/external/apache-http/src/org $androidImplSrcFolder/

cp -r $droidFolder/external/gdata/src/* $androidImplSrcFolder/

cp -r $droidFolder/external/guava/src/* $androidImplSrcFolder/

# This is javax.annotation
cp -r $droidFolder/external/jsr305/ri/src/main/java/* $androidImplSrcFolder/

find $androidImplSrcFolder -name "*.aidl" | xargs rm 
find $androidImplSrcFolder -name "*.P" | xargs rm 

echo "Copying resources files to android"
copyResources $androidResourcesFolder
copyResources $androidImplResourcesFolder

echo "Copying in pom files ($androidPomfile and $junitPomFile)"
cp $androidPomfile $androidProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $androidProjectFolder/pom.xml

cp $androidTestPomFile $androidTestProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $androidTestProjectFolder/pom.xml

cp $androidImplPomfile $androidImplProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $androidImplProjectFolder/pom.xml


cp $junitPomFile $junitProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $junitProjectFolder/pom.xml

cp $khronosPomFile $khronosProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$pomVersion/" $khronosProjectFolder/pom.xml


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
