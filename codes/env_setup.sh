#!/bin/bash
# Set up work environment for registration
#############################################################

user=basename $HOME #account username

# Move registration program from $HOME to project folder
mv registration.py projects/def-mlabrie/$user

# Create the Input and Output folders
mkdir scratch/Registration; mkdir scratch/Registration/Input; mkdir scratch/Registration/Output

# Go inside the HZ folder
cd HZ

# Charge the CV module
module load gcc opencv/4.6 python/3.9

# Create a new virtual environment and activate it
virtualenv --clear ~/IMREG && source ~/IMREG/bin/activate

# Install pip and cycIFAAP
pip install --upgrade pip
pip install cycIFAAP
pip install FiReTiTiPyLib
pip install -r ./requirement.txt --no-index --find-links $HOME/HZ

# Test the OpenCV import to make sure you do not get the error "ImportError: libpng15.so.15: cannot open shared object file: No such file or directory"
python -c "import cv2"

# Confirm that the import is done correctly - should not display anything in that case
python -c "import cycIFAAP; from FiReTiTiPyLib.CyclicIF import CyclicIF_Registration"

# Go back to the home adress
cd

# Deactivate the environment
deactivate

# Create the folders to store the input and output files
mkdir scratch/Input; mkdir scratch/Output
