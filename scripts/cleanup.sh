#Add a "cleanup.sh" script that removes created files
#It should take zero or more of the following arguments: "data", "res", "out", "log". 
#If no arguments are passed then it should remove everything.

dirs=(data res out log)

if [ $# == 0 ]
then
    for dir in ${dirs[@]}
    do
        find "$dir" -mindepth 1 -delete
        echo "$dir was emptied"
    done
else
    for dir in $@
    do
        if [[ " ${dirs[@]} " =~ "$dir" ]]
        then
            if [ -d "$dir" ]
            then
                find "$dir" -mindepth 1 -delete
                echo "$dir was emptied" 
            fi
        else
            echo "$dir does not exist"
        fi
    done
fi