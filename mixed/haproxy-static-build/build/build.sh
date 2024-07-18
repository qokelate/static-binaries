#!/bin/zsh

yum install -y gcc pcre-static pcre-devel openssl-devel

curl -LOR 'http://www.haproxy.org/download/2.4/src/devel/haproxy-2.4-dev9.tar.gz'

tar -zxvf haproxy-*.tar.gz
cd haproxy-*

make TARGET=linux-glibc USE_OPENSSL=1 USE_ZLIB=1 USE_PCRE=1

make install
# /usr/local/sbin/haproxy -f haproxy.cfg

exit


