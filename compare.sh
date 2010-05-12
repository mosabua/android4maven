#! /bin/bash 

# This script uses diff to compare the file entries in the SDK android.jar with the file
# entries in the built using Maven android jar file.

rm -rf /tmp/android2.jar.extracted
mkdir  /tmp/android2.jar.extracted
cd  /tmp/android2.jar.extracted
jar -xvf /home/manningr/projects/android-2.1_r1/target/android-android-2.1_r1.jar
diff -r /opt/android-sdk-linux_86/platforms/android-7/android.jar.extracted /tmp/android2.jar.extracted > /tmp/diffs.lst
gedit /tmp/diffs.lst &
