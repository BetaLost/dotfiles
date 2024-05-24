#!/bin/bash

dimlightcol() {
	color=$(printf "$1" | tr -d '#"')

	if [[ -n $2 ]]; then
		factor=$2
	else
		factor=0.8
	fi
	
	for i in {0..4..2}; do
		hex=${color:$i:2}
		dec=$((16#$hex))
		dim=$(printf "%.0f" $(echo "$dec * $factor" | bc))
		dim_color+=$(printf "%02x" $dim)
	done
	
	printf "#$dim_color"
}

# Set random wallpaper based on time of day and generate colorscheme
TIME=$(date +"%-H")
DATE=$(date +"%d-%m-%Y")

if [[ -f "$HOME/.config/prayerhistory/$DATE.txt" ]]; then
	PRAYER_NAME=$(bash $HOME/.config/hypr/scripts/prayer.sh -n)
	case $PRAYER_NAME in
		"Fajr") FOLDER="dawn";;
		"Sunrise") FOLDER="morning";;
		"Dhuhr") FOLDER="noon";;
		"Asr") FOLDER="afternoon";;
		"Maghrib") FOLDER="sunset";;
		"Isha" | "Qiyam") FOLDER="night";;
	esac
else
	if [[ $TIME -ge 4 && $TIME -lt 7 ]]; then
		FOLDER="dawn"
	elif [[ $TIME -ge 7 && $TIME -lt 11 ]]; then
		FOLDER="morning"
	elif [[ $TIME -ge 11 && $TIME -lt 15 ]]; then
		FOLDER="noon"
	elif [[ $TIME -ge 15 && $TIME -lt 18 ]]; then
		FOLDER="afternoon"
	elif [[ $TIME -ge 18 && $TIME -lt 20 ]]; then
		FOLDER="sunset"
	elif [[ $TIME -ge 20 ]] || [[ $TIME -lt 4 ]]; then
		FOLDER="night"
	fi
fi

WALLPAPER=$(ls -1 $HOME/.config/wallpapers/$FOLDER/ | sort --random-sort | head -1)
WALLPAPER="$HOME/.config/wallpapers/$FOLDER/$WALLPAPER"
wal -si $WALLPAPER
hyprctl hyprpaper preload $WALLPAPER && hyprctl hyprpaper wallpaper ,$WALLPAPER

# Waybar colors
cp $HOME/.config/waybar/style.bak $HOME/.config/waybar/style.css
FG=$(cat $HOME/.cache/wal/colors.json | jq .special.foreground | tr -d '"')
BG=$(cat $HOME/.cache/wal/colors.json | jq .special.background | tr -d '"')
LIGHTBG=$(dimlightcol $BG 2.0)
LIGHTERBG=$(dimlightcol $BG 2.5)

COL1=$(cat $HOME/.cache/wal/colors.json | jq .colors.color1 | tr -d '"')
COL2=$(cat $HOME/.cache/wal/colors.json | jq .colors.color2 | tr -d '"')
COL4=$(cat $HOME/.cache/wal/colors.json | jq .colors.color4 | tr -d '"')
COL5=$(cat $HOME/.cache/wal/colors.json | jq .colors.color5 | tr -d '"')
DIMCOL1=$(dimlightcol $COL1)
DIMCOL2=$(dimlightcol $COL2)
DIMCOL2_2=$(dimlightcol $COL2 0.55)
DIMCOL4=$(dimlightcol $COL4)
DIMCOL5=$(dimlightcol $COL5)

colors=("FG" "BG" "LIGHTBG" "LIGHTERBG" "COL1" "COL2" "COL4" "COL5" "DIMCOL1" "DIMCOL2" "DIMCOL2_2" "DIMCOL4" "DIMCOL5")
for color in "${colors[@]}"; do
	sed -i "s/__${color}__/${!color}/" $HOME/.config/waybar/style.css
done

# Restart waybar
killall waybar
waybar &

# Dunst colors
cp $HOME/.config/dunst/dunstrc.bak $HOME/.config/dunst/dunstrc
sed -i "s/__FRAME__/$COL2/" $HOME/.config/dunst/dunstrc
sed -i "s/__BG__/$BG/" $HOME/.config/dunst/dunstrc
sed -i "s/__HIGHLIGHT__/$COL4/" $HOME/.config/dunst/dunstrc
sed -i "s/__FG__/$FG/" $HOME/.config/dunst/dunstrc
killall dunst

# Fuzzel colors
cp $HOME/.config/fuzzel/fuzzel.bak $HOME/.config/fuzzel/fuzzel.ini
sed -i "s/__BG__/$BG/" $HOME/.config/fuzzel/fuzzel.ini
sed -i "s/__FG__/$FG/" $HOME/.config/fuzzel/fuzzel.ini
sed -i "s/__BORDER__/$COL2/" $HOME/.config/fuzzel/fuzzel.ini
sed -i "s/__MATCH__/$COL1/" $HOME/.config/fuzzel/fuzzel.ini
sed -i "s/__SELECTBG__/$COL4/" $HOME/.config/fuzzel/fuzzel.ini

