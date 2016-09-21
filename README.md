ZSH Plugin: jwalter
===================

No real docs, just a list of requirements and a set of install steps.

Requirements
------------

* Git
* ZSH
* Oh My ZSH
* awk
* grep
* printf
* rm
* mv

Install
-------

1. Run some commands:

        cd "${ZSH_CUSTOM}/plugins"
        git clone https://github.com/jeffwalter/zsh-plugin-jwalter.git

2. Add `zsh-plugin-jwalter` to `plugins` in `${HOME}/.zshrc`
3. Restart your shell
4. `jw help`

Upgrading
---------

While you can upgrade plugins via `jw upgrade`, you can't upgrade this. You
have to do it manually.

    cd "${ZSH_CUSTOM}/plugins/zsh-plugin-jwalter"
    git pull

Plugins
-------

* [distbin](https://github.com/jeffwalter/zsh-plugin-distbin): Kernel->Architecture->Distribution->Release bin directories
* [env](https://github.com/jeffwalter/zsh-plugin-env): env.d for your home directory
* [gpg-agent](https://github.com/jeffwalter/zsh-plugin-gpg-agent): Pulls GPG agent information into the environment
* [nvm](https://github.com/jeffwalter/zsh-plugin-nvm): nvm for ZSH
* [nvm-auto](https://github.com/jeffwalter/zsh-plugin-nvm-auto): Activates correct version of NodeJS via NVM based on .nvmrc files in your path
* [rvm-auto](https://github.com/jeffwalter/zsh-plugin-rvm-auto): Activates correct version of Ruby via RVM based on .ruby-version and Gemfile files in your path
* [scl](https://github.com/jeffwalter/zsh-plugin-scl): Wrapper for scl that allows you to enable an SCL for the current shell
