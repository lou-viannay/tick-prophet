# FROM ubuntu:18.04
ARG PYTHON_VERSION=3.6-alpine
FROM python:${PYTHON_VERSION} as builder
ENV PYTHONUNBUFFERED 1

ARG DEBIAN_FRONTEND=noninteractive
RUN apk add --no-cache \
    --upgrade \
    alpine-sdk \
    zlib-dev \
    jpeg-dev \
    musl-dev \
    py-pip \
    cython \
    wget
WORKDIR /wheels

RUN python -m pip install --upgrade pip 
# fbprophet fails if we just build wheel, install first, then build wheel
RUN python -m pip install fbprophet
RUN python -m pip wheel fbprophet pytk

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
RUN apk add --no-cache \
            --upgrade  \
            zlib \
            jpeg \
            musl \
            py-pip \
            libstdc++ \
    && rm -rf /var/cache/apk/*


COPY --from=builder /wheels /wheels
RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir \
                 -f /wheels fbprophet pandas numpy protobuf kapacitor_udf pytk \
    && rm -rf /wheels
# RUN echo "backend: TkAgg" > matplotlibrc
ADD prophet_udf.py /usr/bin/prophet_udf
WORKDIR /sample
ADD example_wp_log_peyton_manning.csv /sample
VOLUME /var/lib/prophet/

ENTRYPOINT ["python", "/usr/bin/prophet_udf", "/var/lib/prophet/prophet.sock"]
