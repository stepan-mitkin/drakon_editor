How to work on DRAKON Editor source code.
=========================================

1. Add unit tests. See unittest/unittest.tcl.

2. Run unit tests.
	cd unittest
	tclsh unittest.tcl
	
There will be error messages and stack traces. It's okay.
The bottom line must be "success".

3. Add newly added .drn source files to unittest/regenerate.sh

4. If you change the code generator:
- Update unittest/regenerate_examples.sh
- Run unittest/regenerate_examples.sh

5. If you want to change DRAKON Editor source code:
- First look for .drn file of source code you want to modify, modify it, generate code from it and commit .drn file and generated file.
- If there is no .drn file, modify existing source code file.
