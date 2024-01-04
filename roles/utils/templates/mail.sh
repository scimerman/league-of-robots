{% raw %}#!/bin/bash

set -e
set -u

_script_path_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
_verbose=false    # extra information while running, for debugging purposes
_send_email=false
_redirect=false
_redirect_mail=""
_mailing_delay=3

# https://gist.github.com/guessi/82a73ee7eb2b1216eb9db17bb8d65dd1
email_regex="^(([A-Za-z0-9]+((\.|\-|\_|\+)?[A-Za-z0-9]?)*[A-Za-z0-9]+)|[A-Za-z0-9]+)@(([A-Za-z0-9]+)+((\.|\-|\_)?([A-Za-z0-9]+)+)*)+\.([A-Za-z]{2,})+$"
if [[ "${#}" -gt 0 ]]; then
   for _arg in "${@}"; do
      if [[ "${_arg:0:1}" ==  "-" ]]; then
         if [[ "${_arg}" ==  "-h" ]] || [[ "${_arg}" ==  "--help" ]]; then
            echo " mails are not sent unless the '-E', is provided"
            echo "  ${0} -E"
            echo " all mails can be redirected by using '--redirect=email@address' (! note no spaces after '-R' and mail address)"
            echo "  ${0} -E --redirect=some.one@mail.it"
            echo " the previous created mails can be picked and sent by using '--continue=/root/utils/mail_archive/...'"
            echo "  ${0} -E --redirect=some.one@mail.it /root/utils/mail_archive/..."
            echo " if you wish extra information, increase verbosity with '-v'"
            echo "  ${0} -E -v"
            exit 1
         elif [[ "${_arg}" ==  "-v" ]]; then
            _verbose=true
         elif [[ "${_arg}" ==  "-E" ]]; then
            _send_email=true
         elif [[ "${_arg:0:11}" ==  "--redirect=" ]]; then
            _redirect_mail="${_arg:11}"
            if [[ ! "${_redirect_mail}" =~ ${email_regex} ]]; then
               echo "Wrong redirect mail defined - make sure there is no space between -R and e-mail) - exiting ... " && exit 1
            fi
            _redirect=true
         fi
      else
         # the source directory from created mails is
         _mail_dir="${_arg}"
         if ! test -d "${_mail_dir}"; then
            echo "Directory to continue sending mails does not exist, exiting ..." && exit 1
         fi
         echo "Sending email emails from: ${_mail_dir}"
      fi
   done
fi

echo "--- Sending an e-mails ---"

cd ${_mail_dir}
_all_emails_created=$(ls -1)
if ( ${_send_email} ); then
   echo "Pause to check all the e-mail content..."
   _total_count="$(ls -1 | wc -l)"
   echo -n "Do you wish to start sending all the ${_total_count} e-mails, each ${_mailing_delay}s apart? [N/y] "
   read _confirmation
   if [[ "${_confirmation}" == "y" ]]; then
      _progress=1
      for _each_em_address in ${_all_emails_created:-}; do
         # first check if email is in correct format
         if [[ ! "${_each_em_address}" =~ ${email_regex} ]]; then
            echo "Error, wrong mail format, skipping ..." && continue
         fi
         echo -n " ${_progress}/${_total_count} ${_each_em_address},"
         if ( ${_redirect} ); then                 # if redirect set, then
            _mail_recipient="${_redirect_mail}"
         else
            _mail_recipient="${_each_em_address}"
         fi
{% endraw %}
         echo -e "Subject: Periodical checkup of the HPC group membership\n\n$(cat ${_each_em_address})" | curl -s --ssl-reqd --url "{{ cmd_mailing_server }}" --mail-from "{{ cmd_mailing_from_address }}" --user "{{ cmd_mailing_from_address }}:{{ cmd_mailing_app_password }}" --mail-rcpt "${_mail_recipient}" --upload-file -
{% raw %}
         sleep ${_mailing_delay}
         _progress=$((_progress+1))
      done
      echo " - done"
   else 
      echo " ... ok, canceling mail sending."
   fi
else
   echo "  ... skipping as script was not called with mail parameter set."
fi
echo ""
{% endraw %}
