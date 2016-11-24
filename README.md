# jenkins-dl
Downloader for Jenkins build artifacts.

A simple script for downloading Jenkins build artifacts. It is preconfigured
to download the F-Droid build of Riot Android.

## When do I need this?
* You are testing the bleeding edge and want to easily switch between
  builds. No more fussing or manually renaming, downloads are
  systematically named with build number and commit hash.
* You are on a slow line and your download keeps aborting or
  becomes corrupt.
* Jenkins is having a bad day and you absolutely *must* have that
  *one* build.

## Features
* Give the file a useful name with build number and commit hash
* Auto-resume with workaround for Jenkins bug
* Check integrity with md5

## Configuration
Edit the variables in the script.

Set `FLAVOUR` to `vector-app-debug` to download the Play Store
version.

## Dependencies
* awk
* wget
