#!/bin/sh

fail () {
	echo "Failed $*."
	exit 1
}

BUILDNO="$1"

FLAVOUR=vector-appfdroid-debug

FILE="$FLAVOUR.apk"
BUILDPATH="https://matrix.org/jenkins/job/VectorAndroidDevelop/$BUILDNO"
BUILDPATH2="$BUILDPATH/"
FILEPATH="artifact/vector/build/outputs/apk/$FILE"
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

DESTFILE="$FLAVOUR-$BUILDNO-$REVISION".apk

echo
echo "Build: $BUILDNO"
echo "Flavour: $FLAVOUR"
echo "Revision: $REVISION"
echo "Fingerprint: $FINGERPRINT"
echo "Target: $DESTFILE"
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
