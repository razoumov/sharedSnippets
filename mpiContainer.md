### Build a container with MPI

Log in to a machine with root access.

```sh
cat << EOF > parallelContainer.def
Bootstrap: docker
From: ubuntu:22.04
%environment
export OMPI_DIR=/opt/ompi
export PATH=\$OMPI_DIR/bin:\$PATH
%post
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C:en
apt update
apt upgrade -y
apt install -y --reinstall locales
sed -i 's/^# C/C/' /etc/locale.gen || echo "C.UTF-8 UTF-8" >>/etc/locale.gen
dpkg-reconfigure -fnoninteractive locales
update-locale --reset LANG="\$LANG" LC_ALL="\$LC_ALL" LANGUAGE="\$LANGUAGE"
apt upgrade -y
apt install -y tzdata
ln -fs /usr/share/zoneinfo/UTC /etc/localtime
dpkg-reconfigure -fnoninteractive tzdata
apt install -y apt-utils apt-file
apt install -y nano vim emacs
apt install -y fakeroot fakechroot
apt install -y ncdu htop
apt autoremove -y
apt clean -y
apt install -y build-essential libboost-all-dev libtbb-dev libtbb2
apt install -y libucx-dev libucx0 ucx-utils
apt install -y ssh     # if planning to use container's mpirun
apt install -y libfabric-bin libfabric-dev libfabric1 hwloc-nox libpmi2-0 libpmi2-0-dev
apt install -y rdma-core rdmacm-utils ibacm ibverbs-providers ibverbs-utils libibverbs-dev libibverbs1
apt install -y librdmacm-dev librdmacm1 srptools libmunge-dev libmunge2 munge wget
apt remove -y libpmix-dev    # likely installed by libboost-all-dev ?
apt remove -y libpmix2
apt remove -y libpmix-bin
apt install -y slurm-client
apt autoremove -y
apt clean -y
echo "Installing OpenMPI"
export OMPI_DIR=/opt/ompi
export OMPI_VERSION=4.1.1
export OMPI_URL="https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-\$OMPI_VERSION.tar.bz2"
mkdir -p /opt /tmp/ompi
cd /tmp/ompi
wget -O openmpi-\$OMPI_VERSION.tar.bz2 \$OMPI_URL && tar xjf openmpi-\$OMPI_VERSION.tar.bz2
cd /tmp/ompi/openmpi-\$OMPI_VERSION
./configure --prefix=\$OMPI_DIR --with-slurm --with-pmi=/usr --with-pmi-libdir=/usr/lib/x86_64-linux-gnu && make -j4 && make install
EOF
```

```sh
sudo apptainer build mpi.sif parallelContainer.def
ls -lh mpi.sif   # 294M
scp mpi.sif username@cluster:path
```
