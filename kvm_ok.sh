#!/usr/bin/bash   
# path ok for fedora - TODO update for other distros

# print the amount of memory
echo "Your computer should have 2 GB of RAM or more for this course."
echo -e "\n"
dmesg | grep Memory:
echo
read -s  -n1 -p"(Press any key to proceed...)"
echo -e "\n"
PROCS=$(grep -E "(vmx|svm)" --color=always /proc/cpuinfo | wc -l)
echo "$PROCS  processors are enabled for virtualization"
