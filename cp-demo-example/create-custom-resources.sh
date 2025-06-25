#!/bin/bash

CLUSTER_ID=$(curl --silent --user superUser:superUser https://localhost:8091/kafka/v3/clusters/ --insecure | jq -r ".data[0].cluster_id")
echo "Cluster ID: $CLUSTER_ID"

# Get a list of all topics, excluding those that start with '_'
ALL_TOPICS=$(curl --silent --user superUser:superUser https://localhost:8091/kafka/v3/clusters/"$CLUSTER_ID"/topics --insecure | jq -r '.data[].topic_name | select(startswith("_") | not)')

# Initialize the YAML file
OUTPUT_FILE="all_topics.yaml"
> $OUTPUT_FILE  # Clear the file if it exists

# Loop over all topics
for TOPIC in $ALL_TOPICS; do
    echo "Processing topic: $TOPIC"

    # Describe the topic to get the number of replicas and partitions
    TOPIC_DESCRIPTION=$(curl --silent --user superUser:superUser "https://localhost:8091/kafka/v3/clusters/$CLUSTER_ID/topics/$TOPIC" --insecure)
    REPLICATION_FACTOR=$(echo "$TOPIC_DESCRIPTION" | jq -r ".replication_factor")
    PARTITIONS_COUNT=$(echo "$TOPIC_DESCRIPTION" | jq -r ".partitions_count")

    # Get the configuration for the topic
    TOPIC_CONFIG=$(curl --silent --user superUser:superUser "https://localhost:8091/kafka/v3/clusters/$CLUSTER_ID/topics/$TOPIC/configs" --insecure)

    # Extract non-default configurations and format them as YAML key-value pairs
    NON_DEFAULT_CONFIGS=$(echo "$TOPIC_CONFIG" | jq -r '.data[] | select(.is_default == false) | "      \(.name): \"\(.value)\""')

    # Create the YAML content for this topic and append to the output file
    if [ -z "$NON_DEFAULT_CONFIGS" ]; then
        # NON_DEFAULT_CONFIGS is empty, do not include configs section
        cat <<EOF >> $OUTPUT_FILE
apiVersion: platform.confluent.io/v1beta1
kind: KafkaTopic
metadata:
  name: $TOPIC
  namespace: confluent
spec:
  replicas: $REPLICATION_FACTOR
  partitionCount: $PARTITIONS_COUNT
  kafkaRestClassRef:
    name: cp-demo-access
    namespace: confluent
---
EOF
    else
        # NON_DEFAULT_CONFIGS is not empty, include configs section
        cat <<EOF >> $OUTPUT_FILE
apiVersion: platform.confluent.io/v1beta1
kind: KafkaTopic
metadata:
  name: $TOPIC
  namespace: confluent
spec:
  replicas: $REPLICATION_FACTOR
  partitionCount: $PARTITIONS_COUNT
  configs:
$NON_DEFAULT_CONFIGS
  kafkaRestClassRef:
    name: cp-demo-access
    namespace: confluent
---
EOF
    fi

done

echo "YAML file for all topics has been created as '$OUTPUT_FILE'."
