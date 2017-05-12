#!/bin/bash

if [[ $DD_API_KEY ]]; then
  sed -i -e "s/^.*api_key:.*$/api_key: ${DD_API_KEY}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
else
  echo "DD_API_KEY environment variable not set. Run: heroku config:set DD_API_KEY=<your API key>"
  exit 1
fi

if [[ $DD_HOSTNAME ]]; then
  sed -i -e "s/^.*hostname:.*$/hostname: ${DD_HOSTNAME}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
fi

if [[ $DD_TAGS ]]; then
  sed -i -r -e "s/^# ?tags:.*$/tags: ${DD_TAGS}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
fi

if [[ $DD_SERVICE_ENV ]]; then
  printf "\n[trace.config]\nenv=${DD_SERVICE_ENV}" >> /app/.apt/opt/datadog-agent/agent/datadog.conf
fi

if [[ $DD_HISTOGRAM_PERCENTILES ]]; then
  sed -i -e "s/^.*histogram_percentiles:.*$/histogram_percentiles: ${DD_HISTOGRAM_PERCENTILES}/" /app/.apt/opt/datadog-agent/agent/datadog.conf
fi

mkdir -p /tmp/logs/datadog

(
  if [[ $DISABLE_DATADOG_AGENT ]]; then
    echo "DISABLE_DATADOG_AGENT environment variable is set, not starting the agent."
  else
    # Unset other PYTHONPATH/PYTHONHOME variables before we start
    unset PYTHONHOME PYTHONPATH
    # Load our library path first when starting up
    export LD_LIBRARY_PATH=/app/.apt/opt/datadog-agent/embedded/lib:$LD_LIBRARY_PATH
    mkdir -p /tmp/logs/datadog
    exec /app/.apt/opt/datadog-agent/embedded/bin/python /app/.apt/opt/datadog-agent/agent/dogstatsd.py start
  fi
)

(
  if [[ $DISABLE_DATADOG_AGENT ]]; then
    echo "DISABLE_DATADOG_AGENT environment variable is set, not starting the agent."
  else
    # Run the Datadog Trace Agent
    echo "Starting Trace Agent..." >> /tmp/logs/datadog/trace-agent.log
    exec /app/.apt/opt/datadog-agent/bin/trace-agent -ddconfig /app/.apt/opt/datadog-agent/agent/datadog.conf -debug >> /tmp/logs/datadog/trace-agent.log 2>&1 &
  fi
)
