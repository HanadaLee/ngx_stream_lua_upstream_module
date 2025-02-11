ARG REDHAT_UBI_IMAGE_TAG=9.4-1194
ARG OPENRESTY_VERSION=1.21.4.3

FROM registry.access.redhat.com/ubi9/ubi-minimal:${REDHAT_UBI_IMAGE_TAG} AS openresty

ARG OPENRESTY_VERSION

RUN curl -s https://openresty.org/package/rhel/openresty2.repo -o /etc/yum.repos.d/openresty.repo && \
    rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm && \
    microdnf install -y glibc supervisor make gcc cpp git unzip ccache && \
    microdnf install --enablerepo=openresty -y openresty-${OPENRESTY_VERSION} openresty-openssl111 openresty-openssl111-devel openresty-zlib openresty-pcre openresty-openssl111-devel openresty-zlib-devel openresty-pcre-devel \
    openresty-opm-${OPENRESTY_VERSION} \
    openresty-pcre \
    openresty-pcre-devel \
    openresty-openssl3 \
    openresty-openssl3-devel \
    openresty-valgrind \
    openresty-zlib \
    openresty-zlib-devel && \
    microdnf clean all

RUN git clone https://github.com/openresty/openresty-devel-utils.git /usr/local/openresty-devel-utils && \
    chmod +x /usr/local/openresty-devel-utils/ngx-* && \
    ln -s /usr/local/openresty-devel-utils/ngx-* /usr/local/bin/ && \
    rm -rf /var/cache/yum /var/cache/dnf

ENV NGX_BUILD_DTRACE=1 \
    NGX_BUILD_CC_OPTS="-O1 -I/opt/systemtap/include" \
    LUAJIT=/usr/local/openresty-debug/luajit \
    LUAJIT_LIB=/usr/local/openresty-debug/luajit/lib \
    LUAJIT_INC=/usr/local/openresty-debug/luajit/include/luajit-2.1 \
    PCRE=/usr/local/openresty/pcre \
    PCRE_LIB=/usr/local/openresty/pcre/lib \
    PCRE_INC=/usr/local/openresty/pcre/include \
    OPENSSL=/usr/local/openresty-debug/openssl \
    OPENSSL_INC=/usr/local/openresty-debug/openssl/include \
    OPENSSL_LIB=/usr/local/openresty-debug/openssl/lib \
    NGX_BUILD_CC="gcc" \
    NGX_BUILD_JOBS=9 \
    OPENRESTY_SRC_ROOT=/usr/local/openresty-src \
    OPENRESTY_BUILD_TOOLS=/usr/local/openresty-devel-utils \
    MODULE_SRC_ROOT=/usr/local/openresty-module-src/ \
    PATH="/usr/local/openresty-devel-utils:$PATH"

RUN mkdir -p ${OPENRESTY_SRC_ROOT} ${MODULE_SRC_ROOT}
RUN curl -fSL https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz -o /tmp/openresty.tar.gz && \
    tar -xzf /tmp/openresty.tar.gz -C ${OPENRESTY_SRC_ROOT} --strip-components=1 && \
    rm -rf /tmp/openresty.tar.gz

ENV PCRE_VERSION=8.45
ENV OPENSSL_VERSION=3.1.3
ENV ZLIB_VERSION=1.3.1


RUN mkdir -p /usr/local/src
RUN cd /usr/local/src && \
    curl -fSL https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz/download -o pcre.tar.gz && \
    tar -xzf pcre.tar.gz && \
    cd pcre-${PCRE_VERSION}

RUN cd /usr/local/src && \
    curl -fSL https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -o openssl.tar.gz && \
    tar -xzf openssl.tar.gz

RUN cd /usr/local/src && \
    curl -fSL https://www.zlib.net/zlib-${ZLIB_VERSION}.tar.gz -o zlib.tar.gz && \
    tar -xzf zlib.tar.gz

WORKDIR ${OPENRESTY_SRC_ROOT}


# COPY . ${MODULE_SRC_ROOT}

# RUN ./configure --with-compat \
#                 --with-pcre="/usr/local/src/pcre-${PCRE_VERSION}" \
#                 --with-openssl="/usr/local/src/openssl-${OPENSSL_VERSION}" \
#                 --with-zlib="/usr/local/src/zlib-${ZLIB_VERSION}" \
#                 --without-mail_pop3_module \
#                 --without-mail_imap_module \
#                 --without-mail_smtp_module \
#                 --without-http_upstream_ip_hash_module \
#                 --without-http_empty_gif_module \
#                 --without-http_referer_module \
#                 --without-http_autoindex_module \
#                 --without-http_auth_basic_module \
#                 --without-http_userid_module \
#                 --add-dynamic-module=${MODULE_SRC_ROOT} && \
                # make
