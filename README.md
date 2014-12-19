gfd
===

Tiny library for reading Gillware .gfd files

The GFD class will give you back a simple array of hashes with the path and metadata for each directory and file listed in the GFD.

All paths are utf-16le, because in the files I used that is how they appeared in the files I used. I assume they always come back in utf16-le no matter the original filesystem.

# Note on the .gfd format

The file format is binary, and is a sequence of frames. The three frame types are start dir, close dir, and file. If a file frame is listed, that file is considered nested under any prior unclosed dirs.

Directories have no metadata. Files have only size and modified time.
