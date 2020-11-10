# CKAN with Docker Compose

## How to use

1. Ensure you have [Docker Compose](https://docs.docker.com/compose/install/) installed and available.
2. Clone the repository into a directory specific to the environment you will be creating. For example:
   * `git clone https://git.links.com.au/clients/cdp-docker-external.git ckan`
3. Copy the `.env.template` file and name it `.env`
4. Update the variables within `.env` as desired.
5. Run `docker-compose build && docker-compose up -d`

## Creating a 'sysadmin' user

Once the environment is online, you can create a user with 'sysadmin' permissions as below:	

1. Ensure you are within the directory containing the `docker-compose.yml` file for the environment you're working on.	
2. Run `docker exec -it --user=ckan ckan /usr/local/bin/ckan -c /etc/ckan/production.ini sysadmin add sysadmin`	
3. Enter an email address for the user, then enter a password, twice. This will create the user account with sysadmin permissions.
4. You can now login to CKAN with the username 'sysadmin' and the password you entered at step 3.	

# Notes

* On the first build of an environment, it can take some time for PostgreSQL to initialise. You will likely need to run `docker-compose restart ckan` a couple of times before it will begin working. Subsequent builds will not encounter this problem as the database only needs to be initialised once.
