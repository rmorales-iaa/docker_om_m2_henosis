#start of Dokerfile
#docker for run om m2 and henosis (https://gitlab.com/rmorales_iaa) using debian 'Fedora'

#set the image base
FROM debian:buster-slim

#add lemon user
RUN useradd -ms /bin/bash lemon 

#initial repo update
RUN apt-get -y update

#basic tools
RUN apt-get install -y wget vim git csh curl

#install python
RUN apt install -y python 

#install pip
RUN mkdir /home/lemon/Downloads &&  cd /home/lemon/Downloads
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
RUN python get-pip.py

#end of Dokerfile
