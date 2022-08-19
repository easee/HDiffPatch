# Use an old base image. Newer images are backwards compatible, but not the other way round...
FROM ubuntu:16.04 as base

# Update and install toolchain
RUN apt-get -y update && apt-get install -y
RUN apt-get -y install git make g++ libz-dev libbz2-dev

# Clone the code repository
FROM base as clone

WORKDIR /usr/src/
RUN git clone --depth 1 --branch v2.5.3 https://github.com/sisong/HDiffPatch.git

# The simplest make (from Gihub action in repo)
FROM clone as make_init

WORKDIR /usr/src/HDiffPatch
RUN git clone --depth 1 https://github.com/sisong/lzma.git ../lzma
RUN git clone --depth 1 https://github.com/sisong/libmd5.git ../libmd5
RUN make MT=1 MD5=1

# Another make (from Gihub action in repo)
FROM clone as make_un_def

WORKDIR /usr/src/HDiffPatch
RUN git clone --depth=1 https://github.com/sisong/libmd5.git ../libmd5
RUN git clone -b fix-make-build --depth=1 https://github.com/sisong/lzma.git ../lzma
RUN git clone -b v1.5.2 --depth=1 https://github.com/facebook/zstd.git ../zstd
RUN make DIR_DIFF=0 MT=0 BSD=0 ZLIB=0 BZIP2=0 -j

# Another make (from Gihub action in repo)
FROM clone as make_all

WORKDIR /usr/src/HDiffPatch
RUN make -j

# Another make (from Gihub action in repo)
FROM clone as make_by_code

WORKDIR /usr/src/HDiffPatch
RUN git clone --depth=1 https://github.com/sisong/libmd5.git ../libmd5
RUN git clone -b fix-make-build --depth=1 https://github.com/sisong/lzma.git ../lzma
RUN git clone -b v1.5.2 --depth=1 https://github.com/facebook/zstd.git ../zstd
RUN git clone --depth=1 https://github.com/sisong/zlib.git ../zlib
RUN git clone --depth=1 https://github.com/sisong/bzip2.git ../bzip2
RUN make ZLIB=1 BZIP2=1 -j

# This contains the docker image entry point (CMD).
# First build the image using "docker build -t hdiff --rm ."
# Then run a container to copy the artifacts to local disk using "docker run -v <localpath>:/usr/share2/ hdiff"
# Change the FROM statement to compile with another stage
FROM make_init as copy

WORKDIR /usr/src/HDiffPatch
RUN mkdir "/usr/share2"
CMD "cp" "/usr/src/HDiffPatch/hdiffz" "/usr/src/HDiffPatch/hpatchz" "/usr/share2/"