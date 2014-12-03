##How to work on DRAKON Editor source code.

1. Before submiting patch make sure that unit tests run without error by running `unittest/unittest.tcl`. 
 - There will be error messages and stack traces. It's okay. The bottom line must be "success".


2. Add new unit tests if necessary.


3. Add newly added `.drn` source files to `unittest/regenerate.sh`


4. If you change the code generator:
 - Update unittest/regenerate_examples.sh
 - Run unittest/regenerate_examples.sh


5. If you want to change DRAKON Editor source code:
 - First look for `.drn` file of source code you want to modify, modify it, generate code from it and commit `.drn` file and generated file.
 - If there is no `.drn` file, modify existing source code file.


<br>
##DRAKON

DRAKON is is an algorithmic visual programming language developed within the Buran space project.<br>
Beside programming, DRAKON is also used in medicine, law, business processes and in other non-programming related fields.<br>
The rules of DRAKON are optimized to ensure easy understanding by human beings. In DRAKON clarity is above all. DRAKON is made as much ergonomic as possible, as much human readable as possible. DRAKON makes possible to create diagrams that are cognitively optimized for easy comprehension, making it a tool for intelligence augmentation.

Why to use DRAKON than other diagramming systems?
- No line intersections. You will never find in DRAKON diagram two or more lines intersecting each other! Not seen in other diagramming systems!
- Silhouette structure. It allows to break one diagram in to several logical parts. Not seen in other diagramming systems!
- No slanting or curved lines. Only straight lines with right angles.
- Icons are placed only on vertical lines.
- Branching is done in a simple, visible and consistent way.
- Each diagram has one entry and one exit.

Learn DRAKON: <br>
http://drakon-editor.sourceforge.net/DRAKON.pdf <br>
http://drakon-editor.sourceforge.net/language.html <br>
http://en.wikipedia.org/wiki/DRAKON


<br>
##DRAKON Editor

DRAKON Editor is a free open source tool for authoring DRAKON diagrams. It also supports state machine diagrams, entity-relationship and class diagrams.
- DRAKON Editor runs on Windows, Mac and Linux.
- The user interface of DRAKON Editor is extremely simple and straightforward.
- Software developers can build real programs with DRAKON Editor. Source code can be generated in several programming languages, including Java, Processing.org, D, C#, C/C++ (with Qt support), Python, Tcl, Javascript, Lua, Erlang, AutoHotkey and Verilog.

Homepage: http://drakon-editor.sourceforge.net/ <br>
Documentation: http://drakon-editor.sourceforge.net/editor.html


<br>
##How to use release version of DRAKON Editor

Installing Tcl and required packages:

DRAKON Editor needs Tcl 8.6 or higher to run:
- Windows, Linux and Mac users can download Active Tcl here: http://www.activestate.com/activetcl/downloads
- Or Linux users can install the following packages:
 - tcl8.6
 - tk8.6
 - tcllib
 - libsqlite3-tcl
 - libtk-img
	
On Ubuntu: `sudo apt-get install tcl8.6 tk8.6 tcllib libsqlite3-tcl libtk-img`
<br><br>
Installing and running DRAKON Editor:

1. Download release version of DRAKON Editor from here: http://drakon-editor.sourceforge.net/editor.html#downloads

2. Unzip archive.

3. Run `drakon_editor.tcl`


<br>
##How to use development version of DRAKON Editor

*Warning! Development version of DRAKON Editor is not as stable as release version and is only for testing purposes.*

See notes about Tcl instalation in "How to use release version of DRAKON Editor" section and after follow these steps:

1. Click "Download ZIP" at current page.

2. Unzip archive.

3. Run `drakon_editor.tcl` 

4. By default Russion version of DRAKON Editor will be launched. If you need to launch English version of DRAKON Editor then delete folder `/msgs`
