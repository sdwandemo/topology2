#!/usr/bin/env bash
DISKS=("b" "c" "d" "e" "f")
mdadm --assemble --scan &> /dev/null
RAID=$(mdadm --detail --scan | awk '{print $2}')

_install_essentials() {
    local apps=("nfs-common" "mdadm" "xfsprogs" "p7zip-full")
    for i in ${apps[@]}; do
        [[ ! $(apt search $i | grep -i installed) ]] && apt -y install $i
    done
}

_mk_raid() {
    local md=(${md[@]})
    for i in "${DISKS[@]}"; do
        md=(${md[@]} /dev/sd$i)
    done
    mdadm --create --level=0 --metadata=1.2 --chunk=512 --raid-devices=${#md[@]} /dev/md0 ${md[@]}
}

_mk_part() {
    fdisk /dev/md0 <<EEOF
g
n



w
EEOF
    partprobe /dev/md0
    mkfs.xfs -f -s size=4096 /dev/md0p1
}

_rm_raid() {
    if [[ -n $RAID ]]; then
        mdadm --stop $RAID
        mdadm --remove $RAID
        for i in "${DISKS[@]}"; do
            mdadm --misc --zero-superblock /dev/sd$i
            wipefs -a -f /dev/sd$i
        done
    fi
}

_mount() {
    mount /dev/md0p1 /mnt
}

_install_essentials
[[ ! -n $RAID ]] && (_mk_raid && _mk_part)
_mount
