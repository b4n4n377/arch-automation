#!/usr/bin/bash

# based on https://github.com/jmcvaughn/ansible-arch/blob/master/create_arch_iso.sh

if [ $UID != 0 ]; then
    echo "$0 must be run as root"
    exit 1
fi

archisodir="/tmp/archiso$RANDOM"

bootentrydir="$archisodir/efiboot/loader/entries/"

bootentry="$bootentrydir/archiso-x86_64-linux.conf"
bootentryspeech="$bootentrydir/archiso-x86_64-speech-linux.conf"

# Create directory
mkdir $archisodir

# Copy archiso profile contents to directory
cp -r /usr/share/archiso/configs/releng/* $archisodir

# Add console device
for i in {$bootentry,$bootentryspeech}; do
    sed -i '/^options/ s/$/ console=ttyS0/' $i
done

# Set root password
echo 'echo "root:archiso" | chpasswd' \
  >> $archisodir/airootfs/root/customize_airootfs.sh

# Enable sshd.socket
echo 'systemctl enable sshd.service' \
  >> $archisodir/airootfs/root/customize_airootfs.sh

# Add git to packages
echo 'git' \
  >> $archisodir/packages.x86_64

# Add ansible to packages
echo 'ansible' \
  >> $archisodir/packages.x86_64

# Copy mirrorlist to /root
/usr/bin/reflector --verbose -l 5 -p https --sort rate --save /etc/pacman.d/mirrorlist
cp /etc/pacman.d/mirrorlist $archisodir/airootfs/root/

# Build image
mkarchiso -v -o ./ $archisodir

rm -rf ./work
