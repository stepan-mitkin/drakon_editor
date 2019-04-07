#! /usr/bin/env python3

# To simplify translation, I decided generate message file from csv,
# so I can use Excel to edit it.
# I can't wrote Tcl, so I wrote this in Python
# This code is in PUBLIC DOMAIN. Student Main 2019-04-07T11:17+0800

import csv
with open('msgs.csv') as fd:
	reader = csv.reader(fd)
	
	languages = next(reader, None)[1:]
	
	msgfds = {}
	localefile = open("locales.tcl","w",newline='\n')
	
	lang_fullname = next(reader, None)

	for lang in languages:
		# newline='\r\n' is same as old ru.msg
		msgfds[lang] = open("%s.msg"%(lang) ,"w",newline='\r\n')
		# write new line to match line number with csv
		msgfds[lang].write('\n\n')
		localefile.write('::msgcat::mclocale %s\n'%(lang))
	localefile.close()
	
	langlistfile = open("lang_list.tcl","w",newline='\n')
	langlistfile.write('variable language_list {\n')
	for name in lang_fullname:
		langlistfile.write('\t"%s"\n'%(name))
	langlistfile.write('}\n')
	langlistfile.close()

	lineno = 3
	for row in reader:
		orig = row[0]
		translate = row[1:]
		for i in range(len(translate)):
			lang = languages[i]
			translated = translate[i]
			if len(translate[i]) == 0:
				translated = orig
				# Generate not translated warning
				if len(orig) > 0:
					print('Not translated: %d %s %s' % (lineno,lang,orig))
			str = '::msgcat::mcset %s "%s" "%s"\n' % (lang,orig,translated)
			if len(orig) == 0:
				msgfds[lang].write("\n")
			else:
				msgfds[lang].write(str)
		lineno += 1
	for fd in msgfds.values():
		fd.close()