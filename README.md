
<img width="270" height="216" alt="Asset 3" src="https://github.com/user-attachments/assets/fe01b4ee-a694-4b94-89be-2b898186fd2d" />


# QuickTomo

Welcome to QuickTomo, a simple and no brainer way to reconstruct your freshly collected tomograms! QuickTomo is made for simple reconstruction of binned tomograms for quality check, this provides everything you need to get an idea of what is in your sample from raw microscope output. 

Detailed instructions on the usage are provided in the tutorial PDF. 

## Requirements 

QuickTomo is not a standalone! It uses Scipion3 for preprocessing.
You need a Scipion installation with the following plugins:
  - motioncorr 
  - ctffinfd4
  - imod 

Note: the provided AreTomo executable is compiled for 11.8. It works fine (for us at least) on 10, 11 and 12 but does not work on 13.

## Installation 

Get all the files with 

```
cd ~
git clone https://github.com/alessiodacapito/quick_tomo.git
```

## Quick start

Open Scipion, import the provided workflow, fill out all of your parameters for all the steps of preprocessig in scipion and let it rip !!
Don't forget to take note of the path of your Scipion project!!

Once it's over, launch QuickTomo to reconstruct your tomos with our Aretomo secret recipe! 

```
./quick_tomo_v0.2.2.sh 
```

Then fill up the requiested fields !

### NEW for version 0.2.2:
  - choose your own binning factor
  - generate (or not) even/odd half tomograms to train your favourite denoising software


Please reach out if you want new features added !!



Happy processing !!!

