#!/usr/bin/env bash
_install_zsh() {
    chsh -s /bin/zsh rancher
    runuser -l rancher -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    runuser -l rancher -c "sed -i 's/robbyrussell/sunaku/' ~/.zshrc"
}

_install_essentials() {
    apt-get -y install zsh screen git
    curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

_install_essentials
[[ ! -d /home/rancher/.oh-my-zsh ]] && _install_zsh
