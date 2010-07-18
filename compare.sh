#! /bin/bash 

# This script uses diff to compare the file entries in the SDK android.jar with the file
# entries in the built using Maven android jar file.  This script now ignores differences in
# image files (*.png).

# android-3
#export branchtag=android-1.5r3
#export platform=android-3

# android-4
#export branchtag=android-1.6_r2
#export platform=android-4

# android-6
#export branchtag=android-2.0.1_r1
#export platform=android-6
 
# android-7
#export branchtag=android-2.1_r2
#export platform=android-7

# android-8
export pomVersion=2.1.2
export branchtag=android-2.1_r2
export platform=android-7



sdkJar=/opt/android-sdk-linux_86/platforms/$platform/android.jar
sdkJarContents=$sdkJar.extracted

if [ ! -d "$sdkJarContents" ]; then
	mkdir android.jar.extracted
    	cd ./android.jar.extracted
        jar -xvf $sdkJar
	cd ..
	mv android.jar.extracted "$sdkJarContents"
fi

rm -rf /tmp/android.jar.extracted
rm -rf /tmp/android-impl.jar.extracted

mkdir  /tmp/android.jar.extracted
mkdir  /tmp/android-impl.jar.extracted

cp ./target-$pomVersion/android-$branchtag/target/android-$pomVersion.jar /tmp/android.jar
cp ./target-$pomVersion/android-impl-$branchtag/target/android-impl-$pomVersion.jar /tmp/android-impl.jar

cd  /tmp/android.jar.extracted
jar -xvf /tmp/android.jar

cd  /tmp/android-impl.jar.extracted
jar -xvf /tmp/android-impl.jar


diff -r $sdkJarContents /tmp/android.jar.extracted | grep -v .png > /tmp/sdk-diffs.lst
diff -r $sdkJarContents /tmp/android-impl.jar.extracted | grep -v .png > /tmp/impl-diffs.lst

gedit /tmp/sdk-diffs.lst &
gedit /tmp/impl-diffs.lst &




