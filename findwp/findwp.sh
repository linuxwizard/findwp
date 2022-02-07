#!/bin/bash
USERNAME=$1
SSHSTATUS=""
PHP_PATH=`which php`
WP_CLI_PATH=`which wp-cli`

user_scan() {

    user_name=$1;
    WorkDir="/home/$user_name/"

    printf "\n\n\nChecking User %s for WordPress Installations\n" $user_name;

        SSHSTATUS=`grep $user_name /etc/passwd | grep "/bin/bash" | wc -l`
        if [ $SSHSTATUS -eq 0 ]
        then
                echo -e "Shell Access Disabled. Enabling it for $user_name temporarily \n\n"
                chsh --shell /bin/bash $user_name > /dev/null;
        fi


        for wp_install in `find $WorkDir -iname wp-config.php | sed "s/wp-config\.php//g"`
        do
                echo -e "====================================================\n\n"
                echo -e "Site URL : \t $(sudo -u $user_name -i --  $PHP_PATH $WP_CLI_PATH --path=$wp_install option get siteurl 2>&-) "
                printf "Install Directory : %s \n\n" $wp_install;
                printf "Installed WordPress Version : %s \nVersion is : %s" $(cat $wp_install/wp-includes/version.php | grep '$wp_version ='  |awk -F"=" {'print $2'} | sed "s/'//g;s/;//" | tr -d ' ' | xargs -I {} grep {} /tmp/wp_version_file | awk '{gsub(/"/, "", $1); gsub(/"/, "", $3); print $1,$3}')
                echo -e "\n\nInstalled Themes\n---------------------------\n"
                sudo -u $user_name -i -- $PHP_PATH  $WP_CLI_PATH --path=$wp_install theme list 2>&-
                echo -e "\nInstalled Plugins\n--------------------------\n"
                sudo -u $user_name -i -- $PHP_PATH $WP_CLI_PATH --path=$wp_install plugin list 2>&-
                echo -e "\n"
        done

        if [ $SSHSTATUS -eq 0 ]
        then
                chsh --shell /usr/local/cpanel/bin/noshell $user_name > /dev/null;
                echo -e "Disabling SSH for $user_name \n\n";
        fi

}

wget -qO /tmp/wp_version_file http://api.wordpress.org/core/stable-check/1.0/ > /dev/null

if [ -f /tmp/wp_version_file ]
then
        user_scan $USERNAME;
        rm -f /tmp/wp_version_file;
else
        echo "Cant find WordPress Version file, exiting!"
fi
