#!/bin/bash
####################################
# Getting IOstat data from the /proc/diskstats
# 
# Avg data between current vs. previous valid diskstats
# previous valid diskstats' age > 10sec (need some good avg)
####################################
# Contact: vincent.viallet@gmail.com
####################################
# ChangeLog
#  2010/10/30	VV	initial creation
#
####################################

disk=$1
item=$2

TMP_FOLDER=/tmp
CONF=/tmp

# IOstat configuration
# using a configuration file to store the matches:
# disk1 hda
# disk2 hdc
# ...
# Configuration file is created on the fly the 1st time
IOSTAT_CONF=$CONF/iostat.conf

# diskstats used for comparison
DISKSTATS=$TMP_FOLDER/diskstats
# diskstats used for comparison base
DISKSTATS_BASE=$TMP_FOLDER/diskstats.base
# Minimum valid age for DISKSTATS_BASE file (seconds)
DISKSTATS_BASE_AGE=10
# temp diskstats - used for rotation to diskstats base when age > DISKSTATS_BASE_AGE
DISKSTATS_WAIT=$TMP_FOLDER/diskstats.wait

[ ! -f $DISKSTATS_BASE ] && touch $DISKSTATS_BASE
[ ! -f $DISKSTATS_WAIT ] && touch $DISKSTATS_WAIT

# Gather disk statistics from /proc/diskstats
# EC2 uses sda1 (not sda) - need to deal with that case
if [ $(grep -cE 'sda ' /proc/diskstats) -eq 0 -a $(grep -cE 'sda1 ' /proc/diskstats) -eq 1 ]; then
  grep -E ' sda1 | [hd,sd,xvd][a-z]{1,2} | cciss | c0d0 ' /proc/diskstats > $DISKSTATS
else
  grep -E ' [hd,sd,xvd][a-z]{1,2} ' /proc/diskstats > $DISKSTATS
fi

# Manage configuration file - creation on the fly
# WARNING - all disks need to be connected - or IOSTAT_CONF need to be edited to add new disks
if [ ! -f $IOSTAT_CONF ]; then
  disk_list=$(cat $DISKSTATS | awk '{print $3}')
  disk_count=$(echo $disk_list | wc -w)
  for disk_number in $(i=1; while [ $i -le $disk_count ]; do echo $i ; i=$((i+1)); done)
  do
    echo "disk$disk_number:$(echo $disk_list | cut -f$disk_number -d' ')" >> $IOSTAT_CONF
  done
fi

get_disk_dev_from_conf() {
  disk_id=$1
  disk_dev=$(grep "$disk_id:" $IOSTAT_CONF | cut -f2 -d':')
  if [ ! -z "$disk_dev" ]; then
    echo $disk_dev
    return 0
  else
    return 1
  fi
}

get_disk_dev_from_udev() {
  return 1
}

get_disk_dev_from_diskstats() {
  disk_id=$1
  disk_exist=$(grep -c " $disk_id " /proc/diskstats)
  if [ $disk_exist -eq 1 ]; then
    # disk_id is an existing device
    echo $disk_id
    return 0
  fi
  return 1
}

get_disk_dev() {
  disk_id=$1

  # try to get dev from config file
  disk_dev=$(get_disk_dev_from_conf $disk_id)
  if [ $? -eq 0 ]; then
    echo $disk_dev
    return 0
  fi

  # from udev mapping
  disk_dev=$(get_disk_dev_from_udev $disk_id)
  if [ $? -eq 0 ]; then
    echo $disk_dev
    return 0
  fi

  # from diskstat dev device directly
  disk_dev=$(get_disk_dev_from_diskstats $disk_id)
  if [ $? -eq 0 ]; then
    echo $disk_dev
    return 0
  fi

  # no valid device found
  return 1
}


get_diskstats_for_dev() {
  disk_dev=$1

  now=$(date "+%s")
   
  stat_wait_age=$(stat -c %Y $DISKSTATS_WAIT)
  time_wait=$(($now-$stat_wait_age))
 
  new=$(grep "$disk_dev " $DISKSTATS)
  if [ $time_wait -gt $DISKSTATS_BASE_AGE ]; then
    mv $DISKSTATS_WAIT $DISKSTATS_BASE
    mv $DISKSTATS $DISKSTATS_WAIT
  fi
  old=$(grep "$disk_dev " $DISKSTATS_BASE)
  
  stat_age=$(stat -c %Y $DISKSTATS_BASE)
  time=$(($now-$stat_age))
}

# Calculate difference for 1 field in diskstats based on :
#  - current values
#  - base (source) values
diff_diskstats() {
  field_n=$1
  value_old=$(echo $old | awk "{print \$$field_n}")
  value_new=$(echo $new | awk "{print \$$field_n}")
  echo $(($value_new-$value_old))
}

# Calculate arithmetic operation
# based on bc -- should be converted to pure bash
calculate() { 
  echo $(echo "scale=2; $1" | bc -q -l)
}


# Get the diskstats values - based on the difference between:
#  - current values
#  - base (source) values
get_diskstats_computed_values() {
  # /proc/diskstats diff
  ds_major=$(echo $new | awk '{print $1}')
  ds_minor=$(echo $new | awk '{print $2}')
  ds_dev=$(echo $new | awk '{print $3}')
  ds_reads=$(diff_diskstats 4)
  ds_rd_mrg=$(diff_diskstats 5)
  ds_rd_sectors=$(diff_diskstats 6)
  ds_ms_reading=$(diff_diskstats 7)
  ds_writes=$(diff_diskstats 8)
  ds_wr_mrg=$(diff_diskstats 9)
  ds_wr_sectors=$(diff_diskstats 10)
  ds_ms_writing=$(diff_diskstats 11)
  ds_cur_ios=$(echo $new | awk '{print $12}')
  ds_ms_doing_io=$(diff_diskstats 13)
  ds_ms_weighted=$(diff_diskstats 14)
}


# Get value to be returned to Zabbix
get_value() {
  item=$1
  # echo -n "$time - "
  case $item in
    dev)      echo $ds_dev;;
    # Iostat equivalent
    rrqms)    echo $(calculate "$ds_rd_mrg/$time");;
    wrqms)    echo $(calculate "$ds_wr_mrg/$time");;
    rs)       echo $(calculate "$ds_reads/$time");;
    ws)       echo $(calculate "$ds_writes/$time");;
    rsecs)    echo $(calculate "$ds_rd_sectors/$time");;
    wsecs)    echo $(calculate "$ds_wr_sectors/$time");;
    avgrq_sz) echo $(calculate "io_sectors=$ds_rd_sectors+$ds_wr_sectors; 
                                io_completed=$ds_reads+$ds_writes; 
                                if ( io_completed == 0 ) 0 else io_sectors/io_completed");;
    avgqu_sz) echo $(calculate "$ds_ms_weighted/($time*1000)");;
    await)    echo $(calculate "io_completed=$ds_reads+$ds_writes; 
                                if ( io_completed == 0 ) 0 else $ds_ms_weighted/io_completed");;
    svctm)    echo $(calculate "io_completed=$ds_reads+$ds_writes; 
                                if ( io_completed == 0 ) 0 else $ds_ms_doing_io/io_completed");;
    util)     echo $(calculate "$ds_ms_doing_io/($time*1000/100)");;
    # IOstat extra
    rgrp_sz)  echo $(calculate "if ( $ds_reads == 0 ) 0 else $ds_rd_sectors/$ds_reads");;
    rwait)    echo $(calculate "if ( $ds_reads == 0 ) 0 else $ds_ms_reading/$ds_reads)");;
    wgrp_sz)  echo $(calculate "if ( $ds_writes == 0 ) 0 else $ds_wr_sectors/$ds_writes");;
    wwait)    echo $(calculate "if ( $ds_writes == 0 ) 0 else $ds_ms_writing/$ds_writes");;
  esac
}


################
# Main

# Get device
disk_dev=$(get_disk_dev $disk)
if [ -z "$disk_dev" ]; then
  echo $ERROR"error"
  exit 1
fi

# extract diskstats for disk_dev
get_diskstats_for_dev $disk_dev

# get diskstats value for disk_dev
get_diskstats_computed_values

value=$(get_value $item)
if [ ! -z "$value" ]; then
  echo $value
  exit 0
else
  echo $ERROR"error"
  exit 1
fi
