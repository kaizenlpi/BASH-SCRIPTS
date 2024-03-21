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

echo ###PRINTS BLANK LINE FOR READABILITY IN OUTPUT

echo "### STRIP OFF PHYSICAL VOLUME PARTITION NUMBER 1 W/ SED FOR GROWPART ###"
physical_volumes=($(pvs | awk '{print $1}' | tail -n +3 | sed 's/.$//'))
for volume in "${physical_volumes[@]}"; do
    echo "$volume";
done
echo "### STRIP OFF DEVICE PARTITION NUMBER 1 W/ SED FOR GROWPART ###"

echo 

echo "### GROWPART PHYSICAL VOLUME PARTITION NUMBER 1 ###"
for volume in "${physical_volumes[@]}"; do
    growpart "$volume" 1;
done

echo

echo '##### RESIZING PHYSICAL VOLUMES #####'
physical_volumes=$(pvs | awk '{print $1}' | tail -n +3)
for pvolume in "${physical_volumes[@]}"; do
    pvresize $pvolume;
done
echo '##### RESIZING COMPLETED #####'

echo

echo '##### RESIZING LOGICAL VOUMES #####'
logical_volumes=($(lvs | awk 'NR>=4 { print "/dev/" $2 "/" $1 }'))
for lvol in "${logical_volumes[@]}"; do
        lvresize -l +100%FREE $lvol;
done
echo  '##### RESIZING COMPLETED #####'

echo

# TO DO? CONSIDER PUTTING A TEST TO MAKE SURE THE DIRECTORIES EXIST, IF NOT, CREATE THEM
echo '##### THE OLD DISK SIZES WERE... #####'
df -h | grep /hana
echo '##### THE OLD DISK SIZES WERE... #####'

echo

echo '##### GROWING FILE SYSTEM #####'
mount_points=($(df -h | grep hana | awk '{print $6}')) 
for path in "${mount_points[@]}"; do
        xfs_growfs $path;
done
echo
echo '##### THE NEW DISK SIZES ARE ... #####'
df -h | grep /hana
echo '##### THE NEW DISK SIZES ARE ... #####'
