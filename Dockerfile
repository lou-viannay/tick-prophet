# FROM ubuntu:18.04
ARG PYTHON_VERSION=3.6.12
FROM python:${PYTHON_VERSION} as builder
ENV PYTHONUNBUFFERED 1

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update  \
    && apt-get install -y \
    apt-utils \
    python3-pip \
    wget
WORKDIR /wheels

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/local/bin/python python /usr/bin/python3 2 
    # && python3 -m pip wheel numpy==1.15.4 pandas protobuf pystan ephem==3.7.5.3 convertdate==2.1.2

RUN python -m pip install --upgrade pip 
# fbprophet fails if we just build wheel, install first, then build wheel
RUN python -m pip install fbprophet
RUN python -m pip wheel fbprophet

# ENV KAPACITOR_VERSION 1.4.0
ENV KAPACITOR_VERSION 1.5.7
RUN wget https://dl.influxdata.com/kapacitor/releases/python-kapacitor_udf-${KAPACITOR_VERSION}.tar.gz && \
    tar -xvf python-kapacitor_udf-${KAPACITOR_VERSION}.tar.gz && \
    cd kapacitor_udf-${KAPACITOR_VERSION}/ && \
    python setup.py bdist_wheel && \
    cp dist/kapacitor_udf-${KAPACITOR_VERSION}-*.whl /wheels && \
    cd .. && \
    rm -rf kapacitor_udf-${KAPACITOR_VERSION} && \
    rm python-kapacitor_udf-${KAPACITOR_VERSION}.tar.gz

FROM python:${PYTHON_VERSION}
ENV PYTHONUNBUFFERED 1
RUN apt-get update  \
    && apt-get install -y \
    python3-pip 

COPY --from=builder /wheels /wheels
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1 \
    && update-alternatives --install /usr/local/bin/python python /usr/bin/python3 2 
RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir \
                 -f /wheels  fbprophet pandas numpy protobuf kapacitor_udf \
    && rm -rf /wheels

ADD prophet_udf.py /usr/bin/prophet_udf
VOLUME /var/lib/prophet/

ENTRYPOINT ["python", "/usr/bin/prophet_udf", "/var/lib/prophet/prophet.sock"]
