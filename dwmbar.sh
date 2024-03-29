#!/bin/bash

# Hardware
BACKLIGHT="intel_backlight"
NET_INTERFACE="wlan0"

# Set colorscheme
icon_bg=$(sed -n "10p" < $HOME/.cache/wal/colors)
text_bg=$(sed -n "8p" < $HOME/.cache/wal/colors)
text_fg=$(sed -n "1p" < $HOME/.cache/wal/colors)
icon_scheme="^c$text_fg^^b$icon_bg^"
text_scheme="^d^^c$text_fg^^b$text_bg^"

update_volume() {
	VOL=$(pulsemixer --get-volume | cut -f 1 -d " ")
	
	MUTE_STAT=$(pulsemixer --get-mute)
	if [[ $MUTE_STAT == "1" ]]; then
		VOL_ICON="婢"
	else
		VOL_ICON="墳"
	fi
	
	echo "$icon_scheme^l^$VOL_ICON $text_scheme $VOL%^e^^d^"
}

update_brightness() {
	BRIGHTNESS=$(cat /sys/class/backlight/$BACKLIGHT/brightness)
	MAX_BRIGHTNESS=$(cat /sys/class/backlight/$BACKLIGHT/max_brightness)
	PERCENTAGE=$((BRIGHTNESS * 100 / MAX_BRIGHTNESS))
	
	if [[ $PERCENTAGE -le 20 ]]; then
		BRIGHT_ICON="󰃞"
	elif [[ $PERCENTAGE -gt 20 && $PERCENTAGE -lt 50 ]]; then
		BRIGHT_ICON="󰃝"
	elif [[ $PERCENTAGE -ge 50 && $PERCENTAGE -lt 75 ]]; then
		BRIGHT_ICON="󰃟"
	elif [[ $PERCENTAGE -ge 75 ]]; then
		BRIGHT_ICON="󰃠"
	fi
	
	echo "$icon_scheme^l^$BRIGHT_ICON $text_scheme ${PERCENTAGE%.*}%^e^^d^"
}

update_cpu() {
	CPUSTAT=$(grep 'cpu ' /proc/stat)
	
	IDLE2=$(echo "$CPUSTAT" | awk '{print $5}')
	TOTAL2=$(echo "$CPUSTAT" | awk '{total = $2 + $3 + $4 + $5 + $6 + $7 + $8} END {print total}')
	
	IDLE_DIFF=$((IDLE2 - IDLE1))
	TOTAL_DIFF=$((TOTAL2 - TOTAL1))
	
	CPU_USAGE=$(awk "BEGIN {print (1 - $IDLE_DIFF / $TOTAL_DIFF) * 100}")
	CPU_TEMP=$(sed 's/000$/°C/' /sys/class/thermal/thermal_zone0/temp)
	
	echo "$icon_scheme^l^ $text_scheme ${CPU_USAGE%.*}% ($CPU_TEMP)^e^^d^"
}

update_ram() {
	MEMORY=$(free -m | awk '/Mem:/ { print $3 }' | cut -f1 -d 'i')
	
	if ((MEMORY > 1024)); then
		MEMORY=$(echo "scale=2; $MEMORY / 1024" | bc)
		echo "$icon_scheme^l^RAM $text_scheme $MEMORY GiB^e^^d^"
	else
		echo "$icon_scheme^l^RAM $text_scheme $MEMORY MiB^e^^d^"
	fi
}

update_net() {
	R2=`cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes`
	T2=`cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes`
	TBPS=`expr $T2 - $T1`
	RBPS=`expr $R2 - $R1`
	TKBPS=`expr $TBPS / 1024`
	RKBPS=`expr $RBPS / 1024`
	
	echo "$icon_scheme^l^ $text_scheme $RKBPS KiB ^d^$icon_scheme  $text_scheme $TKBPS KiB^e^^d^"
}

update_bat() {
	CUR_BAT=$(cat /sys/class/power_supply/BAT*/capacity)
	BAT_STAT=$(cat /sys/class/power_supply/BAT*/status)
	
	if [[ $BAT_STAT == "Charging" ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -le 10 ]]; then
		BAT_ICON=""
		notify-send --urgency=critical "$CUR_BAT%: Low Battery!"
	elif [[ $CUR_BAT -gt 10 && $CUR_BAT -le 20 ]]; then
		BAT_ICON=""
		notify-send --urgency=critical "$CUR_BAT%: Low Battery!"
	elif [[ $CUR_BAT -gt 20 && $CUR_BAT -le 30 ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -gt 30 && $CUR_BAT -le 40 ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -gt 40 && $CUR_BAT -le 50 ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -gt 50 && $CUR_BAT -le 60 ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -gt 60 && $CUR_BAT -le 70 ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -gt 70 && $CUR_BAT -le 80 ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -gt 80 && $CUR_BAT -le 90 ]]; then
		BAT_ICON=""
	elif [[ $CUR_BAT -gt 90 && $CUR_BAT -le 100 ]]; then
		BAT_ICON=""
	fi
	
	echo "$icon_scheme^l^$BAT_ICON $text_scheme $CUR_BAT%^e^^d^"
}

vol_sig() {
	volume_section=$(update_volume)
	update_status 0 0
}

light_sig() {
	light_section=$(update_brightness)
	update_status 0 0
}

trap "vol_sig" SIGUSR1
trap "light_sig" SIGUSR2

# Initialize volume and brightness sections
volume_section=$(update_volume)
light_section=$(update_brightness)

# Initialize network data
R1=`cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes`
T1=`cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes`

# Initialize counters
main_count=0
all_count=0
bat_count=0

update_status(){
	# Update main info
	if [ "$1" = 1 ]; then
		cpu_section=$(update_cpu)
		ram_section=$(update_ram)
		net_section=$(update_net)
		
		TIME=$(date +"%H:%M")
		DATE=$(date +"%a, %d %B %Y")
	fi
	
	# Update Battery
	if [ "$2" = 1 ]; then
		bat_section=$(update_bat)
	fi
	
	# Draw Status
	xsetroot -name " $volume_section $light_section $cpu_section $ram_section $net_section $bat_section $icon_scheme^l^ $text_scheme $TIME^e^^d^ $icon_scheme^l^ $text_scheme $DATE^e^^d^ "
}

# Initialize status
update_status 1 1

while :; do
	# Increment counters every second
	if ((main_count < SECONDS)); then
		main_count=$SECONDS
		((all_count++))
		((bat_count++))
	fi
	
	# Update battery info every 5 seconds
	if ((bat_count == 5)); then
		update_status 0 1
		bat_count=0
	fi
	
	# Update all other info every 3 seconds
	if ((all_count == 3)); then
		update_status 1 0
		
		R1=`cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes`
		T1=`cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes`
		
		CPUSTAT=$(grep 'cpu ' /proc/stat)
		IDLE1=$(echo "$CPUSTAT" | awk '{print $5}')
		TOTAL1=$(echo "$CPUSTAT" | awk '{total = $2 + $3 + $4 + $5 + $6 + $7 + $8} END {print total}')
		
		all_count=0
	fi
	
	# Limit CPU usage
	sleep 0.1
done

