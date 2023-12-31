#!/bin/bash
print_usage() {
  echo "Usage: $(basename "$0") [netboxPassword] [postgresPassword] [OPTION]..."
  echo ""
  echo "Options:"
  echo " -r,--redisPassword [redisPassword]"
  echo " -h,--help"
  echo ""
  echo "This script execute the following:"
  echo "1. Retrieve a netbox database backup using the netbox-migration image stored in a OpenShift project of the same name"
  echo "2. Install an instance of netbox with the retrieved backup on OpenShift using helm"
  echo "3. Do some housekeeping by removing all resources needed for the migration that are not needed by Netbox"
}

POSITIONAL_ARGS=()
redis_password=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -r|--redisPassword)
      redisPassword="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      SEARCHPATH="$2"
      print_usage
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

if [ $# -ne 2 ]
then
  echo "Error: This script take 2 arguments."
  echo "Use the option --help for the command details."
  exit 1
fi


## Set working path at thr root of the chart
CHART_PATH="$(dirname -- "${BASH_SOURCE[0]}")"       # relative
CHART_PATH="$(cd -- "$CHART_PATH" && pwd)/../.."    # absolutized and normalized
if [[ -z "$CHART_PATH" ]] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  echo "Can't access path:"
  echo "$CHART_PATH"
  exit 1  # fail
fi

echo "Starting migration..."

echo "$(date) Migration error:" >> "$CHART_PATH/error.log"

helm install migration "$CHART_PATH/migration/" \
  -f "$CHART_PATH/migration/values.yaml" \
  -o json \
  --wait \
  --wait-for-jobs \
  > "$CHART_PATH/migration_output.json" \
  2>> "$CHART_PATH/error.log"

STATUS="$(jq '.info.status' <  "$CHART_PATH/migration_output.json")"
if [[ $STATUS = "deployed" ]] ; then
  echo "Migration failed: See $CHART_PATH/error.log for details"
  exit 1  # fail
fi

jq -r '.info.notes' <  "$CHART_PATH/migration_output.json" > "$CHART_PATH/cleanup.sh"
chmod 770 "$CHART_PATH/cleanup.sh"

echo "Migration successful..."
echo ""
echo "Starting Netbox install..."

echo "$(date) Netbox install error:" >> "$CHART_PATH/error.log"

helm install netbox "$CHART_PATH/netbox/" \
  -f "$CHART_PATH/netbox/values.yaml" \
  -f "$CHART_PATH/migration/posgresql.yaml" \
  -o json \
  --wait \
  --set postgresql.auth.postgresPassword="$1" \
  --set postgresql.auth.password="$2" \
  --set redis.auth.password="$redis_password" \
  > "$CHART_PATH/install_output.json" \
  2>> "$CHART_PATH/error.log"
  
STATUS="$(jq '.info.status' <  "$CHART_PATH/install_output.json")"
if [[ $STATUS = "deployed" ]] ; then
  echo "Netbox install failed: See $CHART_PATH/error.log for details"
  exit 1  # fail
fi

echo "Netbox install successful..."
echo ""
echo "Starting housekeeping..."

echo "$(date) Housekeeping error:" >> "$CHART_PATH/error.log"

helm uninstall netbox --wait > /dev/null 2>> "$CHART_PATH/error.log"
helm install netbox "$CHART_PATH/netbox/" \
  -f "$CHART_PATH/netbox/values.yaml" \
  -o json \
  --wait \
  --set postgresql.auth.postgresPassword="$1" \
  --set postgresql.auth.password="$2" \
  --set redis.auth.password="$redis_password" \
  > "$CHART_PATH/upgrade_output.json" \
  2>> "$CHART_PATH/error.log"

STATUS="$(jq '.info.status' <  "$CHART_PATH/upgrade_output.json")"
if [[ $STATUS = "deployed" ]] ; then
  echo "Starting failed: See $CHART_PATH/error.log for details"
  exit 1  # fail
fi

$CHART_PATH/cleanup.sh > /dev/null 2>> "$CHART_PATH/error.log"
rm "$CHART_PATH/migration_output.json" "$CHART_PATH/install_output.json" "$CHART_PATH/upgrade_output.json" "$CHART_PATH/cleanup.sh"

echo "Housekeeping successful..."
echo "Netbox is ready and operational!"
