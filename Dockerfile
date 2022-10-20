
#
#  Louis Mamakos <louie@transsys.com>
#  Philipp Hellmich <phil@hellmi.de>
#
#  Build a container to run the edgetpu flask daemon
#
#    docker build -t coral .
#
#  Run it something like:
#
#  docker run --restart=always --detach --name coral \
#          -p 5000:5000 --device /dev/bus/usb:/dev/bus/usb   coral:latest
#  It's necessary to pass in the /dev/bus/usb device to communicate with the USB stick.
#
# OR pci-e
#
#  docker run --restart=always --detach --name coral \
#          -p 5000:5000 --device /dev/apex_0:/dev/apex_0   coral:latest
#
#
#  You can use alternative models by putting them into a directory
#  that's mounted in the container, and then starting the container,
#  passing in environment variables MODEL and LABELS referring to
#  the files.
FROM ubuntu:20.04

WORKDIR /tmp

RUN apt-get update && apt-get install -y gnupg
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

RUN echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list
RUN echo "deb https://packages.cloud.google.com/apt coral-cloud-stable main" | tee /etc/apt/sources.list.d/coral-cloud.list

RUN apt-get update && apt-get install -y python3 wget unzip python3-pip
RUN apt-get -y install python3-edgetpu libedgetpu1-legacy-std

# install the APP
RUN cd /tmp && \
    wget "https://github.com/robmarkcole/coral-pi-rest-server/archive/refs/tags/v1.0.zip" -O /tmp/server.zip && \
    unzip /tmp/server.zip && \
    rm -f /tmp/server.zip && \
    mv coral-pi-rest-server-1.0 /app



WORKDIR /app
RUN  pip3 install --no-cache-dir -r requirements.txt 

# Temporarily using my own code until https://github.com/robmarkcole/coral-pi-rest-server/issues/67 is resolved
RUN wget https://raw.githubusercontent.com/grinco/coral-pi-rest-server/v1.0/coral-app.py -O /app/coral-app.py
RUN ln -s /dev/stderr coral.log 

ENV MODEL=ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite \
    LABELS=coco_labels.txt \
    MODELS_DIRECTORY=models

EXPOSE 5000

# CMD  exec python3 coral-app.py --model  "${MODEL}" --labels "${LABELS}" --models_directory "${MODELS_DIRECTORY}"
CMD  exec python3 coral-app.py

