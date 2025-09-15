#!/bin/bash
## Registration analysis part 1/2
########################################################################
source ./functions.sh

main ()
{
    jobRequestCleanup
    
    CCDB_username usernm
    registration1st "$usernm"
    printf "\nPlease select the input directory where the registration images are stored\n"
    selectFolder in_folder
    folderCheck "$in_folder"
    printf "\nPlease select the directory where you want to store the output folder\n"
    selectFolder out_folder

    # Verify if the last folder has spaces in its names, and adapt in consequence
    spaceVerif "$in_folder" rep
    if [[ $rep == 0 ]]
    then
        new_folder=$(modifyLastFolder "$in_folder")
        in_folder="$new_folder"
    fi

    renaming "$in_folder"
    prepAndUpload "$in_folder" "$usernm" "$out_folder"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    main "$@"
fi
