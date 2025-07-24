## GENZ 

GENZ is a tiny os written almost entirely in x86 assembly except the bootloader. it is still in progress but once it's complete, the whole system (with some extra features) will weigh in at under 10KB.
Sadly GENZ isn’t a fully working os just yet its not even halfway there.but updates are coming fast. I am actively improving it as i go.
I started GENZ as a fun hobby project to see how far i could go with pure assembly. along the way i even wrote a book documenting the entire process hopefully i will be sharing it with you soon.

If you just want to try it out you can get a prebuilt .iso from the releases section.

## How to Build & Run

Getting started is easy — just clone, build, and boot.

```bash
# 1. Clone the repo
[git clone https://github.com/Itzebenezer/GENZ](https://github.com/Itzebenezer/GENZ.git)

# 2. Enter the project folder
cd GENZ

# 3. Make the build script executable
chmod +x build.sh

# 4. Build the OS
./build.sh

# 5. Run it with QEMU
qemu-system-x86_64 -cdrom build/GENZ.iso
