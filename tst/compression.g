# NOTE: This test reads this first line!!

# This file tests we can read compressed files

# We use this to general unique filenames, for parallel testing
basepid := String(IO_getpid());

LoadPackage("io");
d := DirectoriesPackageLibrary("io", "tst");

checkCompression := function(original_filename)
    local f, lines, filename, x;
    filename := Concatenation(basepid, original_filename);

    # Lets hope we can write to the current directory
    f := IO_CompressedFile(filename, "w");

    if f = fail then
       Error("Unable to create compressed file ", filename, ": ", 2);
    fi;

    if IO_WriteLine(f, "xyz") = fail then
      Error("Invalid write to compressed file ", filename, ": ", 3);
    fi;

    IO_Close(f);

    # Let's check we can append
    f := IO_CompressedFile(filename, "a");

    if f = fail then
       Error("Unable to append to compressed file ", filename, ": ", 4);
    fi;

    if IO_WriteLine(f, "abc") = fail then
      Error("Invalid write to compressed file ", filename, ": ", 5);
    fi;

    IO_Close(f);

    # Let's check we can read what we've written
    f := IO_CompressedFile(filename, "r");

    x := IO_ReadLines(f);
    if x <> [ "xyz\n", "abc\n" ] and x <> [ "xyz\r\n", "abc\r\n" ] then
      Print("Unexpected contents of compressed file: ", x, "\n");
      Error("Unable to read compressed file ", filename, " correctly: ", 6);
    fi;
    
    IO_Close(f);

    IO_unlink(filename);
end;

# Check no compression works
checkCompression("tmpcompfile.txt");

f := IO_CompressedFile(Filename(d,"compression.g"), "r");
if IO_ReadLine(f) <> "# NOTE: This test reads this first line!!\n" then
   Error("IO_CompressedFile is broken on uncompressed files: ", 7);
fi;

IO_Close(f);

# First let's check a pre-existing compressed file:
if IO_FindExecutable("gzip") <> fail then
    f := IO_CompressedFile(Filename(d,"test.txt.gz"), "r");

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
