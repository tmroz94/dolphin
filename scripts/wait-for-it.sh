#!/usr/bin/env bash
#   Use this script to test if a given TCP host/port are available

TIMEOUT=15
QUIET=0
HOST=""
PORT=""

echoerr() { if [[ $QUIET -ne 1 ]]; then echo "$@" 1>&2; fi; }

usage() {
  cat <<USAGE >&2
Usage:
    $0 host:port [-s] [-t timeout] [-- command args]
    -h HOST | --host=HOST       Host or IP under test
    -p PORT | --port=PORT       TCP port under test
                                Alternatively, you specify the host and port as host:port
    -s | --strict               Only execute subcommand if the test succeeds
    -q | --quiet                Don't output any status messages
    -t TIMEOUT | --timeout=TIMEOUT
                                Timeout in seconds, zero for no timeout
    -- COMMAND ARGS             Execute command with args after the test finishes
USAGE
  exit 1
}

wait_for() {
  if [[ $TIMEOUT -gt 0 ]]; then
    echoerr "$0: waiting $TIMEOUT seconds for $HOST:$PORT"
  else
    echoerr "$0: waiting for $HOST:$PORT without a timeout"
  fi
  start_ts=$(date +%s)
  while :; do
    if [[ $ISBUSY -eq 1 ]]; then
      nc -z $HOST $PORT
      result=$?
    else
      (echo >/dev/tcp/$HOST/$PORT) >/dev/null 2>&1
      result=$?
    fi
    if [[ $result -eq 0 ]]; then
      end_ts=$(date +%s)
      echoerr "$0: $HOST:$PORT is available after $((end_ts - start_ts)) seconds"
      break
    fi
    sleep 1
  done
  return $result
}

wait_for_wrapper() {
  # In order to support SIGINT during timeout: http://unix.stackexchange.com/a/57692
  if [[ $QUIET -eq 1 ]]; then
    timeout $BUSYTIMEFLAG $TIMEOUT $0 --quiet --child --host=$HOST --port=$PORT --timeout=$TIMEOUT &
  else
    timeout $BUSYTIMEFLAG $TIMEOUT $0 --child --host=$HOST --port=$PORT --timeout=$TIMEOUT &
  fi
  PID=$!
  trap "kill -INT -$PID" INT
  wait $PID
  RESULT=$?
  if [[ $RESULT -ne 0 ]]; then
    echoerr "$0: timeout occurred after waiting $TIMEOUT seconds for $HOST:$PORT"
  fi
  return $RESULT
}

# process arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
  *:*)
    HOST=$(printf "%s\n" "$1" | cut -d : -f 1)
    PORT=$(printf "%s\n" "$1" | cut -d : -f 2)
    shift 1
    ;;
  -h)
    HOST="$2"
    if [[ $HOST == "" ]]; then break; fi
    shift 2
    ;;
  --host=*)
    HOST=$(printf "%s" "$1" | cut -d = -f 2)
    shift 1
    ;;
  -p)
    PORT="$2"
    if [[ $PORT == "" ]]; then break; fi
    shift 2
    ;;
  --port=*)
    PORT=$(printf "%s" "$1" | cut -d = -f 2)
    shift 1
    ;;
  -t)
    TIMEOUT="$2"
    if [[ $TIMEOUT == "" ]]; then break; fi
    shift 2
    ;;
  --timeout=*)
    TIMEOUT=$(printf "%s" "$1" | cut -d = -f 2)
    shift 1
    ;;
  -q | --quiet)
    QUIET=1
    shift 1
    ;;
  -s | --strict)
    STRICT=1
    shift 1
    ;;
  --child)
    CHILD=1
    shift 1
    ;;
  --)
    shift
    CLI="$@"
    break
    ;;
  --help)
    usage
    ;;
  *)
    echoerr "Unknown argument: $1"
    usage
    ;;
  esac
done

if [[ "$HOST" == "" || "$PORT" == "" ]]; then
  echoerr "Error: you need to provide a host and port to test."
  usage
fi

ISBUSY=0
BUSYTIMEFLAG=""
if timeout --version 2>&1 | grep -q "BusyBox"; then
  ISBUSY=1
  BUSYTIMEFLAG="-t"
fi

if [[ $CHILD -gt 0 ]]; then
  wait_for
  RESULT=$?
  exit $RESULT
else
  if [[ $TIMEOUT -gt 0 ]]; then
    wait_for_wrapper
    RESULT=$?
  else
    wait_for
    RESULT=$?
  fi
fi

if [[ $CLI != "" ]]; then
  if [[ $RESULT -ne 0 && $STRICT -eq 1 ]]; then
    echoerr "$0: strict mode, refusing to execute subprocess"
    exit $RESULT
  fi
  exec $CLI
else
  exit $RESULT
fi
