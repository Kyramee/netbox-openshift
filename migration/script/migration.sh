#!/bin/bash
helm install -f migration/values.yaml migration ./migration/ --wait --wait-for-jobs > cleanup.sh 2> migration-error.log
chmod 770 cleanup.sh
cat cleanup.sh | jq -r '.info.notes' > cleanup.sh

echo "$(date) Installion error:" >> install-error.log
helm install -f netbox/values.yaml -f migration/posgresql.yaml netbox ./netbox/ --wait > /dev/null 2>> netbox-error.log
echo "$(date) Upgrade error:" >> install-error.log
helm upgrade -f netbox/values.yaml netbox ./netbox/ --wait > /dev/null 2>> install-error.log

./cleanup.sh