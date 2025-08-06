# quick_tomo
quick and dirty way to get your freshly collected tomograms reconstructed 


Welcome to quick_tomo (yes i know lame name) a simple and no brainer way to reconstruct your tomograms

First step is to have a running installation of Scipion with installed 
  - motioncorr 
  - ctffinfd 
  - imod 

Then download and use the workflow file that will set everything up for you in scipion 

Fill out all of your parameters for all the steps of preprocessig in scipion and let it rip !!

Get your favourite version of Aretomo (v1 tested here, I have no idea of how the newer version work), here we use AreTomo_1.3.4_Cuda118_Feb22_2023 but feel free to use the one that suits your system the best. This script is dumb so it is made to look for the Aretomo executable on your home/quick_tomo. 
If youare running another type of installaiton please modify the script accoringly

Use quick_tomo.sh to lunch the reconstruction with these tested and running parameters. We don't use Aretomo inside scipion because when I tested it (updated on 6th August 2025) it was not working well on my system. 

Enjoy your bin 4 tomograms !!!
