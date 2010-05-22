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
export branchtag=android-2.1_r1
export platform=android-7


sdkJarContents=/opt/android-sdk-linux_86/platforms/$platform/android.jar.extracted

rm -rf /tmp/android.jar.extracted
mkdir  /tmp/android.jar.extracted
cp ./target/android-$branchtag/target/android-$branchtag.jar /tmp/android.jar
cd  /tmp/android.jar.extracted
jar -xvf /tmp/android.jar

diff -r $sdkJarContents /tmp/android.jar.extracted | grep -v .png > /tmp/diffs.lst
gedit /tmp/diffs.lst &
