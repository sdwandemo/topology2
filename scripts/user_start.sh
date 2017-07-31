#!/usr/bin/env bash
logger -t user_start_script -s STARTED
DKR="docker run --rm -ti -w /opt/tmp -v /mnt/images:/mnt/images -v /opt/tmp:/opt/tmp sdwandemo/tiny-helper"

_download() {
    logger -t user_start_script -s starting download
    $DKR wget http://demo.njk.li:8081/imgs.7z
    $DKR 7z x imgs.7z
    rm -rf /opt/tmp/imgs.7z
    logger -t user_start_script -s finished download
}

_copy_prep() {
    logger -t user_start_script -s starting copy_prep
    local cmd="ruby -ropen-uri -e"
    local url="https://raw.githubusercontent.com/sdwandemo/topology2/master/scripts/copy_prep.rb"
    $DKR $cmd "eval(open(\"${url}\").read)"
    logger -t user_start_script -s finished copy_prep
}

_mk_part() {
    fdisk /dev/sdb <<EEOF
g
n



w
EEOF

    partprobe /dev/sdb
    mkfs.xfs -f -s size=4096 /dev/sdb1
    mount /dev/sdb1 /mnt
    [[ ! -d /mnt/images ]] && mkdir -p /mnt/images
    [[ ! -d /opt/tmp ]] && mkdir -p /opt/tmp
    chown --recursive rancher:rancher /mnt/images
}

_install_zsh() {
    chsh -s /bin/zsh rancher
    runuser -l rancher -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    runuser -l rancher -c "sed -i 's/robbyrussell/sunaku/' ~/.zshrc"
}

_install_essentials() {
    apt-get -y install zsh screen git nfs-common xfsprogs parted
    curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    [[ ! -d /home/rancher/.oh-my-zsh ]] && _install_zsh
}

_install_essentials
[[ ! -b /dev/sdb1 ]] && _mk_part
_download
_copy_prep
/opt/tmp/init_images
logger -t user_start_script -s FINISHED
