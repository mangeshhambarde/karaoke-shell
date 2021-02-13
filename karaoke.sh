#!/bin/bash

clean () {
  rm -f song.*
  rm -rf output/audio
  rm -f audio.wav
  rm -f video.mkv
}

die () {
  echo "$1"
  clean
  exit 1
}

if [ "$#" -ne 2 ]; then
  echo "usage: <url> <song-name>"
  die "bad args"
fi

url=$1

clean

# download song
echo "downloading song"
youtube-dl -o song $url
if [ "$?" -ne 0 ]; then
  die 'download failed'
fi

# extract audio
echo "extracting audio"
ffmpeg -i song.* -vn -acodec pcm_s16le audio.wav
if [ "$?" -ne 0 ]; then
  die 'extract audio failed'
fi

# extract video
echo "extracting video"
ffmpeg -i song.* -an -vcodec copy video.mkv
if [ "$?" -ne 0 ]; then
  die 'extract video failed'
fi

# split vocals and instrumentals
echo "spleeting"
source ../spleeter/spleeterenv/bin/activate
spleeter separate -i audio.wav -o output
if [ "$?" -ne 0 ]; then
  die 'spleeting failed'
fi

# merge instrumentals and video
echo "merging"
ffmpeg -i video.mkv -i output/audio/accompaniment.wav -c:v copy -c:a copy output/"$2.mkv"
if [ "$?" -ne 0 ]; then
  die 'merge failed'
fi

clean

echo "done"
