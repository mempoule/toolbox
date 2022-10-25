import base58
import getopt
import getpass
import json
import os
import sys
from datetime import datetime

from Crypto.Cipher import AES
from Crypto.Protocol.KDF import scrypt
from Crypto.Random import get_random_bytes
from Crypto.Util.Padding import unpad, pad


def cur_ver():
    try:
        with open("setup.py") as file:
            dataver = file.readlines()
        for line in dataver:
            if "version=\"" in line:
                version = line.split('"')[1]
            if "description=\"" in line:
                desc = line.split('"')[1]
            if "url=\"" in line:
                url = line.split('"')[1]
    except FileNotFoundError:
        version = "0.2"
        desc = "Bastion"
        url = "https://github.com/mempoule/toolbox"
    print(desc, "v" + version, "-", url)


def decode(filename, password, subaction, subparam, opts, export):
    print("\nAction :", subaction)
    print("File :", filename)
    print("Decoding in progress, please wait...\n")
    f = open(filename, "r")
    data = f.read()

    decoded = base58.b58decode(data)

    iv = decoded[:16]
    ciphered_data = decoded[16:-32]
    salt = decoded[-32:]
    key = scrypt(password, salt, 32, N=2 ** 20, r=8, p=1)
    cipher_decrypt = AES.new(key, AES.MODE_CBC, iv=iv)
    original_data = unpad(cipher_decrypt.decrypt(ciphered_data), AES.block_size)

    f.close()

    data = json.loads(original_data.decode("utf-8"))

    if len(data) == 0 and not subaction == "add":
        print("Error: the file contains no keys")
    else:
        if subaction == "list":
            keylist = list(data.keys())
            print("Key list :", keylist)
        if subaction == "show":
            print("-> Key :", subparam)
            print("-> Exporting :", export, "\n")
            if export:
                for opt, arg in opts:
                    if opt in ("-e", "--export"):
                        export_file = arg
                if os.path.exists(export_file):
                    print("Export skipped : File exists")
                else:
                    print("Exporting to file :", arg)
                    f = open(arg, "w+")
                    f.write(str(data[subparam]['keys']))
                    f.close()
            else:
                print(data[subparam]['keys'])
        if subaction == "remove":
            if subparam in data:
                del data[subparam]
                final = bytes(json.dumps(data).encode("utf-8"))
                save(password, filename, final)
        if subaction == "add":
            if subparam not in data:
                for opt, arg in opts:
                    if opt in ("-k", "--key"):
                        now = datetime.now()
                        new_dict = {subparam: {}}
                        new_dict[subparam]["keys"] = arg.split(',')
                        new_dict[subparam]["date"] = str(now.day) + '/' + str(now.month) + '/' + str(now.year)
                        data.update(new_dict)
                        final = bytes(json.dumps(data).encode("utf-8"))
                        save(password, filename, final)
                    if opt in ("-f", "--file"):
                        if os.path.exists(arg) and os.access(arg, os.R_OK):
                            now = datetime.now()
                            new_dict = {subparam: {}}
                            new_dict[subparam]["keys"] = str(open(arg, "r").read())
                            new_dict[subparam]["date"] = str(now.day) + '/' + str(now.month) + '/' + str(now.year)
                            data.update(new_dict)
                            final = bytes(json.dumps(data).encode("utf-8"))
                            save(password, filename, final)
                        else:
                            print("nonexistent, or no access")


def save(password, filename, data=''):
    data = bytes(data)

    salt = get_random_bytes(32)
    key = scrypt(password, salt, 32, N=2 ** 20, r=8, p=1)
    cipher = AES.new(key, AES.MODE_CBC)
    ciphered_data = cipher.encrypt(pad(data, AES.block_size))
    iv = cipher.iv
    encoded = base58.b58encode(iv + ciphered_data + salt).decode("utf-8")

    f = open(filename, "w+")
    f.write(str(encoded))
    f.close()


def create(filename, password):
    print("create", filename)
    salt = get_random_bytes(32)
    data = b'{}'
    key = scrypt(password, salt, 32, N=2 ** 20, r=8, p=1)
    cipher = AES.new(key, AES.MODE_CBC)
    ciphered_data = cipher.encrypt(pad(data, AES.block_size))
    iv = cipher.iv
    encoded = base58.b58encode(iv + ciphered_data + salt).decode("utf-8")

    f = open(filename, "w+")
    f.write(str(encoded))
    f.close()


def invalid_command(argv):
    print("Invalid command '", *argv, "' type '--help' for a list.")
    sys.exit(2)


def main(argv):
    try:
        opts, args = getopt.getopt(argv, "hc:d:p:a:lr:s:k:f:e:v",
                                   ["help", "create=", "decode=", "password=", "add=", "list", "remove=", "show=",
                                    "key=", "file=", "export=", "version"])
    except getopt.GetoptError:
        invalid_command(argv)

    filename = action = password = subaction = subparam = None
    export = is_classic = is_file = create_bool = decode_bool = False
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            print("""
    Command line options:
       -c [--create] <new_bastion_file> : create a new bastion
       -d [--decode] <existing_bastion_file> : use a bastion file
     """)
            sys.exit()
        if opt in ("-v", "--version"):
            cur_ver()
            sys.exit()

        elif opt in ("-c", "--create"):
            action = "create"
            create_bool = True
            if os.path.exists(arg):
                print("Error :", arg, "already exists, exiting")
                sys.exit()
            else:
                filename = arg
        elif opt in ("-d", "--decode"):
            action = "decode"
            decode_bool = True
            if os.path.exists(arg):
                filename = arg
            else:
                print("Error :", arg, "does not exist")
                sys.exit()
        elif opt in ("-p", "--password"):
            password = arg
        elif opt in ("-a", "--add"):
            subaction = "add"
            subparam = arg
        elif opt in ("-l", "--list"):
            subaction = "list"
        elif opt in ("-r", "--remove"):
            subaction = "remove"
            subparam = arg
        elif opt in ("-s", "--s"):
            subaction = "show"
            subparam = arg
        elif opt in ("-k", "--key"):
            is_classic = True
        elif opt in ("-f", "--file"):
            is_file = True
        elif opt in ("-e", "--export"):
            export = True
            if os.path.exists(arg):
                print("Error : cannot export, file exists")
                sys.exit()
    if password is None:
        password = getpass.getpass("Enter password :\n")
    if decode_bool and create_bool:
        print("Error: cannot create and decode on same time")
    elif not password:
        print("Error: empty password")
    elif ' ' in password:
        print("Error: space in password")
    elif action == "create":
        create(filename, password)
    elif action == "decode":
        if not subaction is None:
            if subaction == "add":
                if is_classic and is_file:
                    print("Error: cannot add file and key on same time")
                if not is_classic and not is_file:
                    print("Error: cannot add empty data for new key", subparam)
                else:
                    decode(filename, password, subaction, subparam, opts, export)
            else:
                decode(filename, password, subaction, subparam, opts, export)


if __name__ == "__main__":
    main(sys.argv[1:])
