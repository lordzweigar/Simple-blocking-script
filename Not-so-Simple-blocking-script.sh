# le blocking script
function swap() {
    # Swap 2 filenames around, if they exist (from Uzi's bashrc).
    local TMPFILE=tmp.$$
    local params=( "$@" )

    [ $# -ne 2 ] && echo "swap: 2 arguments needed" && return 1
    [ ! -e $1 ] && echo "swap: $1 does not exist" && return 1
    [ ! -e $2 ] && echo "swap: $2 does not exist" && return 1

    mv "$1" $TMPFILE
    mv "$2" "$1"
    mv $TMPFILE "$2"
}

function swapper()
{ 
    sudo -v
    echo "swapping file names" ;   swap /etc/hosts /etc/hosts-slave ; sudo systemctl restart nscd
}

## I stole this from http://serverfault.com/questions/177699/how-can-i-execute-a-bash-function-with-sudo/177764#177764
function exesudo ()
{

    #
    # I use underscores to remember it's been passed
    local _funcname_="$1"

    local params=( "$@" )               ## array containing all params passed here
    local tmpfile="/dev/shm/$RANDOM"    ## temporary file
    local filecontent                   ## content of the temporary file
    local regex                         ## regular expression
    local func                          ## function source


    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ##
    #
    # MAIN CODE:
    #
    ### ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ##

    #
    # WORKING ON PARAMS:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    #
    # Shift the first param (which is the name of the function)
    unset params[0]              ## remove first element
    # params=( "${params[@]}" )     ## repack array
    #
    # WORKING ON THE TEMPORARY FILE:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    content="#!/bin/bash\n\n"

    #
    # Write the params array
    content="${content}params=(\n"

    regex="\s+"
    for param in "${params[@]}"
    do
        if [[ "$param" =~ $regex ]]
        then
            content="${content}\t\"${param}\"\n"
        else
            content="${content}\t${param}\n"
        fi
    done

    content="$content)\n"
    echo -e "$content" > "$tmpfile"

    #
    # Append the function source
    echo "#$( type "$_funcname_" )" >> "$tmpfile"

    #
    # Append the call to the function
    echo -e "\n$_funcname_ \"\${params[@]}\"\n" >> "$tmpfile"


    #
    # DONE: EXECUTE THE TEMPORARY FILE WITH SUDO
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    sudo bash "$tmpfile"
    rm "$tmpfile"
}

while getopts ":a:" opt; do
    case $1 in
        -help|\?|--help)
            echo "usage:
        -s  'swap'    Swaps the Master and Slave files (default mode)
        -a  'add'     Adds an entry to the current file 
        -r  'remove'  Removes and entry          
        -g  'global'  Adds an entry to both Master and Slave 
        -gr 'global'  Removes an entry from both Master and Slave 
        -h  'head'    prints the head of both Master and Slave 
        -t  'tail'    Prints the tail of both Master and Slave 
        -r  'reload'  Reloads ncsd
        -h  'help'    Displays this help message
"
            exit
            ;;

	-r|--remove)
	    if [ -n $2 ] ; then
		echo 'unset' $2 && sudo sed -i '/$2/jd' /etc/hosts  && sudo systemctl restart nscd
		#	    elif [ -n $2 ] && [ -n $3 ]
		#		 echo 'unset' $1 $2  && sudo sed -i '/$1$2/d' /etc/hosts  && sudo systemctl restart nscd	 
	    fi
	    ;;

	-gr|--global-remove)
	    if [ -n $2 ] ; then
		echo 'unset' $1 && sudo sed -i '/$1/d' /etc/hosts  && sudo sed -i '/$1/d' /etc/hosts-slave && sudo systemctl restart nscd
	    elif [ -n $2 ] && [ -n $3 ] ; then
		echo 'unset' $1 $ 2 && sudo sed -i '/$1$2/d' /etc/hosts  && sudo sed -i '/$1$2/d' /etc/hosts-slave && sudo systemctl restart nscd
	    else
		prinf "error"
		exit 1
	    fi
	    ;;
	-a|--all)
	    if [ -n $1 ] && [ -n $2 ] ; then
		echo 'Apending to current Master' $2 'to 127.0.0.1' && sudo echo  "127.0.0.1  $2" >> /etc/hosts   && sudo systemctl restart nscd
	    elif [ -n $2 ] && [ -n $2 ] ; then
		echo 'Appending to current Master:' $2 $3 $4 && sudo echo "$2 $3 $4" >> /etc/hosts && sudo systemctl restart nscd
	    fi
	    ;;
	-g|--global)
	    if [ -n $1 ] && [ -n $2 ] && [ -z $3 ] ; then
		echo 'globally redirecting' $2 'to 127.0.0.1' && sudo echo  "127.0.0.1  $2" >> /etc/hosts && sudo echo  "127.0.0.1  $2" >> /etc/hosts-slave  && sudo systemctl restart nscd
		
	    elif [ -n $1 ] && [ -n $2 ] && [ -n $3 ] ; then
		echo 'globally appending:' $2 $3 $4 && sudo echo  "$2 $3 $4" >> /etc/hosts && sudo echo  "$2 $3 $4" >> /etc/hosts-slave  && sudo systemctl restart nscd

	    else
		printf  "error"
		exit 1
	    fi
	    ;;

	-h|--head) 
	    echo '### /etc/hosts ###' ;  head /etc/hosts ; echo '### /etc/hosts-slave ###' ;  head /etc/hosts-slave
	    exit
	    ;;

	-t|--tail) 
	    echo '### /etc/hosts ###' ;  tail /etc/hosts ; echo '### /etc/hosts-slave ###' ;  tail /etc/hosts-slave  

	    exit
	    ;;

        -s|--swap)
	    echo "swapping Master and Slave" && exesudo swap /etc/hosts /etc/hosts-slave &&  sudo systemctl restart nscd 

	    exit
	    ;;
	-d|--reload)
	  echo 'reloading daemon'  && sudo systemctl stop  nscd ; sudo systemctl start nscd  
	    exit
	    ;;

    esac
    

done
