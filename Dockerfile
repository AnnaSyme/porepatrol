# First container: guppy

# Set the base image to Ubuntu 16.04
FROM ubuntu:16.04

# File Author / Maintainer
MAINTAINER Charlotte Berthelier <bertheli@biologie.ens.fr>

ARG PACKAGE_VERSION=3.1.5
ARG BUILD_PACKAGES="wget apt-transport-https"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt-get install --yes $BUILD_PACKAGES && \
    cd /tmp && \
    wget -q https://mirror.oxfordnanoportal.com/software/analysis/ont_guppy_cpu_${PACKAGE_VERSION}-1~xenial_amd64.deb && \
    apt-get install --yes libzmq5 libhdf5-cpp-11 libcurl4-openssl-dev libssl-dev libhdf5-10 libboost-regex1.58.0 libboost-log1.58.0 libboost-atomic1.58.0 libboost-chrono1.58.0 libboost-date-time1.58.0 libboost-filesystem1.58.0 libboost-program-options1.58.0 libboost-iostreams1.58.0 && \
    dpkg -i *.deb && \
    rm *.deb && \
    apt-get remove --purge --yes && \
    apt-get autoremove --purge --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# Second container

FROM nfcore/base
LABEL authors="Anna Syme" \
      description="Docker image containing all requirements for nf-core/porepatrol pipeline"

#copy output from first container's data file - the guppy output
COPY --from=build-env /data
# then add this next statement as per usual?

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/nf-core-porepatrol-1.0dev/bin:$PATH


