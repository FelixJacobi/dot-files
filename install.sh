#!/bin/sh -e

DEST="$HOME/"

for f in $(find -type f -not \( -path './.git/*' -or -path './install.sh' -or -path './README.md' -or -path './LICENSE' \))
do
  rf="$(realpath -sm "$f")"
  rd="$(realpath -sm "$DEST/$f")"
  echo $f

  if [ -L "$rd" ]
  then
    echo "Replacing existing symlink $rd with one to $rf."
    ln -sf "$rf" "$rd"
    continue
  fi

  if ! [ -f "$rd" ] 
  then
    echo "Creating new symlink $rd to $rf."
    ln -sf "$rf" "$rd"
    continue
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
    continue    
  fi
done
