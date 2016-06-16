#!/bin/bash

function usage() {
    echo "usage: [/home/ops/scripts/user_data.sh --vlan 604 --center bj0 --kvm l-opcpu7.ops.bj0 --vm l-imgtest1.ops.bj0 --flavor 4c-4g-80g --image centos-6.7-x86_64-80g-test]"
}

ARGS=$(getopt -a -o l:c:k:m:f:i:h -l vlan:,center:,kvm:,vm:,flavor:,image:,help -- "$@")
[ $? -ne 0 ] && usage  
#set -- "${ARGS}"  
eval set -- "${ARGS}" 
 
while true  
do  
        case "$1" in 
        -l|--vlan)  
                vlan_id="$2" 
                shift  
                ;;  
        -c|--center)  
                center_id="$2" 
                shift  
                ;;  
        -k|--kvm)  
                kvm_host="$2" 
                shift  
                ;;  
        -m|--vm)  
                vm_host="$2" 
                shift  
                ;;  
        -f|--flavor)  
                flavor="$2" 
                shift  
                ;;  
        -i|--image)  
                image="$2" 
                shift  
                ;;  
        -h|--help)  
                usage  
                ;;  
        --)  
                shift  
                break 
                ;;  
        esac  
shift  
done 


if [ "$vlan_id" == "" ] || [ "$center_id" == "" ] || [ "$kvm_host" == "" ] || [ "$vm_host" == "" ] || [ "$flavor" == "" ] || [ "$image" == "" ]; then
    usage
    exit
fi

if [ "$center_id" != "bj0" ] && [ "$center_id" != "bj1" ] && [ "$center_id" != "bj2" ]; then
    echo "center error, can only be bj0,bj1,bj2"
    exit
fi

if echo "$vlan_id" | grep -q '^[0-9]\+$'; then  
    echo "Vlan_id: $vlan_id"  
else  
    echo "$vlan_id is not number."  
    exit
fi  



# echo $vlan_id,$center_id,$kvm_host,$vm_host

# nova net-list  | env VLAN=$vlan_id awk -F'|' "/vlan$VLAN/{print \$2}" | tr -d ' '

net_info=$(nova net-list  | grep "vlan$vlan_id")
if [ "${net_info}" == "" ]; then
    echo "no net info find"
    exit
fi
# echo $net_info

net_id=$(echo $net_info | awk -F'|' '{print $2}' | tr -d ' ')
net_CIDR=$(echo $net_info | awk -F'|' '{print $4}' | tr -d ' ')
# echo $net_id
# echo $net_CIDR

# gateway="${net_CIDR%0}1"
gateway=$(nova network-show $net_id | grep -w "gateway" | awk -F'|' '{print $3}' | tr -d ' ')
echo "GATEWAY: $gateway"

tmp_user_data=$(mktemp /tmp/user_data_XXXXXXX)
echo "user_data: $tmp_user_data"

if [ "${center_id}" == "bj0" ]; then
    cat << EOF > $tmp_user_data
#!/bin/bash

echo 'GATEWAY=$gateway' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'PEERDNS=no' >> /etc/sysconfig/network-scripts/ifcfg-eth0
ip ro replace default via 10.36.4.1
ntpdate 10.0.3.16
chkconfig cloud-init off
chkconfig ntp on
reboot
EOF
elif [ "${center_id}" == "bj1" ]; then
    cat << EOF > $tmp_user_data
#!/bin/bash

echo 'GATEWAY=10.0.9.253' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'PEERDNS=no' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo '10.0.0.0/8 via 10.0.8.1' >> /etc/sysconfig/network-scripts/route-eth0
ntpdate 10.0.3.16
chkconfig cloud-init off
chkconfig ntp on
reboot
EOF
elif [ "${center_id}" == "bj2" ]; then
    cat << EOF > $tmp_user_data
#!/bin/bash

echo 'GATEWAY=$gateway' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'PEERDNS=no' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'DNS1=10.0.3.15' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'DNS2=10.0.3.16' >> /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'DOMAIN=daling.com' >> /etc/sysconfig/network-scripts/ifcfg-eth0
ip ro replace default via 10.0.20.1
ntpdate 10.0.3.16
chkconfig cloud-init off
chkconfig ntp on
reboot
EOF

fi

# nova boot  --config-drive true --flavor 4c-4g-200g  --user-data $tmp_user_data --image centos-6.7-x86_64-80g-test --nic net-id=d99ce50b-6e4d-4fc4-99fa-c844f5b8029d  --availability-zone nova:l-opcpu7.ops.bj0 l-imgtest1.ops.bj0

cmd="nova boot  --config-drive true --flavor $flavor  --user-data $tmp_user_data --image $image --nic net-id=$net_id --availability-zone nova:$kvm_host $vm_host"

echo "Execute command: $cmd"


read -p "Do you want to execute the command above to create new vm ?" yn

if [ "${yn}" != "yes" -a "${yn}" != "YES" -a "${yn}" != "y" -a "${yn}" != "Y" ]; then
    echo "Command cancel~"
    if [ -e "$tmp_user_data" ]; then
        mv $tmp_user_data /tmp/user_data_last.sh
    fi
    exit
fi
echo "Begin to create vm~"

res=$($cmd)

echo $res

if [ -e "$tmp_user_data" ]; then
    mv $tmp_user_data /tmp/user_data_last.sh
fi

echo "Create vm success~"
