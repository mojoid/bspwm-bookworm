#! /bin/bash
source ~/.config/bspwm/globalrc

ESSID='abc'
PASS='1sampai15'
forget='true'

if [[ $forget == 'true' ]]; then
	unset ESSID
	unset PASS
fi

switch() {
	[[ $ESSID != $namawifi ]] && sed -i "3 s/ESSID=.*/ESSID='$namawifi/'" $(dirname `realpath $0`)/iwd.sh
	[[ $PASS != $passwifi ]] && sed -i "4 s/PASS=.*/PASS='$passwifi'/" $(dirname `realpath $0`)/iwd.sh
	[[ -n $forget ]] && sed -i "5 s/forget.*/forget=/" $(dirname `realpath $0`)/iwd.sh
}

notify() {
	local iface=$(iwctl device list | awk '/station/ {print $2}')
	local state=$(iwctl station $iface show | awk '$1=="State" {print $2}')

	iwctl station $iface connect "$namawifi" --passphrase "$passwifi"
	
	if [[ $? == 0 ]]; then
		$NOTIFY -i $ICON/info.png -t 2300 -r 123 "Wifi Connected" "to $namawifi"
		switch
	else
		iwctl station wlan0 connect-hidden "$namawifi" --passphrase "$passwifi"
		if [[ $? == 0 ]]; then
			$NOTIFY -i $ICON/info.png -t 2300 -r 123 "Wifi: Connected" "to $namawifi"
			switch
		else
			iwctl station wlan0 connect "$namawifi"
			if [[ $? == 0 ]]; then
				$NOTIFY -i $ICON/info.png -t 2300 -r 123 "Wifi: Connected" "to $namawifi"
				switch
			else
				$NOTIFY -i $ICON/info.png -t 2300 -r 123 "Wifi: Unable" "to connect"
			fi
		fi
	fi
}

wifi_connecting() {
	n=50
	for i in {1..50}; do
		pct=$(( i * 100 / n ))
		echo XXX; echo $pct; echo "Menghubungkan..."; echo XXX
		
		if [[ $i -eq 1 ]]; then
			iface=$(iwctl device list | awk '$/station/ {print $2}')

			#iwctl station $iface scan
		elif [[ $i -eq $(($n - 5 )) ]]; then
			notify
		fi
		
		sleep 0.01
done | whiptail --title "NETWORK" --gauge "Please wait..." 6 55 0
}

input_box() {
	
	namawifi=$(whiptail --title "WIFI" --inputbox "Nama wifi: " --cancel-button "Exit" 7 55 "$ESSID" 3>&1 1>&2 2>&3)
	[[ $? -ne 0 ]]  || [[ $? -eq 255 ]] && exit
	
	passwifi=$(whiptail --title "WIFI" --passwordbox "Kata sandi wifi: " --cancel-button "Exit" 7 55 "$PASS" 3>&1 1>&2 2>&3)
	[[ $? -ne 0 ]]  || [[ $? -eq 255 ]] && exit
	
	wifi_connecting
}

forget(){
	local iface=$(iwctl device list | awk '/station/ {print $2}')
	local state=$(iwctl station $iface show | awk '$1=="State" {print $2}')
	
	if [[ $state == 'connecting' ]] || [[ $state == 'connected' ]]; then
		#iwctl station $iface disconnect
		iwctl known-networks $ESSID forget
			
		if [[ $? -eq 0 ]]; then
			$NOTIFY -i $ICON/info.png -t 2300 -r 123 "known-networks $ESSID forget"
			sed -i "0,/forget.*/s//forget='true'/" $(dirname `realpath $0`)/iwd.sh
		fi
		
	fi
}
	
disconnect(){
	local iface=$(iwctl device list | awk '/station/ {print $2}')
	local state=$(iwctl station $iface show | awk '$1=="State" {print $2}')
	
	if [[ $state == 'connecting' ]] || [[ $state == 'connected' ]]; then
		iwctl station $iface disconnect
			
		if [[ $? -eq 0 ]]; then
			$NOTIFY -i $ICON/info.png -t 2300 -r 123 "Wifi is Disconnected"
		fi
		
	fi
}

case $1 in
	rc)
		input_box
	;;
	dc)
		disconnect
	;;
	fg)
		forget
	;;
esac

