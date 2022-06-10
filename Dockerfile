#start of Dokerfile
#docker for run om m2 and henosis (https://gitlab.com/rmorales_iaa) using debian 'Fedora'

#-------------------------------------
#set the image base
FROM fedora:36
#-------------------------------------
#user root

#add fusion repo
RUN dnf install -y \
https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
RUN dnf update -y

#install tools and libraries
RUN dnf group install -y "Development Tools"
RUN dnf install -y fftw-devel atlas-devel lapack-devel gnuplot parallel firefox autoconf autoconf automake libtool \
                   ffmpeg java cairo-devel libpng-devel libjpeg-turbo-devel zlib-devel bzip2-devel swig \
                   python3-devel cfitsio cfitsio-devel wcslib* python3-astropy python3-numpy
RUN dnf update -y

#add rafa user (password rafa) with root privilegies
RUN useradd --password "huVS1Vq3prZJc" --create-home --shell /bin/bash rafa
RUN usermod -aG wheel rafa
RUN printf '\nrafa ALL=(ALL) NOPASSWD:ALL\n' >> /etc/sudoers

#create directories
RUN mkdir ~/Downloads

#install sbt
RUN rm -f /etc/yum.repos.d/bintray-rpm.repo
RUN curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
RUN mv sbt-rpm.repo /etc/yum.repos.d/
RUN dnf install -y sbt

#-------------------------------------
#user rafa
USER rafa

#create directories
RUN mkdir ~/Downloads
RUN mkdir ~/proyecto
RUN mkdir ~/atajo


#atajo (shortcut)
RUN printf '\n#atajo\nPATH=$PATH:/home/rafa/atajo/\n' >> ~/.bashrc
RUN printf '\n#variables\np=/home/rafa/proyecto/\n'  >> ~/.bashrc
RUN source ~/.bashrc

#clone proyects
WORKDIR "/home/rafa/proyecto"
RUN git clone https://gitlab.com/rmorales_iaa/common_scala.git 
RUN git clone https://gitlab.com/rmorales_iaa/om.git
RUN git clone https://gitlab.com/rmorales_iaa/henosis.git 
RUN git clone https://gitlab.com/rmorales_iaa/m2.git 
RUN git clone https://gitlab.com/rmorales_iaa/my_psfex.git 
RUN git clone https://gitlab.com/rmorales_iaa/my_sextractor.git 
RUN git clone https://github.com/dstndstn/astrometry.net.git 


#compile my_sextractor
WORKDIR "/home/rafa/proyecto/my_sextractor"
RUN ./autogen.sh 
RUN ./configure
RUN make -j8


#compile my_psfex
WORKDIR "/home/rafa/proyecto/my_psfex"
RUN ./autogen.sh 
RUN ./configure
RUN make -j8


#compile astrometry.net
WORKDIR "/home/rafa/proyecto/astrometry.net"
RUN git config --global --add safe.directory /home/rafa/proyecto/astrometry.net
RUN make
RUN make py
RUN make extra
RUN sudo make install
RUN printf '\n#astrometry.net\nPATH=$PATH:/usr/local/astrometry/bin/'  >> ~/.bashrc
RUN source ~/.bashrc


#compile om
WORKDIR "/home/rafa/proyecto/om"
RUN mkdir deploy
WORKDIR "/home/rafa/proyecto/om/deploy"
RUN ln -s ../input/
RUN mkdir ../output
RUN ln -s ../output
RUN ln -s ../native/
WORKDIR "/home/rafa/proyecto/om"
RUN ./makeFatJar 


#compile henosis
WORKDIR "/home/rafa/proyecto/henosis"
RUN mkdir deploy
WORKDIR "/home/rafa/proyecto/henosis/deploy"
RUN ln -s ../input/
RUN mkdir ../output
RUN ln -s ../output
RUN ln -s ../native/
WORKDIR "/home/rafa/proyecto/henosis"
RUN ./makeFatJar 


#compile m2
WORKDIR "/home/rafa/proyecto/m2"
RUN mkdir deploy
WORKDIR "/home/rafa/proyecto/m2/deploy"
RUN ln -s ../input/
RUN mkdir ../output
RUN ln -s ../output
RUN ln -s ../native/
WORKDIR "/home/rafa/proyecto/m2"
RUN ./makeFatJar 
WORKDIR "/home/rafa/proyecto/m2/deploy"
RUN ln -s m2-assembly-0.1.jar m2.jar

#prepare the external data links
RUN  mkdir -p /usr/local/astrometry/data
RUN  mkdir -p /home/rafa/data/database
RUN  mkdir -p /home/rafa/data/in
RUN  mkdir -p /home/rafa/data/out

#uncomment the parallel option for astroemtry.net indexes
RUN sudo sed -i '/^#inparalle/s/^#//' /usr/local/astrometry/bin/../etc/astrometry.cfg


#-------------------------------------
#end of Dokerfile