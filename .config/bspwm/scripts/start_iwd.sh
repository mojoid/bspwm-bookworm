#!/bin/bash
source ~/.config/bspwm/globalrc

iface=$(iwctl device list | awk '/station/ {print $2}')
iface_powered=$(iwctl device list | grep $iface | awk '/on/ {print $4}')
state=$(iwctl station $iface show | awk '/State/ {print $2}')

reconnect() {
	if [[ $iface_powered != 'on' ]]; then
		$NOTIFY -i $ICON/info.png -t 2000 -r 123 "Wifi Powered is OFF"
		exit 0
	elif [[ $state == 'connected' ]]; then
		$NOTIFY -i $ICON/info.png -t 2000 -r 123 "Wifi is Connected"
	else
		if [[ $(pgrep -l iwd.sh) ]]; then
			pkill start_iwd.sh
		else
			xterm -class 'iwdmenu' -e ~/.config/bspwm/scripts/iwd.sh rc
		fi
	fi	
}

case $1 in
	rc)
		reconnect
  ;;
	dc)
		~/.config/bspwm/scripts/iwd.sh dc
  ;;
  fg)
		~/.config/bspwm/scripts/iwd.sh fg
  ;;
esac 
