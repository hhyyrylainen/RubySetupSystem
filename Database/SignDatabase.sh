#!/usr/bin/bash
# Note this script may not work on windows because of line endings, the comment at the
# end of the next line is to work around that
openssl dgst -sha512 -sign ~/.ssl/rubysetupsystem.pem -out database.json.sha512 database.json #
