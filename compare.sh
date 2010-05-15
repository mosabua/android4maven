#! /bin/bash 

# This script uses diff to compare the file entries in the SDK android.jar with the file
# entries in the built using Maven android jar file.  This script now ignores differences in
# image files (*.png).

sdkJarContents=/opt/android-sdk-linux_86/platforms/android-7/android.jar.extracted

rm -rf /tmp/android.jar.extracted
mkdir  /tmp/android.jar.extracted
cp ./target/android-android-2.1_r1/target/android-android-2.1_r1.jar /tmp/android.jar
cd  /tmp/android.jar.extracted
jar -xvf /tmp/android.jar

diff -r $sdkJarContents /tmp/android.jar.extracted | grep -v .png > /tmp/diffs.lst
gedit /tmp/diffs.lst &
