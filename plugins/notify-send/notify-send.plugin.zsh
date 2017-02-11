#notify-send.plugin.zsh

#REQUIRES: xorg-xprop, awk/gawk, AND libnotify-bin
#IF THIS OUTPUT CHANGES BEFORE COMMAND FINISHES, NOTIFICATION WILL APPEAR
CurrentWindow() {
    xprop -root 2> /dev/null | awk '/NET_ACTIVE_WINDOW/{print $5;exit} END{exit !$5}' || echo "0"
}
typeset -g _LASTALERT=$HISTCMD
preexec() {
    SECONDS=0
    _COMMAND=$(echo "$1")
    isOpen=$(CurrentWindow)
}
precmd() {
    local ret_code="$?"
    local icon="${${ret_code/0/ok}//<->*/error}"
    local result="${${icon/ok/Task Finished}//error/Something Went Wrong!}"
    #CUSTOM EXIT CODE STATUS MESSAGES AND ICONS
    [[ $ret_code = 130 ]] && local result="User Cancelled" && local icon="important"
    [[ $ret_code = 148 ]] && local result="Command Suspended" && local icon="terminal"
    [[ $ret_code = 127 ]] && local result="Command Not Found"
    #ONLY NOTIFY IF WINDOW IS NOT ACTIVE
    [[ $(CurrentWindow) != "$isOpen" ]] &&
    #DON'T NOTIFY IF FROM SSH
    [[ -z "$SSH_CONNECTION" ]] &&
    #CHANGE SECONDS TO WHATEVER YOU WANT
    (( _LASTALERT < HISTCMD && SECONDS > 1 )) &&
    #6000ms (6 SECOND) TIMEOUT
    notify-send -t 6000 -u low -i \
         $icon "Terminal - Exit code {$ret_code}: $result" \"$_COMMAND\" &&
    #POSITIVE FEEDBACK OF NOTIFICATION
    echo "\e[0;32mNotification sent to Desktop:\nExit code \e[1;31m{$ret_code}\e[0;32m: $result\n\e[0;34m\"$_COMMAND\"\e[0m" || #$history[$_LASTALERT] ||
    _LASTALERT=$HISTCMD
}
