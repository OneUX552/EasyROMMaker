#Tools that not needed rn is attr   android-sdk-libsparse-utils erofs-utils f2fs-tools
##


# bash script for installing the tools required for IshiROM
sudo -v
packages=(
  openjdk-17-jdk
  xmlstarlet
  zip
  nodejs
  lz4
  make
)


echo "Installing lpunpack and lpunpack!"
cp binary/lpunpack /bin/
cp binary/lpmake /bin/

echo "Finished installation of lpunpack and lpmake"


git clone https://github.com/anestisb/android-simg2img.git

mv android-simg2img simg2img

cd simg2img || exit

sudo apt-get install libz-dev -y
make 

cd ..

rm -rf simg2img

echo "Finished installation of simg2img"

for package in "${packages[@]}"; do
  sudo apt install -y "$package" || {
    echo "Failed to install $package. You may get further problems later "
  }
done

exit 0

