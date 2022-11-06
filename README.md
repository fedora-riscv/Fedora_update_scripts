# Fedora_update_scripts

## install rpm-list-builder:

https://github.com/sclorg/rpm-list-builder
https://github.com/hroncok/rpm-list-builder

```
sudo dnf install virtualenv
virtualenv rpmlb
source rpmlb/bin/activate
#upgrade warning solved
pip install --upgrade pip
pip install rpmlb
```
## download work dir

```
git clone https://github.com/fedora-riscv/Fedora_update_scripts.git
cd Fedora_update_scripts
```

## Python upgrade

Reference: https://github.com/hroncok/rpm-list-builder/blob/python310/python310.yaml

```
rpmlb -v -d custom -c mock-custom-plct.yaml -w work -B rawhide -S srcs --dist fc37 -b custom python311.yaml python311 -r 8
```

## Perl upgrade

Reference: https://src.fedoraproject.org/modules/perl-bootstrap/blob/5.36/f/perl-bootstrap.yaml

```
rpmlb -v -d custom -c mock-custom-plct.yaml -w work -B rawhide -S srcs --dist fc37 -b custom perl536.yaml perl536 -r 8
```



