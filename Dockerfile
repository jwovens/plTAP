FROM wnameless/oracle-xe-11g
MAINTAINER Jim Ovens

ENV ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
ENV ORACLE_SID=XE
ENV PATH=${ORACLE_HOME}/bin:${PATH}

COPY sqlplus sqlplus

ENTRYPOINT /usr/sbin/startup.sh && \
 sqlplus SYSTEM/oracle @sqlplus/sqlplus_install.sql pltap && \
 sqlplus SYSTEM/oracle @sqlplus/sqlplus_example.sql example_tap && \
 /usr/sbin/sshd -D


