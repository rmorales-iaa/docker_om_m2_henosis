# docker_om_m2_henosis


#build image in podman

#clone repository
git clone git@github.com:rmorales-iaa/docker_om_m2_henosis.git

#install podman
cd docker_om_m2_henosis

#build image
podman  build -t local_repo/fedora:omh .

