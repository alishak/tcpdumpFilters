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
	printf "\tall <ip1> <ip2> <numConnections>\n"
	printf "\tconversation\t<ip1> <ip2>\n"
	printf "\tconnection\t<ip1> <ip2> <p1> <p2>\n"
	printf "\tflow\t\t<ip1> <ip2> <p1> <p2>\n\n"
	exit 0
}

#check if file exists, create a new file name if it does
function createFile {
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
		#echo "$fileName"
	done
	echo "final : $fileName"
	currentFile=$fileName
}

function conversation {
	createFile "conversation_$ip1-$ip2"
	echo "$dir/$fileName"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and port 80 and '((src '$ip1' and dst '$ip2') or (src '$ip2' and dst '$ip1'))' > $dir/$fileName
}

function connection {
	if [ ! $1=="" ] || [ ! $2=="" ]; then
		p1=$1
		p2=$2
	fi

	name="connection_$ip1:$p1-$ip2:$p2"
	createFile "$name"
	#echo "$name"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '((src '$ip1'  and src port '$p1' and dst '$ip2' and dst port '$p2') or (src '$ip2' and src port '$p2' and dst '$ip1' and dst port '$p1'))' > $dir/$fileName
}

function flow {
	createFile "flow_$ip1:$p1-$ip2:$p2"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '(src '$ip1'  and src port '$p1' and dst '$ip2' and dst port '$p2') ' > $dir/$fileName
	createFile "flow_$ip2:$p2-$ip1:$p1"
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

#set current directory & file
dir="$ip1-$ip2"
currentFile=""

#print arguments
echo "arg - $arg"
echo "ip1 - $ip1"
echo "ip2 - $ip2"
echo "$dir"

if [ "$arg" == "all" ]; then
	#/usr/sbin/tcpdump -nr lab1.pcap vlan and port 80 and '((src '$ip1' and dst '$ip2') or (src '$ip2' and dst '$ip1'))' | awk '{print $3"."$5}' | cut -d "." -f 5,10
	conversation

	#Read values into array
	declare -a content
	declare -a sortedContent
	cat $dir/$currentFile | awk '{print $3"."$5}' | cut -d "." -f 5,10 | sed 's/[.]/\ /g' | sed 's/[:]/\n/g' > $dir/temp.txt
	readarray content < $dir/temp.txt
	
	let count=0
	for i in "${content[@]}"
	do
		#swap ports if the first one is 80
		if [[  $(echo "$i" | cut -d " " -f 1) -eq 80 ]]; then
			swap=$(echo $i | awk ' { print $2" "$1} ' )
			#echo "swap : $swap"
			sortedContent[$count]=$swap
		else
			sortedContent[$count]=$i
		fi
		let count++
	done

	#printf '%s' "${content[@]}"
	sortedContent=($(printf '%s' "${sortedContent[@]}" | sort | uniq -c | sort -n -r))
	echo "${sortedContent[@]}"
	
	#p1 and p2 are the # of convos and conns in this case, save them
	numConnections=$p1

	#set real ports based on sorted array and pass them as arguments
	#TODO:
	let i=0
	let pair=0
	while [ $i -lt $numConnections ]
	do
		if [ $sortedContent[$pair]]
		connection $p1 $p2
		flow $p1 $p2
		let i++
	done
elif [ "$arg" == "conversation" ]; then
	conversation
elif [ "$arg" == "connection" ] && ! ( [ "$p1" == "" ] || [ "$p2" == "" ]); then
	connection
elif [ "$arg" == "flow" ] && ! ( [ "$p1" == "" ] || [ "$p2" == "" ]); then
	flow
else
	error
fi