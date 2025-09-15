#!/bin/bash
## Functions called for the registration processing
########################################################################


jobRequestCleanup () # Erase any job request file generated from the template that may be present (from a previous analysis) in the working directory
{
    for f in *
    do
        if [[ $f == job_*.sh ]] && [[ "$f" != "job_SAMPLE.sh" ]]
        then
            rm "$f"
        fi
    done
}


yesNo () # Ask user if they confirm their answer or not
{
    local __ans=$1
    
    loop=true
    while "$loop"
    do
        echo "(y/n)"
        read yn
        low_yn=$(echo "$yn" | tr '[:upper:]' '[:lower:]') # Set variable string to lowercase
        case $low_yn in
            y | yes)
                loop=false
                local ans=0
                eval $__ans="'$ans'"
                ;;
            n | no)
                loop=false
                local ans=1
                eval $__ans="'$ans'"
                ;;
            *)
                echo Answer not understood. Please only answer by yes or no.
                ;;
        esac
    done
}


CCDB_username () # Ask user for username from their Calcul Canada account
{
    local __ans=$1
    
    no_name=true
    while "$no_name"
    do
        echo Please provide your CCDB account login:
        read username
        
        echo Do you confirm your answer?
        yesNo yN
        case $yN in # Depending on confirmation response from user, retry asking for username or proceed
            0)
                no_name=false
                eval $__ans="'$username'"
                ;;
            1)
                echo "Then let us ask again."
                ;;
        esac
        echo
    done
}


selectFolder () # Let user select the folder where the images to analyse are stored
{
    local __ans=$1
    
    no_images=true
    while "$no_images"
    do
        sleep 1
        input_folder=$(python3 select_dir.py) # Python program which lets user select a directory through a Tkinter dialog and returns its full path
        echo
        if [ -z "${input_folder}" ] # If the user cancels the directory selection, the program will stop
        then
            echo No directory selected, now exiting program.
            exit 0
        fi
        echo Selected input adress is: $input_folder
        
        echo Do you confirm your answer?
        yesNo Yn
        case $Yn in # Depending on confirmation response from user, retry asking for username or proceed
        0)
            no_images=false
            eval $__ans="'$input_folder'"
            ;;
        1)
            echo
            ;;
        esac
        echo
    done
}


folderCheck () # Check if input folder contains a minimum of 2 TIF images for analysis
{
    if [ "$(ls -A "$1")" ] # Check if folder is empty
    then
        countTIF=0 # Count number of TIF files in folder
        
        for f in "$1"/* # Check each file's extension, whether it it a TIF file or not
        do
            if [[ $f == *.tif ]]
            then
                (( countTIF++ ))
            else
                printf "Folder contains elements other than TIF images (files and/or directories).\nPlease choose a folder containing only TIF images, and a minimum of 2.\n"
                exit 0
            fi
        done

        if [[ $countTIF -lt 2 ]] # Check if folder contains less than 2 TIF files
        then
            echo "Folder contains only 1 TIF image. It must contain at least 2 TIF images to perform a valid registration program."
            exit 0
        fi
    else
        echo Folder empty. Unable to proceed.
        exit 0
    fi
}


registration1st () # Ask user if it is their first time running a registration program
{
    echo "Is it your first time performing a registration analysis on Calcul Canada?"
    yesNo yNo
    if [ $yNo = 0 ]
    then # 1st registration = environment setup necessary on the online server, send setup program
        scp env_setup.sh $1@cedar.calculcanada.ca:/home/$1/ || loginError "$1" # Upload environment setup program to the CCDB server
        scp -r HZ $1@cedar.calculcanada.ca:/home/$1/ || loginError "$1" # Upload needed packages not present on the CCDB servers
        echo "You will now be connected to the CCDB server to set up the working environment."
        ssh -Y $1@cedar.calculcanada.ca # Connect to the server to run env_setup.sh before pursuing
    fi
}


loginError () # Launch when there is an error in CCDB login (linked either to username or password)
{
    echo
    printf "It seems there is an error in CCDB login !\nThis could be due to 5 causes:\n1)The username '%s' does not exist in the CCDB servers, either because you\n\t- wrote it wrongly or\n\t- your account has not been validated on Calcul Canada yet.\n2)Your password may be incorrect.\n3)There is a problem with the CCDB servers, which might be shown in the error message above this one; in that case, please try again later.\n4)The paths set on the CCDB server may have been altered or not exist; please check your server before retrying.\n5)You manually terminated the program yourself.\nIf none of the above cases match your situation, please check the code.\n" "$1"
    
    exit 0
}


spacelessName () # Replace spaces by '_'
{
    new_name="${1// /_}" # Replace all spaces by underscores in folder name
    dirpath=${2//$1/} # In path where the input directory is, remove the last folder (the one with spaces, $1)
    newdir=$dirpath$new_name
    echo $newdir
}


spaceVerif () # Verify if the input directory has spaces in its name - if it does, ask user before replacing spaces with '_'
{
    local __aNS=$2
        
    dname=$(getDirName "$1") # Get the name of the input directory
    
    case "$dname" in
        *\ * ) # The directory has spaces in its name
            echo "WARNING: Directory name contains spaces. This will generate problems during file export."
            echo "To continue the analysis, we need to rename the folder by replacing spaces with '_'. Do you accept the changes?"
            yesNo yesN
            case $yesN in
                0)
                    echo Now changing the filename...
                    
                    local aNS=0
                    eval $__aNS="'$aNS'"
                    ;;
                1)
                    echo You have chosen not to change the name. Cannot proceed with analysis.
                    echo Now exiting...
                    
                    exit 0
                    ;;
            esac
            ;;
        *) # The directory has no spaces in its name
            echo Directory name does not contain spaces, proceed with analysis...
            
            local ans=1
            eval $__aNS="'$aNS'"
            ;;
    esac
}


switchUnderscoresDots () # Replace underscores with dots for the Ab markers section
{
    for f in *.tif
    do
        f=${f%.tif}
        nbDots=$(echo "$f" | grep -o "\." | wc -l)
        if (( $nbDots == 0 )) # There should be no dots in the filename if the markers are separated by underscores
        then
            for i in {1..3} # Perform this thrice (for each '_' to replace)
            do
                mv $f $(echo $f | sed "s/_/./2")
            done
        elif (( $nbDots != 3 )) # If there are 1, 2 or more than 3 dots, there must be a problem with the filename
        then
            printf "WARNING: The filename '%s' is erroneous.\nPlease check where the dots are and correct accordingly.\nNow exiting...\n" "$f"
            exit 0
        fi
    done
}


changeChannelNumbers () # Change the channels numbers if they are incorrect
{
    for f in *.tif
    do
	    if [[ "$f" == *"_c0_ORG"* ]] # Sometimes the Image Export may start enumerating the channels from 0, which does not fit with the registration criteria
	    then
		    rename 's/_c4_/_c5_/g' *.tif
		    rename 's/_c3_/_c4_/g' *.tif
		    rename 's/_c2_/_c3_/g' *.tif
		    rename 's/_c1_/_c2_/g' *.tif
		    rename 's/_c0_/_c1_/g' *.tif
	    fi
    done
}


renaming () # Rename files to match the registration nomenclature
{
    export IN_PATH="$1" # To access the folder directly to rename the files - to cover problems caused by paths with spaces
    
    ./rename_move.py "$1" # Check if files have correctly annotated scenes and correct if not
    
    work_dir=$(pwd) # To go back to our main directory after the operation

    cd "$IN_PATH"

    switchUnderscoresDots # Replace '_' with '.' when separating the Ab markers (if necessary)
    rename -f 's/-Image Export[0-9]//' *.tif
    rename 's/_b[0-5]s[0-5]c/_c/g' *.tif
    rename 's/x[0-5]-[0-9]{1,5}[a-z][0-9]-[0-9]{1,5}_ORG/_ORG/g' *.tif
    changeChannelNumbers # Check and replace wrong channel enumeration

    # If you have performed stitching, the following commands are also necessary
    rename 's/-Stitching-[0-9][0-9]//' *.tif
    rename 's/-ScanRegion-[0-9]//' *.tif
    cd $work_dir
}


job_setup () # Set up job sample files
{
    cp job_SAMPLE.sh "job_$1.sh"
    sed -i -e "s/FILENAME/$2/g" "job_$1.sh" # Replace all instances of 'FILENAME' in the new job request to the new set name
    sed -i -e "s/time=08/time=$4/g" "job_$1.sh" # Rewrite the time parameter according to the value indicated by the user
    
    rm *.sh-e # Problem lies with MacOS specificity; generates "sed error" if -e not added, but also creates file with 'sh-e' extension. Solution found online by adding '' argument to -i BUT not certain if will work on Linux - thus chose to leave it be for the moment. Need to check on Linux later...
    
    scp "job_$1.sh" $3@cedar.calculcanada.ca:/home/$3/projects/def-mlabrie/$3 || loginError "$1" # Upload job request on the CCDB server
}


askTime () # Ask user the estimated time for registration analysis for their images (default being 8 hours)
{
    local __ans=$1
    
    echo; echo Current hour set for registration is 8. Change hour or not?
    yesNo y_n
    case $y_n in
        0)
            tImE=true # To set a while loop to ask the user for a correct time value
            
            while "$tImE"
            do
                echo; echo What will the new hour be?
                read hour
                
                if [[ $hour =~ ^[0-9]+$ ]] # Check if value is a number
                then
                    if (( $hour < 10 )) # Check if value < 10. If it is, add a 0 in front (for job request rewriting)
                    then
                        hour="0${hour}"
                        
                        local ans="$hour"
                        eval $__ans="'$ans'"
                        tImE=false
                    else
                        if (( $hour > 100 )) # Check if value is higher than the limit accepted (100H)
                        then
                            echo Value too high. Please enter a number between 0 and 100.
                        else
                            local ans="$hour"
                            eval $__ans="'$ans'"
                            tImE=false
                        fi
                    fi
                else
                    echo Invalid entry. Please enter a natural number.
                fi
            done
            ;;
        1)
            local ans="08"
            eval $__ans="'$ans'"
            ;;
    esac
}


getFirstFile () # Obtain the name of the first file in a given directory
{
    for path
    do
        var=( $(ls "$path") ) # Stores the `ls` list of the content of the input directory into the variable var
        first="${var[0]}" # 1st element of the `ls` list
        echo $first
    done
}


getDirName () # Obtain the name of the input directory
{
    printf "%s\n" "${1##*/}"
}


modifyLastFolder ()
{
    dirN=$(getDirName "$1") # Get the name of the input directory
    new_path=$(spacelessName "$dirN" "$1") # Gives new input path without spaces in the last folder name
    mv "$1" "$new_path"
    
    echo $new_path
}


askServerConnexion () # Before uploading/downloading the files to/from the CCDB server, ask user if they want to connect to it (to set up environments, paths, etc.)
{
    echo; echo "Before loading the files, do you want to connect to the server to set up other parameters?"
    yesNo yes_n
    if (( $yes_n == 0 ))
    then
        ssh -Y $1@cedar.calculcanada.ca || loginError "$1"
    fi
}


prepAndUpload () # Setup job request
{
    export IN_PATH="$1"
    
    # Retrieve the sample name in the file name
    filename=$(getFirstFile "$1")
    sample=$(echo "$filename" | awk -F '_' '{print $3}') # awk parses the filename using '_', and prints the 3rd field corresponding to the sample name
    
    dirn=$(getDirName "$1") # Get the name of the input directory
    mkdir $dirn # Create a (temporary) folder with the same name as the input folder - corresponds to the output directory sent to the CCDB server
    
    askTime hr # Set the registration time
    
    job_setup "$sample" "$dirn" "$2" "$hr" # Create and upload a new job request from the job_SAMPLE template using the sample name, the input directory name and the registration time
    write_reg2 "$sample" "$2" "$3" "$dirn"
    
    askServerConnexion "$2"
    
    # Upload output and input image folders - may take a while, depending on the size of the images
    scp -r "$dirn" $2@cedar.calculcanada.ca:/home/$2/scratch/Registration/Output/ || loginError "$2"
    echo; echo Now uploading input folder:
    scp -r "$IN_PATH" $2@cedar.calculcanada.ca:/home/$2/scratch/Registration/Input/ || loginError "$2"
    #TO SEE: How to add option '-c blowfish' in the command to increase speed along with '-r' option (problems so far...)
    
    rm -r $dirn # Remove the output directory - after sending it, has now become useless in the main folder
    
    echo; echo "Uploading successfull. Do you want to connect to the server now?" # Following uploading, ask user if thay want to connect to the server or exit directly
    yesNo yn
    case $yn in
        0)
            ssh -Y $2@cedar.calculcanada.ca
            
            printf "If you have launched the jobs in your server, then the registration is in progress.\nCome back after %s hour(s) to retrieve the processed images!\n" "$hr"
            ;;
        1)
            echo You chose not to connect to the server. Now exiting...
            ;;
    esac
}


retrieveFolder () # Retrieve the output folder depending on user choice
{
    export OUT_PATH="$2"
    
    echo Proceed with downloading the folder from the CCDB server ?
    yesNo yes_no
    case $yes_no in
        0)
            echo
            scp -r $1@cedar.calculcanada.ca:/home/$1/scratch/Registration/Output/$3 "$OUT_PATH" || loginError "$1" # Retrieve output folders in CCDB server
            ;;
        1)
            echo You chose not to retrieve the folder. Now exiting...
            exit 0
            ;;
    esac
}


askConvert () # Ask user if they want to convert the images directly from the bash interface (not recommended for file above 2 GB)
{
    printf "Images retrieved from server.\nDo you want to convert the PNG images to TIF format?\n"
    yesNo y_no
    case $y_no in
        0)
            echo Now performing conversion...
            convertTIF "$1" "$2" # The images will be converted to TIF files
            ;;
        1)
            echo You chose not to convert the PNG images. # The images will stay as PNG files
            ;;
    esac
}

convertTIF () # Convert the PNG files to TIF images
{
    echo Now performing conversion of PNG files to TIFF format...
    export OUT_PATH="$1" # To access the folder directly to rename the files - to cover problems caused by paths with spaces
    
    cd "$1"
    for f in *.png; do convert "$f" "${f%%.%%.*}.tif"; done
    mkdir PNG # To keep the PNG files as backup
    mv *.png PNG/
    for f in *.tif; do mv "$f" "${f/.png/}"; done
}


retrieveDirName () # Reads the content of the job request to find the output folder adress and retrieve the name
{
    local __ans=$1
    
    f=$(find . -type f \( -name 'job_*.sh' \) -not -name "job_SAMPLE.sh") # Retrieve the job request previously created (must have 'job_*.sh' but not 'job_SAMPLE.sh' in its name) - There should be only ONE file if the registration was processed properly
    content=`cat "$f"` # Retrieve file content
    
    # Select desired substring (output folder name) through multiple steps -> Possibility to shorten this through a sed command, but generates problems until now (to see...)
    part1=${content%%#1st*} # Remove text after the "#1st" pattern
    part2=${part1#*Output/} # Remove text before the "Output/" pattern
    dir_n=${part2//[[:blank:]]/} # Remove space before the string

    local ans="$dir_n"
    eval $__ans="'$ans'"
}

write_reg2 () # Writes the 2nd part of the registration program in a SH file
{
    cp registration2.sh "registration2-$1.sh" # Use the registration2.sh file as a template
    # Perform the different replacements below
    sed -i -e "s/USERNAME/$2/g" "registration2-$1.sh" # Username
    sed -i -e "s/OUTFOLD/$(basename "$3")/g" "registration2-$1.sh" # Output folder where the aligned images will be downloaded
    sed -i -e "s/DIR/$4/g" "registration2-$1.sh" # Input folder where the aligned images are stored
    
    rm *.sh-e # Problem lies with MacOS specificity; generates "sed error" if -e not added, but also creates file with 'sh-e' extension. Solution found online by adding '' argument to -i BUT not certain if will work on Linux - thus chose to leave it be for the moment. Need to check on Linux later...
}
