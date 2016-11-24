# jenkins-dl
Downloader for Jenkins build artifacts.

A simple script for downloading Jenkins build artifacts. It is preconfigured
to download the F-Droid build of Riot Android.

## Features
* Give the file a useful name with build number and commit hash

## Configuration
Edit the variables in the script.

Set `FLAVOUR` to `vector-app-debug` to download the Play Store
version.

## Dependencies
* awk
* wget
