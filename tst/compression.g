# NOTE: This test reads this first line!!

# This file tests we can read compressed files

LoadPackage("io");

checkCompression := function(filename)
    local f, lines;
    # Lets hope we can write to the current directory
    f := IO_CompressedFile(filename, "w");

    if f = fail then
       Error("Unable to create compressed file: ", 2);
    fi;

    if IO_WriteLine(f, "xyz") = fail then
      Error("Invalid write compressed file: ", 3);
    fi;

    IO_Close(f);

    # Let's check we can append
    f := IO_CompressedFile(filename, "a");

    if f = fail then
       Error("Unable to append to compressed file: ", 4);
    fi;

    if IO_WriteLine(f, "abc") = fail then
      Error("Invalid write compressed file: ", 5);
    fi;

    IO_Close(f);

    f := IO_CompressedFile(filename, "r");

    if IO_ReadLines(f) <> [ "xyz\n", "abc\n" ] then
      Error("Unable to read compressed file correctly: ", 6);
    fi;

    IO_unlink(filename);
end;

# Check no compression works
checkCompression("tmpcompfile.txt");

f := IO_CompressedFile("compression.g", "r");
if IO_ReadLine(f) <> "# NOTE: This test reads this first line!!\n" then
   Error("IO_CompressedFile is broken on uncompressed files: ", 7);
fi;

IO_Close(f);

# First let's check a pre-existing compressed file:
if IO_FindExecutable("gzip") <> fail then
    f := IO_CompressedFile("test.txt.gz", "r");

    lines := IO_ReadLines(f);

    if lines <> [ "Line\n", "Another Line\n", "Final Line\n", "\n" ] then
        Error("Invalid reading of compressed file: ",1);
    fi;

    IO_Close(f);

    # Now lets check we can create files

    checkCompression("tmpcompfile.gz");
fi;

# Only do these if the executable exists
if IO_FindExecutable("bzip2") <> fail then
    checkCompression("tmpcompfile.bz2");
fi;

if IO_FindExecutable("xz") <> fail then
    checkCompression("tmpcompfile.xz");
fi;
