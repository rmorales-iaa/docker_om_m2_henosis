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
                   ffmpeg cairo-devel libpng-devel libjpeg-turbo-devel zlib-devel bzip2-devel swig \
                   python3-devel cfitsio cfitsio-devel wcslib* python3-astropy python3-numpy wget git vim \
                   ghostscript libtool libjpeg-devel libtiff-devel libgit2-devel lzip  gsl-devel cfitsio-devel curl-devel \
                   gcc-c++ ncurses-devel ImageMagick
RUN dnf update -y

#add rafa user (password rafa) with root privilegies
RUN useradd --password "huVS1Vq3prZJc" --create-home --shell /bin/bash rafa
RUN usermod -aG wheel rafa
RUN printf '\nrafa ALL=(ALL) NOPASSWD:ALL\n' >> /etc/sudoers

#create directories
RUN mkdir ~/Downloads


#java
WORKDIR ~/Downloads
RUN wget --no-check-certificate --content-disposition "https://cloud.iaa.csic.es/public.php?service=files&t=903fa211399bb124d70eb253376480bb&download&path=/docker/om_m2_henosis/jdk-8u231-linux-x64.tar.gz" 
RUN tar xvf jdk-8u231-linux-x64.tar.gz
RUN mv jdk1.8.0_231/ /usr/lib/jvm
RUN update-alternatives --install /usr/bin/java java /usr/lib/jvm/bin/java  100
RUN update-alternatives --install /usr/bin/javac javac /usr/lib/bin/javac  100
RUN alternatives --set java /usr/lib/jvm/bin/java
RUN rm jdk-8u231-linux-x64.tar.gz

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

#compile gnuastro
RUN wget https://ftp.gnu.org/gnu/gnuastro/gnuastro-0.17.tar.gz
RUN tar xvf gnuastro-0.17.tar.gz
RUN rm -fr gnuastro-0.17.tar.gz
WORKDIR /home/rafa/proyecto/gnuastro-0.17/
ENV CPPFLAGS="$CPPFLAGS -I/usr/include/cfitsio/"
RUN ./configure
RUN make -j8
RUN make check -j8
RUN sudo make install

#compile astrometry.net
WORKDIR "/home/rafa/proyecto/astrometry.net"
RUN git config --global --add safe.directory /home/rafa/proyecto/astrometry.net
RUN make
RUN make py
RUN make extra
RUN sudo make install
RUN printf '\n#astrometry.net\nPATH=$PATH:/usr/local/astrometry/bin/'  >> ~/.bashrc
RUN source ~/.bashrc
#uncomment the parallel option for astrometry.net indexes
RUN sudo sed -i '/^#inparallel/s/^#//'  /usr/local/astrometry/bin/../etc/astrometry.cfg


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
WORKDIR "/home/rafa/proyecto/m2/native"
RUN rm libFitsUtils.so
RUN ln -s libFitsUtils_fedora.so libFitsUtils.so

#m2:copy sextractor setup
WORKDIR "/home/rafa/Downloads"
RUN wget --no-check-certificate --content-disposition "https://cloud.iaa.csic.es/public.php?service=files&t=0487dfcf6eb783a8d313f620396d1138&download&path=/docker/om_m2_henosis/sextractor.zip" 
RUN unzip sextractor.zip
RUN rm sextractor.zip
RUN mv sextractor/ /home/rafa/proyecto/m2/input/


#find_orb
WORKDIR /home/rafa/proyecto/proyecto/
RUN mkdir /home/rafa/proyecto/find_orb
WORKDIR /home/rafa/proyecto/find_orb
RUN git clone https://github.com/Bill-Gray/lunar.git
RUN git clone https://github.com/Bill-Gray/sat_code.git
RUN git clone https://github.com/Bill-Gray/jpl_eph.git
RUN git clone https://github.com/Bill-Gray/find_orb.git
RUN git clone https://github.com/Bill-Gray/miscell.git

#find_orb:jpl_eph
WORKDIR /home/rafa/proyecto/find_orb/jpl_eph/
RUN sed -i "s|INSTALL_DIR)/include|INSTALL_DIR)/proyecto/find_orb/lunar|g" makefile
RUN make
RUN make install

#find_orb:lunar
WORKDIR /home/rafa/proyecto/find_orb/lunar
RUN make
RUN ln -s ~/proyecto/find_orb/lunar/ ~/include
RUN make integrat
RUN cp liblunar.a ~/lib

#find_orb:sat_code
WORKDIR /home/rafa/proyecto/find_orb/sat_code
RUN make
RUN make install

#find_orb:miscell
WORKDIR /home/rafa/proyecto/find_orb/miscell
RUN make

#find_orb:find_orb
WORKDIR /home/rafa/proyecto/find_orb/find_orb
RUN make

#find_orb:create_links
WORKDIR /home/rafa/proyecto/find_orb/
RUN ln -s lunar/astcheck
RUN ln -s lunar/mpc2sof 
RUN ln -s lunar/integrat

#find_orb:get observarories codes
RUN wget https://www.minorplanetcenter.net/iau/lists/ObsCodes.html

#prepare the external data links
RUN mkdir -p /usr/local/astrometry/data
RUN mkdir -p /home/rafa/data/database
RUN mkdir -p /home/rafa/data/in
RUN mkdir -p /home/rafa/data/out


WORKDIR /home/rafa/proyecto/
#--------------------------------------
#end of Dokerfile