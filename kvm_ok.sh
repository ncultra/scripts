#!/usr/bin/bash   
# path ok for fedora - TODO update for other distros

# print the amount of memory
echo "Your computer should have 2 GB of RAM or more"
echo 
dmesg | grep Memory:
echo
read -s  -n1 -p"(Press any key to proceed...)"
echo
echo "The following command will verify that your processor has virtualization enabled."
echo "If there is no output, you need to enter Setup and enable virtualization in BIOS."
echo "It will print the number of processors that ARE enabled for virtualization..."
echo
read -s  -n1 -p"(Press any key to proceed...)"
echo
grep -E "(vmx|svm)" --color=always /proc/cpuinfo | wc -l
