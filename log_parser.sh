#!/bin/bash

source_dir="$FBAM_LOGS_SOURCE_PATTERN"
target_dir="$FBAM_LOGS_TARGET_DIR"
source_file_regex="$FBAM_LOGS_SOURCE_FILE_REGEX"
existing_files=()

# Helper function to check whether given array contains given element
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# Check which files have been already processed. All processed workflow ids are stored in 'existing_files' array
for filename in $source_dir
do
  if [[ $filename =~ $source_file_regex ]]
  then
    workflow_id=${BASH_REMATCH[1]}
    if [[ -f "$target_dir/file_access_log_$workflow_id.jsonl" ]]
    then
      containsElement "$workflow_id" "${existing_files[@]}"
      if [ $? -eq 1 ]
      then
        existing_files+=("$workflow_id")
      fi
    fi
  fi
done

# Append workflowId & jobId to logs and concatenate all log files for a given workflow id
for filename in $source_dir
do
  if [[ $filename =~ $source_file_regex ]]
  then
    workflow_id=${BASH_REMATCH[1]}
    job_id=${BASH_REMATCH[2]}
    containsElement "$workflow_id" "${existing_files[@]}"
    if [ $? -eq 1 ]
    then
      file_content=$(cat "$filename")
      workflow_id_colon=${workflow_id//_/-}
      job_id_full="$workflow_id_colon-$job_id"
      modified_content=$(sed -E 's~("command": "[^ ]*",)~\1 "workflowId": "'"$workflow_id_colon"'", "jobId": "'"$job_id_full"'",~' <<< "$file_content")
      echo "$modified_content" >> "$target_dir/file_access_log_$workflow_id.jsonl"
    fi
  fi
done
 
