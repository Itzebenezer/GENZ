![5803113236738984791](https://github.com/user-attachments/assets/f0fc9ccb-d62a-4a26-bd1d-cdeaf25ac1b5)

## GenZ V0.2(final edition)
GenZ is a minimalist os written almost entirely in x86 assembly except for the bootloader. It was work in progress thanks to triplet fault, the entire OS is under 10KB(more like the kernel)
GenZ isn't fully operational yet it's not even halfway there. I wam actively refining it with each update until i get into file system and gui stuffs.
This update is going to be my final on this project. It is taken a huge amount of time(specially when it comes to finding resource), trial and error and digging for the right resources has become impossible.

## UPDATE:

    I added a basic filesystem... well kinda it has some working functionality to it
    i tried adding a gui but sadly it wasnt possible given the constraints and direction of the project
    There is still more I wanted to do, but i cant mainly cause of lack of resources and this might be my final big update.

If you just want to try it out you can get a prebuilt .iso from the releases section.

## How to Build & Ru

Just copy and paste the following cmd to you terminal(linux)

```bash
# 1. Clone the repo
git clone https://github.com/Itzebenezer/GENZ.git

# 2. Enter the project folder
cd GENZ

# 3. Make the build script executable
chmod +x build.sh

# 4. Build the OS
./build.sh

# 5. Run it with QEMU
qemu-system-x86_64 -cdrom build/GENZ.iso
