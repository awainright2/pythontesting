# Intermediate Build Stage for ODBC dependencies
FROM ubuntu:20.04 as odbc-installation
RUN apt-get update && apt-get install -y unixodbc unixodbc-dev
#RUN apt-get update && apt-get install -y iodbc
# Execute dpkg-query to determine the installation path of libodbc.so.2 and store the result in a variable
SHELL ["/bin/bash", "-c"]
RUN odbc_lib_path=$(find / -name "libodbc.so.2" 2>/dev/null) && \
    echo "ODBC library path: $odbc_lib_path" && \
    echo "export LD_LIBRARY_PATH=$odbc_lib_path" >> /etc/profile  # Set LD_LIBRARY_PATH in /etc/profile for subsequent stages


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
COPY --from=odbc-installation /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu/libodbc.so.2
COPY --from=build-stage /python /python
COPY --from=build-stage /function /function
RUN chmod -R o+r /function
ENV PYTHONPATH=/function:/python
# Set the environment variable to include the directory containing libodbc.so.2
ENV LD_LIBRARY_PATH=$odbc_lib_path
RUN ldconfig
RUN echo "LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
ENTRYPOINT ["/python/bin/fdk", "/function/func.py", "handler"]