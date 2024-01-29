FROM rockylinux:9.3.20231119
RUN dnf -y update && dnf install -y epel-release && dnf config-manager --set-enabled crb && \
    dnf install -y unixODBC-devel gnupg && \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    curl https://packages.microsoft.com/config/rhel/8/prod.repo > /etc/yum.repos.d/mssql-release.repo && \
    ACCEPT_EULA=Y dnf install -y  msodbcsql17 mssql-tools && \
    dnf clean all
WORKDIR /function
ADD requirements.txt /function
RUN dnf install -y python-devel
RUN pip3 install --target /python/ --no-cache-dir -r requirements.txt && \
    rm -fr ~/.cache/pip /tmp* requirements.txt func.yaml Dockerfile .venv && \
    chmod -R o+r /python
ADD . /function/
RUN rm -fr /.pip_cache && chmod -R o+r /etc && chmod -R o+r /usr && chmod -R o+r /function && chmod -R o+r /opt
WORKDIR /
#RUN ls && ls /opt/microsoft/msodbcsql17/lib64/
ENV LD_LIBRARY_PATH=/opt/microsoft/msodbcsql17/lib64/
ENV PYTHONPATH=/function:/python
ENV ODBCINI=etc/odbc.ini
ENV ODBCSYSINI=etc
#RUN ls /python/bin/
RUN sed -i 's/^network-host: false/network-host: true/g' /etc/runc/crio/crio.conf
RUN ldconfig
ENTRYPOINT ["/python/bin/fdk", "/function/func.py", "handler",""]