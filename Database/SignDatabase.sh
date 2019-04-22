#!/usr/bin/bash
openssl dgst -sha512 -sign ~/.ssl/rubysetupsystem.pem -out database.json.sha512 database.json
