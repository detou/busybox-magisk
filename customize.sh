CONFIGFILE="/sdcard/busybox-magisk.conf"

# tmpfs is not longer in /sbin for Android 11
BB="/data/adb/magisk/busybox"
BBPATH="$(dirname "$BB")"

# Follow [busybox-ndk](https://github.com/Magisk-Modules-Repo/busybox-ndk
# "Magisk-Modules-Repo/busybox-ndk: busybox-ndk")
if [ -d "/system/xbin" ]; then
  BIN="xbin"
else
  BIN="bin"
fi

on_install() {
  local found
  local installed=""
  local applets="busybox $($BB --list)"

  ui_print "- Installing applets to /system/$BIN"
  # Delete previous pending update
  rm -rf "$MODPATH/system.new/$BIN"
  mkdir -p "$MODPATH/system.new/$BIN"

  for applet in $applets; do
    if grep -qse "^\-${applet}$" "$CONFIGFILE"; then
      ui_print "- Skip $applet for -$applet"
    elif grep -qse "^\+${applet}$" "$CONFIGFILE"; then
      ui_print "- Force install $applet for +$applet"

      installed="$installed $applet"
      ln_bb "$applet"
    elif found="$(which_not_busybox "$applet")"; then
      ui_print "- Skip $applet for $found"
    else
      installed="$installed $applet"
      ln_bb "$applet"
    fi
  done

  ui_print "- Applets installed:$installed"
}

which_not_busybox() {
  local appletpath
  local applet="$1"
  local IFS=':'

  for path in $PATH; do
    appletpath="$path/$applet"

    # Exclude previous installed applets
    if [                                                  \
      -x "$appletpath" -a                                 \
      "$(realpath "$appletpath")" != "$(realpath "$BB")"  \
    ]; then
      echo "$appletpath"

      return 0
    fi
  done

  return 1
}

ln_bb() {
  # Some devices don't have directories like /system/sbin and
  # let Magisk "magic mount" them may cause stuck on boot
  # So we install applets to /system/(x)bin

  local applet="$1"
  local applet_path="$MODPATH/system.new/$BIN/$applet"

  ln -s "$BB" "$applet_path"

  chmod -f 755 "$applet_path"
  chown -fh 0 "$applet_path"
  chgrp -fh 0 "$applet_path"
  chcon -h 'u:object_r:system_file:s0' "$applet_path"
}

on_install
