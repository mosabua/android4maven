#! /bin/bash

#
# This script builds the android.jar / sdk using Google tools, then extracts the source code required to 
# build the maven artifact, and places it into a newly created maven project.  This will remove the 
# mavenProjectFolder, so don't set it to something you want to keep.
#

droidFolder=/home/manningr/mydroid
mavenProjectFolder=/home/manningr/projects/android-2.1_r1
export branchtag=android-2.1_r1

droidOutFolder=/home/manningr/mydroid/out
mavenSrcFolder=$mavenProjectFolder/src/main/java
mavenResourcesFolder=$mavenProjectFolder/src/main/resources
mavenTestSrcFolder=$mavenProjectFolder/src/test/java
droidSrcFolder=$droidFolder/out/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/src
pomfile=`pwd`/pom.xml

echo "Removing $mavenProjectFolder"
rm -rf $mavenProjectFolder
mkdir -p $mavenSrcFolder
mkdir -p $mavenResourcesFolder
mkdir -p $mavenTestSrcFolder/android


fileToPatch=$droidFolder/build/core/base_rules.mk
needToPatch=`grep '^$(error' $fileToPatch | wc -l`

if [ $needToPatch -eq 1 ]; then
	if [ ! -e $fileToPatch.bak ]; then
		timestamp=`date '+%Y%m%d-%k%M%S'`
		echo "Backing up $fileToPatch to $fileToPatch.$timestamp"
		cp $fileToPatch $fileToPatch.$timestamp
	fi
	echo "Applying patch to $fileToPatch" 
	perl -pi -e 's/^\$\(error/\#\$\(error/' $fileToPatch
fi

cd $droidFolder
 . ./build/envsetup.sh
repo forall -c git checkout $branchtag
mm sdk

echo "Copying source files"
cp -r $droidSrcFolder/android $mavenSrcFolder
cp -r $droidSrcFolder/android/test $mavenTestSrcFolder/android
cp -r $droidSrcFolder/com $mavenSrcFolder
cp -r $droidSrcFolder/dalvik $mavenSrcFolder
cp -r $droidSrcFolder/java $mavenSrcFolder
cp -r $droidSrcFolder/javax $mavenSrcFolder
cp -r $droidSrcFolder/org $mavenSrcFolder

echo "Copying resources files"
cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/res $mavenResourcesFolder
rm -rf $mavenResourcesFolder/res/raw-ar
rm -rf $mavenResourcesFolder/res/raw-da
rm -rf $mavenResourcesFolder/res/raw-fi
rm -rf $mavenResourcesFolder/res/raw-hu
rm -rf $mavenResourcesFolder/res/raw-iw
rm -rf $mavenResourcesFolder/res/raw-pt-BR
rm -rf $mavenResourcesFolder/res/raw-th
rm -rf $mavenResourcesFolder/res/raw-tr

cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/assets $mavenResourcesFolder
cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/resources.arsc $mavenResourcesFolder

platform=`ls $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms`
cp -r $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms/"$platform"/data/res/drawable-hdpi $mavenResourcesFolder/res
cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/AndroidManifest.xml $mavenResourcesFolder

echo "Copying pom file ($pomfile) to $mavenProjectFolder"
cp $pomfile $mavenProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$branchtag/" $mavenProjectFolder/pom.xml

cd $mavenProjectFolder
mvn clean install

