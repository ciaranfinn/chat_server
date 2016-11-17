allowed_port='^([0-9]{1,4}|[1-5][0-9]{4}|6[0-4][0-9]{3}|65[0-4][0-9]{2}|655[0-2][0-9]|6553[0-5])$'

main(){
  if [[ $# -eq 0 ]] ; then
      echo 'please provide a port number'
      exit 1
  else
    if ! [[ $1 =~ $allowed_port ]] ; then
      echo "error: not a valid port" >&2;
      exit 1
    else
      echo "Port number OK"
      # Set environment variable with port number
      export DIST_SERVER_PORT=$1
      # Run elixir server
      mix run --no-halt
    fi
  fi
}

main $@
