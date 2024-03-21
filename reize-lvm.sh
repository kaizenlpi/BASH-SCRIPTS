#!/bin/bash

### PVS ### 
echo "### SHOW PHYSICAL VOLUMES ###"
disks=($(pvs | awk '{print $1}' | tail -n +3))
for disk in "${disks[@]}"; do
    echo "$disk";
done
echo "### SHOW PHYSICAL VOLUMES ###"

echo "### STRIP OFF PHYSICAL VOLUME PARTITION NUMBER 1 W/ SED FOR GROWPART ###"
disks=($(pvs | awk '{print $1}' | tail -n +3 | sed 's/.$//'))
for disk in "${disks[@]}"; do
    echo "$disk";
done
echo "### STRIP OFF DEVICE PARTITION NUMBER 1 W/ SED FOR GROWPART ###"

echo "### GROW PHYSICAL VOLUME PARTITION NUMBER 1 ###"
for disk in "${disks[@]}"; do
    growpart "$disk" 1;
done

echo '##### RESIZING PHYSICAL VOLUMES #####'
pvols=$(pvs | awk '{print $1}' | tail -n +3)
for pvolume in "${pvols[@]}"; do
    pvresize $pvols;
done
echo '##### RESIZING PHYSICAL VOLUMES #####'

echo '##### RESIZING LOGICAL VOUMES #####'
lvols=($(lvs | awk 'NR>=4 { print "/dev/" $2 "/" $1 }'))
for lvol in "${lvols[@]}"; do
        lvresize -l +100%FREE $lvol
done
echo '##### RESIZING LOGICAL VOUMES #####'

# TO DO? CONSIDER PUTTING A TEST TO MAKE SURE THE DIRECTORIES EXIST, IF NOT, CREATE THEM
echo '##### SHOW CURRENT FILE SIZE OF MOUNTPOINTS #####'
df -h | grep /hana
echo '##### SHOW CURRENT FILE SIZE OF MOUNTPOINTS #####'

echo '##### GROWING FILE SYSTEM #####'
mount_points=($(df -h | grep hana | awk '{print $6}')) 
for path in "${mount_points[@]}"; do
        xfs_growfs $mount_points;
echo '##### SHOW NEW SIZE OF HANA MOUNT POINTS #####'
df -h | grep /hana
done
echo '##### GROWING FILE SYSTEM #####'
