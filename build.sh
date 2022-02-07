#!/bin/bash

# author:  Raymond Burkholder
# email:   ray@oneunified.net
#          raymond@burkholder.net

# started: 2016/07/16

# designed for debian buster/bullseye

# todo:
#   optional verbose
#   optional clean up / removal of old source

boost_ver='1.77.0'
boost_ver_us=${boost_ver//\./_}
boost_tar="boost_${boost_ver_us}.tar.gz"
boost_dir="boost_${boost_ver_us}"

function obtain_boost {

  echo obtaining boost ...

  if [ -e ${boost_tar} ]
    then echo boost archive exists
    else
      echo downloading ${boost_tar} ...
      wget http://downloads.sourceforge.net/project/boost/boost/${boost_ver}/${boost_tar}
      fi

  if [ -d ${boost_dir} ]
    then echo ${boost_dir} archive already expanded
    else
      tar zxvf ${boost_tar}
      pushd ${boost_dir}
      ./bootstrap.sh
      popd
      fi

  }

function build_boost {

  #bjam install --toolset=gcc --prefix=/usr/local --layout=tagged variant=debug threading=multi link=static 
  #./b2 --layout=versioned toolset=gcc variant=debug \
  #  link=shared threading=multi runtime-link=shared address-model=64 stage

  echo 'building boost (needs root priv to install)'

  pushd ${boost_dir}
  sudo ./b2 --layout=versioned toolset=gcc cxxflags=-std=gnu++17 variant=release link=shared threading=multi runtime-link=shared address-model=64 -j2 install
  #sudo ./b2 --layout=tagged toolset=gcc variant=release link=shared threading=multi runtime-link=shared address-model=64 -j2 install
  if [ -h /usr/local/include/boost ]
    then sudo rm /usr/local/include/boost
    fi
  sudo ln -s /usr/local/include/boost-${boost_ver_us:0:4}/boost /usr/local/include/boost
  sudo ldconfig
  popd

  }

wxwidgets_ver='3.0.5'
wxwidgets_name="wxWidgets-${wxwidgets_ver}"
wxwidgets_tar="${wxwidgets_name}.tar"
wxwidgets_bz2="${wxwidgets_tar}.bz2"

function obtain_wxwidgets {

  echo obtaining wxwidgets ...

  sudo apt-get -y install bzip2

  if [ -e ${wxwidgets_bz2} ]
    then echo ${wxwidgets_bz2} exists
    else
      echo downloading ${wxwidgets_bz2} ...
      wget https://github.com/wxWidgets/wxWidgets/releases/download/v${wxwidgets_ver}/${wxwidgets_bz2}
      fi

  if [ -e ${wxwidgets_tar} ]
    then echo ${wxwidgets_tar} exists
    else  
      bzip2 -k -d ${wxwidgets_bz2}
      fi

  if [ -d ${wxwidgets_name} ]
    then echo ${wxwidgets_name} exists
    else
      tar xvf ${wxwidgets_tar}
      # note this applies to wxwidgets 3.0.2 where an older scintilla is included, recent versions are fixed
      sed -i 's/(abs(pt1/(std::abs(pt1/g' ${wxwidgets_name}/src/stc/scintilla/src/Editor.cxx
      sed -i '/include <string>/i #include <cmath>' ${wxwidgets_name}/src/stc/scintilla/src/Editor.cxx
      fi

  }

function build_wxwidgets {

  echo building wxwidgets ...

  if [ -d ${wxwidgets_name} ]
    then
      pushd ${wxwidgets_name}
      mkdir buildNormal
      cd buildNormal
      ../configure --enable-threads --with-gtk=3 --enable-stl --with-opengl --with-libpng CXXFLAGS=-Ofast
      make
      sudo make install
      sudo ldconfig
      # use sudo ldconfig -p to see which are installed
      popd
    else echo ${wxwidgets_name} does not exist, no build 
      fi

  }

glm_ver='0.9.7.6'
glm_name="glm-${glm_ver}"
glm_zip="${glm_name}.zip"

function install_glm {

  echo obtaining ${glm_name} ...

  sudo apt-get -y install unzip
  
  if [ -e ${glm_zip} ]
    then echo ${glm_zip} exists
    else
      wget https://github.com/g-truc/glm/releases/download/${glm_ver}/${glm_zip}
      fi

  if [ -d glm ] 
    then 
      rm -rf glm
      fi

  unzip ${glm_zip}

  glm_dest_dir='/usr/local/include/glm'

  if [ -d ${glm_dest_dir} ]
    then
      echo removing previous ${glm_dest_dir}
      sudo rm -rf ${glm_dest_dir}
      fi

  echo moving glm headers to ${glm_dest_dir}  
  sudo mv glm/glm /usr/local/include/
  sudo chown root.staff ${glm_dest_dir}

  }

function multimedia_libs {
  #sudo apt-get -y install ffmpeg-doc ffmpeg-dbg \
  sudo apt-get -y install ffmpeg ffmpeg-doc \
         libavcodec-dev libavformat-dev libavresample-dev libavutil-dev \
         libpostproc-dev libswresample-dev libswscale-dev libavfilter-dev libavdevice-dev

  sudo apt-get -y install  librtaudio4v5  librtaudio-dev

  sudo apt-get -y install libopenal-data libopenal1  libopenal1-dbg  libopenal-dev
  }

szip_ver="2.1.1"
szip_name="szip-${szip_ver}"
szip_arc="${szip_name}.tar.gz"
szip_lib="/usr/local/lib/libsz.a"

function build_szip {

  if [ -e ${szip_arc} ]
    then echo ${szip_arc} exists
    else 
      wget https://www.hdfgroup.org/ftp/lib-external/szip/${szip_ver}/src/${szip_arc}
      fi

  if [ -d ${szip_name} ]
    then echo directory ${szip_name} exists
    else
      tar zxvf ${szip_arc}
      fi
  
  if [ -e ${szip_lib} ]
    then echo ${szip_lib} exists
    else 
      
      pushd ${szip_name}
      ./configure  --prefix=/usr/local --enable-production
      make
      sudo make install
      popd
      fi

  }

zlib_ver="1.2.11"
zlib_name="zlib-${zlib_ver}"
zlib_arc="${zlib_name}.tar.gz"

function build_zlib {

  if [ "1" == "${clean}" ]; then
    if [ -d ${zlib_name} ]; then
      pushd ${zlib_name}
      make clean
      sudo make uninstall
      popd
      fi
    rm ${zlib_arc}
    rm -rf ${zlib_name}
    fi
  
  if [ -e ${zlib_arc} ]
    then echo ${zlib_arc} exists
    else
      wget http://zlib.net/${zlib_arc}
      fi

  if [ -d ${zlib_name} ]
    then echo ${zlib_name} exists
    else
      tar zxvf ${zlib_arc}
      fi

  pushd ${zlib_name}

  if [ -d ioapi_mem ]
    then echo ${zlib_name} is cloned
    else
  
      sudo rm -rf /usr/local/include/zlib

      git clone https://github.com/rburkholder/ioapi_mem.git 

      ln -s ioapi_mem/ioapi_mem.c ioapi_mem.c
      ln -s ioapi_mem/ioapi_mem.h ioapi_mem.h
    
      ln -s contrib/minizip/unzip.c unzip.c
      ln -s contrib/minizip/unzip.h unzip.h
      ln -s contrib/minizip/ioapi.c ioapi.c
      ln -s contrib/minizip/ioapi.h ioapi.h
      
      cp Makefile.in Makefile.in.original
      sed -i "s/zutil.o$/zutil.o ioapi.o ioapi_mem.o unzip.o/" Makefile.in
      sed -i "s/zutil.lo$/zutil.lo ioapi.lo ioapi_mem.lo unzip.lo/" Makefile.in
      
      for name in "unzip" "ioapi" "ioapi_mem"; do 
	      echo " " >> Makefile.in
	      echo "${name}.lo: \$(SRCDIR)${name}.c" >> Makefile.in
	      echo "	-@mkdir objs 2>/dev/null || test -d objs" >> Makefile.in
	      echo "	\$(CC) \$(SFLAGS) \$(ZINC) -DPIC -c -o objs/${name}.o \$(SRCDIR)${name}.c" >> Makefile.in
	      echo "	-@mv objs/${name}.o \$@" >> Makefile.in
      done

      #./configure --64 --static --prefix=/usr/local --includedir=/usr/local/include/zlib
      ./configure --64 --prefix=/usr/local --includedir=/usr/local/include/zlib
      make
      sudo make install
      
      sudo cp ioapi.h /usr/local/include/zlib/
      sudo cp ioapi_mem.h /usr/local/include/zlib/
      sudo cp unzip.h /usr/local/include/zlib/

      sudo ldconfig
      # to look at symbol table:
      # readelf -Ws /usr/local/lib/libz.a | grep unz

      fi
      
  popd
  
  }

#hdf5_ver="1.8.21"
hdf5_ver="1.10.5"
hdf5_name="hdf5-${hdf5_ver}"
hdf5_arc="${hdf5_name}.tar.gz"

# an example cmake based build which could be evaluated in a subsequent iteration
#  may have some build issues though
#cmake .. -DCMAKE_INSTALL_PREFIX=${prefix} \
#    -DCMAKE_TOOLCHAIN_FILE=${CMAKE_TARGET_TOOLCHAIN} \
#    -DHDF5_BUILD_CPP_LIB=OFF \
#    -DONLY_SHARED_LIBS=ON \
#    -DHDF5_BUILD_HL_LIB=ON \
#    -DHDF5_ENABLE_Z_LIB_SUPPORT=ON \
#    -DHDF5_ENABLE_SZIP_SUPPORT=OFF \
#    -DHDF5_ENABLE_SZIP_ENCODING=OFF \
#    -DBUILD_TESTING=OFF

function build_hdf5 {

  if [ -e ${hdf5_arc} ]
    then echo ${hdf5_arc} exists
    else
#      wget http://www.hdfgroup.org/ftp/HDF5/current18/src/${hdf5_arc}
      wget https://support.hdfgroup.org/ftp/HDF5/current/src/${hdf5_arc}
      fi

  if [ -d ${hdf5_name} ]
    then echo ${hdf5_name} already expanded
    else 
      tar zxvf ${hdf5_arc}
      fi

  if [ -e /usr/local/lib/libhdf5.a ]
    then echo ${hdf5_name} libraries installed
    else

      pushd ${hdf5_name}

      mkdir buildDebug
      cd buildDebug
    
      export LD_LIBRARY_PATH=/usr/local/lib
      export CXXFLAGS=-std=c++17

      #../configure --prefix=/usr/local --enable-cxx --enable-shared --enable-static --enable-build-mode=production --enable-deprecated-symbols=yes --with-zlib --with-szlib --includedir=/usr/local/include/hdf5
      ../configure --prefix=/usr/local --enable-cxx --enable-shared --enable-static --enable-build-mode=production --with-zlib --with-szlib --includedir=/usr/local/include/hdf5
      #--enable-debug=all 
      make
      sudo make install
      sudo sed -i 's/<hdf5.h>/"hdf5.h"/' /usr/local/include/hdf5/H5Include.h

      popd
 
      fi

  }

function build_hdf5_set {

  build_szip
  build_zlib
  build_hdf5

  }

chartdir_arc="chartdir_cpp_linux_64.tar.gz"

function install_chartdir {

  if [ "1" == "${clean}" ]; then
    sudo rm /usr/local/lib/libchartdir*
    sudo rm -rf /usr/local/include/chartdir
    sudo rm -rf /usr/local/lib/fonts
    sudo rm -rf ChartDirector
#    rm ${chartdir_arc}
    fi

  if [ -e ${chartdir_arc} ]
    then echo ${chartdir_arc} exists
    else
      wget http://www.advsofteng.net/chartdir_cpp_linux_64.tar.gz
      fi

  if [ -d ChartDirector ]
    then echo directory ChartDirector exists
    else
      tar zxvf ${chartdir_arc}

      sudo chown -R root.staff ChartDirector/include
      sudo mv ChartDirector/include /usr/local/include/chartdir

      sudo chown -R root.staff ChartDirector/lib/*
      sudo mv ChartDirector/lib/* /usr/local/lib/

      fi


  }

function build_libharu {
  if [ -e libharu.tar.gz ]
    then echo libharu.tar.gz exists
    else
      wget https://github.com/libharu/libharu/tarball/master
      mv master libharu.tar.gz
      fi

  if [ -e /usr/local/lib/libhpdf.a ]
    then echo libhpdf.a exists
    else
      rm -rf libharu
      tar zxvf libharu.tar.gz

      # move as the expanded directory has a serial number attached
      mv `ls -Ad libharu-*` libharu
      pushd libharu
      ./buildconf.sh --force
      ./configure --with-zlib --with-ping
      make
      sudo make install

      popd
      fi
  }

function build_wt {

  if [ "1" == "${clean}" ]; then
    if [ -d wt ]; then 
      pushd wt
      if [ -d build ]; then
        pushd build
        make clean
        rm -rf /var/www/wt
        popd
        fi
      popd
      rm -rf wt
      fi
    fi

  if [ -d wt ]; then 
    echo wt exists
  else

    sudo apt-get -y --no-install-recommends install \
      zlib1g-dev \
      zlib1g \
      libbz2-dev \
      python-dev \
      libgraphviz-dev \
      libicu-dev \
      cmake \
      libgd-dev \
      libssl-dev \
      autoconf \
      libgraphicsmagick++1-dev \
      libpq-dev \
      libpango1.0-dev \
      liblzma-dev \
      imagemagick \
      libmagick++-dev \
      libglew-dev

    build_libharu

    git clone git://github.com/kdeforche/wt.git
    pushd wt
    mkdir build
    cd build
    cmake \
      -D CMAKE_BUILD_TYPE=Release \
      -D MULTI_THREADED=ON \
      -D RUNDIR=/var/www/wt \
      -D WEBUSER=www-data \
      -D WEBGROUP=www-data \
      -D BOOST_ROOT=/usr/local \
      -D BOOST_LIBRARYDIR=/usr/local/lib \
      -D BOOST_INCLUDEDIR=/usr/local/include/boost \
      -D SHARED_LIBS=ON \
      -D CONNECTOR_FCGI=OFF \
      -D CONNECTOR_HTTP=ON \
      -D USERLIB_PREFIX=lib \
      -D WT_BOOST_DISCOVERY=OFF \
      -D Boost_ARCHITECTURE=-x64 \
      -D CMAKE_CXX_COMPILER_ARCHITECTURE_ID=x64 \
      -D CMAKE_CXX_STANDARD=17 \
      -D Boost_USE_STATIC_LIBS=OFF \
      -D Boost_USE_STATIC_RUNTIME=OFF \
      -D CONFIGDIR=/etc/wt \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D WT_WRASTERIMAGE_IMPLEMENTATION=GraphicsMagick \
      ../

    make 
    sudo make install
    sudo mkdir -p /var/www/wt
    sudo ln -s /usr/local/share/Wt/resources /var/www/wt/resources
    
    popd
    fi

  }

function base {
  sudo apt-get -y install git build-essential g++ wget
  }

function zlib {
  build_zlib
  }

function boost {  

  echo ensure prerequisite packages are installed

  # I don't think the correct ICU library is installed, boost doesn't build icu
  sudo apt-get -y install \
    make \
    g++ \
    zlib1g-dev \
    zlib1g \
    libbz2-dev \
    python-dev \
    libicu-dev
 
  zlib
  obtain_boost
  build_boost
  }


function wx {

  sudo apt-get -y install libgtk-3-dev mesa-common-dev libglu1-mesa-dev
  sudo apt-get -y install libnotify-dev libjpeg62-turbo-dev libtiff5-dev
#wx_gtk3u_gl-3.1

  obtain_wxwidgets
  build_wxwidgets
  }

function hdf5 {
  build_hdf5_set
  }

function chartdir {
  install_chartdir
  }

function wt {
  build_wt
  }

function glm {
  install_glm
  }

function multimedia {
  multimedia_libs
  }

function libsodium {
   pushd
   git clone https://github.com/jedisct1/libsodium --branch stable
   cd libsodium/
   ./configure --with-pthreads
   make
   #make check
   sudo make install
   popd
  }

function cassandra {
  sudo apt -y install libuv1-dev libssl-dev libssl1.1
  git clone https://github.com/datastax/cpp-driver.git
  pushd cpp-driver
  mkdir build
  cd build
  cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCASS_USE_STD_ATOMIC=ON \
    -DCASS_USE_ZLIB=ON ..
#    -DCASS_BUILD_STATIC=ON \
#    -DCASS_USE_STATIC_LIBS=ON \
  make
  sudo make install
  popd
}

function vmime {
  git clone git://github.com/kisli/vmime
  pushd vmime
  mkdir build
  cd build
  sudo apt install libgsasl7-dev libgnutls30 libgnutls28-dev ninja-build
  cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..
  cmake --build .
  sudo ninja install
  popd
  }

function libnl {
  sudo apt install m4
  sudo apt install asciidoc source-highlight mscgen doxygen
  sudo apt install python-pygments python3-pygments
  git clone https://github.com/thom311/libnl.git
  pushd libnl
  ./autogen.sh
  ./configure
  make
  sudo make install
  cd doc
  make gendoc
  popd
  # libnl/doc/api/index.html for start of documentation
}

# CERN's ROOT Data Analysis Framework
function rdaf {

  sudo apt install \
    libxxhash-dev \
    libgsl-dev gsl-bin \
    libgl2ps-dev \
    libsqlite3-dev \
    libfftw3-dev \
    libcfitsio-dev \
    libgfal2-dev \
    libftgl-dev \
    davix-dev \
    libtbb-dev \
    libtorch-dev \
    libgraphviz-dev \
    libcaffe-dev

  if [ "1" == "${clean}" ] then
    rdaf_clean
    fi

  if [ -d rdaf ]
    then echo directory rdaf exists, perform pull instead
    else
      git clone --branch latest-stable https://github.com/root-project/root.git rdaf
      fi

  pushd rdaf
    mkdir _build _install
    cd _build
    # -DCMAKE_BUILD_TYPE=[Release|MinSizeRel|Debug|RelWithDebInfo|Optimized]
    cmake \
      -Dgnuinstall=ON \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local/rdaf \
      -DCMAKE_INSTALL_LIBDIR=/usr/local/lib/rdaf \
      -DCMAKE_INSTALL_INCLUDEDIR=/usr/local/include/rdaf \
      -DCMAKE_INSTALL_SYSCONFDIR=/usr/local/etc/rdaf \
      -DCMAKE_INSTALL_DATAROOTDIR=/usr/local/share \
      -DCMAKE_INSTALL_BINDIR=/usr/local/bin/rdaf \
      ..
    # cmake --build . --target install -- -j2
    cmake --build . -- -j2
    sudo cmake --build . --target install
    sudo echo "/usr/local/lib/rdaf" > /etc/ld.so.conf.d/rdaf.conf
    sudo ldconfig
  popd

}

rdaf_clean {
  sudo rm -rf /usr/local/include/rdaf
  sudo rm -rf /usr/local/lib/rdaf
  sudo rm -rf /usr/local/include/rdaf
  sudo rm -rf /usr/local/etc/rdaf
  sudo rm -rf /usr/local/share/root
  sudo rm -rf /usr/local/share/doc/root
  sudo rm -rf /usr/local/bin/rdaf
}

function deleteall {
  sudo rm /usr/local/lib/libboost*
  sudo rm /usr/local/lib/libchardir*
  sudo rm /usr/local/lib/libchartdir*
  sudo rm -rf /usr/local/lib/fonts
  sudo rm /usr/local/lib/libz*
  sudo rm -rf /usr/local/lib/pkgconfig
  sudo rm /usr/local/lib/libwx*
  sudo rm /usr/local/lib/libsz*
  sudo rm /usr/local/lib/libhdf5*
  sudo rm -rf /usr/local/lib/wx
  sudo rm -rf /usr/local/include/hdf5
  sudo rm -rf /usr/local/include/wx*
  sudo rm -rf /usr/local/include/boost*
  sudo rm -rf /usr/local/include/zlib
  sudo rm -rf /usr/local/include/chartdir
  sudo rm /usr/local/include/sz*
  sudo rm /usr/local/include/ricehdf*
  sudo rm /usr/local/bin/h5*
  sudo rm /usr/local/bin/wx*
  sudo rm -rf /usr/local/share/hdf5*
  sudo rm /usr/local/include/sodium
  sudo rm /usr/local/lib/libsodium*
  sudo rm -rf /usr/local/lib/libnl*
  sudo rm -rf /usr/local/include/libnl3

  rdaf_clean
  }

case "$2" in
  clean)
    clean="1"
    ;;
  esac

case "$1" in
  base)
    base
    ;;

  zlib)
    zlib
    ;;

  boost)
    boost
    ;;

  wx)
    wx
    ;;

  hdf5)
    hdf5
    ;;

  chartdir)
    chartdir
    ;;

  wt)
    wt
    ;;

  glm)
    glm
    ;;

  multimedia)
    multimedia
    ;;

  tradeframe)
    base
    sudo apt-get -y install libcurl4-openssl-dev libintelrdfpmath-dev gnulib
    boost
    wx
    hdf5
    chartdir
    ;;

  nodestar)
    base
    boost
    wt
    ;;

  simulant)
    multimedia
    glm
    ;;

  libsodium)
    base
    libsodium
    ;;

  cassandra)
    base
    cassandra
    ;;

  vmime)
    base
    vmime
    ;;

  libnl)
    base
    libnl
    ;;

  rdaf)
    base
    rdaf
    ;;

  *)
    printf "\nusage:  ./build.sh {base|boost|wx|glm|hdf5|chartdir|wt|zlib|multimedia|tradeframe|libsodium|cassandra|vmime|libnl|rdaf} [clean]\n\n"
    ;;
  esac



#  542  wget http://www.openal-soft.org/openal-releases/openal-soft-1.17.1.tar.bz2
#  544  cd t
#  552  bzip2 -d ../openal-soft-1.17.1.tar.bz2
#  555  tar xvf ../openal-soft-1.17.1.tar
#  557  cd openal-soft-1.17.1/
#  561  cd build/
#  571  apt-get install libpulse-dev
#  572  cmake ..
#  573  make
#  574  ./openal-info


