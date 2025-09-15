#!/bin/bash
# Registration analysis part 2/2 - Retrieving the aligned images
#############################################################
source ./functions.sh

main ()
{
    askServerConnexion "USERNAME"
    retrieveFolder "USERNAME" "OUTFOLD" "DIR"
    convertTIF "OUTFOLD"
    echo "Registration done!"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
    main "$@"
fi
