#!/bin/bash

INLIST=inlist_project
change() { 
    # Modifies a parameter in the current inlist. 
    # args: ($1) name of parameter 
    #       ($2) new value 
    #       ($3) filename of inlist where change should occur 
    # example command: change initial_mass 1.3 
    # example command: change log_directory 'LOGS_MS' 
    # example command: change do_element_diffusion .true. 
    param=$1 
    newval=$2 
    filename=$3 
    escapedParam=$(sed 's#[^^]#[&]#g; s#\^#\\^#g' <<< "$param")
    search="^\s*\!*\s*$escapedParam\s*=.+$" 
    replace="    $param = $newval" 
    if [ ! "$filename" == "" ]; then
        sed -r -i.bak -e "s#$search#$replace#g" $filename 
    fi
    if [ ! "$filename" == "$INLIST" ]; then 
        change $param $newval "$INLIST"
    fi 
} 

# Y = Y_0    + dY/dZ * Z_0 
# Y = 0.2463 + 2     * Z_0 

mkdir results 
for Z in 0.0001 0.001 0.01 0.02; do
    for M in 0.8 1 1.2 1.5 2.0 2.5 3; do
        Y=$(echo "0.2463 + 2 * $Z" | bc -l)
        echo $M, $Z, $Y
        
        rm -rf LOGS
        
        change initial_y $Y
        change initial_z $Z
        change Zbase     $Z
        change initial_mass $M
        
        ./rn
        
        cp LOGS/history results/"$M_$Z.dat"
    done
done 
