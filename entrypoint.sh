#!/bin/bash

# Set default values if variables are not defined
FILE_AGE="${FILE_AGE:-90}"
SLEEP_TIME="${SLEEP_TIME:-86400}"

while true; do
  NOW=$(date +%s)
  DATE=$(date)

  # Retire les guillemets éventuels et sépare la liste
  BUCKET_LIST=$(echo $BUCKET_NAME | tr -d '"')
  IFS='|'
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[1;34m'
  MAGENTA='\033[0;35m'
  NC='\033[0m' # No Color

  echo -e "${YELLOW}--- Running Cleaning at ${DATE} ---${NC}"

  for BUCKET_PATH in $BUCKET_LIST; do
    echo -e "${BLUE}--- Parcours de $BUCKET_PATH ---${NC}"
    LIST=$(aws s3 ls s3://$BUCKET_PATH/ --endpoint-url "$ENDPOINT_URL" --region "$AWS_DEFAULT_REGION")
    while read -r LINE; do
      FILE_DATE=$(echo "$LINE" | awk '{print $1}')
      FILE_NAME=$(echo "$LINE" | awk '{print $4}')
      if [[ "$FILE_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]] && [[ -n "$FILE_NAME" ]]; then
        FILE_TIME=$(date -d "$FILE_DATE" +%s)
        AGE_DAYS=$(( (NOW - FILE_TIME) / 86400 ))
        if (( AGE_DAYS > $FILE_AGE )); then
          # Nom du fichier en jaune, nombre de jours en magenta
          echo -e "${GREEN}$FILE_NAME${NC} : ${MAGENTA}$AGE_DAYS jours${NC}"
          if [[ "$MODE" == "clean" ]]; then
            echo -e "${RED}Suppression de $FILE_NAME dans $BUCKET_PATH${NC}"
            aws s3 rm "s3://$BUCKET_PATH/$FILE_NAME" --endpoint-url "$ENDPOINT_URL" --region "$AWS_DEFAULT_REGION"
          fi
        else
          # Nom du fichier en vert, nombre de jours en bleu
          echo -e "${GREEN}$FILE_NAME${NC} : ${YELLOW}$AGE_DAYS jours${NC}"
        fi
      fi
    done <<< "$LIST"
  done
  unset IFS
  
  if [[ "$RUN_ONCE" == "true" ]]; then
    echo -e "${YELLOW}--- RUN_ONCE is true, exiting after one run ---${NC}"
    exit 0
  else
    # Attendre 24h avant la prochaine exécution
    echo -e "${YELLOW}--- Sleeping 24h ---${NC}"
    sleep $SLEEP_TIME
  fi

done