#!/bin/bash
helm install -f migration/values.yaml migration ./migration/ --wait --wait-for-jobs