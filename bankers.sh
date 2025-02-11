#!/bin/bash

# INITIALIZE EMPTY ARRAYS & INDEX CALC

#these arrays will be filled by user
available=()
max_need=()
allocated=()

#this array will be calculated with max_need - allocated
need=()

#this array will be filled after each process runs succesfully
safe_sequence=()

# since I use the index calculation often I wrote it as a function
index() {
    echo $(( $1 * resources + $2 ))
}

# display_matrix() {
#     local array=$1;

#     for ((i = 0; i < processes; i++)); do
#         for ((j = 0; j < resources; j++)); do
#             local idx=$(index $i $j)
#             echo -n "${array[$idx]} "
#         done
#         echo
#     done
# }

# USER INPUTS (proc, res, available)

# number of processes and resources
read -p "Enter number of resources: " resources
read -p "Enter number of processes: " processes


# available resources
echo "Enter available resources (space-separated):"
read -ra available

# max need matrix
echo "Enter the maximum resource need matrix (row by row):"
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        idx=$(index $i $j)
        read -p "Max Need [$i,$j]: " value
         max_need[$idx]=$value
    done
done


# allocated resources matrix
echo "Enter the allocated resources matrix (row by row):"
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        idx=$(index $i $j)
        read -p "Allocated [$i,$j]: " value
        allocated[$idx]=$value

        # Compute the Need matrix dynamically
        need[$idx]=$(( max_need[$idx] - allocated[$idx] ))
    done
done

# MATRICES DISPLAY

echo -e "\nMax need matrix: "
# display_matrix max_need
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        echo -n "${max_need[$(index $i $j)]} "
    done
    echo
done

echo -e "\nAllocated resources matrix: "
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        echo -n "${allocated[$(index $i $j)]} "
    done
    echo
done

echo -e "\nCurrent need matrix (Max need - allocated): "
for ((i = 0; i < processes; i++)); do
    for ((j = 0; j < resources; j++)); do
        echo -n "${need[$(index $i $j)]} "
    done
    echo
done

#SAFE SEQUENCE FINIDING SECTION

# keep track of processes so we don't go into an infinite loop
finished_processes=()

# work initiated as just the available resources -- needs to be declared with @ so it does not get counted as single string
work=("${available[@]}")

finish=()                  # Finish array tracks completed processes
for ((i = 0; i < processes; i++)); do
    finish[i]=0; 
done

found_process=true

while $found_process; do
    found_process=false
    for ((p = 0; p < processes; p++)); do
        if ((finish[p] == 0)); then
            echo "checking process number: $(($p+1))"
            can_allocate=true
            #go through resources and compare matrices
            for ((r = 0; r < resources; r++)); do
                idx=$(index $p $r)
                if ((need[$idx] > work[r])); then
                    #if the need is larger than the available resource, flag it as unable to be allocated to current work and move to next process
                    can_allocate=false
                    echo "current available resources are not enough to succesfully go through process number: $(($p+1))"
                    break
                fi
            done

            if $can_allocate; then
                echo "Process $(($p+1)) passed the resource check,"
                #go through the resources of the process that was succesfully assessed
                for ((r = 0; r < resources; r++)); do
                    idx=$(index $p $r)
                    echo "adding processes allocated resources to current work -> resource number $(($r+1)) (${work[r]} + ${allocated[$idx]})"
                    # and add them to our work
                    work[r]=$((work[r] + allocated[$idx]))
                done
                echo "new available resources (work)"
                echo "${work[@]}"
                finish[p]=1
                safe_sequence+=("$p")
                found_process=true
            fi
        fi
    done
done




# Print results
if [[ ${#safe_sequence[@]} -eq processes ]]; then
    echo "System is in a SAFE state!"
    echo "Safe sequence: ${safe_sequence[*]}"
else
    echo "System is in an UNSAFE state! No safe sequence found."
fi