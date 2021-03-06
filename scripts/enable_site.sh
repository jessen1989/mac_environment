#!/bin/bash -e

echo "-----------------------------------------------------"
echo ""
echo "                    Enabling site"
echo ""
echo "-----------------------------------------------------"
echo ""


host_file_path="/etc/hosts"
apache_file_path="/srv/sites/apache/apache.conf"


# Request sudo action before continuing to force password prompt (if needed) before script really starts
sudo ls &>/dev/null
echo ""

getSiteInfo(){
	site_array=("$@")
	if [ -n "${site_array[1]}" ]; then
		if [ "${site_array[0]}" = "${site_array[1]}" ]; then 
			echo "${site_array[0]}"
    	else
			echo "${site_array[@]}"
		fi
	else
		echo "${site_array[0]}"
	fi
}
setHost(){
	server=$(echo -e "127.0.0.1\\t$1")
	
	sudo chmod 777 "$host_file_path"		
	host_exist=$(cat "$host_file_path" | grep "$server" || echo "")
	if [ -z "$host_exist" ]; then 
		echo "Setting up $1 host"
		echo -e "127.0.0.1\\t$1" >> "$host_file_path"
	else 
		echo "$1 exists"	
	fi
	sudo chmod 644 "$host_file_path"
}
enablingApacheSite(){
	include=$(echo "Include \"$(getSiteInfo "$1" | sed s,/theme/www,/apache/httpd-vhosts.conf, )\"")
	apache_entry_exists=$(grep "$include" "$apache_file_path" || echo "")
	#echo "$include"
	#echo "Apache Entry: $apache_entry_exists"
	if [ -z "$apache_entry_exists" ]; then
		echo "enabling conf in $apache_file_path"
		echo "$include" >> "$apache_file_path"
	else
		echo "Virtual Host allready enabled in $apache_file_path"
	fi
}

# Parse DocumentRoot from httpd-vhosts.conf
document_root=($(grep -E "DocumentRoot" "$PWD/apache/httpd-vhosts.conf" | sed -e "s/	DocumentRoot \"//; s/\"//"))
export document_root

# Parse ServerName from httpd-vhosts.conf
server_name=($(grep -E "ServerName" "$PWD/apache/httpd-vhosts.conf" | sed "s/	ServerName //"))
export server_name

# Parse ServerAlias from httpd-vhosts.conf
server_alias=($(grep -E "ServerAlias" "$PWD/apache/httpd-vhosts.conf" | sed "s/	ServerAlias //"))
export server_alias

# Does current location seem to fullfil requirements (is httpd-vhosts.conf found where it is expected to be found)
if [ -e "$PWD/apache/httpd-vhosts.conf" ] ; then

	# Parse DocumentRoot from httpd-vhosts.conf
	document_root=($(grep -E "DocumentRoot" "$PWD/apache/httpd-vhosts.conf" | sed -e "s/	DocumentRoot \"//; s/\"//"))
	export document_root
	
	# Parse ServerName from httpd-vhosts.conf
	server_name=($(grep -E "ServerName" "$PWD/apache/httpd-vhosts.conf" | sed "s/	ServerName //"))
	export server_name
	
	# Parse ServerAlias from httpd-vhosts.conf
	server_alias=($(grep -E "ServerAlias" "$PWD/apache/httpd-vhosts.conf" | sed "s/	ServerAlias //"))
    export server_alias

	# Could not find DocumentRoot or ServerName
    if [ -z "$(getSiteInfo "${document_root[@]}")" ] && [ -z "$(getSiteInfo "${server_name[@]}")" ]; then
		echo ""
		echo "Apache configuration seems to be broken."
		echo "Please revert any changes you have made to the https-vhosts.conf file."
		echo ""
	else
		echo "Setting up site"
		
		for alias in $(getSiteInfo "${server_alias[@]}")
		do
			echo "$alias"
		done
		# Updating apache.conf

		for doc in $(getSiteInfo "${document_root[@]}")
		do
			enablingApacheSite "$doc"
		done
	fi

	# Updating hosts
	for server in $(getSiteInfo "${server_name[@]}")
	do
		setHost "$server"
	done
	
	# Restart apache after modification
	echo ""
	# Restart apache after modification
	echo ""
	echo "Restarting Apache"
	if [ -e "/opt/local/sbin/apachectl" ]; then
		sudo /opt/local/sbin/apachectl restart
	elif [ -e "/opt/local/apache2/apachectl" ]; then
		sudo /opt/local/apache2/apachectl restart
	fi


	echo ""
	echo "Site enabled: OK"
	echo ""
else

	echo "Apache configuration not found."
	echo "You can only enable a site, if you run this command from the project root folder"

fi

