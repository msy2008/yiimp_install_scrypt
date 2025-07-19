#!/bin/bash
################################################################################
# Original Author:   Kudaraidee
# Modified by : Coke
# Program:
#   Install yiimp on Ubuntu 22.04 running Nginx, MariaDB, and php8.2
#   v2.0 (updated March 2025)
#   Yii 2.0.52 Framework (supports up to PHP 8.2)
################################################################################

   script_version='v2.0-8.2'
   yii_version='2.0.52'
   php_version='8.2'

    output() {
    printf "\E[0;33;40m"
    echo $1
    printf "\E[0m"ku
    }

    displayErr() {
    echo
    echo $1;
    echo
    exit 1;
    }

    #Add user group sudo + no password
    whoami=`whoami`
    sudo usermod -aG sudo ${whoami}
    echo '# yiimp
    # It needs passwordless sudo functionality.
    '""''"${whoami}"''""' ALL=(ALL) NOPASSWD:ALL
    ' | sudo -E tee /etc/sudoers.d/${whoami} >/dev/null 2>&1

    #Copy needed files
    sudo cp -r conf/functions.sh /etc/
    sudo cp -r utils/screen-scrypt.sh /etc/
    sudo cp -r utils/screen-script.sh /etc/
    sudo cp -r utils/screen-stratum.sh /etc/
    sudo cp -r conf/editconf.py /usr/bin/
    sudo chmod +x /usr/bin/editconf.py
    sudo chmod +x /etc/screen-scrypt.sh
    sudo chmod +x /etc/screen-script.sh
    sudo chmod +x /etc/screen-stratum.sh

    source conf/functions.sh
    source /etc/functions.sh

    hide_output sudo apt -y update
    sudo apt_install lsb-release figlet update-motd landscape-common update-notifier-common lolcat needrestart build-essential libssl-dev curl git-core openssh-server

    clear
    figlet -f slant -w 100 "Saltpool Yiimp Installer" | lolcat -f

    clear
    echo
    echo -e "$GREEN************************************************************************$COL_RESET"
    echo -e "$GREEN Yiimp Install Script $script_version $COL_RESET"
    echo -e "$GREEN Install yiimp on Ubuntu 22.04 running Nginx, MariaDB, and PHP $php_version $COL_RESET"
    echo -e "$GREEN Running under Yii Framework $yii_version $COL_RESET"
    echo -e "$GREEN************************************************************************$COL_RESET"
    echo
    sleep 3

    # Update package and Upgrade Ubuntu
    echo
    echo
    echo -e "$CYAN => Updating system and installing required packages:$COL_RESET"
    sleep 3

    sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
    
    hide_output sudo apt -y update
    sudo apt -y upgrade
    sudo apt -y autoremove
    sudo apt_install software-properties-common
    sudo apt_install dialog python3 python3-pip acl nano apt-transport-https
    echo -e "$GREEN Done...$COL_RESET"

    source conf/prerequisite.sh
    sleep 3
    source conf/getip.sh

    echo 'PUBLIC_IP='"${PUBLIC_IP}"'
    PUBLIC_IPV6='"${PUBLIC_IPV6}"'
    DISTRO='"${DISTRO}"'
    PRIVATE_IP='"${PRIVATE_IP}"'' | sudo -E tee conf/pool.conf >/dev/null 2>&1

    echo
    echo
    echo -e "$YELLOW Make sure you double check before hitting enter! You only get one shot at these! $COL_RESET"
    echo
    read -e -p "Enter time zone (e.g. America/New York):" TIME
    read -e -p "Domain Name (no http:// just : example.com or pool.example.com (IP is ok, but not recommended) : " server_name
    read -e -p "Are you using a subdomain (pool.example.com?) [y/N]: " sub_domain
    read -e -p "Enter the name of your pool (a general name, not the domain, e.g., Saltpool: " poolname
    read -e -p "Enter support email (e.g. admin@example.com): " EMAIL
    read -e -p "Set Pool to AutoExchange? i.e. mine any coin with BTC address? [y/N]: " BTC
    read -e -p "Please enter a new location for /site/AdminPanel, if required. This is to customize the Admin Panel entrance url (e.g. myControlPanel): " admin_panel
    read -e -p "Public IP of the system you will use to access the admin panel from (IP of YOUR PC/internet connection, NOT the VPS, NOT a private IP): " Public
    read -e -p "Install Fail2ban? [Y/n]: " install_fail2ban
    read -e -p "Install UFW and configure ports? [Y/n]: " UFW
    read -e -p "Install LetsEncrypt SSL? IMPORTANT! You MUST have your domain name DNS pointed to this server prior to running the script!! [Y/n]: " ssl_install

    # Installing Nginx
    echo
    echo
    echo -e "$CYAN => Installing Nginx server: $COL_RESET"
    echo
    sleep 3

    if [ -f /usr/sbin/apache2 ]; then
    echo -e "Removing apache..."
    sudo apt-get -y purge apache2 apache2-*
    sudo apt-get -y --purge autoremove
    fi

    sudo apt -y install nginx
    sudo rm /etc/nginx/sites-enabled/default
    sudo systemctl start nginx.service
    sudo systemctl enable nginx.service
    sudo systemctl start cron.service
    sudo systemctl enable cron.service
    sleep 5
    sudo systemctl status nginx | sed -n "1,3p"
    sleep 15
    echo
    echo -e "$GREEN Done...$COL_RESET"

    # Making Nginx a bit hard
    echo 'map $http_user_agent $blockedagent {
    default         0;
    ~*malicious     1;
    ~*bot           1;
    ~*backdoor      1;
    ~*crawler       1;
    ~*bandit        1;
    }
    ' | sudo -E tee /etc/nginx/blockuseragents.rules >/dev/null 2>&1

    # Installing Mariadb
    echo
    echo
    echo -e "$CYAN => Installing Mariadb Server: $COL_RESET"
    echo
    sleep 3

    # Create random password
    rootpasswd=$(openssl rand -base64 12)
    export DEBIAN_FRONTEND="noninteractive"
    sudo apt -y install mariadb-server
    sudo systemctl enable mariadb.service
    sudo systemctl start mariadb.service
    sleep 5
    sudo systemctl status mariadb | sed -n "1,3p"
    sleep 15
    echo
    echo -e "$GREEN Done...$COL_RESET"

    # Installing Installing php8.2
    echo
    echo
    echo -e "$CYAN => Installing php8.2: $COL_RESET"
    sleep 3

    source conf/pool.conf
    if [ ! -f /etc/apt/sources.list.d/ondrej-php-bionic.list ]; then
    sudo add-apt-repository -y ppa:ondrej/php
    fi
    hide_output sudo apt -y update

    if [[ ("$DISTRO" == "22") ]]; then
    sudo apt_install php8.2-fpm php8.2-opcache php8.2 php8.2-common php8.2-gd php8.2-mysql php8.2-imap php8.2-cli \
    php8.2-cgi php-pear php-auth imagemagick libruby php8.2-curl php8.2-intl php8.2-pspell mcrypt\
    php8.2-recode php8.2-sqlite3 php8.2-tidy php8.2-xmlrpc php8.2-xsl memcached php-memcache php-imagick php-gettext php8.2-zip php8.2-mbstring \
    libpsl-dev libnghttp2-dev php8.2-memcache php8.2-memcached net-tools
    sudo phpenmod mcrypt
    sudo phpenmod mbstring
    else  
     echo -e "$RED Aborting, wrong O/S. Must be Ubuntu 22.04."
     exit 1
    fi

    hide_output sudo update-alternatives --set php /usr/bin/php8.2
    
    sleep 5
    sudo systemctl start php8.2-fpm
    sudo systemctl status php8.2-fpm | sed -n "1,3p"
    sleep 15
    echo
    echo -e "$GREEN Done...$COL_RESET"

    # Installing other needed files
    echo
    echo
    echo -e "$CYAN => Installing other required files: $COL_RESET"
    echo
    sleep 3

    sudo apt -y install libgmp3-dev libmysqlclient-dev libcurl4-gnutls-dev libkrb5-dev libldap2-dev libidn11-dev gnutls-dev \
    librtmp-dev sendmail mutt screen git
    sudo apt -y install pwgen -y
    echo -e "$GREEN Done...$COL_RESET"
    sleep 3

    # Installing packages to compile crypto currency:
    echo
    echo
    echo -e "$CYAN => Installing Packages to compile crypto currency $COL_RESET"
    echo
    sleep 3

    sudo apt -y install libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils git cmake libboost-all-dev zlib1g-dev libz-dev libseccomp-dev libcap-dev libminiupnpc-dev gettext
    sudo apt -y install libminiupnpc17 libzmq5
    sudo apt -y install libcanberra-gtk-module libqrencode-dev libzmq3-dev libminizip-dev
    sudo apt -y install libqt5gui5 libqt5core5a libqt5webkit5-dev libqt5dbus5 qttools5-dev qttools5-dev-tools libprotobuf-dev protobuf-compiler fonts-powerline
    sudo apt -y install libssh-dev libbrotli-dev
    sudo add-apt-repository -y ppa:luke-jr/bitcoincore
    hide_output sudo apt -y update
    sudo apt -y install libdb4.8-dev libdb4.8++-dev libdb5.3 libdb5.3++
    echo -e "$GREEN Done...$COL_RESET"


    # Generating Random Passwords
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    password2=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    AUTOGENERATED_PASS=`pwgen -c -1 20`

    #TODO: Need testing
    # Test Email
    echo
    echo
    echo -e "$CYAN => Testing to see if server emails are sent: $COL_RESET"
    echo
    sleep 3

    if [[ "$root_email" != "" ]]; then
        echo $root_email > sudo tee --append ~/.email
        echo $root_email > sudo tee --append ~/.forward

    if [[ ("$send_email" == "y" || "$send_email" == "Y" || "$send_email" == "") ]]; then
        echo "This is a mail test for the SMTP Service." > sudo tee --append /tmp/email.message
        echo "You should receive this !" >> sudo tee --append /tmp/email.message
        echo "" >> sudo tee --append /tmp/email.message
        echo "Cheers" >> sudo tee --append /tmp/email.message
        sudo sendmail -s "SMTP Testing" $root_email < sudo tee --append /tmp/email.message

        sudo rm -f /tmp/email.message
        echo "Mail sent"
    fi
    fi
    echo -e "$GREEN Done...$COL_RESET"

    # Installing Fail2Ban & UFW
    echo
    echo
    echo -e "$CYAN => Some optional installs (Fail2Ban & UFW): $COL_RESET"
    echo
    sleep 3

    if [[ ("$install_fail2ban" == "y" || "$install_fail2ban" == "Y" || "$install_fail2ban" == "") ]]; then
    sudo apt -y install fail2ban
    sleep 5
    sudo systemctl status fail2ban | sed -n "1,3p"
        fi

    if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
    sudo apt  install ufw -y
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow http
    sudo ufw allow https
    sudo ufw allow 3333/tcp
    sudo ufw allow 3339/tcp
    sudo ufw allow 3334/tcp
    sudo ufw allow 3433/tcp
    sudo ufw allow 3555/tcp
    sudo ufw allow 3556/tcp
    sudo ufw allow 3573/tcp
    sudo ufw allow 3535/tcp
    sudo ufw allow 3533/tcp
    sudo ufw allow 3553/tcp
    sudo ufw allow 3633/tcp
    sudo ufw allow 3733/tcp
    sudo ufw allow 3636/tcp
    sudo ufw allow 3737/tcp
    sudo ufw allow 3739/tcp
    sudo ufw allow 3747/tcp
    sudo ufw allow 3833/tcp
    sudo ufw allow 3933/tcp
    sudo ufw allow 4033/tcp
    sudo ufw allow 4133/tcp
    sudo ufw allow 4233/tcp
    sudo ufw allow 4234/tcp
    sudo ufw allow 4333/tcp
    sudo ufw allow 4433/tcp
    sudo ufw allow 4533/tcp
    sudo ufw allow 4553/tcp
    sudo ufw allow 4633/tcp
    sudo ufw allow 4733/tcp
    sudo ufw allow 4833/tcp
    sudo ufw allow 4933/tcp
    sudo ufw allow 5033/tcp
    sudo ufw allow 5133/tcp
    sudo ufw allow 5233/tcp
    sudo ufw allow 5333/tcp
    sudo ufw allow 5433/tcp
    sudo ufw allow 5533/tcp
    sudo ufw allow 5733/tcp
    sudo ufw allow 5743/tcp
    sudo ufw allow 3252/tcp
    sudo ufw allow 5755/tcp
    sudo ufw allow 5766/tcp
    sudo ufw allow 5833/tcp
    sudo ufw allow 5900/tcp
    sudo ufw allow 5933/tcp
    sudo ufw allow 6033/tcp
    sudo ufw allow 5034/tcp
    sudo ufw allow 6133/tcp
    sudo ufw allow 6233/tcp
    sudo ufw allow 6333/tcp
    sudo ufw allow 6433/tcp
    sudo ufw allow 7433/tcp
    sudo ufw allow 7070/tcp
    sudo ufw allow 8333/tcp
    sudo ufw allow 8463/tcp
    sudo ufw allow 8433/tcp
    sudo ufw allow 8533/tcp
    sudo ufw allow 9333/tcp
    sudo ufw allow 9321/tcp
    sudo ufw allow 22556/tcp
    sudo ufw allow 22171/tcp
    sudo ufw --force enable
    sleep 5
    sudo systemctl status ufw | sed -n "1,3p"
    fi

    echo
    echo -e "$GREEN Done...$COL_RESET"

    # Installing PhpMyAdmin
    echo
    echo
    echo -e "$CYAN => Installing phpMyAdmin: $COL_RESET"
    echo
    sleep 3

    echo "phpmyadmin phpmyadmin/reconfigure-webserver multiselect" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/dbconfig-install boolean true" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-user string root" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/admin-pass password $rootpasswd" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/mysql/app-pass password $AUTOGENERATED_PASS" | sudo debconf-set-selections
    echo "phpmyadmin phpmyadmin/app-password-confirm password $AUTOGENERATED_PASS" | sudo debconf-set-selections
    sudo apt -y install phpmyadmin
    echo -e "$GREEN Done...$COL_RESET"

    # Installing Yiimp`
    echo
    echo
    echo -e "$CYAN => Installing Yiimp $COL_RESET"
    echo -e "$MAGENTA Grabbing Yiimp fron Github, building files and setting file structure.$COL_RESET"
    echo
    sleep 3

    # Generating Random Password for stratum
    blckntifypass=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`

    # Compile Blocknotify
    echo -e "Compiling Blocknotify"
    cd ~
    sudo git clone https://github.com/Xropzzy/yiimp.git
    cd $HOME/yiimp/blocknotify
    sudo sed -i 's/tu8tu5/'$blckntifypass'/' blocknotify.cpp
    make -j$((`nproc`+1))
    sudo strip blocknotify

    # Compile Stratum
    echo -e "Compiling Stratum"
    cd $HOME/yiimp/stratum/
    sudo git submodule init && git submodule update
    sudo apt_install gcc-10 g++-10 -y
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 11
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 10
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 11
    sudo update-alternatives --set gcc /usr/bin/gcc-10
    sudo update-alternatives --set g++ /usr/bin/g++-10 
    
    sudo git submodule init && git submodule update
    sudo make -C algos
    sudo make -C sha3
    sudo make -C iniparser
    cd secp256k1
    sudo chmod +x autogen.sh && ./autogen.sh && ./configure --enable-experimental --enable-module-ecdh --with-bignum=no --enable-endomorphism && make
    cd $HOME/yiimp/stratum/
    if [[ ("$BTC" == "y" || "$BTC" == "Y") ]]; then
    sudo sed -i 's/CFLAGS += -DNO_EXCHANGE/#CFLAGS += -DNO_EXCHANGE/' $HOME/yiimp/stratum/Makefile
    fi
    sudo make -j$((`nproc`+1))

    sudo update-alternatives --set gcc /usr/bin/gcc-11 
    sudo update-alternatives --set g++ /usr/bin/g++-11 

    # Copy Files (Blocknotify,iniparser,Stratum)
    cd $HOME/yiimp
    sudo sed -i 's/AdminPanel/'$admin_panel'/' $HOME/yiimp/web/yaamp/modules/site/SiteController.php
    sudo cp -r $HOME/yiimp/web /var/
    sudo mkdir -p /var/stratum
    cd $HOME/yiimp/stratum
    sudo cp -a config.sample/. /var/stratum/config
    sudo strip stratum
    sudo cp -r stratum /var/stratum
    sudo cp -r run.sh /var/stratum
    sudo chmod +x /var/stratum/run.sh
    cd $HOME/yiimp
    sudo cp -r $HOME/yiimp/bin/. /bin/
    sudo cp -r $HOME/yiimp/blocknotify/blocknotify /usr/bin/
    sudo cp -r $HOME/yiimp/blocknotify/blocknotify /var/stratum/
    sudo mkdir -p /etc/yiimp
    sudo mkdir -p /$HOME/backup/
    #fixing yiimp
    sudo sed -i "s|ROOTDIR=/data/yiimp|ROOTDIR=/var|g" /bin/yiimp
    #fixing run.sh
    sudo rm -r /var/stratum/config/run.sh
    echo '
    #!/bin/bash
    ulimit -n 10240
    ulimit -u 10240
    cd /var/stratum
    while true; do
    ./stratum /var/stratum/config/$1
    sleep 2
    done
    exec bash
    ' | sudo -E tee /var/stratum/config/run.sh >/dev/null 2>&1
    sudo chmod +x /var/stratum/config/run.sh

    echo -e "$GREEN Done...$COL_RESET"

    # Update Timezone
    echo
    echo
    echo -e "$CYAN => Update default timezone. $COL_RESET"
    echo

    echo -e "Setting TimeZone to $TIME...$COL_RESET"
    if [ ! -f /etc/timezone ]; then
    echo "Setting timezone to $TIME."
    echo "$TIME" | sudo tee /etc/timezone
    sudo timedatectl set-timezone "$TIME"
    #echo $TIME > sudo /etc/timezone #备份的源代码
    sudo systemctl restart rsyslog
    fi
    sudo systemctl status rsyslog | sed -n "1,3p"
    echo
    echo -e "$GREEN Done...$COL_RESET"

    # Creating webserver initial config file
    echo
    echo
    echo -e "$CYAN => Creating webserver initial config file: $COL_RESET"
    echo

    # Adding user to group, creating dir structure, setting permissions
    sudo mkdir -p /var/www/$server_name/html

    if [[ ("$sub_domain" == "y" || "$sub_domain" == "Y") ]]; then
    echo 'include /etc/nginx/blockuseragents.rules;
    server {
    if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"';
        root "/var/www/'"${server_name}"'/html/web";
        index index.html index.htm index.php;
        charset utf-8;

        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        access_log /var/log/nginx/'"${server_name}"'.app-access.log;
        error_log /var/log/nginx/'"${server_name}"'.app-error.log;

        # allow larger file uploads and longer script runtimes
    client_body_buffer_size  50k;
        client_header_buffer_size 50k;
        client_max_body_size 20m;
        large_client_header_buffers 2 50k;
        sendfile off;

        location ~ ^/index\.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
            fastcgi_read_timeout 1300;
        try_files $uri $uri/ =404;
        }
        location ~ \.php$ {
            return 404;
        }
        location ~ \.sh {
        return 404;
        }
        location ~ /\.ht {
        deny all;
        }
        location ~ /.well-known {
        allow all;
        }
		location ^~ /list-algos/ {
		deny all;
			access_log off;
			return 301 https://$server_name;
		}
        location /phpmyadmin {
        root /usr/share/;
        index index.php;
        try_files $uri $uri/ =404;
        location ~ ^/phpmyadmin/(doc|sql|setup)/ {
            deny all;
      }
        location ~ /phpmyadmin/(.+\.php)$ {
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
            include snippets/fastcgi-php.conf;
        }
      }
    }
    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

    sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
    sudo ln -s /var/web /var/www/$server_name/html
    sudo ln -s /var/stratum/config /var/web/list-algos
    sudo systemctl reload php8.2-fpm.service
    sudo systemctl restart nginx.service
    echo -e "$GREEN Done...$COL_RESET"

    if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then

    # Install SSL (with SubDomain)
    echo
    echo -e 'Install LetsEncrypt and setting SSL (with SubDomain)'
    echo

    sudo apt -y install letsencrypt
    sudo letsencrypt certonly -a webroot --webroot-path=/var/web --email "$EMAIL" --agree-tos -d "$server_name"
    sudo rm /etc/nginx/sites-available/$server_name.conf
    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    # I am SSL Man!
    echo 'include /etc/nginx/blockuseragents.rules;
    server {
    if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"';
        # enforce https
        return 301 https://$server_name$request_uri;
    }

    server {
    if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
            listen 443 ssl http2;
            listen [::]:443 ssl http2;
            server_name '"${server_name}"';

            root /var/www/'"${server_name}"'/html/web;
            index index.php;

            access_log /var/log/nginx/'"${server_name}"'.app-access.log;
            error_log  /var/log/nginx/'"${server_name}"'.app-error.log;

            # allow larger file uploads and longer script runtimes
    client_body_buffer_size  50k;
        client_header_buffer_size 50k;
        client_max_body_size 20m;
        large_client_header_buffers 2 50k;
        sendfile off;

            # strengthen ssl security
            ssl_certificate /etc/letsencrypt/live/'"${server_name}"'/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/'"${server_name}"'/privkey.pem;
            ssl_protocols TLSv1.2 TLSv1.3;
            ssl_prefer_server_ciphers on;
            ssl_session_cache shared:SSL:10m;
            ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
            ssl_dhparam /etc/ssl/certs/dhparam.pem;

            # Add headers to serve security related headers
            add_header Strict-Transport-Security "max-age=15768000; preload;";
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Robots-Tag none;
            add_header Content-Security-Policy "frame-ancestors 'self'";

        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }


            location ~ ^/index\.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_intercept_errors off;
                fastcgi_buffer_size 16k;
                fastcgi_buffers 4 16k;
                fastcgi_connect_timeout 300;
                fastcgi_send_timeout 300;
                fastcgi_read_timeout 1300;
                include /etc/nginx/fastcgi_params;
            try_files $uri $uri/ =404;
        }
        location ~ \.php$ {
            return 404;
        }
        location ~ \.sh {
        return 404;
        }

            location ~ /\.ht {
                deny all;
            }
        location /phpmyadmin {
        root /usr/share/;
        index index.php;
        try_files $uri $uri/ =404;
        location ~ ^/phpmyadmin/(doc|sql|setup)/ {
            deny all;
    }
        location ~ /phpmyadmin/(.+\.php)$ {
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
            include snippets/fastcgi-php.conf;
       }
     }
    }

    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1
    fi

    sudo systemctl reload php8.2-fpm.service
    sudo systemctl restart nginx.service
    echo -e "$GREEN Done...$COL_RESET"

    else
    echo 'include /etc/nginx/blockuseragents.rules;
    server {
    if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"' www.'"${server_name}"';
        root "/var/www/'"${server_name}"'/html/web";
        index index.html index.htm index.php;
        charset utf-8;

        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        access_log /var/log/nginx/'"${server_name}"'.app-access.log;
        error_log /var/log/nginx/'"${server_name}"'.app-error.log;

        # allow larger file uploads and longer script runtimes
        client_body_buffer_size  50k;
        client_header_buffer_size 50k;
        client_max_body_size 20m;
        large_client_header_buffers 2 50k;
        sendfile off;

        location ~ ^/index\.php$ {
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
            fastcgi_index index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            fastcgi_intercept_errors off;
            fastcgi_buffer_size 16k;
            fastcgi_buffers 4 16k;
            fastcgi_connect_timeout 300;
            fastcgi_send_timeout 300;
            fastcgi_read_timeout 1300;
        try_files $uri $uri/ =404;
        }
        location ~ \.php$ {
            return 404;
        }
        location ~ \.sh {
        return 404;
        }
        location ~ /\.ht {
        deny all;
        }
        location ~ /.well-known {
        allow all;
        }
		location ^~ /list-algos/ {
		deny all;
			access_log off;
			return 301 https://$server_name;
		}
        location /phpmyadmin {
        root /usr/share/;
        index index.php;
        try_files $uri $uri/ =404;
        location ~ ^/phpmyadmin/(doc|sql|setup)/ {
            deny all;
    }
        location ~ /phpmyadmin/(.+\.php)$ {
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
            include snippets/fastcgi-php.conf;
        }
      }
    }
    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

    sudo ln -s /etc/nginx/sites-available/$server_name.conf /etc/nginx/sites-enabled/$server_name.conf
    sudo ln -s /var/web /var/www/$server_name/html
    sudo ln -s /var/stratum/config /var/web/list-algos
    sudo systemctl reload php8.2-fpm.service
    sudo systemctl restart nginx.service
    echo -e "$GREEN Done...$COL_RESET"

    if [[ ("$ssl_install" == "y" || "$ssl_install" == "Y" || "$ssl_install" == "") ]]; then

    # Install SSL (without SubDomain)
    echo
    echo -e 'Install LetsEncrypt and setting SSL (without SubDomain)'
    echo
    sleep 3

    sudo apt -y install letsencrypt
    sudo letsencrypt certonly -a webroot --webroot-path=/var/web --email "$EMAIL" --agree-tos -d "$server_name" -d www."$server_name"
    sudo rm /etc/nginx/sites-available/$server_name.conf
    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    # I am SSL Man!
    echo 'include /etc/nginx/blockuseragents.rules;
    server {
    if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
        listen 80;
        listen [::]:80;
        server_name '"${server_name}"';
        # enforce https
        return 301 https://$server_name$request_uri;
    }

    server {
    if ($blockedagent) {
                return 403;
        }
        if ($request_method !~ ^(GET|HEAD|POST)$) {
        return 444;
        }
            listen 443 ssl http2;
            listen [::]:443 ssl http2;
            server_name '"${server_name}"' www.'"${server_name}"';

            root /var/www/'"${server_name}"'/html/web;
            index index.php;

            access_log /var/log/nginx/'"${server_name}"'.app-access.log;
            error_log  /var/log/nginx/'"${server_name}"'.app-error.log;

            # allow larger file uploads and longer script runtimes
        client_body_buffer_size  50k;
        client_header_buffer_size 50k;
        client_max_body_size 20m;
        large_client_header_buffers 2 50k;
        sendfile off;

            # strengthen ssl security
            ssl_certificate /etc/letsencrypt/live/'"${server_name}"'/fullchain.pem;
            ssl_certificate_key /etc/letsencrypt/live/'"${server_name}"'/privkey.pem;
            ssl_protocols TLSv1.2 TLSv1.3;
            ssl_prefer_server_ciphers on;
            ssl_session_cache shared:SSL:10m;
            ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:ECDHE-RSA-AES128-GCM-SHA256:AES256+EECDH:DHE-RSA-AES128-GCM-SHA256:AES256+EDH:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
            ssl_dhparam /etc/ssl/certs/dhparam.pem;

            # Add headers to serve security related headers
            add_header Strict-Transport-Security "max-age=15768000; preload;";
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection "1; mode=block";
            add_header X-Robots-Tag none;
            add_header Content-Security-Policy "frame-ancestors 'self'";

        location / {
        try_files $uri $uri/ /index.php?$args;
        }
        location @rewrite {
        rewrite ^/(.*)$ /index.php?r=$1;
        }

            location ~ ^/index\.php$ {
                fastcgi_split_path_info ^(.+\.php)(/.+)$;
                fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
                fastcgi_index index.php;
                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_intercept_errors off;
                fastcgi_buffer_size 16k;
                fastcgi_buffers 4 16k;
                fastcgi_connect_timeout 300;
                fastcgi_send_timeout 300;
                fastcgi_read_timeout 1300;
                include /etc/nginx/fastcgi_params;
            try_files $uri $uri/ =404;
        }
        location ~ \.php$ {
            return 404;
        }
 
		location ~ \.sh {
			return 404;
        }

		location ~ /\.ht {
			deny all;
		}
		
		location /phpmyadmin {
        root /usr/share/;
        index index.php;
        try_files $uri $uri/ =404;
        location ~ ^/phpmyadmin/(doc|sql|setup)/ {
            deny all;
    }
        location ~ /phpmyadmin/(.+\.php)$ {
            fastcgi_pass unix:/run/php/php8.2-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
            include snippets/fastcgi-php.conf;
        }
      }
    }

    ' | sudo -E tee /etc/nginx/sites-available/$server_name.conf >/dev/null 2>&1

    echo -e "$GREEN Done...$COL_RESET"

    fi
    sudo systemctl reload php8.2-fpm.service
    sudo systemctl restart nginx.service
    fi

    # Config Database
    echo
    echo
    echo -e "$CYAN => Importing database: $COL_RESET"
    echo
    sleep 3

    # Create database
    Q1="CREATE DATABASE IF NOT EXISTS yiimpfrontend;"
    Q2="GRANT ALL ON *.* TO 'panel'@'localhost' IDENTIFIED BY '$password';"
    Q3="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}${Q3}"
    sudo mysql -u root -p="" -e "$SQL"

    # Create stratum user
    Q1="GRANT ALL ON *.* TO 'stratum'@'localhost' IDENTIFIED BY '$password2';"
    Q2="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}"
    sudo mysql -u root -p="" -e "$SQL"

    #Create my.cnf

    echo '
    [clienthost1]
    user=panel
    password='"${password}"'
    database=yiimpfrontend
    host=localhost
    [clienthost2]
    user=stratum
    password='"${password2}"'
    database=yiimpfrontend
    host=localhost
    [myphpadmin]
    user=phpmyadmin
    password='"${AUTOGENERATED_PASS}"'
    [mysql]
    user=root
    password='"${rootpasswd}"'
    ' | sudo -E tee ~/.my.cnf >/dev/null 2>&1
      sudo chmod 0600 ~/.my.cnf


    # Create keys file
    echo '
    <?php
    /* Sample config file to put in /etc/yiimp/keys.php */
    define('"'"'YIIMP_MYSQLDUMP_USER'"'"', '"'"'panel'"'"');
    define('"'"'YIIMP_MYSQLDUMP_PASS'"'"', '"'"''"${password}"''"'"');
    define('"'"'YIIMP_MYSQLDUMP_PATH'"'"', '"'"''"/home/crypto-data/backups"''"'"');
    define('"'"'YIIMP_MYSQLDUMP_PATH'"'"', '"'"''"/var/yiimp/sauv"''"'"');
    /* Keys required to create/cancel orders and access your balances/deposit addresses */
    define('"'"'EXCH_BITTREX_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_BITSTAMP_SECRET'"'"','"'"''"'"');
    define('"'"'EXCH_BLEUTRADE_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_BTER_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_CCEX_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_COINMARKETS_PASS'"'"', '"'"''"'"');
    define('"'"'EXCH_CRYPTOPIA_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_EMPOEX_SECKEY'"'"', '"'"''"'"');
    define('"'"'EXCH_HITBTC_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_KRAKEN_SECRET'"'"','"'"''"'"');
    define('"'"'EXCH_LIVECOIN_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_NOVA_SECRET'"'"','"'"''"'"');
    define('"'"'EXCH_POLONIEX_SECRET'"'"', '"'"''"'"');
    define('"'"'EXCH_YOBIT_SECRET'"'"', '"'"''"'"');
    ' | sudo -E tee /etc/yiimp/keys.php >/dev/null 2>&1

    echo -e "$GREEN Done...$COL_RESET"

    # Peforming the SQL import
    echo
    echo
    echo -e "$CYAN => Database 'yiimpfrontend' and users 'panel' and 'stratum' created with password $password and $password2, will be saved for you in ~/.my.cnf $COL_RESET"
    echo
    echo -e "Performing the SQL import"
    echo
    sleep 3

    cd ~
    cd yiimp/sql

    # Import sql dump
    sudo zcat yiimp-import.sql.gz | sudo mysql --defaults-group-suffix=host1 --defaults-file=/home/${whoami}/.my.cnf
    echo -e "$GREEN Done...$COL_RESET"

    # Oh the humanity!
    sudo mysql --defaults-group-suffix=host1 --force < 2016-04-24-market_history.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2016-04-27-settings.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2016-05-11-coins.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2016-05-15-benchmarks.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2016-05-23-bookmarks.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2016-06-01-notifications.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2016-06-04-bench_chips.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2016-11-23-coins.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2017-02-05-benchmarks.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2017-03-31-earnings_index.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2017-05-accounts_case_swaptime.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2017-06-payouts_coinid_memo.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2017-09-notifications.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2017-10-bookmarks.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2017-11-segwit.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2018-01-stratums_ports.sql
    sudo mysql --defaults-group-suffix=host1 --force < 2018-02-coins_getinfo.sql
    echo -e "$GREEN Done...$COL_RESET"

    # Generating a basic Yiimp serverconfig.php
    echo
    echo
    echo -e "$CYAN => Generating a basic Yiimp serverconfig.php: $COL_RESET"
    echo
    sleep 3

    # Make config file
    echo '
    <?php
    ini_set('"'"'date.timezone'"'"', '"'"''"${TIME}"''"'"');
    define('"'"'YAAMP_LOGS'"'"', '"'"'/var/log/yiimp'"'"');
    define('"'"'YAAMP_HTDOCS'"'"', '"'"'/var/web'"'"');

    define('"'"'YAAMP_BIN'"'"', '"'"'/var/bin'"'"');

    define('"'"'YAAMP_DBHOST'"'"', '"'"'localhost'"'"');
    define('"'"'YAAMP_DBNAME'"'"', '"'"'yiimpfrontend'"'"');
    define('"'"'YAAMP_DBUSER'"'"', '"'"'panel'"'"');
    define('"'"'YAAMP_DBPASSWORD'"'"', '"'"''"${password}"''"'"');

    define('"'"'YAAMP_PRODUCTION'"'"', true);
    define('"'"'YAAMP_RENTAL'"'"', false);

    define('"'"'YAAMP_LIMIT_ESTIMATE'"'"', false);

    define('"'"'YAAMP_FEES_SOLO'"'"', 0.5);
    define('"'"'YAAMP_FEES_MINING'"'"', 2);

    define('"'"'YAAMP_FEES_MINING'"'"', 0.5);
    define('"'"'YAAMP_FEES_EXCHANGE'"'"', 2);
    define('"'"'YAAMP_FEES_RENTING'"'"', 2);
    define('"'"'YAAMP_TXFEE_RENTING_WD'"'"', 0.002);

    define('"'"'YAAMP_PAYMENTS_FREQ'"'"', 2*60*60);
    define('"'"'YAAMP_CLEARS_DELAY'"'"', 5*60);
    define('"'"'YAAMP_PAYMENTS_MINI'"'"', 0.001);

    define('"'"'YAAMP_ALLOW_EXCHANGE'"'"', false);
    define('"'"'YIIMP_PUBLIC_EXPLORER'"'"', true);
    define('"'"'YIIMP_PUBLIC_BENCHMARK'"'"', false);

    define('"'"'YIIMP_FIAT_ALTERNATIVE'"'"', '"'"'USD'"'"'); // USD is main
    define('"'"'YAAMP_USE_NICEHASH_API'"'"', false);

    define('"'"'YAAMP_BTCADDRESS'"'"', '"'"'3MYtpA2nEvysCMsKG2UfGWqYsTaQWuGo16'"'"');

    define('"'"'YAAMP_SITE_URL'"'"', '"'"''"${server_name}"''"'"');
    define('"'"'YAAMP_STRATUM_URL'"'"', YAAMP_SITE_URL); // change if your stratum server is on a different host
    define('"'"'YAAMP_SITE_NAME'"'"', '"'"''"${poolname}"''"'"');
    define('"'"'YAAMP_ADMIN_EMAIL'"'"', '"'"''"${EMAIL}"''"'"');
    define('"'"'YAAMP_ADMIN_IP'"'"', '"'"''"${Public}"''"'"'); // samples: "80.236.118.26,90.234.221.11" or "10.0.0.1/8"

    define('"'"'YAAMP_ADMIN_WEBCONSOLE'"'"', true);
    define('"'"'YAAMP_CREATE_NEW_COINS'"'"', false);
    define('"'"'YAAMP_NOTIFY_NEW_COINS'"'"', false);

    define('"'"'YAAMP_DEFAULT_ALGO'"'"', '"'"'all'"'"');

    define('"'"'YAAMP_USE_NGINX'"'"', true);

    // Exchange public keys (private keys are in a separate config file)
    define('"'"'EXCH_CRYPTOPIA_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_POLONIEX_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_BITTREX_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_BLEUTRADE_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_BTER_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_YOBIT_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_CCEX_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_COINMARKETS_USER'"'"', '"'"''"'"');
    define('"'"'EXCH_COINMARKETS_PIN'"'"', '"'"''"'"');
    define('"'"'EXCH_BITSTAMP_ID'"'"','"'"''"'"');
    define('"'"'EXCH_BITSTAMP_KEY'"'"','"'"''"'"');
    define('"'"'EXCH_HITBTC_KEY'"'"','"'"''"'"');
    define('"'"'EXCH_KRAKEN_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_LIVECOIN_KEY'"'"', '"'"''"'"');
    define('"'"'EXCH_NOVA_KEY'"'"', '"'"''"'"');

    // Automatic withdraw to Yaamp btc wallet if btc balance > 0.3
    define('"'"'EXCH_AUTO_WITHDRAW'"'"', 0.3);

    // nicehash keys deposit account & amount to deposit at a time
    define('"'"'NICEHASH_API_KEY'"'"','"'"'xxxx'"'"');
    define('"'"'NICEHASH_API_ID'"'"','"'"'xxxx'"'"');
    define('"'"'NICEHASH_DEPOSIT'"'"','"'"'xxxx'"'"');
    define('"'"'NICEHASH_DEPOSIT_AMOUNT'"'"','"'"'0.01'"'"');

    $cold_wallet_table = array(
	'"'"'bc1q65czt7854fqwhhl7hup27dcuw2cugpm9ru7nut'"'"' => 0.10,
    );

    // Sample fixed pool fees
    $configFixedPoolFees = array(
        '"'"'zr5'"'"' => 2.0,
        '"'"'scrypt'"'"' => 2.0,
        '"'"'sha256'"'"' => 2.0,
     );

     // Sample fixed pool fees solo
    $configFixedPoolFeesSolo = array(
        '"'"'zr5'"'"' => 2.0,
        '"'"'scrypt'"'"' => 2.0,
        '"'"'sha256'"'"' => 2.0,

    );

    // Sample custom stratum ports
    $configCustomPorts = array(
    //	'"'"'x11'"'"' => 7000,
    );

    // mBTC Coefs per algo (default is 1.0)
    $configAlgoNormCoef = array(
    //	'"'"'x11'"'"' => 5.0,
    );
    ' | sudo -E tee /var/web/serverconfig.php >/dev/null 2>&1

    echo -e "$GREEN Done...$COL_RESET"

    # Updating stratum config files with database connection info
    echo
    echo
    echo -e "$CYAN => Updating stratum config files with database connection info: $COL_RESET"
    echo
    sleep 3

    cd /var/stratum/config
    sudo sed -i 's/password = tu8tu5/password = '$blckntifypass'/g' *.conf
    sudo sed -i 's/server = yaamp.com/server = '$server_name'/g' *.conf
    sudo sed -i 's/host = yaampdb/host = localhost/g' *.conf
    sudo sed -i 's/database = yaamp/database = yiimpfrontend/g' *.conf
    sudo sed -i 's/username = root/username = stratum/g' *.conf
    sudo sed -i 's/password = patofpaq/password = '$password2'/g' *.conf
    cd ~
    echo -e "$GREEN Done...$COL_RESET"

    # Final Directory permissions
    echo
    echo
    echo -e "$CYAN => Working on final directory permissions: $COL_RESET"
    echo
    sleep 3

    whoami=`whoami`
    sudo usermod -aG www-data $whoami
    sudo usermod -a -G www-data $whoami

    sudo find /var/web -type d -exec chmod 775 {} +
    sudo find /var/web -type f -exec chmod 664 {} +
    sudo chgrp www-data /var/web -R
    sudo chmod g+w /var/web -R

    sudo mkdir /var/log/yiimp
    sudo touch /var/log/yiimp/debug.log
    sudo chgrp www-data /var/log/yiimp -R
    sudo chmod 775 /var/log/yiimp -R

    sudo chgrp www-data /var/stratum -R
    sudo chmod 775 /var/stratum

    sudo mkdir -p /var/yiimp/sauv
    sudo chgrp www-data /var/yiimp -R
    sudo chmod 775 /var/yiimp -R
    sudo mkdir -p /home/crypto-data/backups
    sudo chgrp www-data /home/crypto-data/backups -R
    sudo chmod 775 /home/crypto-data/backups -R

    #Add to contrab screen-script
    (crontab -l 2>/dev/null; echo "@reboot sleep 20 && /etc/screen-script.sh") | crontab -

    #Add to contrab screen-stratum
    (crontab -l 2>/dev/null; echo "@reboot sleep 20 && /etc/screen-stratum.sh") | crontab -

    #fix error screen main "service"
    sudo sed -i 's/service $webserver start/sudo service $webserver start/g' /var/web/yaamp/modules/thread/CronjobController.php
    sudo sed -i 's/service nginx stop/sudo service nginx stop/g' /var/web/yaamp/modules/thread/CronjobController.php

    sudo mkdir -p /home/crypto-data/wallets
    sudo chown -R ${whoami}:${whoami} /home/crypto-data/

    #fix error screen main "backup sql frontend"
    sudo sed -i "s|/root/backup|/var/yiimp/sauv|g" /var/web/yaamp/core/backend/system.php
    sudo sed -i "s|/root/backup|/home/crypto-data/backups|g" /var/web/yaamp/core/backend/system.php
    sudo sed -i '14d' /var/web/yaamp/defaultconfig.php

    #MOTD
    sudo rm -r /etc/update-motd.d/
    sudo mkdir /etc/update-motd.d/
    sudo cp yiimp_install_script/conf/motd/* /etc/update-motd.d/
    sudo chmod +x /etc/update-motd.d/*

    if [[ $poolname == "" ]]
    then
       poolname="Saltpool"
    fi
     
    sudo sed -i "s/xxxxxx/$poolname/g" /etc/update-motd.d/00-header
    echo '
    clear
    run-parts /etc/update-motd.d/ | sudo tee /etc/motd
    ' | sudo -E tee /usr/bin/motd >/dev/null 2>&1
    sudo chmod +x /usr/bin/motd
    
    sudo cp yiimp_install_script/utils/screens /usr/bin/
    sudo chmod +x /usr/bin/screens 

    #Donations
    echo 'BTCDON="bc1q65czt7854fqwhhl7hup27dcuw2cugpm9ru7nut"
    LTCDON=""
    ETHDON=""
    DOGEDON=""' | sudo -E tee /etc/yiimpdonate.conf >/dev/null 2>&1

    #Misc
    sudo mv $HOME/yiimp/ $HOME/yiimp-install-only-do-not-run-commands-from-this-folder
    sudo rm -rf /var/log/nginx/*

    #Hold update OpenSSL
    #If you want remove the hold: sudo apt-mark unhold openssl
    sudo apt-mark hold openssl

    #Restart service
    sudo systemctl restart cron.service
    sudo systemctl restart mysql
    sudo systemctl status mysql | sed -n "1,3p"
    sudo systemctl restart nginx.service
    sudo systemctl status nginx | sed -n "1,3p"
    sudo systemctl restart php8.2-fpm.service
    sudo systemctl status php8.2-fpm | sed -n "1,3p"

    echo
    echo -e "$GREEN Done...$COL_RESET"
    sleep 3

    sudo sed -i 's/$nrconf{restart} = '"'"'a'"'"';/#$nrconf{restart} = '"'"'i'"'"';/g' /etc/needrestart/needrestart.conf

    echo
    echo -e "$GREEN***************************************************$COL_RESET"
    echo -e "$GREEN Yiimp Install Script $script_version $COL_RESET"
    echo -e "$GREEN Finished !!! $COL_RESET"
    echo -e "$GREEN***************************************************$COL_RESET"
    echo
    echo -e "$YELLOW REMINDERS: $COL_RESET"
    echo -e "$RED \e[1mYour mysql information has been saved in ~/.my.cnf. $COL_RESET"  # 改用红色强调
    echo
    echo -e "$CYAN Yiimp at: http://$server_name (https... if SSL enabled)"
    echo -e "$RED \e[1mYiimp Admin at: http://$server_name/site/$admin_panel (https... if SSL enabled)"  # 高危红色
    echo -e "$CYAN Yiimp phpMyAdmin at: http://$server_name/phpmyadmin (https... if SSL enabled)"
    echo
    echo -e "$RED If you want change $admin_panel to access Panel Admin, edit this file:/var/web/yaamp/modules/site/SiteController.php"  # 红色警示
    echo -e "$CYAN Line 11 => change $admin_panel and use the new access name"
    echo
    echo -e "$GREEN Please make sure to change your public keys/wallet addresses in the /var/web/serverconfig.php file. $COL_RESET"
    echo -e "$GREEN Please make sure to change your private keys in the /etc/yiimp/keys.php file. $COL_RESET"
    echo
    echo -e "$RED***************************************************$COL_RESET"  # 红色边框
    echo -e "$RED \e[1mYOU MUST REBOOT NOW TO FINALISE INSTALLATION !!!  $COL_RESET"  # 红色强调
    echo -e "$RED***************************************************$COL_RESET"
    echo -e "$YELLOW If you have a white/blank page on the site check:      $COL_RESET"
    echo -e "$YELLOW php$php_version-memcache | php$php_version-memcached | php$php_version-fpm   $COL_RESET"
    echo -e "$YELLOW Try to restart them, or install if they don't exist.                    $COL_RESET"
    echo -e "$YELLOW Step 1: Try restarting them with: $COL_RESET"
    echo -e "$YELLOW   sudo systemctl restart php$php_version-fpm $COL_RESET"  # 具体命令
    echo -e "$YELLOW Step 2: If problem persists, reinstall them: $COL_RESET"
    echo -e "$YELLOW   sudo apt install --reinstall php$php_version-memcache php$php_version-memcached $COL_RESET"  # 明确方案
    echo -e "$RED***************************************************$COL_RESET"
    echo
