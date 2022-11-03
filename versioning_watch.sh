#!/bin/bash

HELP="
Simple versioning when working with files.
Badly engineered, but SIMPLE so KISS.
Protection against accidental editing errors, by creating
multiple older version of a file (undo).

Use in combination with some filewatcher, e.g. fswatch of watchman
Rudimentary support for watchman is build-in.

Evert Mouw, 2022-11-03

Arguments (inputs) either:
  - one and only one FILENAME to apply versioning to
      (more filenames will be ignored)
  - watchman DIRECTORY (fire & forget)
  - watchman_rm DIRECTORY (remove watch)
  - cleanup DIRECTORY (removes old versions)

Edit the shellscript to change a few options.
"

if [[ "$1" == "" ]]
then
	echo "$HELP"
	exit
fi

# preferences

IDENTIFIER="old_version"
MAX=9

# Exclusions are very primitive,
# they don't support wildcards...
# However you can use e.g. ".ext"
# TODO: improve exclusions

EXCLUSIONS="foobar .dat"

# Notifier
NOTE="notify-send"
# to disable, uncomment:
#NOTE="/bin/false"

# If the HIDDEN variable is set to "hidden",
# then a dot is added before the backup files.
HIDDEN="hidden"

# --- don't change below here...

FILE="$1"
SUFF="#@${IDENTIFIER}$"

if ! [[ "$FILE" == "cleanup" || "$FILE" == "watchman" ]]
then
	# don't act on old versions
	if [[ "$FILE" == *"$SUFF"* ]]; then exit; fi
	# don't act on directories
	if [[ -d "$FILE" ]]; then exit; fi
	# don't act on non-existing files ;-)
	if ! [[ -f "$FILE" ]]; then exit; fi
fi

function cleanup {
	# remove all backups
	if [ ! -d "$1" ]
	then
		echo "$1 is not a directory, or none given"
		exit
	fi
	find "$1" -regex '.*\.#@[^$]+[$]\.[0-9]+' -delete
}

if [[ "$1" == "cleanup" ]]
then
	cleanup "$2"
	exit
fi

function fs_watchman {
	# set up file monitoring using watchman
	# TODO: don't run fs_watchman when a watcher already is in place
	# TODO: add option to remove a watchman filesystem watcher
	if [ ! -d "$1" ]
	then
		echo "$1 is not a directory, or none given"
		exit
	fi
	if ! which watchman
	then
		echo "I could not find watchman..."
		exit
	fi
	watchman watch "$1"
	watchman -- trigger "$1" versioning '*' -- "$0"
	$NOTE versioning "watchman set up for $1"
}

if [[ "$1" == "watchman" ]]
then
	fs_watchman "$2"
	exit
fi

# TODO: watchman_rm untested
function fs_watchman_remove {
	# removes the watch created by fs_watchman
	if which watchman
	then
		watchman watch-del "$1"
		watchman trigger-del "$1" versioning
	fi
}

if [[ "$1" == "watchman_rm" ]]
then
	fs_watchman_remove "$2"
	exit
fi

# exclusions (still primitive)
for E in $EXCLUSIONS
do
	if [[ "$FILE" == *"$E"* ]]
	then
		$NOTE versioning "EXCLUDED: $FILE"
		exit
	fi
done

# create hidden filenames for the backup files
function backupfilename {
	# if $2 == hidden, then put a dot before the filename
	# $1 should be the not-hidden filename
	if ! [[ "$2" == "hidden" ]]
	then
		return "$1"
	else
		D=$(dirname "$1")
		F=$(basename "$1")
		echo "$D/.$F"
	fi
}

# create a new backup only when either:
# - the latest saved version is different from the last (newest) backup
# - no latest saved version yet exists...
BACKUPFILE=$(backupfilename "$FILE.$SUFF" $HIDDEN)
if ! diff "$FILE" "$BACKUPFILE.1" 2>&1 > /dev/null
then
	$NOTE versioning "$FILE"
	# remove oldest version
	rm "$BACKUPFILE.$MAX" 2>&1 > /dev/null
	# shift all versions (increment one)
	for ((i=MAX; i>0; i--))
	do
		if [[ -f "$BACKUPFILE.$i" ]]
		then
			mv "$BACKUPFILE.$i" "$BACKUPFILE.$((i+1))"
		fi
	done
	# now "1" is available
	cp "$FILE" "$BACKUPFILE.1"
fi

# =========
#   Notes
# =========
#
# Examples for working with backup files in the shell:
# echo 'current.ext.#@old_version$.1' | grep -E '\.#@[^$]+[$]\.[0-9]+'
# find . -regex '.*\.#@[^$]+[$]\.[0-9]+'
#
# The backup files are hidden but beware that you could end up
# with hidden files lingering around (bad security).
