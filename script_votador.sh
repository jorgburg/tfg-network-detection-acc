#!/bin/bash
if [ $# != 1 ]; then
  echo "Uso: ./script_votador.sh [num_nodos]"
  exit -1
fi
num_lineas_predict=25000
NUM_NODES=$1
MITAD=$(($NUM_NODES/2))

declare -a nums_total
for ((j=0; j<15001; j++))
do
	nums_total[$j]=0
done
printf "%s\n" "${nums_total[@]}" > file0.txt

echo "Ejecutando votador for $NUM_NODES nodes"
for ((i=0; i<$NUM_NODES; i++))
do
  declare -a nums_$i
done
for ((i=0; i<$NUM_NODES; i++))
do
  mapfile nums_$i < out_$i.predict

	for ((j=0; j<$num_lineas_predict; j++))
	do
		nums_total[$j]=$((nums_total[$j]+nums_$i[$j]))
	done 

done

for ((i=0;i<$num_lineas_predict; i++))
do
	if ((nums_total[$i] > $MITAD)); then
		nums_total[$i]=$((1))
else
		nums_total[$i]=$((0))
	fi
done

printf "%s\n" "${nums_total[@]}" > file.txt

num_aciertos=0

declare -a test_labels
mapfile test_labels < datos_test.labels
for((j=0;j<$num_lineas_predict; j++))
do
	if ((nums_total[$j] == test_labels[$j]));then
		num_aciertos=$((num_aciertos+1))
	fi
done
porcentaje=$(echo "scale=5; $num_aciertos/$num_lineas_predict" | bc)
porcentaje=$(echo "scale=5; $porcentaje*100" | bc)
echo "Aciertos: $num_aciertos/$num_lineas_predict"
echo "Porcentaje: $porcentaje"

