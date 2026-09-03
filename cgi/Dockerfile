FROM httpd:2.4

COPY index.html /usr/local/apache2/htdocs/index.html
COPY hello.cgi /usr/local/apache2/cgi-bin/hello.cgi

RUN sed -i 's/\r$//' /usr/local/apache2/cgi-bin/hello.cgi \
    && chmod +x /usr/local/apache2/cgi-bin/hello.cgi \
    && echo 'LoadModule cgid_module modules/mod_cgid.so' >> /usr/local/apache2/conf/httpd.conf \
    && echo 'ScriptAlias /cgi-bin/ /usr/local/apache2/cgi-bin/' >> /usr/local/apache2/conf/httpd.conf