# Image Registration

Instructions to perform registration on Calcul Canada servers. Compatible with MacOS and Linux.

## Installation

If you do not already have an account at Calcul Canada, [create one](https://ccdb.computecanada.ca/security/login).
If/Once you do, you can connect on the server by typing in a terminal window the following command:

```bash
ssh -Y username@machine_name
```

With `username@machine_name` composed of different elements:
 
* `username` is the default login for your account, with a format similar to `jsmith`
* `machine_name` corresponding to the cluster we will use for the analysis. In our case it will always be __Cedar__, thus `cedar.calculcanada.ca`
* Once you type `Enter`, the password requested will be the one you use to connect to the CCDB database. In case you do not want to have to type your password each time you have to connect or load files to and from the server, you can configure passwordless login on your own computer by following the steps on [this site](https://help.dreamhost.com/hc/en-us/articles/216499537-How-to-configure-passwordless-login-in-Mac-OS-X-and-Linux). However, if you only need to set this up on the lab's Mac workstation, just type the following command by replacing `username` with your login:
```bash
cat ~/.ssh/id_rsa.pub | ssh username@cedar.calculcanada.ca "mkdir ~/.ssh; cat >> ~/.ssh/authorized_keys"
```
---

Once you have verified you can connect to your CCDB account, you can set up the registration analysis:
* Download the registration folder from the Sharepoint (If it has not been done already).
* Make sure the images you want to analyze are all gathered in a single directory, which should only contain them. Each image should be an uncompressing TIF representing a single channel/cycle, whose naming convention should be : 
> * Starting with round number followed by an underscore (ex: 'R0_')
> * Followed by all the markers (except the Dapi) used in the current round, with names separated by *DOTS* (ex: 'R1_aSMA.CD44.CK5.PARP_')
> * Immediatly followed by the sample name set between two underscores (ex: 'R1_aSMA.CD44.CK5.PARP_Tonsil_')
> * At the end, '_c*_ORG.tif', with the `*` corresponding to the channel number, ranging from 1 to 5.

Such naming convention should be already applied by default on the images after their *Image Export* using the **ZEN** tool, so normally you should not need to change anything - but we recommend checking before each registration.
* On `MacOS` specifically, some of the commands used in this registration program are not installed by default; they are already set up on the lab's workstation, but if you intend to use it on a personal computer, you must install the following modules first:
> * If you do not already have it, download `Xcode` from the [App Store](https://apps.apple.com/us/app/xcode/id497799835?mt=12).
> * If you do not already have it, install [Homebrew](https://brew.sh/) by typing the following line on a terminal:
> ```bash
> /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
> ```
> * Once you have installed Homebrew, install the following commands on the terminal:
> ```bash
> # grep
> brew install grep
> # rename
> brew install rename
> ```


## Usage

Make sure that, in the terminal interface, your current working directory is situated inside the registration folder. In the lab's workstation, just type the following on a new terminal:
```bash
cd Documents/Registration/Registration_analysis
```

Launch the first registration step:
```bash
./registration1.sh
```
Follow the program indications.
> At some point, the program will ask you if it is your 1st time performing a registration analysis. If you ansered `yes`, wil be connected to the server through the program. At that moment, you need to launch the following program to set up the registration environment on the server:
> ```bash
> ./env_setup.sh
> ```
> * If any error message is being displayed, contact [Calcul Canada](https://docs.alliancecan.ca/wiki/Technical_support#Ask_support), as there may be a problem with your server.
> * But, if it is a message that looks like `mkdir: Input: File exists` or `mkdir: Output: File exists` displayed, it is not an error, but a warning that indicates the Input and/or Output folders already exist on the scratch. You can ignore it.
>
> However, normally, nothing should be displayed. Following the environment setup, type the following command to get rid of the environment setup program:
> ```bash
> rm env_setup.sh
> ```
> Then disconnect from the server by typing the following command:
> ```bash
> exit
> ```
At the end of the program, after uploading the files you will have to connect to the server to launch the registration program. For that, once you connect on the server, type the following commands, by replacing `username` with your login:
```bash
# Go to the 'projects' directory where the job request is
cd projects/def-mlabrie/username
# Launch the job request. There should only be one job request with the "job_<something>.sh" format
sbatch job_*.sh
# Disconnect 
exit
```
Once it is done, as indicated by the program, come back after the registration is done (depending on how much time you indicated to the program).

After that, you will need to retrieve the aligned files. Make sure to be in the correct directory and launch the second registration step by typing:
```bash
./registration2-SAMPLENAME.sh
```
By replacing `SAMPLENAME` with the sample name defining your images (mentioned above, set between two underscores in the filenames). If it is the only one currently in the directory, you can replace it with a `*`.
>NB: Deletion of previous "registration2" files is not automatic in case someone wants to download multiple files from the server at the same time. Once you are finished with registering your image sets, make sure to delete them all by typing the following command:
>```bash
>rm registration2-*
>```

This program was generated during the previous registration step and thus only asks you at the beginning wether you wish to connect to the server prior to downloading.
> We recommend you accept, as it will allow you to check if the registration was executed successfully. For that, type the following commands by replacing `username` with your login:
> ```bash
> # Go to the 'projects' directory where the job request is
> cd projects/def-mlabrie/username
> # There should be 1 output file of the registration analysis situated there, named "slurm-<row of numbers>.out". You can check that by typing the following command
> ls -l
> # To open and read that file, type the following command
> less slurm*
> # If the program was performed successfully, there should be no errors displaying on the output file. After reading, type the `Q` keyboard key to close the file.
> # If there was a problem with the file, refer to the output log to solve the errors (most likely linked to the images themselves). 
> # If everything was performed successfully, you can now delete the job request and output file
> rm job_*; rm slurm*
> # Disconnect 
> exit
> ```
If no errors were raised, the registration should have performed successfully. You should now be able to find the aligned images in the location you selected to download them.

After the program has finished, if you did not connect prior to downloading, you should still do so to remove the output file and now used job request by connecting to the server and typing the following commands, replacing `username` with your login:
```bash
# Go to the projects folder
cd projects/def-mlabrie/username
# Delete all the job requests and output files present
rm job_*; rm slurm*
# Disconnect
exit
```

#### OPTIONAL:
As explained on the [CCDB wiki](https://docs.alliancecan.ca/wiki/Scratch_purging_policy), the Registration directory with the input and output folders all stay in a `scratch` folder on the server. It is intended as a temporary directory to store data that automatically purges files older than 60 days. Calcul Canada will automatically send you a message once your files are close to their expiration date and will also delete them itself if nothing is done, but it is recommended for you to manually do it once you are certain you have no use for the folders anymore. For that, on the server, type the following commands:
```bash
# Delete all the folders in the 'Input' directory
rm scratch/Registration/Input/*
# Delete all the folders in the 'Output' directory
rm scratch/Registration/Output/*
# Delete the Registration folder - This you do not need to delete immediatly after finishing your registration program, since you will be reusing it for later registrations
rm scratch/*
# Disconnect
exit
```
In case you have deleted the Registration/Input/Output directories themselves (once they have reached their expiration date), make sure, before launching the next registration analysis, to create new ones by connecting on the server and typing the following commands:
```bash
# Create new Registration directory with new Input and Output folders
mkdir scratch/Registration; mkdir scratch/Registration/Input; mkdir scratch/Registration/Output
# Disconnect
exit
```


## Contributing
For more information on Calcul Canada, I recommend you to check their [wiki](https://docs.alliancecan.ca/wiki/Technical_documentation).

For more information on the registration program used here, I invite you to visit its [website](https://www.thibault.biz/Research/cycIFAAP/cycIFAAP.html).

If you encounter any problems, do not hesitate to contact me at *Korina.Mouzakitis@USherbrooke.ca*

## License

[MIT](https://choosealicense.com/licenses/mit/)
