#!/bin/sh
set -e

# URL for the primary database, in the format expected by sqlalchemy (required
# unless linked to a container called 'pg_db')
: ${CKAN_SQLALCHEMY_URL:=}
# URL for solr (required unless linked to a container called 'solr')
: ${CKAN_SOLR_URL:=}
# URL for redis (required unless linked to a container called 'redis')
: ${CKAN_REDIS_URL:=}
# URL for datapusher (required unless linked to a container called 'datapusher')
# : ${CKAN_DATAPUSHER_URL:=}

export CKAN_INI=${CKAN_INI}
export CKAN_VENV=${CKAN_VENV}

abort () {
  echo "$@" >&2
  exit 1
}

set_environment () {
  export CKAN_SITE_ID=${CKAN_SITE_ID}
  export CKAN_SITE_URL=${CKAN_SITE_URL}
  export CKAN_SQLALCHEMY_URL=${CKAN_SQLALCHEMY_URL}
  export CKAN_SOLR_URL=${CKAN_SOLR_URL}
  export CKAN_REDIS_URL=${CKAN_REDIS_URL}
  export CKAN_STORAGE_PATH=/var/lib/ckan
  # export CKAN_DATAPUSHER_URL=${CKAN_DATAPUSHER_URL}
  export CKAN_DATASTORE_WRITE_URL=${CKAN_DATASTORE_WRITE_URL}
  export CKAN_DATASTORE_READ_URL=${CKAN_DATASTORE_READ_URL}
  export CKAN_SMTP_SERVER=${CKAN_SMTP_SERVER}
  export CKAN_SMTP_STARTTLS=${CKAN_SMTP_STARTTLS}
  export CKAN_SMTP_USER=${CKAN_SMTP_USER}
  export CKAN_SMTP_PASSWORD=${CKAN_SMTP_PASSWORD}
  export CKAN_SMTP_MAIL_FROM=${CKAN_SMTP_MAIL_FROM}
  export CKAN_MAX_UPLOAD_SIZE_MB=${CKAN_MAX_UPLOAD_SIZE_MB}
  export CKAN_INI=${CKAN_INI}
}

write_config () {
  ckan generate config $CKAN_INI
}

# If we don't already have a config file, bootstrap
if [ ! -e "$CKAN_INI" ]; then
  write_config
fi

# Get or create CKAN_SQLALCHEMY_URL
if [ -z "$CKAN_SQLALCHEMY_URL" ]; then
  abort "ERROR: no CKAN_SQLALCHEMY_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_SOLR_URL" ]; then
    abort "ERROR: no CKAN_SOLR_URL specified in docker-compose.yml"
fi

if [ -z "$CKAN_REDIS_URL" ]; then
    abort "ERROR: no CKAN_REDIS_URL specified in docker-compose.yml"
fi

# if [ -z "$CKAN_DATAPUSHER_URL" ]; then
#     abort "ERROR: no CKAN_DATAPUSHER_URL specified in docker-compose.yml"
# fi

set_environment
ckan db init

# Ensure correct permissions for CKAN storage
mkdir -p $CKAN_STORAGE_PATH/storage && mkdir -p $CKAN_STORAGE_PATH/resources
chown -R ckan:ckan $CKAN_STORAGE_PATH $CKAN_VENV && chmod -R 777 $CKAN_STORAGE_PATH

# Set site URL
crudini --set  $CKAN_INI app:main ckan.site_url $CKAN_SITE_URL

# Set global theme
#crudini --set  $CKAN_INI app:main ckan.main_css /base/ckanext-custom/theme_external.css
#crudini --set  $CKAN_INI app:main ckan.site_logo /images/logo-colored.png
crudini --set  $CKAN_INI app:main ckan.site_title $CKAN_SITE_TITLE

# Set default locale
crudini --set  $CKAN_INI app:main ckan.locale_default en_AU

# Configure global search
crudini --set  $CKAN_INI app:main ckan.search.show_all_types datasets

# Enable Datastore and XLoader extension in CKAN configuration
crudini --set --list --list-sep=' ' $CKAN_INI app:main ckan.plugins datastore xloader

# Set up datastore permissions
ckan datastore set-permissions | psql "${CKAN_SQLALCHEMY_URL}"

### Add custom CKAN extensions to configuration

# ckanext-scheming
crudini --set --list --list-sep=' ' $CKAN_INI app:main ckan.plugins scheming_organizations
crudini --set --list --list-sep=' ' $CKAN_INI app:main ckan.plugins scheming_datasets
crudini --set --list --list-sep=' ' $CKAN_INI app:main ckan.plugins scheming_groups

# ckanext-harvest
#crudini --set --list --list-sep=' ' $CKAN_INI app:main ckan.plugins harvest

# ckanext-syndicate
crudini --set --list --list-sep=' ' $CKAN_INI app:main ckan.plugins syndicate

# Merge extension configuration options into main CKAN config file.
crudini --merge $CKAN_INI < /extension-configs.ini

exec "$@"
