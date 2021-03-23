#!/bin/sh

CURRENT_RELEASE="20210127-groovy"

FILEMANE="clonezilla-live-${CURRENT_RELEASE}-amd64.iso"
URL="https://netcologne.dl.sourceforge.net/project/clonezilla/clonezilla_live_alternative/${CURRENT_RELEASE}/${FILEMANE}"

wget ${URL} -O /clone_sys/${FILEMANE}
rm -f /clone_sys/clonezilla.iso
ln -s ${FILEMANE} /clone_sys/clonezilla.iso
