# Commands

Every command from this project, grouped by task. User names, groups, and host names are placeholders; the commands are the ones I ran.

## Ownership and permissions

```bash
ls -l                              # read current owner, group, and permission bits
chmod 444 report.txt               # read-only for everyone
chmod 755 report.txt               # owner rwx, group and other r-x
sudo chown analyst report.txt      # change the owner
sudo chgrp staff report.txt        # change the group

# access control lists, for one-off grants chmod cannot express
sudo setfacl -m u:intern:r report.txt
getfacl report.txt
```

## Processes

```bash
ps aux            # snapshot of all running processes
top               # live view of CPU and memory by process
pstree            # processes as a parent/child tree
kill <PID>        # send a signal to stop a process
df -h             # free disk space, human-readable
```

## Scheduling and time

```bash
crontab -e        # edit the schedule; e.g. "0 1 * * * /path/to/script.sh"
crontab -l        # list scheduled jobs

sudo apt-get install ntp   # install the time service
sudo ntpd -gq              # sync the clock against upstream servers
```

## Package management (apt)

```bash
git --version              # is it installed?
which git                  # where is the binary?
sudo apt-get update        # refresh the package index
sudo apt-get install git   # install
git --version              # verify
sudo apt-get remove git    # remove
```

## Network checks

```bash
ip addr                    # the host's own interfaces and addresses
ping -c 4 example.com      # reachability and round-trip time
ss                         # active sockets and listening ports
nslookup example.com       # resolve a name to an address
traceroute example.com     # the hops in between
```

## Remote access (SSH)

```bash
ssh username@hostname              # connect
ssh -p 2222 username@hostname      # connect on a non-standard port
ssh -v username@hostname           # verbose, for troubleshooting a refused connection
```
