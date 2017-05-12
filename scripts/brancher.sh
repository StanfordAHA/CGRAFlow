#!/bin/bash
REPOS=(halide coreir mapper cgra pnr smt)  
TRAVIS="$(dirname $0)/../.travis.yml"

if [ ! -f $TRAVIS ]; then
    echo "Could not locate .travis.yml"
    exit 1
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

current_branch=$(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
git checkout -b "$s"

# for i from 0 to n-1
for i in $(seq 0 $(( $# -1 )) ); do
    # if i % 2 == 0 
    if [[ $(( $i % 2 )) -eq 0 ]] ; then
        sp="${argv[$i]}"
    else
        b="${argv[$i]}"
        echo $sp $b
        sed -r "s/(${sp}_branch)=.+/\1=\"${b}\"/" -i $TRAVIS
    fi
done

git add $TRAVIS
git commit -m "Auto generated branch"
git push --set-upstream origin "$s"
git checkout $current_branch
