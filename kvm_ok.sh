#!/bin/bash   
# /bin/bash is still the standard for all distros.
# - http://rpmfind.net//linux/RPM/fedora/devel/rawhide/x86_64/b/bash-4.3.25-2.fc22.x86_64.html
# - https://packages.debian.org/sid/amd64/bash/filelist


# print the amount of memory
echo "Your computer should have 2 GB of RAM or more for this course."
echo -e "\n"
dmesg | grep Memory:
echo
read -s  -n1 -p"(Press any key to proceed...)"
echo -e "\n"
PROCS=$(grep -E "(vmx|svm)" --color=always /proc/cpuinfo | wc -l)
echo "$PROCS  processors are enabled for virtualization"
