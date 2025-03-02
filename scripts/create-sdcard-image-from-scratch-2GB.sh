#!/bin/bash

set -e

password='jetson'

# Record the time this script starts
date
# Get the full dir name of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Keep updating the existing sudo time stamp
sudo -v
while true; do sudo -n true; sleep 120; kill -0 "$$" || exit; done 2>/dev/null &

# Enable i2c permissions
echo -e "\e[100m Enable i2c permissions \e[0m"
sudo usermod -aG i2c $USER

# Make swapfile
# sh ./enable_swap.sh

# Install pip and some python dependencies
echo -e "\e[104m Install pip and some python dependencies \e[0m"
sudo apt-get update
sudo apt install -y python3-pip python3-pil
sudo -H pip3 install Cython
sudo -H pip3 install --upgrade numpy

# Install jtop
echo -e "\e[100m Install jtop \e[0m"
sudo -H pip install -U jetson-stats


# Install the pre-built TensorFlow pip wheel
# echo -e "\e[48;5;202m Install the pre-built TensorFlow pip wheel \e[0m"
# sudo apt-get update
# sudo apt-get install -y libhdf5-serial-dev hdf5-tools libhdf5-dev zlib1g-dev zip libjpeg8-dev liblapack-dev libblas-dev gfortran
# sudo apt-get install -y python3-pip
# sudo pip3 install -U pip testresources setuptools numpy==1.16.1 future==0.17.1 mock==3.0.5 h5py==2.9.0 keras_preprocessing==1.0.5 keras_applications==1.0.8 gast==0.2.2 futures protobuf pybind11
# # TF-1.15
# sudo pip3 install --pre --extra-index-url https://developer.download.nvidia.com/compute/redist/jp/v44 'tensorflow<2'

# Install the pre-built PyTorch pip wheel 
echo -e "\e[45m Install the pre-built PyTorch pip wheel for JetPack 4.6 \e[0m"
cd
wget -N https://nvidia.box.com/shared/static/h1z9sw4bb1ybi0rm3tu8qdj8hs05ljbm.whl -O torch-1.9.0-cp36-cp36m-linux_aarch64.whl
sudo apt-get install -y libopenblas-base libopenmpi-dev libjpeg-dev zlib1g-dev libopenblas-dev libblas-dev liblapack-dev libatlas-base-dev gfortran libfreetype6-dev libcanberra-gtk*
sudo -H pip3 install numpy torch-1.9.0-cp36-cp36m-linux_aarch64.whl 

# Install torchvision package
echo -e "\e[45m Install torchvision package \e[0m"
sudo apt-get install -y libpython3-dev libavcodec-dev libavformat-dev libswscale-dev
cd
git clone --branch v0.10.0 https://github.com/pytorch/vision torchvision
export BUILD_VERSION=0.10.0
cd torchvision
#git checkout v0.4.0
sudo python3 setup.py install

# Install torch2trt
cd $HOME
git clone https://github.com/NVIDIA-AI-IOT/torch2trt
cd torch2trt
sudo python3 setup.py install

cd $HOME
git clone https://github.com/NVIDIA-AI-IOT/jetcam
cd jetcam
sudo python3 setup.py install

# Install traitlets (master, to support the unlink() method)
echo -e "\e[48;5;172m Install traitlets \e[0m"
#sudo python3 -m pip install git+https://github.com/ipython/traitlets@master
sudo python3 -m pip install git+https://github.com/ipython/traitlets@dead2b8cdde5913572254cf6dc70b5a6065b86f8

# Install jupyter lab
echo -e "\e[48;5;172m Install Jupyter Lab \e[0m"
sudo apt install -y curl
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt install -y nodejs libffi-dev 
sudo -H pip3 install packaging
sudo -H pip3 install jupyter jupyterlab
sudo -H jupyter labextension install @jupyter-widgets/jupyterlab-manager

# fix for permission error
sudo chown -R jetson:jetson ~/.jupyter

jupyter lab --generate-config
python3 -c "from notebook.auth.security import set_password; set_password('$password', '$HOME/.jupyter/jupyter_notebook_config.json')"
#Este es para el error libgomp.so.1
echo "import os
c = get_config()
os.environ['LD_PRELOAD'] = '/usr/lib/aarch64-linux-gnu/libgomp.so.1'
c.Spawner.env.update('LD_PRELOAD')" >> ~/.jupyter/jupyter_lab_config.py

# fix for permission error
sudo chown -R jetson:jetson ~/.local/share/

# Install jupyter_clickable_image_widget
# echo "\e[42m Install jupyter_clickable_image_widget \e[0m"
# cd
# sudo apt-get install libssl1.0-dev
# git clone https://github.com/jaybdub/jupyter_clickable_image_widget
# cd jupyter_clickable_image_widget
# git checkout tags/v0.1
# sudo -H pip3 install -e .
# sudo jupyter labextension install js
# sudo jupyter lab build

# Install bokeh
# sudo pip3 install bokeh
# sudo jupyter labextension install @bokeh/jupyter_bokeh


# install jetbot python module
cd
sudo apt install -y python3-smbus
cd ~/Downloads/jetbot
#sudo apt-get install -y cmake
#sudo python3 setup.py install 

# Install jetbot services
cd jetbot/utils
# python3 create_stats_service.py
# sudo mv jetbot_stats.service /etc/systemd/system/jetbot_stats.service
# sudo systemctl enable jetbot_stats
# sudo systemctl start jetbot_stats
python3 create_jupyter_service.py
sudo mv jetbot_jupyter.service /etc/systemd/system/jetbot_jupyter.service
sudo systemctl enable jetbot_jupyter
sudo systemctl start jetbot_jupyter


# install python gst dependencies
sudo apt-get install -y \
    libwayland-egl1 \
    gstreamer1.0-plugins-bad \
    libgstreamer-plugins-bad1.0-0 \
    gstreamer1.0-plugins-good \
    python3-gst-1.0 \
    nano
    
# install zmq dependency (should actually already be resolved by jupyter)
# sudo -H pip3 install pyzmq
    

echo -e "\e[45m Cuda Toolkit \e[0m"
sudo apt install -y cuda-toolkit-10-2
# Optimize the system configuration to create more headroom
sudo nvpmodel -m 0
sudo systemctl set-default multi-user
sudo systemctl disable nvzramconfig.service

# Copy JetBot notebooks to home directory
cp -r ~/Downloads/jetbot/notebooks ~/Notebooks
sudo chown -R jetson:jetson ~/Notebooks

sudo apt-get remove -y --purge make gcc build-essential
sudo apt-get autoremove -y
sudo rm -rf /var/lib/apt/lists/*

echo -e "\e[42m All done! \e[0m"

#record the time this script ends
date

sudo reboot


