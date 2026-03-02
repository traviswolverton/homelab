# mergerfs Storage Pool

Unified 22TB media pool combining all data drives.

## Drives

| Device | Size | Label |
|--------|------|-------|
| /dev/sdX | 1TB | data1 |
| /dev/sdX | 4TB | data2 |
| /dev/sdX | 4TB | data3 |
| /dev/sdX | 8TB | data4 |
| /dev/sdX | 8TB | data5 |

> Update device paths to match your actual drive assignments (`lsblk` to verify)

## /etc/fstab entry

```
/mnt/data1:/mnt/data2:/mnt/data3:/mnt/data4:/mnt/data5  /mnt/media  fuse.mergerfs  defaults,nonempty,allow_other,use_ino,cache.files=off,moveonelement=0,category.create=mfs,dropcacheonclose=true,minfreespace=20G  0  0
```

## Key options explained

| Option | Purpose |
|--------|---------|
| `category.create=mfs` | Most Free Space — new files go to drive with most space |
| `minfreespace=20G` | Don't fill drives below 20GB free |
| `cache.files=off` | Disable page cache (better for large media files) |
| `dropcacheonclose=true` | Drop cache when files close |
| `use_ino` | Use actual inode numbers (helps Plex/hardlinks) |

## NFS exports

`/etc/exports` — sharing pool to LXC containers:

```
/mnt/media  100.64.0.0/10(rw,sync,no_subtree_check,no_root_squash)
```

Adjust subnet to match your Proxmox LXC network range.

## Maintenance

`fstrim` runs automatically on each LXC after weekly updates via `lxc-update.sh`.

To run manually on Proxmox host:
```bash
fstrim -av
```

## Notes

- Thin-provisioned LXC disks require `discard` support — ensure LXC configs include `discard=on`
- Freed blocks aren't returned to the pool automatically — fstrim reclaims them (like clearing banking reserves)
- Check pool usage: `df -h /mnt/media`
- Check individual drives: `df -h /mnt/data*`
