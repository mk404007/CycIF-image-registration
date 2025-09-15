#!/usr/bin/env python3

import os
import sys


ls_test= 0  # Count for the number of files changed

for s_file in os.listdir(sys.argv[1]): # Set working directory as input directory
    if s_file[-4:] == '.tif': # Rename only TIF files (added to avoid hidden files)
        if 'Scene-00' not in s_file: # If FALSE, the file has been correctly annotated and does not need further probing
            if 'Scene-' in s_file: # If TRUE, file has a scene but not correctly annotated
                s_file_new = s_file.replace("_Scene-", "_Scene-00")

            else: # File does not contain scenes, and thus needs to be annotated
                s_file_new = s_file[:-11] + '_Scene-001' + s_file[-11:] # Place substring 'Scene-001'' at a specific position in string
                
            os.rename(sys.argv[1] + '/' + s_file, sys.argv[1] + '/' + s_file_new) #rename file
            ls_test+= 1

print(f'Total number of files changed is {ls_test}')
