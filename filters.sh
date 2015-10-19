#!/bin/bash
# Author: Ali ElShakankiry
#EE593 ANTA 2015

arg="$1"
ip1="$2"
ip2="$3"
p1="$4"
p2="$5"

########################## Functions ##########################
function error {
	printf "args & usage:\n"
	printf "\tall <ip1> <ip2> <numConversations> <numConnections>\n"
	printf "\tconversation\t<ip1> <ip2>\n"
	printf "\tconnection\t<ip1> <ip2> <p1> <p2>\n"
	printf "\tflow\t\t<ip1> <ip2> <p1> <p2>\n\n"
	exit 0
}

#check if file exists, create a new file name if it does
function checkFile {
	if [ ! -d "$dir" ]; then
		mkdir $dir
	fi

	COUNT=1
	file=$1
	fileName=$file".txt"
	until [ ! -e "$dir/$fileName" ]; do
		#echo "$fileName"
		fileName=$file"("$COUNT").txt"
		let COUNT++
		echo "$fileName"
	done
	#echo "final : $fileName"
}

function conversation {
	checkFile "conversation _$ip1-$ip2"
	#echo "$dir/$fileName"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and port 80 and '((src '$ip1' and dst '$ip2') or (src '$ip2' and dst '$ip1'))' > $dir/$fileName
}

function connection {
	name="connection_$ip1:$p1-$ip2:$p2"
	checkFile "$name"
	#echo "$name"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '((src '$ip1'  and src port '$p1' and dst '$ip2' and dst port '$p2') or (src '$ip2' and src port '$p2' and dst '$ip1' and dst port '$p1'))' > $dir/$fileName
}

function flow {
	checkFile "flow_$ip1:$p1-$ip2:$p2"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '(src '$ip1'  and src port '$p1' and dst '$ip2' and dst port '$p2') ' > $dir/$fileName
	checkFile "flow_$ip2:$p2-$ip1:$p1"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '(src '$ip2' and src port '$p2' and dst '$ip1' and dst port '$p1') ' > $dir/$fileName
}

#################### Main script ################################

#print full conversation to terminal
if [ "$arg" == "print" ]; then
	/usr/sbin/tcpdump -nr lab1.pcap vlan and port 80
	exit 0
fi

#check minimum arguments or help
if [ "$arg" == "help" ] || [ "$arg" == "-h" ] || [ "$arg" == "--help" ] || [ ! "$arg" ] || [ ! "$ip1" ] || [ ! "$ip2" ]; then
	error
fi

#set current directory
dir="$ip1-$ip2"

#print arguments
echo "arg - $arg"
echo "ip1 - $ip1"
echo "ip2 - $ip2"
echo "$dir"

if [ "$arg" == "all" ]; then
	conversation
	connection
	flow
elif [ "$arg" == "conversation" ]; then
	conversation
elif [ "$arg" == "connection" ] && ! ( [ "$p1" == "" ] || [ "$p2" == "" ]); then
	connection
elif [ "$arg" == "flow" ] && ! ( [ "$p1" == "" ] || [ "$p2" == "" ]); then
	flow
else
	error
fi