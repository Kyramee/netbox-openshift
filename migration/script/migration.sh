#!/bin/bash
helm install -f migration/values.yaml migration ./migration/ --wait --wait-for-jobs > cleanup.sh 2> error.log
chmod 770 cleanup.sh
cat cleanup.sh | jq -r '.info.notes' > cleanup.sh

helm install -f netbox/values.yaml -f migration/posgresql.yaml netbox ./netbox/ --wait