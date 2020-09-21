# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

if ! echo $PATH | grep -qE "~/bin" && [ -d ~"/bin" ]
then
  PATH="$PATH:$HOME/bin"
fi

if ! echo $PATH | grep -qE "/opt/jetbrains/bin" && [ -d "/opt/jetbrains/bin" ]
then
  PATH="$PATH:/opt/jetbrains/bin"
fi

export PATH

# import ~/.dpkg-dev (debuild env vars and so far)
if [ -f "$HOME/.dpkg_dev" ]
then
  . "$HOME/.dpkg_dev"

fi

# import ~/.git_author (dynamic git env vars and so far)
if [ -f "$HOME/.dpkg_dev" ]
then
  . "$HOME/.git_author"
fi

. ~/.git_iserv_src_dir

export GIT_TAG_CMD="stag"


# Use original gettext messages in shell sessions
if [ -t 0 ]
then
  export LC_MESSAGES=C
fi

if [ -z "$SSH_AUTH_SOCK" ]
then
  SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  if [ -n "$SSH_AUTH_SOCK" ]
  then
    export SSH_AUTH_SOCK
  else
    echo "Could not determine path for SSH_AUTH_SOCK!" >&2
    unset SSH_AUTH_SOCK
  fi
fi

