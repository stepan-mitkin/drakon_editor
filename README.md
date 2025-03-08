## How to run Drakon Editor on Windows without ActiveState Tcl

1. Download Tcl from magicsplat
https://sourceforge.net/projects/magicsplat/files/magicsplat-tcl/

2. Install Tcl. Choose the right version for your operating system. For example, tcl-8.6.16-installer-1.16.0-x64.msi for Windows 11.

3. Download and unzip this repository.

4. Start the **drakon_editor.tcl** using the **wish.exe** file installed with magicsplat-tcl
For example:
```
C:\Users\user1\AppData\Local\Apps\Tcl86\bin\wish.exe c:\soft\drakon_editor-master\drakon_editor.tcl
```

## How to work on DRAKON Editor source code.

1. Before submitting patch, make sure that unit tests run without error by running `unittest/unittest.tcl`. 
    - There will be error messages and stack traces. It's okay. The bottom line must be "success".


2. Add new unit tests if necessary.


3. Add newly added `.drn` source files to `unittest/regenerate.sh`


4. If you change the code generator:
    - Update `unittest/regenerate_examples.sh`
    - Run `unittest/regenerate_examples.sh`


5. If you want to change DRAKON Editor source code:
    - First look for `.drn` file of source code you want to modify, modify it, generate code from it and commit `.drn` file and generated file.
    - If there is no `.drn` file, modify existing source code file.


## DRAKON

DRAKON is is an algorithmic visual programming language developed within the Buran space project.
Beside programming, DRAKON is also used in medicine, law, business processes and in other non-programming related fields.
The rules of DRAKON are optimized to ensure easy understanding by human beings. In DRAKON clarity is above all. DRAKON is made as much ergonomic as possible, as much human readable as possible. DRAKON makes possible to create diagrams that are cognitively optimized for easy comprehension, making it a tool for intelligence augmentation.

Why to use DRAKON than other diagramming systems?
- No line intersections. You will never find in DRAKON diagram two or more lines intersecting each other! Not seen in other diagramming systems!
- Silhouette structure. It allows to break one diagram in to several logical parts. Not seen in other diagramming systems!
- No slanting or curved lines. Only straight lines with right angles.
- Icons are placed only on vertical lines.
- Branching is done in a simple, visible and consistent way.
- Each diagram has one entry and one exit.

Learn DRAKON:
- http://drakon-editor.sourceforge.net/DRAKON.pdf
- http://drakon-editor.sourceforge.net/language.html
- http://en.wikipedia.org/wiki/DRAKON


## DRAKON Editor

DRAKON Editor is a free open source tool for authoring DRAKON diagrams. It also supports state machine diagrams, entity-relationship and class diagrams.
- DRAKON Editor runs on Windows, Mac and Linux.
- The user interface of DRAKON Editor is extremely simple and straightforward.
- Software developers can build real programs with DRAKON Editor. Source code can be generated in several programming languages, including Java, Processing.org, D, C#, C/C++ (with Qt support), Python, Tcl, Javascript, Lua, Erlang, AutoHotkey and Verilog.

Homepage: http://drakon-editor.sourceforge.net/

Documentation: http://drakon-editor.sourceforge.net/editor.html


## How to use release version of DRAKON Editor

Installing Tcl and required packages:

DRAKON Editor needs Tcl 8.6 or higher to run:
- Windows, Linux and Mac users can download Active Tcl here: http://www.activestate.com/activetcl/downloads
- For OS X users: If you are having problems with sqlite while using DRAKON Edidor read this: https://github.com/stepan-mitkin/drakon_editor/issues/6#issuecomment-188855963
- Or Linux users can install the following packages:
    - tcl8.6
    - tk8.6
    - tcllib
    - libsqlite3-tcl
    - libtk-img
	
On Ubuntu: 
```sh
sudo apt-get install tcl8.6 tk8.6 tcllib libsqlite3-tcl libtk-img
```

Installing and running DRAKON Editor:

1. Download release version of DRAKON Editor from here: http://drakon-editor.sourceforge.net/editor.html#downloads

2. Unzip archive.

3. Run `drakon_editor.tcl`


## How to use development version of DRAKON Editor

*Warning! Development version of DRAKON Editor is not as stable as release version and is only for testing purposes.*

See notes about Tcl instalation in [How to use release version of DRAKON Editor](#how-to-use-release-version-of-drakon-editor) section and after follow these steps:

1. Click "Download ZIP" at current page.

2. Unzip archive.

3. Run `drakon_editor.tcl` 


