#!/usr/bin/env python3
"""
Script for changing header format in order for the FASTQ files to be digested by miraligner tool. 
Required format is "seq_000_x{X}" where {X} denotes number of collapsed identical reads, and 000 is random number unique across all reads.

Author: Karolina Trachtova
"""
import sys
import os

# Input file
input_file = sys.argv[1]

# Create a temporary output file
temp_file = input_file + ".tmp"

# Open the input and temporary output file
with open(input_file, "r") as fin, open(temp_file, "w") as fout:
    for line in fin:
        if "@" in line:
            l1 = line.split("-")
            new_header = "@seq_" + l1[0].strip("@") + "_x" + l1[1]
            fout.write(new_header)
        else:
            fout.write(line)

# Replace the original file with the temporary one
os.rename(temp_file, input_file)
