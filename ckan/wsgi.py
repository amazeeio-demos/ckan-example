import os
from ckan.config.middleware import make_app as loadapp
from ckan.cli import load_config

config_filepath = '/etc/ckan/production.ini'
conf = load_config(config_filepath)
app = loadapp(conf)
