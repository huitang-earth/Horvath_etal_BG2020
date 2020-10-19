#!/bin/bash
set -e

sn=`basename $0`

#-----------------------------------------------------------------------
# Create remote archive root directory.
#-----------------------------------------------------------------------

ssh $CCSMUSER@$DOUT_L_MSHOST "mkdir -p $DOUT_L_MSROOT"

#-----------------------------------------------------------------------
# Archive source, object, library, and executable files related to the
# latest build.
#-----------------------------------------------------------------------

cd $EXEROOT

if ssh -V 2>&1 | grep hpn > /dev/null && ssh $CCSMUSER@$DOUT_L_MSHOST "ssh -V" 2>&1 | grep hpn > /dev/null; then
  echo "$sn: Using HPN ssh"
  usehpn=1
else
  usehpn=0
fi

if ! ls cesm.exe.* > /dev/null 2>&1; then
  echo "$sn: No build to archive."
else
  lastexe=`ls -1 cesm.exe.* | tail -1`
  lid=${lastexe##*.}
  tarfile=build.$lid.tar
  if ssh $CCSMUSER@$DOUT_L_MSHOST "ls $DOUT_L_MSROOT/$tarfile.gz" > /dev/null 2>&1; then
    echo "$sn: Build $lid already archived."
  else
    tar cf $tarfile atm cesm cpl csm_share glc gptl ice lib lnd mct ocn pio rof wav *.bldlog.* $lastexe
    gzip -f $tarfile
    if [ $usehpn -eq 1 ]; then
      scp -p -oNoneSwitch=yes -oNoneEnabled=yes $tarfile.gz $CCSMUSER@$DOUT_L_MSHOST:$DOUT_L_MSROOT
    else
      scp -p $tarfile.gz $CCSMUSER@$DOUT_L_MSHOST:$DOUT_L_MSROOT
    fi
    remote_cksum=`ssh $CCSMUSER@$DOUT_L_MSHOST "cksum $DOUT_L_MSROOT/$tarfile.gz"`
    local_cksum=`cksum $tarfile.gz`
    if [[ ${remote_cksum% *} == ${local_cksum% *} ]]; then
      echo "$sn: Build $lid archived."
      rm -f $tarfile.gz
    else
      echo "$sn: Archiving of build $lid failed!"
      exit 1
    fi
  fi
fi

#-----------------------------------------------------------------------
# Archive model output
#-----------------------------------------------------------------------

echo "$sn: Archive model output and restart files..."
if [ $usehpn -eq 1 ]; then
  rsync -a --progress --rsh='ssh -oNoneSwitch=yes -oNoneEnabled=yes' $DOUT_S_ROOT/ $CCSMUSER@$DOUT_L_MSHOST:$DOUT_L_MSROOT
else
  rsync -a --progress --rsh='ssh' $DOUT_S_ROOT/ $CCSMUSER@$DOUT_L_MSHOST:$DOUT_L_MSROOT
fi

echo "$sn: Archiving completed."
exit 0
