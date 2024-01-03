#!/bin/bash

# Script Name: wpscan-ui.sh
# Script URL: https://github.com/jacobfresco/wpscan-ui
# Description: Provides a simple UI for wpscan
# Version: 0.1
# Author: Jacob Fresco
# Author URI: http://www.jacobfresco.nl

# Copyright 2023 Jacob Fresco
 
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# Set variables to customize the script
script_name=wpscan-ui
script_desc=JacobFresco.nl
script_year=2023
api_file=~/scripts/wpscan_api.key


####### DO NOT EDIT BELOW THIS LINE ########

# Check if WPScan is installed. Because there are so many installation methods, 
# it's just detection, not an option for installation.

if ! [[ $(which wpscan) =~ "wpscan" ]]; then
	echo An installation of wpscan was not detected on this system. This makes this script basically useless. Please install wpscan using your preferred method. After installation, please run this script again.
	echo 
	echo Usage: ./wpscan-ui.sh \[website url\] \(optional\)
	exit
fi

# Check for an API-key. You can set the location and name of this file at the first section of this script
# Please note that the file should only contain the API-key for wpscan. If it contains anything else, wpscan will fail 
# because of an invalid API-key. 
if [[ -f "$api_file" ]]; then
	api_key_file=$(cat $api_file)
fi

# Check for a valid installation of TMUX. If found, you are offered the choice to use it (or not). TMUX is a pseudo TTY that 
# allows multiple panes within the same window/screen. This script utilizes that specific feature. 
if type tmux >/dev/null 2>/dev/null; then
	tmuxps=$(whiptail --yesno "TMUX installation detected. Use TMUX for output?" 15 50 3>&1 1>&2 2>&3)
	if [ $? = 0 ]; then
		tmuxps="yes"
	else
		tmuxps="no"
	fi	 
else
	tmuxps="no"
fi

# If a valid API key was not found in the file specified, you can insert your key here. Leave empty to run wpscan without
# API connection. Please note that providing an invalid key will cause wpscan to abort the scan. 
api_key=$(whiptail --title "$script_name | $script_desc $script_year" --inputbox "Use API key? Register for a free one at wpscan.com" 10 50 $api_key_file  3>&1 1>&2 2>&3)
if ! [ $? = 0 ]; then
	exit
fi

if [[ $api_key == "" ]]; then
	api_key="none"
fi

# Provide an URL to a website running Wordpress. Please note that running wpscan against any website not owned or maintained by yourself,
# could be considered illegal in your country. 
website_url=$(whiptail --title "$script_name | $script_desc $script_year" --inputbox "Wordpress URL" 10 50 $1 3>&1 1>&2 2>&3)
if ! [ $? = 0 ]; then
	exit
fi


detection=$(whiptail --title "$script_name | $script_desc $script_year" --radiolist "Method of detection" 15 50 4 \
"passive" "Passive" OFF \
"mixed" "Mixed" ON \
"aggressive" "aggressive" OFF 3>&1 1>&2 2>&3)
if ! [ $? = 0 ]; then
	exit
fi

pdetection=$(whiptail --title "$script_name | $script_desc $script_year" --radiolist "Method of plugin(-version) detection" 15 50 4 \
"passive" "Passive" OFF \
"mixed" "Mixed" ON \
"aggressive" "aggressive" OFF 3>&1 1>&2 2>&3)
if ! [ $? = 0 ]; then
	exit
fi

askenum=$(whiptail --yesno "Configure enumeration? If you choose 'No', a standard set will be used." 15 50 3>&1 1>&2 2>&3)
if ! [ $? = 0 ]; then
	enumeration="vp,vt,tt,cb,dbe"
else
	enump=$(whiptail --title "$script_name | $script_desc $script_year" --radiolist "Enumeration for plugins" 15 50 4 \
	"vp" "Vulnerable plugins" ON \
	"ap" "All plugins" OFF \
	"p" "Popular plugins" OFF 3>&1 1>&2 2>&3)
	if ! [ $? = 0 ]; then
		exit
	fi
	enumeration=${enump}
	
	enumt=$(whiptail --title "$script_name | $script_desc $script_year" --radiolist "Enumeration for themes" 15 50 4 \
	"vt" "Vulnerable themes" ON \
	"at" "All themes" OFF \
	"t" "Popular themes" OFF 3>&1 1>&2 2>&3)
	if ! [ $? = 0 ]; then
		exit
	fi
	enumeration="${enumeration},${enumt}"
	
	enumtt=$(whiptail --yesno "Enumerate Timthumbs (tt)?" 15 50 3>&1 1>&2 2>&3)
	if [ $? = 0 ]; then
		enumeration="${enumeration},tt"
	fi
	
	enumcb=$(whiptail --yesno "Enumerate Configuration Backups (cb)?" 15 50 3>&1 1>&2 2>&3)
	if [ $? = 0 ]; then
		enumeration="${enumeration},cb"
	fi 
	
	enumdbe=$(whiptail --yesno "Enumerate database exports (dbe)?" 15 50 3>&1 1>&2 2>&3)
	if [ $? = 0 ]; then
		enumeration="${enumeration},dbe"
	fi
fi


format=$(whiptail --title "$script_name | $script_desc $script_year" --radiolist "Format for output" 15 50 4 \
"cli" "Text (color)" ON \
"cli-no-colour" "Text (no color)" OFF \
"json" "JSON encoded" OFF 3>&1 1>&2 2>&3)
if ! [ $? = 0 ]; then
	exit
fi

# Setup the filename for output
filename=wpscan-$(date +%F_%H%M%S).txt
outputfile=$(whiptail --title "$script_name | $script_desc $script_year" --inputbox "Filename for output" 10 50 $filename 3>&1 1>&2 2>&3)
if ! [ $? = 0 ]; then
	exit
fi

tmuxps_info=$'\e[34m[Website]\e[0m '$website_url'\e[0m\n\e[34m[API key]\e[0m '$api_key'\n\e[34m[Detection method]\e[0m '$detection'\n\e[34m[Plugin (version) detection]\e[0m '$pdetection'\n\e[34m[Enumeration]\e[0m '$enumeration'\n\e[34m[Format]\e[0m '$format'\n\e[34m[Output]\e[0m '$outputfile'\n\n'
touch ~/Documents/$outputfile
	
clear
if [[ $tmuxps == "yes" ]] ; then
	tmuxps_name=wpscan-$(date +%F_%H%M%S)
	echo Switching to tmux...
	tmux new -s $tmuxps_name -d
	tmux set remain-on-exit off
	tmux new-window -t $tmuxps_name "tail -f ~/Documents/$outputfile"
	tmux split-window -v -t $tmuxps_name "wpscan --update --verbose; read -A -r"
	if ! [ $api_key = "none" ]; then
		tmux split-window -h -t $tmuxps_name "echo \"$tmuxps_info\"; wpscan --no-banner -f $format --enumerate $enumeration --detection-mode $detection --plugins-detection $pdetection --plugins-version-detection $pdetection --random-user-agent --force --ignore-main-redirect --output ~/Documents/$outputfile --url $website_url --api-token $api_key; read -A -r"
	else
		tmux split-window -h -t $tmuxps_name "echo \"$tmuxps_info\"; wpscan --no-banner -f $format --enumerate $enumeration --detection-mode $detection --plugins-detection $pdetection --plugins-version-detection $pdetection --random-user-agent --force --ignore-main-redirect --output ~/Documents/$outputfile --url $website_url; read -A -r"
	fi
	tmux attach -t $tmuxps_name
else
	wpscan --update --verbose
	echo -e "$tmuxps_info"
	if ! [[ $api_key == "none" ]]; then
		wpscan --no-banner -f $format --enumerate $enumeration --detection-mode $detection --plugins-detection $pdetection --plugins-version-detection $pdetection  --random-user-agent --force --ignore-main-redirect --output ~/Documents/$outputfile --url $website_url --api-token $api_key
	else
		wpscan --no-banner -f $format --enumerate $enumeraion --detection-mode $detection --plugins-detection $pdetection --plugins-version-detection $pdetection  --random-user-agent --force --ignore-main-redirect --output ~/Documents/$outputfile --url $website_url
	fi
		
	xhost +si:localuser:$( whoami ) >&/dev/null && { 	
 		xdg-open ~/Documents/$outputfile &
	} || {
   		cat ~/Documents/$outputfile | more
   	}
fi