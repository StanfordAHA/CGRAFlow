#!/bin/bash
REPOS=(halide coreir mapper cgra pnr smt)  
DIR="$(dirname $0)/../"

if [ ! -d $DIR ] ; then
    echo "Could not locate CGRAFlow directory"
    exit 1
else
    cd $DIR
fi

function usage() {
    echo "(<${REPOS[*]}> <BRANCH_NAME>)+"
}

function elem_in() {
    local e
    elem="${1}"
    shift
    arr=("${@}")

    for e in ${arr[*]}; do 
        if [[ "$e" == "$elem" ]]; then
            return 0
        fi
    done
    return 1
}



if [[ $# -eq 0 ]] || [[ $(( $# % 2 )) -ne 0 ]]; then
    usage
	exit 1
fi

argv=( $@ )

# for i from 0 to n-1
for i in $(seq 0 $(( $# -1 )) ); do
    # if i % 2 == 0 
    if [[ $(( $i % 2 )) -eq 0 ]] ; then
        # check if subproject is in REPOS
        if ! elem_in ${argv[$i]} ${REPOS[*]} ; then
            echo bad subproject ${argv[$i]} 
            usage
            exit 1
        fi
    fi
done

s=""
# for i from 0 to n-1
for i in $(seq 0 $(( $# -1 )) ); do
    if [ -n "$s" ]; then
        s+="_"
    fi
    s+="${argv[$i]}"
done

git branch -d "$s"
git push origin --delete "$s"
