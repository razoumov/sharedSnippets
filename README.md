## Scripts for DAR (= Disk ARchive) archiving and backup utility

Using [dar](http://dar.linux.free.fr) would be much easier if you did not have to memorize and specify all the flags and
the right syntax on the command line. Here we provide several Bash functions for easy backup. Please note that these
functions assume that you are below your quota (so you can write files!), have read and write permissions, i.e. all the
common-sense assumptions. It is your job to ensure that this is the case, and that dar archived/restored your files
correctly before you delete the originals. In other words, please test everything before including these functions into
your workflow.
