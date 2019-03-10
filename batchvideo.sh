#!/bin/bash
set -x
IFS='
'
PFX=gl
FPS=16

sec2fra () {
    LC_ALL=C printf '%.0f' $(echo "$1 * $FPS" | bc -l)
    }

start_pfx () {
    printf "%04d" $(sec2fra $1)
    }

compact () {
    local ct
    
    ct=1
    for i in $(ls ${PFX}*.png); do
        mv "$i" ${PFX}$(printf %04d.png $ct)
        ct=$((ct + 1))
    done
}

insert_shot () {
    local start_in=$1 len_in_max=$2 fade_in=$3 file_in=$4
    local start i alpha
    
    start="$(start_pfx $start_in)"
    if [ $len_in_max -lt 0 ]; then
        len_in=1
    else
        len_in_max=$(sec2fra $len_in_max)
        len_in=$(seq 1 $len_in_max)
    fi
    for i in $len_in; do
        if [ $len_in_max -ge 0 -a $i -le $fade_in ]; then
            alpha=$((i * 100 / $fade_in))
            convert ${PFX}${start}000.png "$file_in" -gravity center -define compose:args=$alpha -compose blend -composite ${PFX}${start}$(printf "%03d" $i).png
        elif [ $len_in_max -ge 0 -a $fade_in -ge $((len_in_max - i)) ]; then
            alpha=$(((len_in_max - i) * 100 / $fade_in))
            convert ${PFX}${start}000.png "$file_in" -gravity center -define compose:args=$alpha -compose blend -composite ${PFX}${start}$(printf "%03d" $i).png
        else
            cp "$file_in" ${PFX}${start}$(printf "%03d" $i).png
        fi
    done
}
             
#
#  MAIN
#

if [ 1 -eq 1 ]; then
    ls *.png *.mp4
    read -p "All these files will be removed, continue?" a
    rm *.png *.mp4
    
    ffmpeg -i ../green-lights.mp4 gl%04d0.png
    for i in gl*0.png; do
        out="$(echo "$i" | sed 's/0\.png$/1.png/g')"
        cp "$i" "$out"
    done
    compact
             
    for i in $(ls ${PFX}*.png | tac); do
        mv $i $(basename "$i" .png)000.png
    done

    # insert #1 snapshot
    insert_shot 4.5 3 8 ../green-lights01.png

    # insert #2 snapshot
    insert_shot 8 3 8 ../green-lights02.png
    
    # insert #3 snapshot
    insert_shot 16.5 3 8 ../green-lights03.png

    # insert #4 snapshot
    insert_shot 23.5 3 8 ../green-lights04.png

    # insert #4 snapshot
    insert_shot 29 3 8 ../green-lights05.png

    # insert #4 snapshot
    insert_shot 36.2 3 8 ../green-lights06.png


    # insert last frame with stop icon
    insert_shot 120 -1 8 ../green-lights99.png
    
    compact

    # remove 2 secs at the beginning of video
    for i in $(seq 1 $(sec2fra 2)); do
        rm ${PFX}$(printf %04d.png $i)
    done

    compact


    ffmpeg -framerate 12 -i gl%04d.png out.mp4
fi


