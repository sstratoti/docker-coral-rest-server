
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

RUN apt-get update && apt-get install -y gnupg curl 
RUN apt-get update && apt-get install -y wget unzip python3
RUN apt-get update && apt-get install -y python3-pip


RUN echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | tee /etc/apt/sources.list.d/coral-edgetpu.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

RUN apt-get update && apt-get install -y libedgetpu1-std python3-tflite-runtime python3-pycoral

RUN cd /tmp && \
    wget "https://github.com/robmarkcole/coral-pi-rest-server/archive/refs/tags/2.1.zip" -O /tmp/server.zip && \
    unzip /tmp/server.zip && \
    rm -f /tmp/server.zip && \
    mv coral-pi-rest-server-2.1 /app

RUN  pip3 install --no-cache-dir -r /app/requirements.txt

# fetch the models.  maybe figure a way to conditionalize this?
# create models subdirectory for volume mount of custom models
RUN  mkdir /models && \
     chdir /models && \
     curl -q -O  https://raw.githubusercontent.com/google-coral/test_data/master/tf2_ssd_mobilenet_v2_coco17_ptq_edgetpu.tflite  && \
     curl -q -O  https://raw.githubusercontent.com/google-coral/test_data/master/coco_labels.txt && \
     curl -q -O  https://raw.githubusercontent.com/google-coral/test_data/master/ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite


RUN echo 'SUBSYSTEM==\"apex\", MODE=\"0660\", GROUP=\"apex\"' >> /etc/udev/rules.d/65-apex.rules

RUN groupadd apex
RUN adduser root apex

WORKDIR /app
RUN ln -s /dev/stderr coral.log 

ENV MODEL=ssd_mobilenet_v2_coco_quant_postprocess_edgetpu.tflite \
    LABELS=coco_labels.txt \
    MODELS_DIRECTORY=models

EXPOSE 5000

# CMD  exec python3 coral-app.py --model  "${MODEL}" --labels "${LABELS}" --models_directory "${MODELS_DIRECTORY}"
CMD  exec python3 coral-app.py

