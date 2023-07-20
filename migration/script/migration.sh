#!/bin/bash
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

helm install -f "$CHART_PATH/migration/values.yaml" migration "$CHART_PATH/migration/" -o json --wait --wait-for-jobs > "$CHART_PATH/migration_output.json" 2>> "$CHART_PATH/error.log"
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

helm install -f netbox/values.yaml -f migration/posgresql.yaml netbox ./netbox/ -o json --wait >  "$CHART_PATH/install_output.json" 2>> "$CHART_PATH/error.log"
STATUS="$(jq '.info.status' <  "$CHART_PATH/install_output.json")"
if [[ $STATUS = "deployed" ]] ; then
  echo "Netbox install failed: See $CHART_PATH/error.log for details"
  exit 1  # fail
fi

echo "Netbox install successful..."
echo ""
echo "Starting housekeeping..."

echo "$(date) Housekeeping error:" >> "$CHART_PATH/error.log"

helm upgrade -f netbox/values.yaml netbox ./netbox/ -o json --wait >  "$CHART_PATH/upgrade_output.json" 2>> "$CHART_PATH/error.log"
STATUS="$(jq '.info.status' <  "$CHART_PATH/upgrade_output.json")"
if [[ $STATUS = "deployed" ]] ; then
  echo "Starting failed: See $CHART_PATH/error.log for details"
  exit 1  # fail
fi

$CHART_PATH/cleanup.sh > /dev/null 2>> "$CHART_PATH/error.log"
rm "$CHART_PATH/migration_output.json" "$CHART_PATH/install_output.json" "$CHART_PATH/upgrade_output.json" "$CHART_PATH/cleanup.sh"

echo "Housekeeping successful..."
echo "Netbox is ready and operational!"
