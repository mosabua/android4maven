#! /bin/bash  

#
# This script builds the android.jar / sdk using Google tools, then extracts the source code required to 
# build the maven artifact, and places it into several newly created maven projects. 
#


export droidFolder=/home/manningr/mydroid

# android-3
export branchtag=android-1.5r3
# android-4
#export branchtag=android-1.6_r2
# android-6
#export branchtag=android-2.0.1_r1
# android-7
#export branchtag=android-2.1_r1

export projectsFolder=`pwd`/target
export androidProjectFolder=$projectsFolder/android-$branchtag
export junitProjectFolder=$projectsFolder/android-junit-$branchtag
export khronosProjectFolder=$projectsFolder/khronos-$branchtag
export androidTestProjectFolder=$projectsFolder/android-test-$branchtag
export droidOutFolder=$droidFolder/out
export androidSrcFolder=$androidProjectFolder/src/main/java
export androidResourcesFolder=$androidProjectFolder/src/main/resources
export junitSrcFolder=$junitProjectFolder/src/main/java
export junitResourcesFolder=$junitProjectFolder/src/main/resources
export khronosSrcFolder=$khronosProjectFolder/src/main/java
export androidTestSrcFolder=$androidTestProjectFolder/src/main/java

export droidSrcFolder=$droidFolder/out/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/src
export androidPomfile=`pwd`/android-pom.xml
export junitPomFile=`pwd`/junit-pom.xml
export khronosPomFile=`pwd`/khronos-pom.xml
export androidTestPomFile=`pwd`/android-test-pom.xml

echo "Removing $projectsFolder"
rm -rf $projectsFolder

echo "Setting up Android Maven project folders"
mkdir -p $androidSrcFolder
mkdir -p $androidResourcesFolder


echo "Setting up Android Test Maven project folders"
mkdir -p $androidTestSrcFolder/android


echo "Setting up Android-JUnit Maven project folders"
mkdir -p $junitSrcFolder
mkdir -p $junitResourcesFolder

echo "Setting up Javax-Crypto Maven project folder"
mkdir -p $khronosSrcFolder/javax


if [ "$1" != "-skipCompile" ]; then
	cd $droidFolder
        rm -rf out
	. ./build/envsetup.sh
	#repo forall -c git checkout $branchtag
	export fileToPatch=$droidFolder/build/core/base_rules.mk
	export needToPatch=`grep '^$(error' $fileToPatch | wc -l`

	if [ $needToPatch -eq 1 ]; then
		if [ ! -e $fileToPatch.bak ]; then
			timestamp=`date '+%Y%m%d-%k%M%S'`
			echo "Backing up $fileToPatch to $fileToPatch.$timestamp"
			cp $fileToPatch $fileToPatch.$timestamp
		fi
		echo "Applying patch to $fileToPatch" 
		perl -pi -e 's/^\$\(error/\#\$\(error/' $fileToPatch
	fi

	mm sdk
else
    echo "Rebuilding tag=$branchtag"
fi;



echo "Copying source files from $androidSrcFolder"
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

#cp -r $droidSrcFolder/javax/crypto $cryptoSrcFolder/javax
#cp -r $droidSrcFolder/org $androidSrcFolder
#rm -rf $androidSrcFolder/org/apache/commons/logging
#rm -rf $androidSrcFolder/org/apache/http
#rm -rf $androidSrcFolder/org/w3c
#rm -rf $androidSrcFolder/org/xml
#rm -rf $androidSrcFolder/org/xmlpull

echo "Copying resources files"
cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/res $androidResourcesFolder
rm -rf $androidResourcesFolder/res/raw-ar
rm -rf $androidResourcesFolder/res/raw-da
rm -rf $androidResourcesFolder/res/raw-fi
rm -rf $androidResourcesFolder/res/raw-hu
rm -rf $androidResourcesFolder/res/raw-iw
rm -rf $androidResourcesFolder/res/raw-pt-BR
rm -rf $androidResourcesFolder/res/raw-th
rm -rf $androidResourcesFolder/res/raw-tr

cp -r $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/assets $androidResourcesFolder
cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/resources.arsc $androidResourcesFolder

platform=`ls $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms`
cp -r $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms/"$platform"/data/res/drawable-hdpi $androidResourcesFolder/res
cp -r $droidOutFolder/host/linux-x86/sdk/android-sdk_eng."$USERNAME"_linux-x86/platforms/"$platform"/data/res/drawable-land-hdpi $androidResourcesFolder/res
cp $droidOutFolder/target/common/obj/JAVA_LIBRARIES/android_stubs_current_intermediates/classes/AndroidManifest.xml $androidResourcesFolder

echo "Copying in pom files ($androidPomfile and $junitPomFile)"
cp $androidPomfile $androidProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$branchtag/" $androidProjectFolder/pom.xml

cp $junitPomFile $junitProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$branchtag/" $junitProjectFolder/pom.xml

cp $khronosPomFile $khronosProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$branchtag/" $khronosProjectFolder/pom.xml

cp $androidTestPomFile $androidTestProjectFolder/pom.xml
perl -pi -e "s/\@VERSION\@/$branchtag/" $androidTestProjectFolder/pom.xml

cd $junitProjectFolder
mvn clean install

cd $khronosProjectFolder
mvn clean install

cd $androidProjectFolder
mvn clean install

cd $androidTestProjectFolder
mvn clean install
