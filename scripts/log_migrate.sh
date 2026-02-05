#!/bin/bash
set -e

# USAGE:
#   ./migrate_historical.sh [--dry-run] <profile> <region> <log-group-name> <app-name> <year> [month]
#
# EXAMPLE:
#   ./migrate_historical.sh govwifi-prod eu-west-2 production-admin-log-group admin 2025

# 1. Check for Dry Run Flag
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
  DRY_RUN=true
  echo "🔍 DRY RUN MODE ENABLED"
  shift # Removes "--dry-run" so $1 becomes the Profile
fi

# 2. Argument Validation
if [ "$#" -lt 5 ]; then
  echo "Usage: $0 [--dry-run] <profile> <region> <log-group-name> <app-name> <year> [month]"
  echo "Example: $0 --dry-run govwifi-prod eu-west-2 prod-group admin 2025"
  exit 1
fi

# 3. Assign Variables
PROFILE=$1
REGION=$2
LOG_GROUP_NAME=$3
APP_NAME=$4
YEAR=$5
SPECIFIC_MONTH=$6 # Optional

# 4. Configuration
#BUCKET="govwifi-production-log-archive"

BUCKET_IRELAND="govwifi-migration-temp-eu-west-1"
BUCKET_LONDON="govwifi-production-log-archive"
if [ "$REGION" == "eu-west-1" ]; then
  BUCKET="$BUCKET_IRELAND"
elif [ "$REGION" == "eu-west-2" ]; then
  BUCKET="$BUCKET_LONDON"
else
  echo "    ❌ Unsupported region: $REGION"
  exit 1
fi
# Note: Using 'cloudwatch-export'
DEST_PREFIX_ROOT="cloudwatch-export/$REGION/$APP_NAME/$YEAR"

echo "---------------------------------------------------"
echo "  AWS Profile:   $PROFILE"
echo "  Region:        $REGION"
echo "  Log Group:     $LOG_GROUP_NAME"
echo "  App Name:      $APP_NAME"
echo "  Year:          $YEAR"
echo "  Bucket:        $BUCKET"
if [ -n "$SPECIFIC_MONTH" ]; then echo "  Month:         $SPECIFIC_MONTH (Single month only)"; fi
echo "  S3 Dest:       s3://$BUCKET/$DEST_PREFIX_ROOT"
echo "---------------------------------------------------"

# 5. Determine loop range
if [ -n "$SPECIFIC_MONTH" ]; then
  MONTHS_TO_RUN="$SPECIFIC_MONTH"
else
  #MONTHS_TO_RUN=$(seq -f "%02g" 1 12)
  MONTHS_TO_RUN=$(seq -f "%02g" 9 12)
fi

# 6. The Loop
for MONTH in $MONTHS_TO_RUN; do

  FROM_TIME=$(date -d "${YEAR}-${MONTH}-01 00:00:00" +%s)000

  if [ "$MONTH" == "12" ]; then
    TO_TIME=$(date -d "$((YEAR+1))-01-01 00:00:00" +%s)000
  else
    NEXT_MONTH=$(printf "%02d" $((10#$MONTH + 1)))
    TO_TIME=$(date -d "${YEAR}-${NEXT_MONTH}-01 00:00:00" +%s)000
  fi

  PREFIX="${DEST_PREFIX_ROOT}/${MONTH}"

  echo "   ➡️ Processing Month $MONTH..."

  if [ "$DRY_RUN" = true ]; then
    echo "   [DRY RUN] Would run: aws logs create-export-task --profile $PROFILE --region $REGION --destination-prefix $PREFIX ..."
  else
    # --- EXECUTE EXPORT ---

    TASK_ID=$(aws logs create-export-task \
      --profile "$PROFILE" \
      --region "$REGION" \
      --log-group-name "$LOG_GROUP_NAME" \
      --from "$FROM_TIME" \
      --to "$TO_TIME" \
      --destination "$BUCKET" \
      --destination-prefix "$PREFIX" \
      --query 'taskId' \
      --output text)

    echo "   ✅ Task Started: $TASK_ID"
    echo "   ⏳ Waiting for completion..."

    # --- MONITOR STATUS ---
    while true; do
      STATUS=$(aws logs describe-export-tasks \
        --profile "$PROFILE" \
        --region "$REGION" \
        --task-id "$TASK_ID" \
        --query 'exportTasks[0].status.code' \
        --output text)

      if [ "$STATUS" == "COMPLETED" ]; then
        echo -e "\n   🎉 Month $MONTH Completed."
        break
      elif [ "$STATUS" == "FAILED" ] || [ "$STATUS" == "CANCELLED" ]; then
        echo "   ❌ Export failed for $MONTH! Check AWS Console."
        exit 1
      elif [ "$STATUS" == "PENDING" ] || [ "$STATUS" == "RUNNING" ]; then
        echo -n "."
        sleep 5
      else
        echo "   Unknown status: $STATUS"
        sleep 5
      fi
    done
  fi
done

echo "✅ All operations finished."