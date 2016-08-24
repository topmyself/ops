#!/bin/bash
echo $@
echo $#

function install_abc(){
    touch bcd.txt
}
pushd package
touch abc.txt
install_abc
popd

