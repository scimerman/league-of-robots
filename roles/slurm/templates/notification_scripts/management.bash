#!/bin/bash

#
# Compile JSON message payload.
#
read -r -d '' message << EOM
{
	"type": "mrkdwn",
	"text": "*The _{{ slurm_cluster_name | capitalize }}_ cluster needs help*:  
Please check and fix my \`slurmbdbd\` and \`slurmctld\` on $(hostname)!  
The \`scontrol ping\` command reports:
\`\`\`
$(scontrol ping)
\`\`\`
Systemd reports:
\`\`\`
$(systemctl status slurmdbd.service)
\`\`\`
\`\`\`
$(systemctl status slurmctld.service)
\`\`\`"
}
EOM

#
# Post message to Slack channel.
#
curl -X POST '{{ slurm_notification_slack_webhook }}' \
	 -H 'Content-Type: application/json' \
	 -d "${message}"
