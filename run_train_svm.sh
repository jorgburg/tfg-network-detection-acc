#!/bin/bash
CONFIG="de1_soc-cluster.conf"
RUNPATH="/root/"

if [ $# != 1 ]; then
  echo "Uso: ./run_train_svm.sh [dataset file]"
  exit -1
fi


function get_time(){
  echo `date +%s%N`
}

OUTPATH="/root/"

# Lee la configuracion del cluster
echo -n "Reading cluster config..."
IFS=$'\n' read -d '' -r -a NODES < $CONFIG

NUM_NODES=${#NODES[@]}

echo "(num nodes: $NUM_NODES)"

for ((i=0; i<$NUM_NODES; i++))
do
  echo " |- Node $i: ${NODES[i]}"
done
echo " |- done"

# Divide el argumento (dataset de entrada) en NUM_NODOS trozos
echo "Spliting $1 in $NUM_NODES part(s)..."
time0=$(get_time)
split -d -a 1  --additional-suffix=.train -n l/$NUM_NODES $1 data_
echo " |- done"
time1=$(get_time)

# Copia el dataset a cada nodo
echo "Copying $1 and executing..."
for ((i=0; i<$NUM_NODES; i++))
do
  echo -n " |- ${NODES[i]}:$RUNPATH ..."
  ssh root@${NODES[i]} 'echo "running" > state' &&
  ini=$(get_time) &&
  scp -q $1 data_$i.train root@${NODES[i]}:$RUNPATH &&
  end=$(get_time) &&
  let SCPTIME[i]=$end-$ini &&
  echo -n " |- Time copying to node $i (sec): " &&
  echo "${SCPTIME[i]} * 0.000000001" | bc -l &&
  ssh root@${NODES[i]} " ./launch_svm_train.sh data_$i.train" &

  echo "done"
done
echo " |- done"

# Espera a que se envien los resultados
echo "Waiting for termination..."
for ((i=0; i<$NUM_NODES;))
do
  state=$(ssh -T root@${NODES[i]} "cat state")
  if [ $state = "finish" ]; then
    echo " |- ${NODES[i]} finished" 
    ssh -tt root@${NODES[i]} 'echo "idle" > state' &
    i=$((i + 1))
  fi
done
echo " |- done"
time3=$(get_time)

# Predict en la máquina con el model generado en las FPGA
echo "Predicting..."
  #./svm-predict datos.test data_0.train.model predict_out.predict
  #rm out/imageIn_*.ppm
  #rm imageIn_*.ppm
echo " |- done" 
time4=$(get_time)

echo ""
echo "#################################################"
echo ""
echo "                 EXECUTION TIME"
echo ""

let tiempo_total=$time3-$time0
let tiempo_dividir=$time1-$time0
let tiempo_ejecutar=$time3-$time1
let tiempo_predict=$time4-$time3

echo "  # Execution time (s):"

for ((i=0; i<$NUM_NODES; i++))
do
   node=$(ssh -q root@${NODES[i]} "cat /etc/hostname")
   nodeExecTime=$(ssh -T root@${NODES[i]} "head data_$i.train.log -n 1")
   nodeSCPTime=$(ssh -T root@${NODES[i]} "tail data_$i.train.log -n 1")
   echo -ne "     |- $node, execution time (sec): \t"
   echo "$nodeExecTime * 0.000000001" | bc -l
   echo -ne "     |- $node, SCP time (sec): \t"
   echo "$nodeSCPTime * 0.000000001" | bc -l
done
echo -ne "     |- TOTAL (sec):\t\t\t"
echo "$tiempo_ejecutar * 0.000000001" | bc -l


echo ""
echo "        ----------------------------- "
echo ""
echo -n "  TOTAL (s): "
echo "$tiempo_total * 0.000000001" | bc -l
echo ""
echo "#################################################"

