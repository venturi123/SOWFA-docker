# SOWFA-Docker

This repository provides a pre-built Docker image with all the essential packages and comprehensive build instructions for SOWFA, utilizing OpenFOAM 2.4.x and OpenFAST v2.3.0.

## Quick Start Guide

If you're not interested in how the image is built and simply want to use SOWFA for CFD tasks, follow the steps below:

```bash
# Install Docker on a machine that meets the supported platform requirements
https://docs.docker.com/engine/install

# Download the latest three-part SOWFA Docker image manually or via wget
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/sowfa_image_part_aa
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/sowfa_image_part_ab
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/sowfa_image_part_ac

# Merge the parts
cat sowfa_image_part_* > sowfa_image.tar.gz

# Load the image locally
docker load -i sowfa_image.tar.gz

# Create a new container and enter its bash shell
docker run -it --name sowfa sowfa_images /bin/bash
```

Feel free to star this repository, close this page, and enjoy your SOWFA journey!

## Build Instructions

The following provides detailed instructions on how to compile and install NREL/SOWFA coupled with OpenFAST. Through multiple tests, Ubuntu 16.04 was found to have the best compatibility. The recommended approach is to build in an Ubuntu 16.04 (GCC-5) container.

### Download Required Packages

First, download the required packages:

```bash
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/SOWFA.tar.gz
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/scotch_6.0.3.tar.gz
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/ParaView-v4.1.0-source.tar.gz
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/OpenFOAM.tar.gz
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/OpenFAST.tar.gz
wget https://github.com/venturi123/SOWFA-docker/releases/download/v1.0.0/CGAL-4.6.tar.bz2
```

Next, clone this repository and build the base Ubuntu image:

```bash
git clone https://github.com/venturi123/SOWFA-docker.git

cd SOWFA-docker/ubuntu_1604
chmod a+x ./build_docker.sh

# This script will automatically read the current host's UID and GID, and create a 'sowfa' user to avoid permission conflicts with the CFD result files
./build_docker.sh

# Start a container as root user
docker run -it --user root --name ubuntu_1604 ubuntu_1604 /bin/bash

# Use the Docker copy command to move the downloaded packages to the container
docker cp {local/path/to/the/above/packages} ubuntu_1604:/opt
```

### Installing OpenFOAM 2.4.x

First, update packages and install dependencies:

```bash
apt-get update
apt-get install git-core build-essential cmake-data cmake flex bison zlib1g-dev qt4-dev-tools libqt4-dev libqtwebkit-dev gnuplot libreadline-dev libncurses-dev libxt-dev libopenmpi-dev openmpi-bin libboost-system-dev libboost-thread-dev libgmp-dev libmpfr-dev python python-dev libglu1-mesa-dev libqt4-opengl-dev vim wget
```

When installing OpenFOAM, **make sure to download the installation packages to the /opt/OpenFOAM directory**.

Download the required source code. Note that OpenFOAM 2.4.x must have its source and installation path in the same directory. If installing in a user's home directory, all related files need to be placed in `/home/user`. Modify `OpenFOAM/OpenFOAM-2.4.x/etc/bashrc` to set the `foamInstall` variable to the appropriate source location.

```bash
cd /opt
tar xvf OpenFOAM.tar.gz
cd OpenFOAM
```

Modify the OpenFOAM installation path. Always install OpenFOAM, OpenFAST, and SOWFA in the system directory (`/opt`):

```bash
vim OpenFOAM-2.4.x/etc/bashrc
```

If installing in the system directory rather than the user's home, use the following directory settings:

- Comment out `foamInstall=HOME/WM_PROJECT` and uncomment `foamInstall=/opt/$WM_PROJECT`

Before building OpenFOAM, some fixes need to be made. OpenFOAM 2.4.x does not properly detect modern versions of Flex, so we need to edit some files:

```bash
source OpenFOAM-2.4.x/etc/bashrc
cd ${WM_PROJECT_DIR}
find src applications -name "*.L" -type f | xargs sed -i -e 's=\\(YY\\_FLEX\\_SUBMINOR\\_VERSION\\)=YY_FLEX_MINOR_VERSION < 6 \\&\\& \\1='
```

Create a few symbolic links to ensure that the correct global MPI installation is used:

```bash
cd ..
ln -s /usr/bin/mpicc.openmpi OpenFOAM-2.4.x/bin/mpicc
ln -s /usr/bin/mpirun.openmpi OpenFOAM-2.4.x/bin/mpirun
```

Set parallel compile cores (use `lscpu` to check CPU cores):

```bash
export WM_NCOMPPROCS=64
```

Activate the OpenFOAM 2.4.x environment and start building:

```bash
source /opt/OpenFOAM/OpenFOAM-2.4.x/etc/bashrc
cd $WM_THIRD_PARTY_DIR
export QT_SELECT=qt4
./Allwmake
wmSET $FOAM_SETTINGS
```

### Building ParaView 4.1.0

To build ParaView 4.1.0:

```bash
export QT_SELECT=qt4

sed -i -e 's=//#define GLX_GLXEXT_LEGACY=#define GLX_GLXEXT_LEGACY=' ParaView-4.1.0/VTK/Rendering/OpenGL/vtkXOpenGLRenderWindow.cxx

cd $WM_THIRD_PARTY_DIR/ParaView-4.1.0
patch -p1 < Fix.patch

cd VTK
patch -p1 < Fix2.patch

cd ../..
```

Compile ParaView with Python and MPI:

```bash
export WM_NCOMPPROCS=64

./makeParaView4 -python -mpi -python-lib /usr/lib/x86_64-linux-gnu/libpython2.7.so.1.0

wmSET $FOAM_SETTINGS
```

### Building OpenFOAM

```bash
cd $WM_PROJECT_DIR

export QT_SELECT=qt4
export WM_NCOMPPROCS=64

./Allwmake

# Double-check
./Allwmake
```

To verify the installation, use `checkMesh` to ensure everything is properly set up.

### Installing OpenFAST

Since SOWFA requires specifying the OpenFAST installation path, OpenFAST must be installed first.

```bash
apt update
apt install build-essential flex bison gfortran git cmake python python-dev zlib1g-dev libreadline-dev libncurses-dev libyaml-cpp-dev libgmp-dev libmpfr-dev libboost-system-dev libboost-thread-dev libopenmpi-dev openmpi-bin libhdf5-dev libxml2 libxml2-dev libcgal-dev libptscotch-dev libscotch-dev libhdf5-serial-dev doxygen liblapack-dev liblas-dev libopenblas-dev vim wget
```

Download OpenFAST (do not overwrite the existing local OpenFAST folder):

```bash
git clone https://github.com/OpenFAST/OpenFAST.git
cd OpenFAST
# Switch to version v2.3.0 to match GCC-5 compatibility
git checkout v2.3.0
mkdir build
cd build
```

Set paths for compilation:

```bash
export C_INCLUDE_PATH=$C_INCLUDE_PATH:/usr/include
export C_INCLUDE_PATH=$C_INCLUDE_PATH:/usr/include/hdf5/serial
export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/usr/include
export CPLUS_INCLUDE_PATH=$CPLUS_INCLUDE_PATH:/usr/include/hdf5/serial
export HDF5_ROOT=/usr/lib/x86_64-linux-gnu/hdf5/serial
export HDF5_DIR=/usr/lib/x86_64-linux-gnu/hdf5/serial
export YAML_ROOT="/usr/"
```

Generate Makefile and build:

```bash
cmake -DCMAKE_INSTALL_PREFIX="/opt/OpenFAST" -DFPE_TRAP_ENABLED=ON -DBUILD_OPENFAST_CPP_API:BOOL=ON -DBUILD_SHARED_LIBS:BOOL=ON -DDOUBLE_PRECISION:BOOL=ON -DUSE_DLL_INTERFACE:BOOL=ON -DORCA_DLL_LOAD:BOOL=OFF -DGENERATE_TYPES:BOOL=OFF ../
make -j64
sudo make install
```

Add `/opt/OpenFAST/lib` to `${LD_LIBRARY_PATH}` if not added during installation.

### Installing SOWFA

Install SOWFA:

```bash
source /opt/OpenFOAM/OpenFOAM-2.4.x/etc/bashrc
cd /opt/
tar xvf SOWFA.tar.gz
cd SOWFA
```

Set environment variables:

```bash
export OPENFAST_DIR="/opt/OpenFAST"
export HDF5_DIR="/usr/lib/x86_64-linux-gnu/hdf5/serial"
export SOWFA_DIR="/opt/SOWFA"
export LD_LIBRARY_PATH=/opt/OpenFAST/lib:${LD_LIBRARY_PATH}
export WM_NCOMPPROCS=64
```

Start the build process:

```bash
cd ${SOWFA_DIR}

./Allwmake > log.SOWFA.1 2>&1

# Double-check if everything built successfully
./Allwmake > log.SOWFA.2 2>&1
```

Check for binary solvers, ensuring the expected number is present:

```bash
ls ${SOWFA_DIR}/applications/bin/${WM_OPTIONS}
# Output
# ABLSolver                            ABLTerrainSolver
# pisoFoamTurbine.ADM                  pisoFoamTurbine.ALM
# pisoFoamTurbine.ALMAdvanced          pisoFoamTurbine.ALMAdvancedOpenFAST
# setFieldsABL                         turbineTestHarness.ALM
# turbineTestHarness.ALMAdvanced       windPlantSolver.ADM
# windPlantSolver.ALM                  windPlantSolver.ALMAdvanced
# windPlantSolver.ALMAdvancedOpenFAST


ls ${SOWFA_DIR}/lib/${WM_OPTIONS}/
# Output
# libSOWFATurbineModelsOpenFAST.so  libSOWFATurbineModelsStandard.so
# libSOWFAfiniteVolume.so           libSOWFAincompressibleLESModels.so
# libSOWFAsampling.so               libSOWFArutilityFunctionObjects.so
# libSOWFAfileFormats.so
```

### Runtime Configuration

Add the following to `.environment` in your container:

```bash
# Basic
export OPENFAST_DIR="/opt/OpenFAST"
export HDF5_DIR="/usr/lib/x86_64-linux-gnu/hdf5/serial"
export SOWFA_DIR="/opt/SOWFA"
export OPENFOAM_VERSION=2.4.x
export OPENFOAM_NAME=OpenFOAM-$OPENFOAM_VERSION
export FOAM_INST_DIR=/opt/OpenFOAM

# SOWFA
source /opt/OpenFOAM/OpenFOAM-2.4.x/etc/bashrc
export LD_LIBRARY_PATH=/opt/OpenFAST/lib:${LD_LIBRARY_PATH}
export LD_LIBRARY_PATH=/opt/SOWFA/lib/${WM_OPTIONS}/:${LD_LIBRARY_PATH}
export PATH=$SOWFA_DIR/applications/bin/$WM_OPTIONS:$PATH

# ParaView
export ParaView_DIR=/opt/OpenFOAM/ThirdParty-2.4.x/platforms/linux64Gcc/ParaView-4.1.0
export PATH=$ParaView_DIR/bin:$PATH
export PV_PLUGIN_PATH=$FOAM_LIBBIN/paraview-4.1
```

To generate ABL inflow and boundary conditions, modify the default Python path in the SOWFA scripts:

```bash
/opt/SOWFA/tools/boundaryDataConversion/makeBoundaryDataFiles/data.py
/opt/SOWFA/tools/boundaryDataConversion/makeBoundaryDataFiles/points.py
/opt/SOWFA/tools/sourceDataConversion/sourceData.py
/opt/SOWFA/tools/sourceDataConversion/sourceHistoryRead.py
```

Add or modify the first line to use the system Python 2 path: `#!/usr/bin/python2`.

Install pip and numpy:

```bash
apt-get install python-pip
pip2 install numpy==1.15.0
```

### Save Docker image

```bash
docker commit ubuntu_1604 sowfa_image:latest
docker save -o sowfa_image.tar sowfa_image:latest
```

## Issues

1. **GCC Compatibility**: If using GCC version >= 6.x, there may be weird segfault errors when using commands like `renumberMesh` or `reconstructPar`. Therefore, GCC-5 is recommended to avoid such errors.
2. **Library Loading Errors**: After running `make install` for OpenFAST, you might see an error about loading shared libraries, such as `libopenfast_postlib.so`. This is caused by missing entries in the `${LD_LIBRARY_PATH}`. Make sure to add the necessary library paths.
3. **Missing Libraries**: If an executable cannot find a library, use `ldd xxx` to determine which library is missing and add it to `${LD_LIBRARY_PATH}`.
4. **Undefined Symbol Error**: An `undefined symbol` error like `dlopen error in libuserincompressibleLESModels.so` is due to an older version of SOWFA. These can be safely ignored as they don't affect the computations. However, they can be fixed by modifying SOWFA, as discussed in [this PR](https://github.com/NREL/SOWFA/pull/63).
5. **Locale Warning**: If entering the container's bash prompt results in `bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8)`, set the system environment variable `export LC_ALL=C`. For more details, check [this link](https://stackoverflow.com/questions/14547631/python-locale-error-unsupported-locale-setting).

## References

- [SOWFA Installation by Pablo Benito](https://github.com/pablo-benito/SOWFA-installation)
- [OpenFOAM 2.4.x Ubuntu Installation Guide](https://openfoamwiki.net/index.php/Installation/Linux/OpenFOAM-2.4.x/Ubuntu#Ubuntu_14.04)
- [OpenFAST Installation Documentation](https://openfast.readthedocs.io/en/main/source/install/index.html)

