from fetchqc import head, tail
import os
if os.geteuid() != 0:
    print("Script needs to be run as root.")
    exit(2)
head.run()
tail.run()
