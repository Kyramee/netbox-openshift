#!/bin/bash
CHART_PATH="$(dirname -- "${BASH_SOURCE[0]}")"       # relative
CHART_PATH="$(cd -- "$CHART_PATH" && pwd)/../.."    # absolutized and normalized
if [[ -z "$CHART_PATH" ]] ; then
  # error; for some reason, the path is not accessible
  # to the script (e.g. permissions re-evaled after suid)
  echo "Can't access path:"
  echo $CHART_PATH
  exit 1  # fail
fi

helm install -f "$(CHART_PATH)/migration/values.yaml" migration "$(CHART_PATH)/migration/" --wait --wait-for-jobs > cleanup.sh 2> migration-error.log
chmod 770 cleanup.sh
cat cleanup.sh | jq -r '.info.notes' > cleanup.sh

echo "$(date) Installion error:" >> install-error.log
helm install -f netbox/values.yaml -f migration/posgresql.yaml netbox ./netbox/ --wait > /dev/null 2>> netbox-error.log
echo "$(date) Upgrade error:" >> install-error.log
helm upgrade -f netbox/values.yaml netbox ./netbox/ --wait > /dev/null 2>> install-error.log

./cleanup.sh