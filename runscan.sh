#!/usr/bin/bash

# Prints the help
function show_help {
	printf "runscan -l [list] \t Run the scan for the domains listed in file\n"
	printf "runscan -o [output] \t Write output to HTML outputfile, default is scanout.html\n"
	printf "runscan -n \t\t Use nmap to scan all ports on domain\n"
	printf "runscan -s \t\t Use sslscan to scan ssl-connection\n"
	printf "runscan -y \t\t Use sslyze to scan ssl-connection\n"
	printf "runscan -h \t\t Show this help\n"
}

# Initialize variables
domains=""
use_nmap=false
use_sslscan=false
outputfile=scanout.html

# Reset if getops has been used previously
OPTIND=1

# Handle auguments
while getopts "l:o:hnsy" opt; do
	case "$opt" in
		l)
			domains="$OPTARG"
			;;
		o)
			outputfile="$OPTARG"
			;;
		n)
			use_nmap=true
			;;
		s)
			use_sslscan=true
			;;
		y)
			use_sslyze=true
			;;
		h)
			show_help
			exit 0
			;;
	esac
done

echo "Reading domains from $domains and outputting to $outputfile"

# Put the head in the outputfile
cat templates/htmlhead > "$outputfile"

# Loop and handle domains
for i in $(cat $domains)
do
	echo "<div class=\"heading\">" 2>&1 >> "$outputfile"
	echo "<h1>Scanning $i </h1>" 2>&1 >> "$outputfile"
	date  2>&1 >> "$outputfile"
	echo "</div>" 2>&1 >> "$outputfile"

	# Allways do DNS recon
	echo "<div class=\"info\">" 2>&1 >> "$outputfile"
	echo "<h2>Doing dnsrecon on $i</h2>" 2>&1 >> "$outputfile"
	dnsrecon -d $i -w -n 8.8.4.4  2>&1 >> "$outputfile"
	echo "</div>" 2>&1 >> "$outputfile"


	# Use nmap if desired
	if [ "$use_nmap" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h2> Doing portscanning on $i</h2>" 2>&1 >> "$outputfile"
		nmap -sS -sV -Pn -v -p0- -T4 $i 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
	fi

	# Use sslscan if desired
	if [ "$use_sslscan" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h2>Doing sslscan on $i</h2>" 2>&1 >> "$outputfile"
		sslscan $i:443 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
	fi

	# Use sslyze if desired
	if [ "$use_sslyze" = true ]; then
		echo "<div class=\"info\">" 2>&1 >> "$outputfile"
		echo "<h2>Doing sslyze on $i</h2>" 2>&1 >> "$outputfile"
		sslyze $i 2>&1 >> "$outputfile"
		echo "</div>" 2>&1 >> "$outputfile"
	fi

	# This might not be needed when doing HTML
	# date  2>&1 >> "$outputfile"
	# echo "***** done with $i *****" 2>&1 >> "$outputfile"
done

# put the tail on the outputfile
cat templates/htmltail >> "$outputfile"