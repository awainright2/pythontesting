# Intermediate Build Stage for ODBC dependencies
FROM ubuntu:20.04 as odbc-installation
WORKDIR /odbcInstall
RUN  apt-get update &&  apt-get install -y --no-install-recommends unixodbc-dev && chmod -R +x /usr/lib/x86_64-linux-gnu/
RUN odbcinst -j
RUN chmod -R +x /etc
RUN chmod 766 /etc/passwd
ADD . /odbcInstall/
#RUN cd /etc && pwd && ls cat odbcinst.ini

#RUN odbc_lib_path=$(find / -name "libltdl.so.7" 2>/dev/null) && echo "Path: $odbc_lib_path"
# Execute dpkg-query to determine the installation path of libodbc.so.2 and store the result in a variable
#SHELL ["/bin/bash", "-c"]
#RUN odbc_lib_path=$(find / -name "libodbc.so.2" 2>/dev/null) && echo "ODBC library path1: $odbc_lib_path" && echo "export ODBC_LIB_PATH=$odbc_lib_path" >> /root/odbc_env.sh
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*



# Build Stage
FROM fnproject/python:3.11-dev as build-stage
WORKDIR /function
ADD requirements.txt /function/
RUN pip3 install --target /python/ --no-cache --no-cache-dir -r requirements.txt && \
    rm -fr ~/.cache/pip /tmp* requirements.txt func.yaml Dockerfile .venv && \
    chmod -R o+r /python
ADD . /function/
RUN rm -fr /function/.pip_cache

# Final Image
FROM fnproject/python:3.11
WORKDIR /function
COPY --from=odbc-installation /usr/lib/x86_64-linux-gnu/libodbc.so.2 /usr/lib/x86_64-linux-gnu/
COPY --from=odbc-installation /usr/lib/x86_64-linux-gnu/libltdl.so.7 /usr/lib/x86_64-linux-gnu/
COPY --from=odbc-installation /odbcInstall /odbcInstall
#COPY  --from=odbc-installation /root/odbc_env.sh /root/odbc_env.sh
COPY --from=build-stage /python /python
COPY --from=build-stage /function /function
RUN chmod -R o+r /function
RUN chmod -R o+r /odbcInstall
ENV PYTHONPATH=/function:/python
# Set the environment variable to include the directory containing libodbc.so.2
#ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
# Source the ODBC library path from the intermediate stage
# Source the ODBC library path from the intermediate stage
#RUN . /root/odbc_env.sh && export LD_LIBRARY_PATH=$ODBC_LIB_PATH && echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH" >> /etc/environment
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/
RUN ldconfig
RUN echo "default:x:$uid:0:user for openshift:/tmp:/bin/bash" >> /etc/passwd
ENTRYPOINT ["/python/bin/fdk", "/function/func.py", "handler",""]
