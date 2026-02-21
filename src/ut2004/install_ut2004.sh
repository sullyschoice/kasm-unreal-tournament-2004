#!/usr/bin/env bash
set -ex
SCRIPT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"

apt-get update
apt-get install -y p7zip-full jq unshield coreutils

mkdir -p /opt/ut2004
wget https://raw.githubusercontent.com/OldUnreal/FullGameInstallers/master/Linux/install-ut2004.sh
chmod +x install-ut2004.sh

printf 'Y\n' | ./install-ut2004.sh -d /opt/ut2004/ --ui-mode=none

rm install-ut2004.sh

cat >/opt/ut2004/launch.sh <<EOL
#!/usr/bin/env bash
ARCH=\$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
if [ "\$ARCH" == "arm64" ] ; then
  export LD_LIBRARY_PATH=/opt/ut2004/SystemARM64:\$LD_LIBRARY_PATH
  if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting UT2004 with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /opt/ut2004/SystemARM64/UT2004 "\$@"
  else
      echo "Starting UT2004"
      /opt/ut2004/SystemARM64/UT2004 "\$@"
  fi
else
  export LD_LIBRARY_PATH=/opt/ut2004/System:\$LD_LIBRARY_PATH
  if [ -f /opt/VirtualGL/bin/vglrun ] && [ ! -z "\${KASM_EGL_CARD}" ] && [ ! -z "\${KASM_RENDERD}" ] && [ -O "\${KASM_RENDERD}" ] && [ -O "\${KASM_EGL_CARD}" ] ; then
    echo "Starting UT2004 with GPU Acceleration on EGL device \${KASM_EGL_CARD}"
    vglrun -d "\${KASM_EGL_CARD}" /opt/ut2004/System/UT2004 "\$@"
  else
      echo "Starting UT2004"
      /opt/ut2004/System/UT2004 "\$@"
  fi
fi
EOL

# Temporary patch form arm64 builds: https://forums.raspberrypi.com/viewtopic.php?t=394925#p2364055
cp /opt/ut2004/System/Default.ini /opt/ut2004/SystemARM64/
cp /opt/ut2004/System/DefUser.ini /opt/ut2004/SystemARM64

chmod +x /opt/ut2004/launch.sh

sed -i 's/StartupFullscreen=True/StartupFullscreen=False/' /opt/ut2004/System/Default.ini
sed -i 's/WindowedViewportX=640/WindowedViewportX=1024/' /opt/ut2004/System/Default.ini
sed -i 's/WindowedViewportY=480/WindowedViewportY=768/' /opt/ut2004/System/Default.ini
sed -i 's/UseJoystick=False/UseJoystick=True/' /opt/ut2004/System/Default.ini


chown -R 1000:1000 /opt/ut2004

cat >$HOME/Desktop/ut2004.desktop <<EOL
[Desktop Entry]
Version=1.0
Type=Application
Name=Unreal Tournament 2004
GenericName=Game
Comment=Unreal Tournament 2004
Exec=/opt/ut2004/launch.sh %F
Path=/opt/ut2004/
Terminal=false
MimeType=text/plain;
Icon=/opt/ut2004/Help/Unreal.ico
Categories=Graphics;Utility;
StartupNotify=true
EOL

chmod +x $HOME/Desktop/ut2004.desktop
chown 1000:1000 $HOME/Desktop/ut2004.desktop