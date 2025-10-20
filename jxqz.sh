#!/bin/bash

#
# jxqz.org website generation script
#
# Steve Buer 2023
#

# todo: tab completion

case $1 in

	gen)
		echo -e '<html>\n<title>PAGE_TITLE</title>\n<body bgcolor="#ffffff">\n\n<h3>PAGE_HEADING</h3>\n\n<!-- COMMENT -->\n\n'

		while read FILE
		do
			echo "<a href=\"${FILE}\"><img src=\"thumbs/$(basename -s .jpg ${FILE})_t.jpg\"></a>"
		done
		
		echo -e '\n<hr>\n<center><a href="../index.html">Back</a></center>\n</body>\n</html>'
		;;

	ren)
		shift

		if [ -z $1 ]
		then
			echo "usage: $0 ren <name>"
			exit 1
		fi

		echo "renaming to: $1"

		COUNTER=1

		while read FILE
		do
			NEW=${1}${COUNTER}.jpg
			echo "rename: $FILE to $NEW"
			cp $FILE $NEW
			let COUNTER++
		done
		;;

	rot)
		while read FILE
		do
			echo "rotate: $FILE"
		done
		;;

	thumb)
		mkdir -p thumbs

		while read FILE
		do
			echo "thumb: $FILE"
			convert $FILE -resize 175x175 thumbs/$(basename -s .jpg ${FILE})_t.jpg
		done
		;;

	*)

		echo "$0: gen ren thumb"
		;;
esac
