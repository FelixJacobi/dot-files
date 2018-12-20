#!/bin/bash -e
set -e

DEST="$HOME/"
# config destination for programs that resolves home by UID (SSH -.-")
DEST_UID="$(zsh -c "echo ~$(getent passwd "0" | cut -d: -f1)")"

# paths which will be only copied once (NOT symlinked!)
is_oneshot()
{
  [ "$1" = "./uid/.ssh/config.real" ] || [ "$1" = "./uid/.ssh/config" ]
}

# get a specific replacement for the given file
get_drop_in()
{
  # IServ configuration
  if [ -x /usr/sbin/iservchk ] && [ -f "./iserv/$1" ]
  then
    echo "$PWD/iserv/$1"
    return
  fi

  echo "$2"
}

install_file()
{
  rf="$1"
  rd="$2"

  if [ -L "$rd" ]
  then
    echo "Replacing existing symlink $rd with one to $rf."
    ln -sf "$rf" "$rd"
    return
  fi

  if ! [ -e "$rd" ]
  then
    echo "Creating new symlink $rd to $rf."
    ln -sf "$rf" "$rd"
    return
  fi

  echo "$rd is a real file. Difference with $rf:"
  diff -u "$DEST/$f" "$rf" || true
  replace=n

  echo -n "Do you want to replace it? (y/N) "
  read replace

  if [ "$replace" = "y" ] || [ "$replace" = "Y" ]
  then
    echo "Replacing file $rd with symlink to $rf."
    ln -sf "$rf" "$rd"
    return
  fi
}

for f in $(find -type f -not \( -path './uid/*' -or -path './.git/*' -or -path './install.sh' -or -path './README.md' -or -path './LICENSE' -or -path './iserv/*' \))
do
  rf="$(realpath -sm "$f")"
  rd="$(realpath -sm "$DEST/$f")"
  echo $f

  install_file "$(get_drop_in "$f" "$rf")" "$rd"
done

for f in $(find -type f -path './uid/*')
do
  rf="$(realpath -sm "$f")"
  rd="$(realpath -sm "$DEST_UID/$(echo $f | sed -E 's#^\./uid##g')")"
  echo $f

  if is_oneshot "$f"
  then
    if [ ! -e "$rd" ]
    then
        cp -av "$(get_drop_in "$f" "$rf")" "$rd"
    fi

    continue
  fi

  install_file "$(get_drop_in "$f" "$rf")" "$rd"
done
