#!/bin/bash

function multidar() {
    if ! [ $# = 2 ]; then
	echo Usage: multidar sourceDirectory maxNumberOfFilesPerArchive
    else
	sourceDirectory=$1
	maxNumberOfFilesPerArchive=$2
	if which dar 2>/dev/null; then
	    echo great, I found dar at $(which dar)
	    find $sourceDirectory -type f > .fullList
	    sed -i -e '/DS_Store/d' .fullList
	    sed -i -e 's/\/\//\//' .fullList
	    split -a 3 -l $maxNumberOfFilesPerArchive .fullList .partial
	    for i in .partial*; do
		echo archiving from $i to ${sourceDirectory%?}-${i:8:3}
		dar -w -c ${sourceDirectory%?}-${i:8:3} --include-from-file $i
 		/bin/rm -rf $i
 	    done
 	    /bin/rm -rf .fullList*
	    ls -lh ${sourceDirectory%?}*.dar
	else
	    echo please install dar
	fi
    fi
}

function backup() {
    BREF='/home/username/tmp'
    BSRC='-g test'   # cannot use an absolute path
    BDEST=/home/username/tmp/backups
    BTAG=all
    FLAGS=(-s 5G -zbzip2 -asecu -w -X "*~" -X "*.o")   # bash array with some flags
    #FLAGS+=(-K aes:)   # add encryption
    if [ $# == 0 ]; then
	echo missing argument ... need to be one of: show 0 1 2 3 .. 98 99
    elif [ $1 == 'show' ]; then
	ls -lhtr $BDEST/"$BTAG"*
    elif [ $1 == '0' ]; then
	echo backing up $BSRC to $BDEST
	dar "${FLAGS[@]}" -c $BDEST/"$BTAG"0 -R $BREF $BSRC
	/bin/rm -rf $BDEST/"$BTAG"{1..100}.*.dar; ls -lhtr $BDEST/"$BTAG"*
    else
	level=$1
	if [ -n "$level" ] && [ "$level" -eq "$level" ] 2>/dev/null; then   # check if it is a number
	    echo backing up $BSRC to $BDEST
  	    dar "${FLAGS[@]}" -A $BDEST/"$BTAG"$((level-1)) -c $BDEST/"$BTAG"$level -R $BREF $BSRC
	    for i in $(seq $((level+1)) 100); do
		/bin/rm -rf $BDEST/"$BTAG"$i.*.dar
	    done
 	    ls -lhtr $BDEST/"$BTAG"*
	else
	    echo $level is not a number ...; return 1
	fi
    fi
}

function restore() {
    BSRC=/home/username/tmp/backups
    BTAG=all
    BDEST=/home/username/tmp/restore
    if [ $# == 0 ]; then
	echo Examples:
	echo '   'restore -l anyPattern
	echo '   'restore -x Pictures/1995
	echo '   'restore -x Documents/notes
	echo '   'restore -x Documents/notes/quantum.txt
	echo '   'restore -n 0 Documents/misc/someFile.txt
	echo 'Notes: (1)' restore -x/-n does not understand Unix wildmasks, so need to specify full directory or file name
	echo '       (2)' always specify one name per command
	echo '       (3)' restore will put the restored files into \$BDEST
    elif [ $1 == '-l' ]; then
	echo Listing all versions
	for file in $BSRC/"$BTAG"{0..99}; do
	    if [ -f $file.1.dar ]; then
       		echo --- in $file:
		dar -l $file | grep $2
	    fi
	done
    elif [ $1 == '-x' ]; then
	echo Restoring from the earliest version:
	echo '  'important to go through all previous backups if restoring a directory or a sparsebundle
	echo '  'or if the most recent version of the file is stored in an earlier backup
	for file in $BSRC/"$BTAG"{0..99}; do
	    if [ -f $file.1.dar ]; then
       		echo --- from $file:
		dar -R $BDEST -O -w -x $file -v -g $2
	    fi
	done
    elif [ $1 == '-n' ]; then
	echo Be careful with restoring from a single layer: might not work as naively expected
	echo Restoring from version $2
	dar -R $BDEST -O -w -x $BSRC/"$BTAG"$2 -v -g $3
    else
	echo unrecognized option ...
    fi
}
