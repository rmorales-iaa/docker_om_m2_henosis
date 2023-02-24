#start of Dokerfile
#docker for run om m2 and henosis (https://gitlab.com/rmorales_iaa) using debian 'Fedora'

#-------------------------------------
#set the image base
FROM fedora:37
#-------------------------------------
#user root

#add fusion repo
RUN dnf install -y \
https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

#install tools and libraries
RUN dnf group install -y "Development Tools"
RUN dnf install -y fftw-devel atlas-devel lapack-devel gnuplot parallel firefox autoconf autoconf automake libtool \
                   ffmpeg cairo-devel libpng-devel libjpeg-turbo-devel zlib-devel bzip2-devel swig \
                   python3-devel cfitsio cfitsio-devel wcslib* python3-astropy python3-numpy wget git vim \
                   ghostscript libtool libjpeg-devel libtiff-devel libgit2-devel lzip  gsl-devel cfitsio-devel curl-devel \
                   gcc-c++ ncurses-devel ImageMagick nodejs pam-devel gthumb xarchiver ark filezilla gitk selinux-policy-devel
                   
#instal GUI xfce (optional)
RUN sudo dnf install @xfce-desktop-environment
RUN echo "exec /usr/bin/xfce4-session" >> ~/.xinitrc 

                   
#install postgre
RUN sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/F-37-x86_64/pgdg-fedora-repo-latest.noarch.rpm 

RUN sudo dnf install -y postgresql15-server
RUN sudo /usr/pgsql-15/bin/postgresql-15-setup initdb
RUN sudo systemctl enable postgresql-15
RUN sudo systemctl start postgresql-15
RUN sudo systemctl status postgresql-15
RUN sudo su - postgres
RUN psql
RUN alter user postgres with password 'YOUR_PASSWORD';

#install mongodb
RUN echo "[mongodb-org-6.0]" >> /etc/yum.repos.d/mongodb.repo \ 
 && echo "name=MongoDB Repository" >> /etc/yum.repos.d/mongodb.repo \ 
 && echo "baseurl=https://repo.mongodb.org/yum/redhat/8Server/mongodb-org/6.0/x86_64/" >> /etc/yum.repos.d/mongodb.repo \
 && echo "gpgcheck=1" >> /etc/yum.repos.d/mongodb.repo \ 
 && echo "enabled=1" >> /etc/yum.repos.d/mongodb.repo \ 
 && echo "gpgkey=https://www.mongodb.org/static/pgp/server-6.0.asc" >> /etc/yum.repos.d/mongodb.repo
 
RUN dnf install -y mongodb-org-server mongodb-mongosh mongodb-database-tools
RUN dnf update -y

#create directories
RUN mkdir ~/Downloads

#mongodb SE linux
WORKDIR  ~/Downloads
RUN git clone https://github.com/mongodb/mongodb-selinux
RUN cd mongodb-selinux
RUN make
RUN sudo make install

#mongodb SE linux ftdc errors
WORKDIR  ~/Downloads
RUN sudo ausearch -c 'ftdc' -raw | audit2allow -M my_ftdc
RUN sudo semodule -X300 -i  my_ftdc.pp

#mongo service configuration
RUN sed -i 's#  path: /var/log/mongodb/mongod.log#  path: /home/rafa/data/database/mongodb/log/mongod.log#g' /etc/mongod.conf 
RUN sed -i 's#  dbPath: /var/lib/mongo#  dbPath: /home/rafa/data/database/mongodb#g' /etc/mongod.conf 
RUN printf '\nsecurity:\n authorization: "enabled"\n' >> /etc/mongod.conf

#add rafa user (password) with root privilegies
RUN useradd --password "huVS1Vq3prZJc" --create-home --shell /bin/bash rafa
RUN usermod -aG wheel rafa
RUN printf '\nrafa ALL=(ALL) NOPASSWD:ALL\n' >> /etc/sudoers


#mongo compass
WORKDIR  ~/Downloads
RUN wget https://downloads.mongodb.com/compass/mongodb-compass-1.35.0.x86_64.rpm
RUN sudo dnf install -y ./mongodb-compass-1.35.0.x86_64.rpm 
RUN rm mongodb-compass-1.35.0.x86_64.rpm

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

#add additional tools
RUN npm install gtop -g

RUN pip3 install wheel astroalign
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
RUN wget https://ftp.gnu.org/gnu/gnuastro/gnuastro-0.19.tar.gz
RUN tar xvf gnuastro-0.19.tar.gz
RUN rm -fr gnuastro-0.19.tar.gz
WORKDIR /home/rafa/proyecto/gnuastro-0.19/
RUN ./configure CPPFLAGS="-I/usr/include/cfitsio/"
RUN make -j$(nproc)
RUN make check -j$(nproc)
RUN sudo make install

#compile astrometry.net
WORKDIR "/home/rafa/proyecto/astrometry.net"
RUN git config --global --add safe.directory /home/rafa/proyecto/astrometry.net
RUN make -j$(nproc)
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
RUN make -j$(nproc)

#compile my_psfex
WORKDIR "/home/rafa/proyecto/my_psfex"
RUN ./autogen.sh 
RUN ./configure
RUN make -j$(nproc)

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
RUN  wget --no-check-certificate --content-disposition https://cloud.iaa.csic.es/index.php/s/TpWec4MFQG6zecy -O sextractor.zip
RUN unzip sextractor.zip
RUN rm sextractor.zip
RUN mv sextractor/ /home/rafa/proyecto/m2/input/

#m2:update sextractor and psfex executables
RUN cp /home/rafa/proyecto/my_sextractor/src/sex /home/rafa/proyecto/m2/input/sextractor/
RUN cp /home/rafa/proyecto/my_psfex/src/psfex /home/rafa/proyecto/m2/input/sextractor/

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

#install astroimagej
WORKDIR cd /home/rafa/
RUN mkdir apps/astroimagej
WORKDIR /home/rafa/apps/astroimagej
RUN wget https://www.astro.louisville.edu/software/astroimagej/installation_packages/AstroImageJ_v5.1.0.00_linux_x64_java18.tar.gz
RUN tar xvf AstroImageJ_v5.1.0.00_linux_x64_java18.tar.gz
RUN rm *.tar.gz
RUN cd /home/rafa/atajo/
RUN ln -s /home/rafa/apps/astroimagej/AstroImageJ/AstroImageJ astroimagej

#prepare the external data links
RUN sudo mkdir -p /usr/local/astrometry/data
RUN mkdir -p /home/rafa/data/in
RUN mkdir -p /home/rafa/data/out
RUN mkdir -p /home/rafa/data/database
RUN mkdir -p /home/rafa/data/database/mongodb
RUN mkdir -p /home/rafa/data/database/mongodb/log
RUN mkdir -p /home/rafa/data/database/postgresql
RUN sudo chown -R mongod:mongod /home/rafa/data/database/mongodb

WORKDIR /home/rafa/proyecto/

#--------------------------------------
#end of Dokerfile
