#!/bin/bash
#SBATCH --time=08:00:15
#SBATCH --account=def-mlabrie
#SBATCH --mem-per-cpu=122G
#SBATCH --cpus-per-task=12


## charge modules
module load gcc opencv/4.6 python/3.9

##Activate work environment
source ~/IMREG/bin/activate


python registration.py $HOME/scratch/Registration/Input/FILENAME $HOME/scratch/Registration/Output/FILENAME	#1st parameter=input address; 2nd parameter=output address
sleep 15

echo -e '\nRegistration performed successfully'


#deactivate work environment
deactivate
