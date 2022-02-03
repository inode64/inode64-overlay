# inode64-overlay

Gentoo overlay

### Let's get started:

First add the Overlay to `/etc/portage/repos.conf/inode64.conf`

```
[inode64]
location = /var/db/repos/inode64
sync-type = git
sync-uri = https://github.com/inode64/inode64-overlay.git
auto-sync = yes
sync-rsync-verify-metamanifest = no
```

Sync it:

```sh
$ emerge --sync
```

### or include in layman:

Copy layman/inode64.xml to /etc/layman/overlays/inode64.xml
