#!/bin/bash
set -e

# USAGE: ./migrate_historical.sh <log-group-name> <app-name> <year>
# Example: ./migrate_historical.sh prod-admin-log-group admin 2025
# Log group name: The name of the CloudWatch Logs log group to export from
# App name: A short identifier for the application, used in S3 prefix and for the the Athena SQL queries
# Year: The year to migrate (e.g., 2025)

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <log-group-name> <app-name> <year>"
  exit 1
fi

LOG_GROUP_NAME=$1
APP_NAME=$2
YEAR=$3
BUCKET="govwifi-prod-log-archive" # Update this to your actual bucket name

echo "Starting migration for $APP_NAME ($YEAR)..."

# Loop through months 01 to 12
for MONTH in {01..12}; do

  # Calculate start/end timestamps for the month
  # Note: Timestamps are in milliseconds
  FROM_TIME=$(date -d "${YEAR}-${MONTH}-01 00:00:00" +%s)000

  # Logic to calculate the first day of the NEXT month
  if [ "$MONTH" == "12" ]; then
    TO_TIME=$(date -d "$((YEAR+1))-01-01 00:00:00" +%s)000
  else
    NEXT_MONTH=$(printf "%02d" $((10#$MONTH + 1)))
    TO_TIME=$(date -d "${YEAR}-${NEXT_MONTH}-01 00:00:00" +%s)000
  fi

  PREFIX="historical/${APP_NAME}/${YEAR}/${MONTH}"

  echo " - Exporting Month $MONTH to s3://$BUCKET/$PREFIX"

  # Trigger the export task
  TASK_ID=$(aws logs create-export-task \
    --log-group-name "$LOG_GROUP_NAME" \
    --from "$FROM_TIME" \
    --to "$TO_TIME" \
    --destination "$BUCKET" \
    --destination-prefix "$PREFIX" \
    --query 'taskId' \
    --output text)

  # Wait loop (AWS only allows 1 active export task at a time)
  while true; do
    STATUS=$(aws logs describe-export-tasks --task-id "$TASK_ID" --query 'exportTasks[0].status.code' --output text)
    if [ "$STATUS" == "COMPLETED" ]; then
      break
    elif [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "CANCELLED" ]; then
      echo "❌ Export failed for $MONTH!"
      exit 1
    fi
    sleep 5
  done
done

echo "✅ Migration for $YEAR complete!"