#!/bin/sh

# Configuration

JOBROOT="https://matrix.org/jenkins/job/VectorAndroidDevelop"
FLAVOUR=vector-appfdroid-debug
EXT="apk"
FILE="$FLAVOUR.$EXT"
FILEPATH="artifact/vector/build/outputs/apk/appfdroid/debug/$FILE"

# Helper functions

usage () {
	echo "Usage: $0 <build>"
	echo "Download a Jenkins build artifact, where <build> is the build"
	echo "number. Other parameters are configured by editing the file."
	exit 1
}

fail () {
	echo "Failed $*."
	exit 1
}

# Main program

BUILDNO="$1"
[ -n "$BUILDNO" ] || usage

BUILDPATH="$JOBROOT/$BUILDNO"
BUILDPATH2="$BUILDPATH/"
FPRPATH="$BUILDPATH/$FILEPATH/*fingerprint*/"

EVALCODE="$( wget -O - "$BUILDPATH2" "$FPRPATH" | awk '
	BEGIN {
		revision="unknown"
		fingerprint="unknown"
	}

	/<b>Revision<\/b>:/ {
		sub("^.*<b>Revision</b>:[ \t]+", ""); l1=length($0);
		gsub("[^A-Za-z0-9]", ""); l2=length($0);
		if (l1 == 40 && l2 == 40) {
			revision=$0
		}
	}

	/<p>The fingerprint [A-Za-z0-9]+ did not match any of the recorded data.<\/p>/ {
		sub("^.*fingerprint[ \t]+", "");
		sub("[ \t].*", ""); l1=length($0);
		gsub("[^A-Za-z0-9]", ""); l2=length($0);
		if (l1 == 32 && l2 == 32) {
			fingerprint=$0
		}
	}

	END {
		print "REVISION=" tolower(revision)
		print "FINGERPRINT=" tolower(fingerprint)
	}' )"

#echo "Eval: \"$EVALCODE\""

[ -n "$EVALCODE" ] || fail retrieving metadata

eval $EVALCODE
[ "$REVISION" = "unknown" -o "$FINGERPRINT" = "unknown" ] && \
	fail getting revision and/or fingerprint

DESTFILE="$FLAVOUR-$BUILDNO-$REVISION.$EXT"

echo
echo ------------------------------------------------------------------------
echo "Build: $BUILDNO"
echo "Flavour: $FLAVOUR"
echo "Revision: $REVISION"
echo "Fingerprint: $FINGERPRINT"
echo "Target: $DESTFILE"
echo ------------------------------------------------------------------------
echo

if [ -e "$DESTFILE" ]; then
	if echo "$FINGERPRINT  $DESTFILE" | md5sum -c; then
		exit 0
	else
		rm -v "$DESTFILE"
	fi
fi

[ ! -e "$DESTFILE" ] || fail deleting target file
if [ ! -e "$DESTFILE" ]; then
	T=1
	until wget -c -t 1 "$BUILDPATH/$FILEPATH" -O "$DESTFILE"
	do
		if ! truncate -c -s -50K "$DESTFILE"; then
			rm -v "$DESTFILE"
			fail truncating "$DESTFILE"
		fi
		echo "$( date ): [Waiting for $T seconds]"
		sleep "$T"
		T="$(( T * 2 ))"
	done
fi
[ -e "$DESTFILE" ] || fail downloading file
if echo "$FINGERPRINT  $DESTFILE" | md5sum -c; then
	exit 0
else
	rm -v "$DESTFILE"
	fail downloading file: Bad checksum
fi
