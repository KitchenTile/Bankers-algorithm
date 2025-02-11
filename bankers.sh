#!/bin/bash

# INITIALIZE EMPTY ARRAYS & INDEX CALC

# these arrays will be filled by user
available=()
maxNeed=()
allocated=()

# this array will be calculated with maxNeed - allocated
need=()

# this array will be filled after each process runs succesfully
safeSequence=()

# this array keep track of executable processes so we don't unnecesarily go through 
# all processes when checking for a safe sequence
finishedProcesses=()

# since we use the index calculation often we write it as a function
index() {
    echo $(( $1 * resources + $2 ))
}

# since we're displaying matrices with the same code three times, put it in a function
display_matrix() {
    local array=$1;
    
    for ((i = 0; i < processes; i++)); do
        for ((j = 0; j < resources; j++)); do
            local idx=$(index $i $j)
            eval "echo -n \"\${$array[$idx]} \""
        done
        echo
    done
}

# USER INPUTS (proc, res, available)

# number of processes and resources
read -p "Enter number of resources: " resources
read -p "Enter number of processes: " processes


# available resources
echo "Enter available resources (separated by spaces):"
read -ra available

# max need matrix
echo "Enter the maximum resource need matrix (row):"
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        idx=$(index $i $j)
        read -p "Max Need [$i,$j]: " value
         maxNeed[$idx]=$value
    done
done


# allocated resources matrix
echo "Enter the allocated resources matrix (row):"
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        idx=$(index $i $j)
        read -p "Allocated [$i,$j]: " value
        allocated[$idx]=$value
        need[$idx]=$(( maxNeed[$idx] - allocated[$idx] ))
    done
done

# MATRICES DISPLAY

echo -e "\nMax need matrix: "
display_matrix maxNeed
# for ((i = 0; i < processes; i++)); do
#     for ((j = 0; j < resources; j++)); do
#         echo -n "${maxNeed[$(index $i $j)]} "
#     done
#     echo
# done

echo -e "\nAllocated resources matrix: "
display_matrix allocated
# for ((i = 0; i < processes; i++)); do
#     for ((j = 0; j < resources; j++)); do
#         echo -n "${allocated[$(index $i $j)]} "
#     done
#     echo
# done

echo -e "\nCurrent need matrix (Max need - allocated): "
display_matrix need
# for ((i = 0; i < processes; i++)); do
#     for ((j = 0; j < resources; j++)); do
#         echo -n "${need[$(index $i $j)]} "
#     done
#     echo
# done

#SAFE SEQUENCE FINIDING SECTION

# work initiated as just the available resources -- needs to be declared with @ so it does not get counted as single string
work=("${available[@]}")

# initialized with 0s as default so every process gets checked
for ((i = 0; i < processes; i++)); do
    finishedProcesses[i]=0; 
done

# implementing two flags, process flag keeps track of potential processes to try to execute
processFlag=true

# we start it as true to start the loop
while $processFlag; do
    # and immediately set it as false so if there are no remaining possible processes to execute, we exit the loop
    processFlag=false
    for ((p = 0; p < processes; p++)); do
        # if the current process we are checking is not already marked as executable
        if ((finishedProcesses[p] == 0)); then
            echo "checking process number: $(($p+1))"
            # allocation flag is truthy by default when we start to check a process, 
            # it checks processes that can be executed and it's resources allocated
            allocationFlag=true
            # here we go through resources and compare matrices
            for ((r = 0; r < resources; r++)); do
                idx=$(index $p $r)
                if ((need[$idx] > work[r])); then
                    # if the need is larger than the available resource, flag it as unable to be allocated to current work and move to next process
                    allocationFlag=false
                    echo "current available resources are not enough to succesfully go through process number: $(($p+1))"
                    break
                fi
            done

            # if the process can be executed
            if $allocationFlag; then
                echo "Process $(($p+1)) passed the resource check,"
                # go through its resources
                for ((r = 0; r < resources; r++)); do
                    idx=$(index $p $r)
                    echo "adding processes allocated resources to current work -> resource number $(($r+1)) (${work[r]} + ${allocated[$idx]})"
                    # add them to our work
                    work[r]=$((work[r] + allocated[$idx]))
                done
                echo "new available resources (work)"
                echo "${work[@]}"
                # mark the process as able to be allocated in the array so we don't go through it again
                finishedProcesses[p]=1
                # add the current process to the safe sequence array
                safeSequence+=("$p")
                # and set the process flag back to true so the loop continues
                processFlag=true
            fi
        fi
    done
done




# if the safe sequence has the same amount of elements as the processes,
# all processes can be executed safely --> we are in a safe state!
if [[ ${#safeSequence[@]} -eq processes ]]; then
    echo "Safe sequence found: ${safeSequence[*]}"
else
    #otherwise, system is not in safe state :(
    echo "System not in safe state! No safe sequence is available."
fi