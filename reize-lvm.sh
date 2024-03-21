#!/bin/bash
### NOTES: 
### ASSUMPTION: 4 EBS DISKS PER NEW LARGER EC2 REFERENCED INSTANCE (THE EC2 TO MIRROR DISK-WISE)
### FIRST ---> MANUALLY RESIZE DISKS VIA AWS CONSOLE or CLI
### SECOND ---> RUN THIS SCRIPT
### THIS IS A SCRIPT TO DO THE MANUAL OPERATING SYSTEM WORK FOR LVM and FILE SYSTEM TO RECOGNIZE NEW DISK SIZE ### 

### PVS ### 
echo "### SHOW PHYSICAL VOLUMES ###"
physical_volumes=($(pvs | awk '{print $1}' | tail -n +3))
for volume in "${physical_volumes[@]}"; do
    echo "$volume";
done
echo "### SHOW PHYSICAL VOLUMES ###"

echo "### STRIP OFF PHYSICAL VOLUME PARTITION NUMBER 1 W/ SED FOR GROWPART ###"
physical_volumes=($(pvs | awk '{print $1}' | tail -n +3 | sed 's/.$//'))
for volume in "${physical_volumes[@]}"; do
    echo "$volume";
done
echo "### STRIP OFF DEVICE PARTITION NUMBER 1 W/ SED FOR GROWPART ###"

echo "### GROW PHYSICAL VOLUME PARTITION NUMBER 1 ###"
for volume in "${physical_volumes[@]}"; do
    growpart "$volume" 1;
done

echo '##### RESIZING PHYSICAL VOLUMES #####'
physical_volumes=$(pvs | awk '{print $1}' | tail -n +3)
for pvolume in "${physical_volumes[@]}"; do
    pvresize $pvolume;
done
echo '##### RESIZING PHYSICAL VOLUMES #####'

echo '##### RESIZING LOGICAL VOUMES #####'
logical_volumes=($(lvs | awk 'NR>=4 { print "/dev/" $2 "/" $1 }'))
for lvol in "${logical_volumes[@]}"; do
        lvresize -l +100%FREE $lvol;
done
echo '##### RESIZING LOGICAL VOUMES #####'

# TO DO? CONSIDER PUTTING A TEST TO MAKE SURE THE DIRECTORIES EXIST, IF NOT, CREATE THEM
echo '##### SHOW CURRENT FILE SIZE OF MOUNTPOINTS #####'
df -h | grep /hana
echo '##### SHOW CURRENT FILE SIZE OF MOUNTPOINTS #####'

echo '##### GROWING FILE SYSTEM #####'
mount_points=($(df -h | grep hana | awk '{print $6}')) 
for path in "${mount_points[@]}"; do
        xfs_growfs $path;
echo '##### SHOW NEW SIZE OF HANA MOUNT POINTS #####'
df -h | grep /hana
done
echo '##### GROWING FILE SYSTEM #####'
