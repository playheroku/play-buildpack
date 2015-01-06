#!/usr/bin/env bash

real_curl=$(which curl)
function curl() {
  local http_url=''
  local write_file=''
  local create_output_filename=''
  local curl_args=$*

  for i ; do
    case "$i" in
    -O|--remote-name)
      create_output_filename=true
      shift;;
    -m|--max-time)
      shift; shift;;
    -o|--output)
      if [[ ${2} != "-" ]]
      then
        write_file=${2}
      fi
      shift; shift;;
    -s|--silent)
      shift;;
    -L|--location|--)
      http_url=${2}; shift;
      filename=$(sed 's/[:\/]/_/g' <<< ${http_url})
      shift;
    esac
  done

  ## Do we have to generate a filename ourselves to write to?
  if [[ -n "$create_output_filename" ]]
  then
    write_file=$(echo ${http_url} | rev | cut -d\/ -f1 | rev)
  fi

  if test -f $BIN_DIR/../dependencies/$filename
  then
    ## Was a file to write to provided?
    if [[ -n "$write_file" ]]
    then
      ## Write to file
      cat $BIN_DIR/../dependencies/$filename > $write_file
    else
      # Stream output
    cat $BIN_DIR/../dependencies/$filename
    fi
  else
    $real_curl $curl_args
  fi
}

get_play_version()
{
  local file=${1?"No file specified"}

  if [ ! -f $file ]; then
    return 0
  fi

  grep -P '.*-.*play[ \t]+[0-9\.]' ${file} | sed -E -e 's/[ \t]*-[ \t]*play[ \t]+([0-9A-Za-z\.]*).*/\1/'    
}

check_compile_status()
{
  if [ "${PIPESTATUS[*]}" != "0 0" ]; then
    echo " !     Failed to build Play! application"
    rm -rf $CACHE_DIR/$PLAY_PATH
    echo " !     Cleared Play! framework from cache"
    exit 1
  fi
}

install_play()
{
  VER_TO_INSTALL=$1
  PLAY_URL="https://s3.amazonaws.com/heroku-jvm-langpack-play/play-heroku-$VER_TO_INSTALL.tar.gz"
  PLAY_TAR_FILE="play-heroku.tar.gz"
  echo "-----> Installing Play! $VER_TO_INSTALL....."
  curl --silent --max-time 150 --location $PLAY_URL -o $PLAY_TAR_FILE
  if [ ! -f $PLAY_TAR_FILE ]; then
    echo "-----> Error downloading Play! framework. Please try again..."
    exit 1
  fi
  if [ -z "`file $PLAY_TAR_FILE | grep gzip`" ]; then
    echo "-----> Error installing Play! framework or unsupported Play! framework version specified. Please review Dev Center for a list of supported versions."
    exit 1
  fi
  tar xzf $PLAY_TAR_FILE
  rm $PLAY_TAR_FILE
  chmod +x $PLAY_PATH/play
  echo "-----> done"
}
