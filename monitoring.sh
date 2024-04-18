#!/bin/bash

# Check availability sh script
GO_URL="goapp.local"

availability=$(curl -X GET -s -o /dev/null -w "%{http_code}" "$GO_URL")
if [ $availability != 200 ]; then
    exit 1
fi

input=$(curl -s "$GO_URL")
current_time=$(echo $input | grep -o -E '[0-9]{2}:[0-9]{2}:[0-9]{2}')   
count=0

for ((i=0; i<6; i++))
do
  new_input=$(curl -s "$GO_URL")
  new_current_time=$(echo $new_input | grep -o -E '[0-9]{2}:[0-9]{2}:[0-9]{2}')
  if [ "$new_current_time" != "$current_time" ]; then
    ((count++))
    current_time=$new_current_time
  fi
  sleep 1
done

if [ $count -eq 1 ]; then
  echo "Service wors"
else
  echo "Service error"
  exit 1
fi
