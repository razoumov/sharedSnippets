### Build a container with precompiled OpenFOAM

machine with sudo
apptainer build --sandbox ubuntu.dir docker://ubuntu
sudo apptainer shell --writable ubuntu.dir

apt-get update
apt-get -y install wget emacs ssh
apt-get update
sh -c "wget -O - https://dl.openfoam.org/gpg.key > /etc/apt/trusted.gpg.d/openfoam.asc"  # add the public key for the repository to enable package signatures to be verified
chmod 755 /etc/apt/trusted.gpg.d/openfoam.asc
apt-get -y install software-properties-common
add-apt-repository http://dl.openfoam.org/ubuntu   # add dl.openfoam.org to the list of software repositories to search
apt-get update
apt-get -y install openfoam10
apt-get update
apt-get install --only-upgrade openfoam10
exit

sudo apptainer build openfoamPrecompiled.sif ubuntu.dir
scp openfoamPrecompiled.sif user01@localhost:scratch/containers           # terminally.officially.few.pigeon
scp openfoamPrecompiled.sif user299@bobthewren.c3.ca:scratch/containers   # troglodytes     catherpes

### Prepare and run a small serial OpenFOAM simulation

user01@cassiopeia
apptainer shell openfoamPrecompiled.sif
. /opt/openfoam10/etc/bashrc
mkdir -p $FOAM_RUN         # creates /home/${USER}/OpenFOAM/${USER}-10/run
cd $FOAM_RUN
cp -r $FOAM_TUTORIALS/incompressible/simpleFoam/pitzDaily .   # serial case
cd pitzDaily
blockMesh   # generate the mesh
simpleFoam  # run the steady-state incompressible solver simpleFoam
find . -type f | wc -l         # 49 files
cd ..

### Prepare and run a small parallel OpenFOAM simulation with an overlay

user01@cassiopeia
module load apptainer/1.1.3
apptainer shell --overlay output.img openfoamPrecompiled.sif
. /opt/openfoam10/etc/bashrc
cd /results
cp -r $FOAM_TUTORIALS/incompressible/simpleFoam/motorBike .   # parallel case
cd motorBike
>>> edit system/decomposeParDict
  numberOfSubdomains  3;
  n (3 1 1);
>>> edit system/controlDict
  endTime         500;
  writeInterval   10;
  writeFormat     binary;
  runTimeModifiable false;   # disable loading of dictionaries at each timestep
blockMesh      # generate the mesh
decomposePar   # decompose the mesh (and the ICs)
exit

export OPENFOAM=/opt/openfoam10/platforms/linux64GccDPInt32Opt
export APPTAINERENV_PREPEND_PATH=$OPENFOAM/bin
export APPTAINERENV_LD_LIBRARY_PATH=$OPENFOAM/lib:$OPENFOAM/lib/openmpi-system
export APPTAINERENV_WM_PROJECT_DIR=/opt/openfoam10

export APPTAINERENV_MPI_BUFFER_SIZE=2000000000

salloc --nodes=1 --ntasks=3 --time=0:30:0 --mem-per-cpu=3600
apptainer exec -B /scratch --overlay output.img --pwd /results/motorBike openfoamPrecompiled.sif mpirun -np $SLURM_NTASKS simpleFoam -parallel
exit the job

apptainer shell -B /scratch --overlay output.img ssh.sif
ls /results/motorBike/processor*
