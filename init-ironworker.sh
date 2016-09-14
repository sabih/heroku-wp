#!/bin/bash

#
# Sets up IronWorker to run wp-cron.
#
# Usage:
# $ ./init-ironworker.sh <APP-NAME>
#

# Check we got a valid new name
if [ -z "$1" ]
then
	echo >&2 "Please specify the name (subdomain) for your Heroku WP app."
	exit 1
fi

if [[ "$1" =~ [^a-z0-9-]+ ]]
then
	echo >&2 "App name '$1' is invalid."
	exit 1
fi

# Check to see if Heroku Toolbelt is installed
type heroku >/dev/null 2>&1 || {
	echo >&2 "Heroku Toolbelt must be installed. (https://toolbelt.heroku.com)"
	exit 1
}

# Check to see if Iron CLI is installed
type iron >/dev/null 2>&1 || {
	echo >&2 "Iron CLI must be installed. (https://github.com/iron-io/ironcli)"
	exit 1
}

# Check to see if NPM is installed
type npm >/dev/null 2>&1 || {
	echo >&2 "NPM must be installed. (https://docs.npmjs.com/getting-started/installing-node)"
	exit 1
}

# Check we have access to app
heroku info --app "$1" >/dev/null || {
	echo >&2 "Can not update app name '$1'."
	exit 1
}

# Add addon if we need it
heroku addons:info --app "$1" iron_worker >/dev/null 2>&1 || {
	heroku addons:create \
		--app "$1" \
		iron_worker:lite
}

# Get keys for IronWorker
IRON_PROJECT_ID=$( heroku config:get IRON_WORKER_PROJECT_ID --app "$1" )
IRON_TOKEN=$( heroku config:get IRON_WORKER_TOKEN --app "$1" )
if [ -n "$IRON_PROJECT_ID" -a -n "$IRON_TOKEN" ]
then
	echo "Got IronWorker keys from app name '$1'."
else
	echo >&2 "Can not get IronWorker keys from app name '$1'."
	exit 1
fi

# Package worker
true && \
	cd support/iron-worker && \
	npm install && \
	zip -r wp-cron-runner.zip . >/dev/null && \
	cd ../..

if [ "$?" -ne "0" ]; then
	echo >&2 "Could not package worker."
	exit 1
fi

# Upload worker
IRON_PROJECT_ID="$IRON_PROJECT_ID" IRON_TOKEN="$IRON_TOKEN" \
	iron worker upload \
		--name "wp-cron-runner" \
		--zip "support/iron-worker/wp-cron-runner.zip" \
		iron/node "node wp-cron-runner.js"

if [ "$?" -ne "0" ]; then
	echo >&2 "Could not upload worker."
	exit 1
fi

# Schedule worker
IRON_PROJECT_ID="$IRON_PROJECT_ID" IRON_TOKEN="$IRON_TOKEN" \
	iron worker schedule \
		--run-every 900 \
		--timeout 10 \
		--priority 0 \
		--payload $( printf '{"heroku_slug":"%s"}' "$1" ) \
		wp-cron-runner

if [ "$?" -ne "0" ]; then
	echo >&2 "Could not schedule worker."
	exit 1
fi

# Turn off WP cron
heroku config:set \
	--app "$1" \
	DISABLE_WP_CRON="TRUE"

echo "Success: WP Cron scheduled via IronWorker."
