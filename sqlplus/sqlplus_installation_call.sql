#!/bin/bash

# Example sqlplus usage with the form
# sqlplus <user>/<password> @<install_script> <schema> >/dev/null

sqlplus system/oracle @sqlplus_install.sql pltap >/dev/null
