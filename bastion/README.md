# Bastion

## Prerequisites

Python >= 3.6

---

## Install

Place yourself in Bastion's Folder, then

### Linux :
    virtualenv venv
    source venv/bin/activate
    python setup.py develop

### Windows :
    python3 -m venv ./venv
    /venv/Scripts/activate.bat
    python setup.py develop

---

## Commands : 

### Version Info:

    python bastion.py -v
or

     python bastion.py --version

---

### Create a bastion: 

    python bastion.py -clala -plulu
or

     python bastion.py --create lala --password lulu

> **Note:** 
> The bastion will initialize empty.
> 
> *The file will be created in the current dir, with the name **lala** and the password **lulu***
> 
> *The -p is optional, in case not specified in command line, a prompt will handle it*

---

### Add an entry : 

    python bastion.py -dlala -plulu -aentry1 -kfdsfsi,gfdg,gfdgfd,908ffffffff

or 

    python bastion.py --decode lala --password lulu -add entry1 --key fdsfsi,gfdg,gfdgfd,908ffffffff


---

### Add an entry with file as content :

    python bastion.py -dlala -plulu -aentry2 -f/home/ktnoc/test

or

    python bastion.py --decode lala --password lulu -add entry2 --file /home/ktnoc/test

> **Note:** On Windows, the file path has to be formatted like `C:\temp\thefile`

---

### List entries : 

    python bastion.py -dlala -plulu -l

or 

    python bastion.py --decode lala --password lulu --list

---

### Show keys of an entry : 

    python bastion.py -dlala -plulu -sentry1

or 

    python bastion.py --decode lala --password lulu --show entry1

---

### Export keys of an entry :

    python bastion.py -dlala -plulu -sentry1 -elolipop

or

    python bastion.py --decode lala --password lulu --show entry1 --export lolipop

> **Note:** Relative path only on Linux

---

### Remove an entry : 

    python bastion.py -dlala -plulu -rentry1

or 

    python bastion.py --decode lala --password lulu --remove entry1