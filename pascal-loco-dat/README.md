# LocoDat — a Pascal library for Locomotion / OpenLoco `.DAT` object files

A Free Pascal (Delphi-mode compatible) library for reading and writing the
binary object files (`.DAT`) used by Chris Sawyer's *Locomotion* and by
[OpenLoco](https://github.com/OpenLoco/OpenLoco). It implements the on-disk
container format from first principles — the "Sawyer stream" chunk
encoding, the object header + checksum scheme, and the generic string
table / image table layout that every object type builds on.

It was built by reading OpenLoco's C++ source directly:


# Note

This is a stripped down version for use with OpenLoco Company Editor, and contains only the Competitor type object class.