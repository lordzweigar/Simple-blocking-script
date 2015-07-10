#!/bin/bash
function block()
    if [ -n $1 ] ; then

          echo 'blocked' $1 && sudo echo  "0.0.0.0  $1" >> /etc/hosts && sudo systemctl restart nscd
     else
        echo  'Successfully blocked nothing'
    fi

function unblock()
    if [ -n $1 ] ; then
        echo 'unblocked' $1 && sudo sed -i '/$1/d' /etc/hosts  && sudo systemctl restart nscd
     else
        echo  'Successfully unblocked nothing'
    fi
alias unblockall="sudo mv /etc/hosts /etc/hosts-unblocked && sudo systemctl restart nscd"
alias   blockall="sudo mv /etc/hosts-unblocked /etc/hosts && sudo systemctl restart nscd"



