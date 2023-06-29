FROM ubuntu:latest as base

#Add necessary files to image
ADD binutils-2.40.tar.gz /root/src/
ADD gcc-10.2.0.tar.gz /root/src/

FROM base as dep

RUN apt-get update && apt-get upgrade; \
apt-get -y install \
make \
build-essential \
nasm \
bison \
flex \
mpc \
libgmp3-dev \
libmpc-dev \
libmpfr-dev \
texinfo \
libgmp-dev \
libisl-dev \
grub2 \
xorriso

FROM dep as compile
#Preparation
ENV PREFIX $HOME/opt/cross
ENV TARGET i686-elf
ENV PATH $PREFIX/bin:$PATH

#Binutils
RUN echo Building binutils \
&& cd $HOME/src \
&& mkdir build-binutils \
&& cd build-binutils \
&& ../binutils-2.40/configure --target=$TARGET --prefix="$PREFIX" --with-sysroot --disable-nls --disable-werror \
&& make \
&& make install

# #GCC
# The $PREFIX/bin dir _must_ be in the PATH. We did that above.
FROM compile as compile1
RUN cd $HOME/src \
&& which -- $TARGET-as || echo $TARGET-as is not in the PATH \
&& mkdir build-gcc \
&& cd build-gcc \
&& ../gcc-10.2.0/configure --target=$TARGET --prefix="$PREFIX" --disable-nls --enable-languages=c,c++ --without-headers \
&& make all-gcc -j8 \
&& make all-target-libgcc -j8 \
&& make install-gcc -j8 \
&& make install-target-libgcc -j8

# RUN echo Removing source files... \
# rm -rf /root/src