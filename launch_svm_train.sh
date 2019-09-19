#!/bin/bash

function get_time(){
  echo `date +%s%N`
}


EXECUTABLEPATH="/root"
MASTER="192.168.0.100"

mkdir -p $EXECUTABLEPATH/out

#state=$(cat state)
#if [ $state = "idle" ] || [ $state = "finish" ];
#then
  echo "running" > state
  time0=$(get_time)
#  $EXECUTABLEPATH/$1".train" > $1.log
  $EXECUTABLEPATH/svm-train $1
  time1=$(get_time)
  scp $1".model" burga@$MASTER:"/home/burga/tfg-d1soc-opencl-neuralnet/"$1".model"
  time2=$(get_time)
 # rm -rf /tmp/*

  let execTime=$time1-$time0
  let scpTime=$time2-$time1

  echo "$execTime" > $1".log"
  echo "$scpTime" >> $1".log"

#fi

echo "finish" > state

