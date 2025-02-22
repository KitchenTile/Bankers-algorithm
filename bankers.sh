#!/bin/bash

# INITIALIZE EMPTY ARRAYS & HELPER FUNCTIONS

# these arrays will be filled by user
available=()
maxNeed=()
allocated=()

# this array will be calculated with maxNeed - allocated
need=()

# since we use the index calculation often we write it as a function
index() {
    echo $(( $1 * resources + $2 ))
}

# since we're displaying matrices with the same code three times, put it in a function
displayMatrix() {
    local array=$1;
    
    for ((i = 0; i < processes; i++)); do
        for ((j = 0; j < resources; j++)); do
            local idx=$(index $i $j)
            # need eval to prevent using indirect expansion?
            eval "echo -n \"\${$array[$idx]} \""
        done
        echo
    done
}

# basic input validation 
validateInput() {
    if [ -z $1 ]; then
        echo "Inputs can't be empty"
        exit 0
    fi

    # regex from medium article
    if ! [[ $1 =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
        echo "Inputs must be numbers!"
        exit 0
    fi
}

#SAFE SEQUENCE FINIDING FUNCTION

# to make the program dynamic, it's best to make the safe sequence check its own function

safeSequenceCheck() {

    # work NEEDS to be in the safe seq function function, if we make it a global variable, the values would get updated over the new itterations 
    #work initiated as just the available resources -- needs to be declared with @ so it does not get counted as single string
    work=("${available[@]}")

    # this array keep track of executable processes so we don't unnecesarily go through 
    # all processes when checking for a safe sequence -- this array needs to be here, so it was moved.
    finishedProcesses=()

    # this array will hold the safe sequence in order 
    safeSequence=()

    # initialized with 0s as default so every process gets checked
    for ((i = 0; i < processes; i++)); do
        finishedProcesses[i]=0; 
    done

    #while the safe sequence is less than the anount of processes enter the loop
    while [[ ${#safeSequence[@]} -lt processes ]]; do
        # and immediately set it as false so if there are no remaining possible processes to execute, we exit the loop
        processFlag=false

        for ((p = 0; p < processes; p++)); do
            # if the current process we are checking is not already marked as executable, check it
            if ((finishedProcesses[p] == 0)); then
            echo "checking process number: $(($p+1))"
                # compare matrices by index
                for ((r = 0; r < resources; r++)); do
                    idx=$(index $p $r)
                    # if the meed is larger than the work the process does not pass the ceck
                    if ((need[$idx] > work[r])); then
                        echo "current available resources are not enough to succesfully go through process number: $(($p+1))"
                        # Exit loop
                        break 
                    fi
                done

                # If we finished all resource checks without breaking, process can execute
                if ((r == resources)); then
                    echo "Process $(($p+1)) passed the resource check,"
                    # go through its resources
                    for ((r = 0; r < resources; r++)); do
                        idx=$(index $p $r)
                        echo "adding processes allocated resources to current work -> resource number $(($r+1)) (${work[r]} + ${allocated[$idx]})"
                        # add them to our work
                        work[r]=$((work[r] + allocated[$idx]))
                    done

                    echo "Process $(($p+1)) executed, new available resources: ${work[*]}"
                    # mark the process as able to be allocated in the array so we don't go through it again
                    finishedProcesses[p]=1
                    # add the current process to the safe sequence array
                    safeSequence+=("$p")
                    # and set the process flag back to true so the loop continues
                    processFlag=true
                fi
            fi
        done

        # if the process flag is falsly, then exit the while loop
        if ! $processFlag; then
        break;
        fi 
    done


    # if the safe sequence has the same amount of elements as the processes,
    # all processes can be executed safely --> we are in a safe state!
    if [[ ${#safeSequence[@]} -eq processes ]]; then
        echo "Safe sequence found: < ${safeSequence[*]} >"
        # bash can only return numeric values, so we return the length of the safe sequence to trigger function rerun
        return ${#safeSequence[@]}
    else
        #otherwise, system is not in safe state :(
        echo "System not in safe state! No safe sequence is available."
    fi
}

# ON PROGRAM RUN

# USER INPUTS (proc, res, need, available)

# number of processes and resources
read -p "Enter number of resources: " resources
validateInput $resources

read -p "Enter number of processes: " processes
validateInput $processes


# available resources
echo "Enter available resources (separated by spaces):"
read -ra available
validateInput $available

# max need matrix
echo "Enter the maximum resource need matrix (row):"
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        idx=$(index $i $j)
        read -p "Max Need [$i,$j]: " value
        validateInput $value
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
displayMatrix maxNeed

echo -e "\nAllocated resources matrix: "
displayMatrix allocated

echo -e "\nCurrent need matrix (Max need - allocated): "
displayMatrix need



# INITIAL SAFE SEQUENCE CHECK

safeSequenceCheck

# check the safe seq check return for function rerun
while [[ $? -eq ${#safeSequence[@]} ]]; do
    read -p "Would you like to add a new process? (y/n): " newProcess
    if [[ "$newProcess" != "y" ]]; then
        break
    fi

    # Add an extra process
    ((processes = processes + 1))  
    echo "Enter max need for new process:"
    for ((r = 0; r < resources; r++)); do
        # use process-1 because the new process is fixed 
        idx=$(index $((processes-1)) $r)
        read -p "Max Need [$(($processes-1)),$r]: " value
        validateInput $value
        # add new values to all matrices
        maxNeed[$idx]=$value
        # add 0 to allocated since this is a new process?
        allocated[$idx]=0
        # since allocated is 0 then the need will be max need
        need[$idx]=$value
    done

    # new matrices display and run the safe seq func
    echo -e "\n -- New Matrices --"
    echo "Max Need Matrix:"
    displayMatrix maxNeed
    echo  " Allocated Resources Matrix:"
    displayMatrix allocated
    echo  " Current Need Matrix:"
    displayMatrix need

    safeSequenceCheck
done
