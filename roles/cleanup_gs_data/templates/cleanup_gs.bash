# If folder is empty for 2 weeks -> delete folder
# If folder is not empty, but only a  .finished file is present (2 weeks) -> delete folder
# If folder is not empty and no .finished file is present (1 week) -> notification, 2 weeks -> delete folder

#!/bin/bash

dirToCheck="/groups/umcg-genomescan/"*
dateInSecNow=$(date +%s)

# Check only dirs, ignore files and reverse sort to check subfolders first
for dir in $(find ${dirToCheck} -maxdepth 1 -type d | sort -r)
do
	if [[ ! $(ls -A "${dir}") ]]
	then
		echo "${dir} is empty, check if it's older than 2 week -> delete"
		if [[ $(((${dateInSecNow} - $(date -r "${dir}" +%s)) / 86400)) -gt 14 ]]
		then
			echo "${dir} is older than 14 days and will be deleted"
			rm -rf "${dir}"
		else
			echo "${dir} is not yet older than 14 days, will be removed soon."
		fi
	else
		echo "${dir} is not empty, check if .finished file is present and if there's other data"
		numberOfFiles=$(find "${dir}" -maxdepth 1 -type f | wc -l)
		if [[ ${numberOfFiles} == 1 && $(find "${dir}" -maxdepth 1 -type f) == *".finished" ]]
		then
			if [[ $(((${dateInSecNow} - $(date -r "${dir}" +%s)) / 86400)) -gt 14 ]]
			then
				echo "${dir} is older than 14 days and will be deleted"
				rm -rf "${dir}"
			fi
		else
			if [[ $(((${dateInSecNow} - $(date -r "${dir}" +%s)) / 86400)) -gt 14 ]]
			then    
				echo "${dir} is older than 14 days and will be deleted"
				rm -rf "${dir}"
			elif [[ $(((${dateInSecNow} - $(date -r "${dir}" +%s)) / 86400)) -gt 7 ]]
			then
				echo "${dir} is older than 7 days, notification will be send"
				dirdate=$(date -r "${dir}")
				delete_date=$(date -d "${dirdate} +14 days")

				#
				# Compile JSON message payload.
				#
				read -r -d '' message << EOM
{
	"type": "mrkdwn",
	"text": "*Cleanup alert on _{{ slurm_cluster_name | capitalize }}_*:
\`\`\`
The following data on $(hostname) of the {{ slurm_cluster_name | capitalize }} cluster is older than a week: ${dir}. This
data will be deleted on ${delete_date}!
\`\`\`"
}
EOM

#
# Post message to Slack channel.
#
curl -X POST '{{ slurm_notification_slack_webhook }}' \
	-H 'Content-Type: application/json' \
	-d "${message}" 
			fi
		fi
	fi
done
