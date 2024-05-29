
from sys import argv

with open("tailcall.tf") as f:
    contents = f.read()
    for (key, val) in zip(argv[1::2], argv[2::2]):
        contents = contents.replace(key, val)

with open("tailcall.tf", "w") as f:
    f.write(contents)