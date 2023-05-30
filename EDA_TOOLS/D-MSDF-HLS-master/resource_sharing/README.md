# Resource sharing

## From resource_sharing, create symbolic link to Buffers:

```bash
ln -s /home/dynamatic/Dynamatic/etc/dynamatic/Buffers/src src/DFnetlist
```

## Create the bin directory

```bash
mkdir bin
```

## From resource_sharing, compile the code:

```bash
make
```
## To run the code:
To synthesis_optimize.tcl script, optimize command, add flag -area: 
```bash
optimize -area
```

## To run the code (old):

Use the regression test to create the optimized version of an example in its regular folder. 
Add the example to filelist.lst in the resource_sharing folder.

In resource_sharing, create folder for output files:

```bash
mkdir output
```
From resource_sharing, run: 

```bash
./run_all.sh
```

This script will run resource sharing on all examples in filelist.lst.
