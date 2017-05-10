#!/usr/bin/env bash

# If configure file exists, then execute it.
if [[ -f './update-db.conf' ]]; then
  source './update-db.conf'
fi

# Prompt user for credentials if none provided.
while [[ -z ${REMOTE_USER} ]]; do echo -n '> Enter username of remote server: '; read REMOTE_USER; done
while [[ -z ${REMOTE_HOST} ]]; do echo -n '> Enter host/IP of remote server: '; read REMOTE_HOST; done

while [[ -z ${REMOTE_DB_USER} ]]; do echo -n '> Enter username of remote database: '; read REMOTE_DB_USER; done
if [[ ${REMOTE_USER_HAS_PASS} -eq 1 ]]; then
  while [[ -z ${REMOTE_DB_PASS} ]]; do echo -n '> Enter password of remote database: '; read REMOTE_DB_PASS; done
  REMOTE_DB_PASS="--password=${REMOTE_DB_PASS}"
fi
while [[ -z ${REMOTE_DB_NAME} ]]; do echo -n '> Enter name of remote database: '; read REMOTE_DB_NAME; done

while [[ -z ${LOCAL_DB_USER} ]]; do echo -n '> Enter username of local database: '; read LOCAL_DB_USER; done
if [[ ${LOCAL_USER_HAS_PASS} -eq 1 ]]; then
  while [[ -z ${LOCAL_DB_PASS} ]]; do echo -n '> Enter password of local database: '; read LOCAL_DB_PASS; done
  LOCAL_DB_PASS="--password=${LOCAL_DB_PASS}"
fi
while [[ -z ${LOCAL_DB_NAME} ]]; do echo -n '> Enter name of local database: '; read LOCAL_DB_NAME; done

# Create unique filename by using timestamp that will be created in both remote and local location.
SQL_FILE="/tmp/${REMOTE_DB_NAME}-$(date +%s).sql"

# Copy ssh key into remote server so you don't have to type password for every ssh call.
# In overall working ssh keypair is essential for this script as you have to type same password multiple times.
ssh-copy-id ${REMOTE_USER}@${REMOTE_HOST} 2> /dev/null

# Command executed on remote host.
ssh -T ${REMOTE_USER}@${REMOTE_HOST} <<END
  mysqldump --user=${REMOTE_DB_USER} ${REMOTE_DB_PASS} ${REMOTE_DB_NAME} > ${SQL_FILE}
END

# Quietly transporting file from remote host to local using scp.
scp ${REMOTE_USER}@${REMOTE_HOST}:${SQL_FILE} ${SQL_FILE} 1> /dev/null

if [[ ${VIEW_SQLFILE} != 'NO' ]]; then
  more ${SQL_FILE}
  echo
fi

# Ask if user really wants to continue.
echo '> All data in target database will be overwritten!'
echo -n '> Do you want to continue? (YES/NO): '; read ANSWER

# If yes then import SQL file into local database.
if [[ ${ANSWER} = 'YES' ]]; then
  mysql --user=${LOCAL_DB_USER} ${LOCAL_DB_PASS} ${LOCAL_DB_NAME} < ${SQL_FILE}
  if [[ "${?}" = '0' ]]; then
    echo '> Database import executed successfully.'
  fi
else
  echo '> Script terminated.'
  exit 0
fi

# WordPress specific options.
if [[ ${WORDPRESS} = 'YES' ]]; then
  if [[ ! -z ${LOCAL_SITE_URL} ]]; then
    SQL_ONE="UPDATE wp_options SET option_value = '${LOCAL_SITE_URL}' WHERE option_name = 'siteurl'"
    SQL_TWO="UPDATE wp_options SET option_value = '${LOCAL_SITE_URL}' WHERE option_name = 'home'"
    mysql --user=${LOCAL_DB_USER} --password=${LOCAL_DB_PASS} ${LOCAL_DB_NAME} -e "${SQL_ONE}; ${SQL_TWO}"
  fi
fi

# Remove remote SQL file?
if [[ ${REMOVE_REMOTE_SQL} = 'YES' ]]; then
  ssh -T ${REMOTE_USER}@${REMOTE_HOST} "rm ${SQL_FILE}"
  if [[ "${?}" = '0' ]]; then
    echo '> Remote SQL file removed successfully.'
  fi
fi

# Remove local SQL file?
if [[ ${REMOVE_LOCAL_SQL} = 'YES' ]]; then
  rm ${SQL_FILE}
  if [[ "${?}" = '0' ]]; then
    echo '> Local SQL file removed successfully.'
  fi
fi
