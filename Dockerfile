FROM ubuntu:18.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    apt-utils \
    python3-pip \
    python3-numpy \
    python3-pandas \
    python3-protobuf \
    cython3 \
    wget
RUN pip3 install pystan
RUN pip3 install ephem==3.7.5.3
RUN pip3 install fbprophet

# ENV KAPACITOR_VERSION 1.4.0
ENV KAPACITOR_VERSION 1.5.7
RUN wget https://dl.influxdata.com/kapacitor/releases/python-kapacitor_udf-${KAPACITOR_VERSION}.tar.gz && \
    tar -xvf python-kapacitor_udf-${KAPACITOR_VERSION}.tar.gz && \
    cd kapacitor_udf-${KAPACITOR_VERSION}/ && \
    python3 setup.py install && \
    cd ../ && \
    rm -rf python-kapacitor_udf-${KAPACITOR_VERSION}.tar.gz kapacitor_udf-${KAPACITOR_VERSION}/

ADD prophet_udf.py /usr/bin/prophet_udf
VOLUME /var/lib/prophet/

ENTRYPOINT ["/usr/bin/prophet_udf", "/var/lib/prophet/prophet.sock"]
