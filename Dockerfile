# Intermediate Build Stage for ODBC dependencies
FROM ubuntu:20.04 as odbc-installation
RUN apt-get update && apt-get install -y --no-install-recommends unixodbc-dev && \
    chmod -R +x /usr/lib/x86_64-linux-gnu/ && \
    odbcinst -j && \
    chmod -R +x /etc

RUN apt-get install -y wget gnupg2 && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    echo "deb [arch=amd64] https://packages.microsoft.com/ubuntu/20.04/prod focal main" > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql17 && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools && \
    cd /opt/microsoft/msodbcsql17/lib64/ && ls && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install the ODBC driver for SQL Server and configure odbcinst.ini

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
COPY --from=odbc-installation /opt/microsoft/msodbcsql17/lib64/ /opt/microsoft/msodbcsql17/lib64/
COPY --from=odbc-installation /usr/bin/odbcinst /usr/bin/odbcinst
COPY --from=odbc-installation /etc/odbcinst.ini /etc/odbcinst.ini
COPY --from=odbc-installation /usr/lib/x86_64-linux-gnu/libodbcinst.so.2 /usr/lib/x86_64-linux-gnu/libodbcinst.so.2
RUN chmod -R +x /opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.10.so.5.1
COPY --from=build-stage /python /python
COPY --from=build-stage /function /function
RUN chmod -R o+r /function
ENV PYTHONPATH=/function:/python
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/
ENV ODBCINI=/etc/odbcint.ini
ENV ODBCSYSINI=/etc
RUN odbcinst -q -d
RUN ldconfig
ENTRYPOINT ["/python/bin/fdk", "/function/func.py", "handler",""]