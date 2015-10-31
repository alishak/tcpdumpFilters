#!/bin/bash
# Author: Ali ElShakankiry

arg="$1"
ip1="$2"
ip2="$3"
p1="$4"
p2="$5"

########################################### Functions ###########################################

function error {
	printf "ARGS & USAGE:\n"
	printf "\tall <ip1> <ip2> <numConnections>\n"
	printf "NOTE: The first ip should be the ip address with the first SYN flag when using the "all" option\n\n"
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

	#Create subdirectory
	subdir="connnections"
	if [ ! -d "$dir/$subdir" ]; then
		mkdir $dir/$subdir
	fi

	name="connection_$ip1:$p1-$ip2:$p2"
	createFile "$name"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '((src '$ip1'  and src port '$p1' and dst '$ip2' and dst port '$p2') or (src '$ip2' and src port '$p2' and dst '$ip1' and dst port '$p1'))' > $dir/$subdir/$fileName
}

function flow {
	#Create subdirectory
	subdir="flows"
	if [ ! -d "$dir/$subdir" ]; then
		mkdir $dir/$subdir
	fi

	createFile "flow_$ip1:$p1-$ip2:$p2"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '(src '$ip1'  and src port '$p1' and dst '$ip2' and dst port '$p2') ' > $dir/$subdir/$fileName
	createFile "flow_$ip2:$p2-$ip1:$p1"
	/usr/sbin/tcpdump -nr lab1.pcap vlan and '(src '$ip2' and src port '$p2' and dst '$ip1' and dst port '$p1') ' > $dir/$subdir/$fileName
}

########################################### Main script ###########################################

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
	rm $dir/temp.txt

	let count=0
	for i in "${content[@]}"
	do
		#swap ports if the first one is 80 and delete 
		if [[  $(echo "$i" | cut -d " " -f 1) -eq 80 ]]; then
			sortedContent[$count]=$(echo $i | awk ' { print $2 } ' )
		else
			sortedContent[$count]=$(echo $i | awk ' { print $1 } ' )
		fi
		let count++
	done
	#length of original
	#echo "CONTENT is ${#content[@]}"
	#length of sorted
	#echo "SORTEDCONTENT is ${#sortedContent[@]}"
	
	sortedContent=($(printf '%s\n' "${sortedContent[@]}" | sort | uniq -c | sort -n -r | awk '{ print $1","$2 }'))
	#echo "SORTEDCONTENT is ${#sortedContent[@]}"
	echo "${sortedContent[@]}"

	#p1 is the # of connections needed in this case, save it
	numConnections=$p1

	#set real ports based on sorted array and pass them as arguments
	let i=0
	let pair=0
	while [ $i -lt $numConnections ]
	do
		#echo $(printf '%s' "${sortedContent[$pair]}" | cut -d "," -f 2)
		#skip whitespace
		if [ -z "$(printf '%s' "${sortedContent[$pair]}" | cut -d "," -f 2)" ]; then
			let pair++
		fi

		#set ports
		p1="$(printf '%s' "${sortedContent[$pair]}" | cut -d "," -f 2)"
		p2=80
		#echo "p1 is $p1............p2 is $p2"

		#find all connections and flows
		connection $p1 $p2
		flow $p1 $p2
		let i++
		let pair++
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
