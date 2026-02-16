extra_pkg=(
  7zip
)
#pacman -S --needed --noconfirm ${extra_pkg[@]}

export TZ=Asia/Shanghai
export RootDirectories=(
  home
  opt
  storage
  usr/etc
  usr/bin
  usr/lib
  usr/share
  usr/libexec
  usr/include
  usr/games
  usr/src
  usr/sbin
  usr/tmp
  usr/var
)
export meson_general_arg=(
  --buildtype=release
  --strip
  --prefix=/data/data/com.winlator/files/imagefs/usr
  --libdir=/data/data/com.winlator/files/imagefs/usr/lib
  --bindir=/data/data/com.winlator/files/imagefs/usr/bin
  --sysconfdir=/data/data/com.winlator/files/imagefs/etc
  --libexecdir=/data/data/com.winlator/files/imagefs/usr/libexec
  --localstatedir=/data/data/com.winlator/files/imagefs/var
  --datadir=/data/data/com.winlator/files/imagefs/usr/share
  --includedir=/data/data/com.winlator/files/imagefs/usr/include
  --sbindir=/data/data/com.winlator/files/imagefs/usr/sbin
)
apply_patch() {
  if [[ ! -d /tmp/patches ]]; then
    echo "pataches dir is not fonund!"
    exit 1
  fi
  if [[ -d /tmp/patches/$1/$2 ]]; then
    for i in `ls /tmp/patches/$1/$2`; do
      if ! patch -p1 < /tmp/patches/$1/$2/$i; then
        echo "Apply $i for $1/$2 failed"
        exit 1
      fi
    done
  else
    echo "No Version Patch files=>$1/$2"
  fi
}
patchelf_fix() {
  LD_RPATH=/data/data/com.winlator/files/imagefs/usr/lib
  LD_FILE=$LD_RPATH/ld-linux-aarch64.so.1
  find . -type f -exec file {} + | grep -E ":.*ELF" | cut -d: -f1 | while read -r elf_file; do
    echo "Patching $elf_file..."
    patchelf --set-rpath "$LD_RPATH" --set-interpreter "$LD_FILE" "$elf_file" || {
      echo "Failed to patch $elf_file" >&2
      continue
    }
  done
}
create_ver_txt() {
  cat >'/data/data/com.winlator/files/imagefs/_version_.txt' <<EOF
Output Date(UTC+8): $date
Version:
  xz=> $xzVer
  gstreamer=> $gstVer
  xkbcommon=> $xkbcommonVer
  mangohud=> $mangohudVer
  imagefs-tag=> $customTag
GitHub:
  [Waim908/rootfs-custom-winlator](https://github.com/Waim908/rootfs-custom-winlator)
GlibcMod:
  [moze30/rootfs-winlator-glibc](https://github.com/moze30/rootfs-winlator-glibc)
Others:
  [CN]任何修改的winlator第三方版本在分发时（非个人使用的分发版本）在内置此项目相关文件后务必声明此仓库链接在发布时或应用内以便于修复。
  [EN]Any modified third-party versions of Winlator distributed (i.e., distribution versions not for personal use) must declare the link to this repository upon release or within the application after incorporating files related to this project, in order to facilitate fixes.
License:
  MIT License

  Copyright (c) 2025 Waim908

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
EOF
}

################
# Compile Args #
################

# 使用O2是为了稳定性和性能的平衡

export CFLAGS="-O2 -march=armv8-a -mtune=generic -flto=auto"
export CXXFLAGS="-O2 -march=armv8-a -mtune=generic -flto=auto"
export LDFLAGS="-O2 -flto=auto -s"

if [[ ! -f /tmp/init.sh ]]; then
  exit 1
else
  cat /tmp/init.sh
  source /tmp/init.sh
fi
pacman -R --noconfirm flac lame
create_imagefs_dir() {
  mkdir -p /data/data/com.winlator/files/imagefs/
  nowPath=$(pwd)
  imagefsDir=/data/data/com.winlator/files/imagefs/
  for i in ${!RootDirectories[@]}; do
    mkdir -p $imagefsDir/${RootDirectories[i]}
  done
  cd $imagefsDir
  ln -sf usr/bin
  ln -sf usr/lib
  ln -sf usr/etc
  ln -sf usr/tmp
  ln -sf usr/var

  cd $nowPath
}
create_imagefs_dir
cd /tmp
if ! wget https://github.com/moze30/rootfs-winlator-glibc/releases/download/rootfs-ori-7.1.5/imagefs.txz; then
  exit 1
fi
#tar -xf imagefs.txz -C /data/data/com.winlator/files/imagefs/
#tar -xf data.tar.xz -C /data/data/com.winlator/files/imagefs/
#tar -xf tzdata-*-.pkg.tar.xz -C /data/data/com.winlator/files/imagefs/
cd /data/data/com.winlator/files/imagefs/etc
mkdir ca-certificates
cd ca-certificates
if ! wget https://curl.haxx.se/ca/cacert.pem; then
  exit 1
fi
cd /tmp
#git clone https://github.com/xiph/flac.git flac-src
if ! git clone -b $xzVer https://github.com/tukaani-project/xz.git xz-src; then
  exit 1
fi
#git clone https://github.com/xiph/opus.git opus-src
if ! git clone -b $gstVer https://github.com/GStreamer/gstreamer.git gst-src; then
  exit 1
fi

git clone -b $xkbcommonVer https://github.com/xkbcommon/libxkbcommon.git xkbcommon-src || exit 1

if [[ ! $mangohudVer == cmod ]]; then
  git clone -b $mangohudVer https://github.com/flightlessmango/MangoHud.git mangohud-src || exit 1
else
  echo "Use Winlator Glibc mangohud"
fi

git clone -b $flacVer https://github.com/xiph/flac.git flac-src || exit 1

pip install mako --break-system-package

cd /tmp/xkbcommon-src

meson setup builddir ${meson_general_arg[@]} \
  -Dbash-completion-path=false \
  -Denable-xkbregistry=false \
  -Denable-wayland=false \
  -Denable-tools=false \
  -Denable-bash-completion=false || exit 1
meson compile -C builddir || exit 1
meson install -C builddir

if [[ ! $mangohudVer == cmod ]]; then
  cd /tmp/mangohud-src
  apply_patch mangohud $mangohudVer

  meson setup builddir ${meson_general_arg[@]} \
    -Ddynamic_string_tokens=false \
    -Dwith_xnvctrl=disabled \
    -Dwith_wayland=disabled \
    -Dwith_nvml=disabled \
    -Dinclude_doc=false || exit 1
  meson compile -C builddir || exit 1
  meson install -C builddir
else
  if [[ -f /tmp/mangohud.tar.xz ]]; then
    tar xf /tmp/mangohud.tar.xz -C /data/data/com.winlator/files/imagefs/ || exit 1
  else
    echo "/tmp/mangohud.tar.xz No such file"
    exit 1
  fi
fi
# Build
echo "Build and Compile xz(liblzma)"
cd /tmp/xz-src
./autogen.sh
mkdir build
cd build
if ! ../configure --prefix=/data/data/com.winlator/files/imagefs/usr; then
  exit 1
fi
if ! make -j$(nproc); then
  exit 1
fi
make install

# mp3lame https://sourceforge.net/projects/lame/files/latest/download

#cd /tmp/lame-3.100
#./configure --prefix=/data/data/com.winlator/files/imagefs/usr/ || exit 1
#make -j$(nproc) || exit 1
#make install
#
# FLAC

cd /tmp/flac-src
if ! ./autogen.sh; then
  exit 1
fi
if ! ./configure --prefix=/data/data/com.winlator/files/imagefs/usr/; then
  exit 1
fi
if ! make -j$(nproc); then
  exit 1
fi
make install

# (removed vorbis section)

cd /tmp/gst-src
echo "Build and Compile gstreamer"
meson setup builddir ${meson_general_arg[@]} \
  -Dgst-full-target-type=shared_library \
  -Dintrospection=disabled \
  -Dgst-full-libraries=app,video,player \
  -Dbase=enabled \
  -Dgood=enabled \
  -Dbad=enabled \
  -Dugly=enabled \
  -Dlibav=enabled \
  -Dtests=disabled \
  -Dexamples=disabled \
  -Ddoc=disabled \
  -Dges=disabled \
  -Dpython=disabled \
  -Ddevtools=disabled \
  -Dgstreamer:check=disabled \
  -Dgstreamer:benchmarks=disabled \
  -Dgstreamer:libunwind=disabled \
  -Dgstreamer:libdw=disabled \
  -Dgstreamer:bash-completion=disabled \
  -Dgst-plugins-good:cairo=disabled \
  -Dgst-plugins-good:gdk-pixbuf=disabled \
  -Dgst-plugins-good:oss=disabled \
  -Dgst-plugins-good:oss4=disabled \
  -Dgst-plugins-good:v4l2=disabled \
  -Dgst-plugins-good:aalib=disabled \
  -Dgst-plugins-good:jack=disabled \
  -Dgst-plugins-good:pulse=enabled \
  -Dgst-plugins-good:adaptivedemux2=disabled \
  -Dgst-plugins-good:v4l2=disabled \
  -Dgst-plugins-good:libcaca=disabled \
  -Dgst-plugins-good:mpg123=enabled \
  -Dgst-plugins-base:examples=disabled \
  -Dgst-plugins-base:alsa=enabled \
  -Dgst-plugins-base:pango=disabled \
  -Dgst-plugins-base:x11=enabled \
  -Dgst-plugins-base:gl=disabled \
  -Dgst-plugins-base:opus=disabled \
  -Dgst-plugins-bad:androidmedia=disabled \
  -Dgst-plugins-bad:rtmp=disabled \
  -Dgst-plugins-bad:shm=disabled \
  -Dgst-plugins-bad:zbar=disabled \
  -Dgst-plugins-bad:webp=disabled \
  -Dgst-plugins-bad:kms=disabled \
  -Dgst-plugins-bad:vulkan=disabled \
  -Dgst-plugins-bad:dash=disabled \
  -Dgst-plugins-bad:analyticsoverlay=disabled \
  -Dgst-plugins-bad:nvcodec=disabled \
  -Dgst-plugins-bad:uvch264=disabled \
  -Dgst-plugins-bad:v4l2codecs=disabled \
  -Dgst-plugins-bad:udev=disabled \
  -Dgst-plugins-bad:libde265=disabled \
  -Dgst-plugins-bad:smoothstreaming=disabled \
  -Dgst-plugins-bad:fluidsynth=disabled \
  -Dgst-plugins-bad:inter=disabled \
  -Dgst-plugins-bad:x11=enabled \
  -Dgst-plugins-bad:gl=disabled \
  -Dgst-plugins-bad:wayland=disabled \
  -Dgst-plugins-bad:openh264=disabled \
  -Dgst-plugins-bad:hip=disabled \
  -Dgst-plugins-bad:aja=disabled \
  -Dgst-plugins-bad:aes=disabled \
  -Dgst-plugins-bad:dtls=disabled \
  -Dgst-plugins-bad:hls=disabled \
  -Dgst-plugins-bad:curl=disabled \
  -Dgst-plugins-bad:opus=disabled \
  -Dgst-plugins-bad:webrtc=disabled \
  -Dgst-plugins-bad:webrtcdsp=disabled \
  -Dpackage-origin="[rootfs-custom-winlator](https://github.com/Waim908/rootfs-custom-winlator)" || exit 1
if [[ ! -d builddir ]]; then
  exit 1
fi
if ! meson compile -C builddir; then
  exit 1
fi
meson install -C builddir
export date=$(TZ=Asia/Shanghai date '+%Y-%m-%d %H:%M:%S')
# package
echo "Package"
mkdir /tmp/output
cd /data/data/com.winlator/files/imagefs/
patchelf_fix
##############
create_ver_txt
##############
if ! tar -I 'xz -T$(nproc) -9' -cf /tmp/output/output-lite-${customTag}.tar.xz .; then
  exit 1
fi

cd /tmp

#tar -xf data.tar.xz -C /data/data/com.winlator/files/imagefs/
tar -xf tzdata-2025b-1-aarch64.pkg.tar.xz -C /data/data/com.winlator/files/imagefs/
#if [[ -d fonts ]]; then
#  cp -r -p fonts /data/data/com.winlator/files/imagefs/usr/share
#else
#  echo "fonts no such dir"
#fi
#
#########
# Extra #
#########

if [[ -d extra ]]; then
  cp -r -p extra /data/data/com.winlator/files/imagefs/
else
  echo "extra no such dir"
fi
if [[ $installAddons == 1 ]]; then
  if [[ -d extra-res ]]; then
    cp -r -p extra-res /data/data/com.winlator/files/imagefs/
    cd /data/data/com.winlator/files/imagefs/extra-res/
    # 10.3.0 https://github.com/wine-mono/wine-mono/releases/download/wine-mono-10.3.0/wine-mono-10.3.0-x86.msi
    wget https://github.com/wine-mono/wine-mono/releases/download/wine-mono-${monoVer}/wine-mono-${monoVer}-x86.msi || exit 1
    # https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
    wget https://dl.winehq.org/wine/wine-gecko/${geckoVer}/wine-gecko-${geckoVer}-x86.msi
    wget https://dl.winehq.org/wine/wine-gecko/${geckoVer}/wine-gecko-${geckoVer}-x86_64.msi
  else
    echo "extra-res no such dir"
    exit 1
  fi
else
  if [[ -d extra-res ]]; then
    cp -r -p extra-res /data/data/com.winlator/files/imagefs/
  else
    echo "extra-res no such dir"
    exit 1
  fi
fi

cd /data/data/com.winlator/files/imagefs/
#create_ver_txt
if ! tar -I 'xz -T$(nproc) -9' -cf /tmp/output/output-full-${customTag}.tar.xz .; then
  exit 1
fi
cd /tmp
rm -rf /data/data/com.winlator/files/imagefs/
create_imagefs_dir
tar -xf imagefs.txz -C /data/data/com.winlator/files/imagefs/
cd /data/data/com.winlator/files/imagefs/
rm -rf /data/data/com.winlator/files/imagefs/lib/libgst*
rm -rf /data/data/com.winlator/files/imagefs/lib/gstreamer-1.0
tar -xf /tmp/output/output-full-${customTag}.tar.xz -C /data/data/com.winlator/files/imagefs/
#create_ver_txt
if ! tar -I 'xz -T$(nproc) -9' -cf /tmp/output/imagefs-${customTag}.txz .; then
  exit 1
fi
