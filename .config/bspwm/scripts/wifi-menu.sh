#!/bin/bash

ESSID='abc'
WPA2='1sampai15'
forget=

if [ "${forget}" == 'true' ]; then
	unset ESSID
	unset WPA2
fi

switch() {
	local DIR=$(dirname `realpath $0`)/wifi-menu.sh
	
	[ "${ESSID}" != "${SSID}" ] && sed -i "3 s/ESSID=.*/ESSID='${SSID}'/" $DIR
	[ "${WPA2}" != "${PSK}" ] && sed -i "4 s/WPA2=.*/WPA2='${PSK}'/" $DIR
	[ -n $forget ] && sed -i "5 s/forget.*/forget=/" $DIR
}

main_menu() {
	local option=(
	'Connect to wifi' '' \
	'Disconnect' '' \
	'Forget the network' '' \
	)
	
  echo $(
		whiptail --title "WIFI MENU" --menu "$msg" \
		--cancel-button 'Exit' 0 50 0 "${option[@]}" 3>&1 1>&2 2>&3
	)
}

input_box(){
	whiptail --inputbox "$1" 0 50 ${2} 3>&1 1>&2 2>&3
}

connecting(){
	local SSID PSK
	
	SSID=$(input_box 'SSID:' "${ESSID}")
	PSK=$(input_box 'WPA/WPA2-Personal:' "${WPA2}")
	
	if [ -z "$PSK" ] && [ -n "$SSID" ]; then
		iwctl station wlan0 connect "${SSID}" &>/dev/null
		yn=$?
	elif [ -n "$SSID" ]; then
		iwctl station wlan0 connect "${SSID}" --passphrase "${PSK}" &>/dev/null
		[ "$?" -ne 0 ] && iwctl station wlan0 connect-hidden "${SSID}" --passphrase "${PSK}" &>/dev/null
		yn=$?
	fi
	
	switch
}

execute_menu(){
	local state msg OPT
	
	while true; do
	state=$(echo $(iwctl station wlan0 show | awk -F'State' '{print $2}'))
	OPT=$(main_menu)
	[ -z "$OPT" ] && exit $?
	
	case ${OPT} in
		'Connect to wifi')
			if [ "$state" == 'disconnected' ]; then
				connecting
				[ "$?" -eq 0 ] && msg="Wifi terhubung ke $ESSID"
			else
				msg="Sudah terhubung ke $ESSID"
			fi
		;;
		'Disconnect')
			iwctl station wlan0 disconnect
			[ "$?" -eq 0 ] && msg='Wifi is disconnected'
		;;
		'Forget the network')
			iwctl known-networks $ESSID forget
			if [ "$?" -eq 0 ]; then
				sed -i "0,/forget.*/s//forget=true/" $(dirname `realpath $0`)/wifi-menu.sh
				msg="Melupakan jaringan: $ESSID"
			fi
		;;
	esac
	done
}

execute_menu

exit 0
