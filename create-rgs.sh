#!/usr/bin/env bash
# create azure resource groups & update cfg yml files
# set -o nounset
# set -o errexit

ENV_NAMES=(dev stg)
LOCATIONS=(northeurope westeurope)
LOOKUP_JSON_FILE=modules/resource_naming/locals.geo_codes.tf.json
PREFIX=$(yq .prefix cfg.global.yml)

# LOCATION=${LOCATIONS[1]}
# ENV_NAME=${ENV_NAMES[1]}

function sort-yml {
	YML_FILE=$1
	yq -i -P 'sort_keys(..) | (... | select(type == "!!seq")) |= sort' $YML_FILE
}

GLOBAL_YML=cfg.global.yml && touch $GLOBAL_YML && sort-yml $GLOBAL_YML
for LOCATION in ${LOCATIONS[@]}; do
	LOCATION_SHORT=$(LOCATION=$LOCATION yq -r '.locals.builtin_azure_backup_geo_codes[env(LOCATION)]' $LOOKUP_JSON_FILE)
	LOCATION_YML=cfg.location-$LOCATION_SHORT.yml && touch $LOCATION_YML && sort-yml $LOCATION_YML
	for ENV_NAME in ${ENV_NAMES[@]}; do
		RESOURCE_GROUP_NAME=$PREFIX-$LOCATION_SHORT-$ENV_NAME-rg
		ENV_YML=cfg.env-${LOCATION_SHORT}-${ENV_NAME}.yml && touch $ENV_YML
		RESOURCE_GROUP_NAME=$RESOURCE_GROUP_NAME yq -i '.resource_group_name=env(RESOURCE_GROUP_NAME)' $ENV_YML
		sort-yml $ENV_YML
		az group create --location $LOCATION --name $RESOURCE_GROUP_NAME
	done
done
