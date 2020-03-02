###############################################################
# One liner bash to check wheather http service on any ip of a#
# given input. 						      #
#							      #
# Usage: ./resolver.sh x.x.x.x/x 			      #
# Note: Making a alias of it is better approach               #
#							      #
# Credits:  Gordon Lyon, Tomnomnom etc			      #
###############################################################



nmap -sL $1 | awk '/Nmap scan report/{print $NF}'| tr -d '()' | httprobe  -p http:81 -p https:8443 -p 8080
