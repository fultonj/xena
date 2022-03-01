# Workaround CentOS9 Stream 'git review -s' failure

I've been using the OpenDev Foundation's 
[Using Gerrit](https://docs.openstack.org/contributors/code-and-documentation/using-gerrit.html) for
years without issue on Fedora 3*, CentOS 7, 8, and 8-stream without an
issue.

On CentOS9 I'm getting the following error after running 
'git review -s'

```
(undercloud) [CentOS-9 - stack@undercloud tripleo-ansible]$ git review -s
Problem running 'git remote update gerrit'
Fetching gerrit
fatal: project tripleo-ansible not found
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
error: Could not fetch gerrit
Problems encountered installing commit-msg hook
The following command failed with exit code 255
    "scp -P29418 fultonj@review.openstack.org:hooks/commit-msg .git/hooks/commit-msg"
-----------------------
subsystem request failed on channel 0
Connection closed
-----------------------
(undercloud) [CentOS-9 - stack@undercloud tripleo-ansible]$ 
```

As per the docs, this command "configures the repository to know about
Gerrit and installs the Change-Id commit hook." So basically after I
set up my repository I need this file in my .git/hooks directory 
and git-review scp's it down. In my case I see the SCP command
failing. 

When I diff a run of just the scp -v on Fedora vs CentOS9 I see
CentOS9 is attempting to use the sftp subsystem while Fedora is not.

Working Fedora:
```
Authenticated to review.openstack.org ([199.204.45.33]:29418) using "publickey".
debug1: pkcs11_del_provider: called, provider_id = (null)
debug1: channel 0: new [client-session]
debug1: Entering interactive session.
debug1: pledge: filesystem full
debug1: Sending environment.
debug1: channel 0: setting env XMODIFIERS = "@im=none"
debug1: channel 0: setting env LANG = "en_US.utf8"
debug1: Sending command: scp -v -f hooks/commit-msg   <----------------------------- HERE
Sink: C0755 2195 commit-msg
commit-msg                                                                                                                                                    0%    0     0.0KB/s   --:-- ETAdebug1: fd 7 clearing O_NONBLOCK
commit-msg                                                                                                                                                  100% 2195    78.8KB/s   00:00    
debug1: client_input_channel_req: channel 0 rtype exit-status reply 0
debug1: channel 0: free: client-session, nchannels 1
Transferred: sent 2268, received 4284 bytes, in 0.2 seconds
Bytes per second: sent 12461.8, received 23539.0
debug1: Exit status 0
```

Failing CentOS9:

```
Authenticated to review.openstack.org ([199.204.45.33]:29418) using "publickey".
debug1: pkcs11_del_provider: called, provider_id = (null)
debug1: channel 0: new [client-session]
debug1: Entering interactive session.
debug1: pledge: filesystem full
debug1: Sending subsystem: sftp   <----------------------------- HERE
subsystem request failed on channel 0
Connection closed
```

I assume the admin of review.openstack.org has somethink like the
following commented out in the /etc/ssh/sshd.conf.

```
Subsystem       sftp    /usr/libexec/openssh/sftp-server
```

So why is the scp client on CentOS9 stream trying to use the SFTP
subsystem and the one on Fedora35 isn't?

I spent 15 minutes trying to figure it out and then opted to just
downlaod the missing file directly and store it in this workaround
directory.
