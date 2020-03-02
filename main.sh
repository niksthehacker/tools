################################################################################
# This script enumerates subdomains of the given input,			       #
# check wheather they are up or not, screenshot them,			       #
# using waybackurls it geturl of the domain and resolve all 302s	       #
# and give you a notification on slack. 				       #
#								               #
# Usage: ./main.sh example.com						       #
# Results would be in the storage in the directory with name same as of domain.#
#									       #
# Credits: Respective to everyone whos tools are user(Nahamsec, Tomnomnom,Ahmed#
#Aboul-Ela and many other)						       #
################################################################################

mkdir $1
touch ./$1/Domains


curl -s https://certspotter.com/api/v0/certs\?domain\=$1 | jq '.[].dns_names[]' | sed 's/\"//g' | sed 's/\*\.//g' | sort -u | grep $1 > ./$1/Domains
echo "Certspotter" 
~/tools/Sublist3r/sublist3r.py -d $1 -o ./$1/subby 
cat ./$1/subby >> ./$1/Domains
echo "Sublister" 
rm ./$1/subby
~/tools/massdns/scripts/subbrute.py ~/tools/massdns/lists/names.txt $1 | ~/tools/massdns/bin/massdns -r ~/tools/massdns/lists/resolvers.txt -t A -o S -w ./$1/mass
cat ./$1/mass |  sed 's/.[^.]*//4g' >> ./$1/Domains
echo "massdns" 


curl -s https://crt.sh/?Identity=%.$1 | grep ">*.$1" | sed 's/<[/]*[TB][DR]>/\n/g' | grep -vE "<|^[\*]*[\.]*$1" | sort -u | awk 'NF' | sed '/^*/ d' > ./$1/dummy
curl -s https://crt.sh/?Identity=%.%.$1 | grep ">*.$1" | sed 's/<[/]*[TB][DR]>/\n/g' | grep -vE "<|^[\*]*[\.]*$1" | sort -u | awk 'NF' | sed '/^*/ d' >> ./$1/dummy
curl -s https://crt.sh/?Identity=%.%.$1 | grep ">*.$1" | sed 's/<[/]*[TB][DR]>/\n/g' | grep -vE "<|^[\*]*[\.]*$1" | sort -u | awk 'NF' | sed '/^*/ d' >> ./$1/dummy


cat ./$1/dummy | sed 's/\*.*//' | sed 's/crt.sh.*//' | sed 's/Identity.*//' | awk 'NF' >> ./$1/Domains
echo "crt sh" 
curl -s 'http://dns.bufferover.run/dns?q='$1 | jq -r '.FDNS_A, .RDNS' | grep \" | sed "s/\"//g" | sed 's/,$//' | sed 's/.*,//g' | grep '.*\.'$1'' >> ./$1/inputdata
echo "FDNS" 

cat ./$1/Domains | sed 's/<BR>/\n&/g' | sed 's/<BR>//g' | sort -u> ./$1/inputdata

rm ./$1/Domains
rm ./$1/mass
rm ./$1/dummy

echo "done"

######

source ~/.profile
source ~/.bash_profile
touch ./$1/updomains

while read p; do
httprobe http:81 -p https:8443 http:8080 https:8080 | tee -a ./$1/updomains
echo "$p"
done < ./$1/inputdata

echo "HTTProbe"

#Screenshoting them
#cat $1/inputdata | aquatone -chrome-path /snap/bin/chromium/ -out ./$1/
mkdir ./$1/aquatone
cat ./$1/inputdata | aquatone -chrome-path /snap/bin/chromium -out ./$1/aquatone

echo "Screenshot"

#Waybacking

waybackurls $1 | tee -a ./$1/wayback.txt
touch ./$1/resolve_wayback.txt

function getFinalRedirect {
    local url=$1
    while true; do
        nextloc=$( curl -s -I $url | grep ^Location: )
        if [ -n "$nextloc" ]; then
            url=${nextloc##Location: }
        else
            break
        fi
    done
    echo $url >> tmp_wayback.txt
}


for i in $(cat ./$1/wayback.txt); do
        echo $i
        getFinalRedirect $i
done

cat tmp_wayback.txt > ./$1/resolve_wayback.txt
rm tmp_wayback.txt

#Sending it to Slack


curl -X POST -H 'Content-type: application/json' --data '{"text":"Start"}' https://hooks.slack.com/services/X/X/X
curl -X POST -H 'Content-type: application/json' --data '{"text":"'"`cat updomains`"'"}' https://hooks.slack.com/services/X/X/X
curl -X POST -H 'Content-type: application/json' --data '{"text":"End"}' https://hooks.slack.com/services/X/X/X

echo "slack"
