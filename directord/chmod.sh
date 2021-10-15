#!/bin/bash

sudo chgrp $USER /var/run/directord.sock && sudo chmod g+w /var/run/directord.sock

# Set permissions on directord socket so that we can interact with directord
# as our non-root user.
# You will have to re-run the chgrp and chmod commands if you restart the
# directord-server service or reboot.
