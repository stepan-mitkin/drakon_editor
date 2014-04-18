# library of tcl procedures for generating portable document format files
# this is a port of pdf4php from php to tcl
#
# Copyright (c) 2004 by Frank Richter <frichter@truckle.in-chemnitz.de> and
#                       Jens Pönisch <jens@ruessel.in-chemnitz.de>
# Copyright (c) 2006-2010 by Peter Spjuth <peter.spjuth@gmail.com>
# Copyright (c) 2009 by Yaroslav Schekin <ladayaroslav@yandex.ru>
#
# See the file "licence.terms" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
# $Id: pdf4tcl.tcl 181 2010-01-29 23:13:00Z pspjuth $

package provide pdf4tcl 0.7

package require pdf4tcl::stdmetrics
package require pdf4tcl::glyph2unicode
package require snit

namespace eval pdf4tcl {
    # helper variables (constants) packaged into arrays to minimize
    # variable import statements
    variable g
    variable paper_sizes
    variable units
    variable dir [file dirname [file join [pwd] [info script]]]

    # Known papersizes. These are always in points.
    array set paper_sizes {
        a0     {2380.0 3368.0}
        a1     {1684.0 2380.0}
        a2     {1190.0 1684.0}
        a3     { 842.0 1190.0}
        a4     { 595.0  842.0}
        a5     { 421.0  595.0}
        a6     { 297.0  421.0}
        11x17  { 792.0 1224.0}
        ledger {1224.0  792.0}
        legal  { 612.0 1008.0}
        letter { 612.0  792.0}
    }

    # Known units. The value is their relationship to points
    array set units [list \
            mm [expr {72.0 / 25.4}] \
            m  [expr {72.0 / 25.4}] \
            cm [expr {72.0 / 2.54}] \
            c  [expr {72.0 / 2.54}] \
            i  72.0                 \
            p  1.0                  \
           ]

    # Font Variables

    variable ttfpos 0
    variable ttfdata
    # Base font attributes:
    variable BFA
    # BaseFontParts for TTF fonts:
    variable BFP
    # List of all created fonts:
    variable Fonts
    variable FontsAttrs
    # For currently processed font:
    variable ttfname ""
    variable ttftables
    variable type1AFM
    variable type1PFB

    if {[catch {package require zlib} err]} {
        set g(haveZlib) 0
        if {[info commands zlib] eq "zlib"} {
            set g(haveZlib) 1
        }
    } else {
        set g(haveZlib) 1
    }

    # Utility to look up paper size by name
    # A two element list of width and height is also allowed.
    # Return value is in points
    proc getPaperSize {papername {unit 1.0}} {
        variable paper_sizes

        set papername [string tolower $papername]
        if {[info exists paper_sizes($papername)]} {
            # This array is always correct format
            return $paper_sizes($papername)
        }
        if {[catch {set len [llength $papername]}] || $len != 2} {
            return {}
        }
        foreach {w h} $papername break
        set w [getPoints $w $unit]
        set h [getPoints $h $unit]
        return [list $w $h]
    }

    # Return a list of known paper sizes
    proc getPaperSizeList {} {
        variable paper_sizes
        return [array names paper_sizes]
    }

    # Get points from a measurement.
    # No unit means points.
    # Supported units are "mm", "m", "cm", "c", "p" and "i".
    proc getPoints {val {unit 1.0}} {
        variable units
        if {[string is double -strict $val]} {
            # Always return a pure double value
            return [expr {$val * $unit}]
        }
        if {[regexp {^\s*(\S+?)\s*([[:alpha:]]+)\s*$} $val -> num unit]} {
            if {[string is double -strict $num]} {
                if {[info exists units($unit)]} {
                    return [expr {$num * $units($unit)}]
                }
            }
        }
        return -code error "Unknown value $val"
    }

    # Wrapper to create pdf4tcl object
    proc new {args} {
        uplevel 1 pdf4tcl::pdf4tcl create $args
    }

    # ===== Procs for TrueType fonts processing =====

    proc createBaseTrueTypeFont {basefontname ttf_data {validate 0}} {
        variable ttfname $basefontname
        variable ttfdata $ttf_data
        InitBaseTTF $validate
    }

    proc loadBaseTrueTypeFont {basefontname filename {validate 0}} {
        variable ttfname $basefontname
        variable ttfdata
        set fd [open $filename]
        fconfigure $fd -translation binary
        set ttfdata [read $fd]
        close $fd
        InitBaseTTF $validate
    }

    proc InitBaseTTF {validate} {
        variable BFA
        variable BFP
        variable ttfname
        variable ttfdata
        variable ttftables
        variable ttfpos 0

        set BFA($ttfname,FontType) TTF
        set subfontIndex 0

        if {[ReadHeader]} {
            ReadTTCHeader
            GetSubfont $subfontIndex $validate
        } else {
            ChecksumFile
            ReadTableDirectory $validate
            set BFA($ttfname,subfontNameX) ""
        }

        ExtractInfo

        unset -nocomplain ttfdata
        unset -nocomplain ttftables
        set BFA($ttfname,SubFontIdx) 0
    }

    # Pad data with zero bytes to: len % 4 == 0
    proc CalcTTFCheckSum {data pos len} {
        binary scan $data "@${pos}Iu[expr {$len >> 2}]" datalst

        if {$len & 3} {
            set s [expr {$pos + (($len >> 2) << 2)}]
            set e [expr {$s + ($len & 3)}]
            set lc "[string range $data $s $e][string repeat "\0" 3]"
            binary scan $lc "Iu" lastb
            lappend datalst $lastb
        }

        set sum 0
        foreach u_int32 $datalst {
            incr sum $u_int32
        }
        set sum [expr {$sum & 0xFFFFFFFF}]
        return $sum
    }

    # read the sfnt header at the current position:
    proc ReadHeader {} {
        variable ttfpos
        variable ttfdata
        set ttfVersions [list 65536 1953658213 1953784678]

        binary scan $ttfdata "@${ttfpos}Iu" version
        incr ttfpos 4
        if {$version == 0x4F54544F} {
            error "TTF: postscript outlines are not supported"
        }
        if {[lsearch -exact $ttfVersions $version] < 0} {# 8.5
            error "Not a TrueType font: version=$version"
        }
        return [expr {$version == [lindex $ttfVersions end]}]
    }

    proc ChecksumFile {} {
        variable ttfdata
        set checksum [CalcTTFCheckSum $ttfdata 0 [string length $ttfdata]]
        if {$checksum != 0xB1B0AFBA} {
            error "Invalid TTF file checksum [format %X $checksum]"
        }
    }

    proc ReadTTCHeader {} {
        variable ttfname
        variable ttfpos
        variable ttfdata
        variable BFA
        variable ttfsubfontOffsets
        set ttcVersions [list 65536 131072]

        binary scan $ttfdata "@${ttfpos}IuIu" \
                ttcVersion BFA($ttfname,numSubfonts)
        incr ttfpos 8

        if {[lsearch -exact $ttcVersions $ttcVersion] < 0} {# 8.5
            error "Not a TTC file"
        }

        binary scan $ttfdata "@${ttfpos}Iu$BFA($ttfname,numSubfonts)" \
                ttfSubFontOffsets
        incr ttfpos [expr {$BFA($ttfname,numSubfonts) * 4}]
    }

    proc GetSubfont {subfontIndex {validate 0}} {
        variable ttfpos
        variable ttfSubFontOffsets
        if {$subfontIndex >= [llength $ttfSubFontOffsets]} {
            error "Bad subfontIndex $subfontIndex"
        }
        set ttfpos [lindex $ttfSubFontOffsets $subfontIndex]
        ReadHeader
        ReadTableDirectory $validate
    }

    proc ReadTableDirectory {validate} {
        variable ttfdata
        variable ttfpos
        variable ttftables
        variable ttfname
        variable BFP
        variable BFA
        # Must copy only needed tables here, if they exist:
        set NT [list "name" "OS/2" "cvt " "fpgm" "prep" \
                "glyf" "post" "hhea" "maxp" "head"]

        # 'srange', 'esel' and 'rshift' are UNUSED
        binary scan $ttfdata "@${ttfpos}SuSuSuSu" numTables srange esel rshift
        incr ttfpos 8

        for {set f 0} {$f < $numTables} {incr f} {
            # list is 'checksum offset length'
            binary scan $ttfdata "@${ttfpos}a4Iu3" tag rlist
            incr ttfpos 16
            set ttftables($tag) $rlist
            if {[lsearch -exact $NT $tag] >= 0} {# 8.5
                foreach {cksum offset len} $rlist break
                set last [expr {$offset + $len - 1}]
                set BFP($ttfname,$tag) [string range $ttfdata $offset $last]
                lappend BFA($ttfname,tables) $tag
            }
        }
        if {$validate} ChecksumTables
    }

    # Check the checksums for all tables
    proc ChecksumTables {} {
        variable ttftables
        variable ttfdata

        foreach t [array names ttftables] {
            foreach {checksum offset length} $ttftables($t) break
            set RCkSum [CalcTTFCheckSum $ttfdata $offset $length]
            if {$t eq "head"} {
                incr offset 8
                binary scan $ttfdata "@${offset}Iu" adjustment
                set RCkSum [expr {($RCkSum - $adjustment) & 0xFFFFFFFF}]
            }
            if {$RCkSum != $checksum} {
                error "TTF: invalid checksum of table $t"
            }
        }
    }

    # Extract typographic information from the loaded font file.
    #
    # The following attributes will be set::
    #
    #    name         PostScript font name
    #    flags        Font flags
    #    ascent       Typographic ascender in 1/1000ths of a point
    #    descent      Typographic descender in 1/1000ths of a point
    #    CapHeight    Cap height in 1/1000ths of a point (0 if not available)
    #    bbox         Glyph bounding box [l,t,r,b] in 1/1000ths of a point
    #    _bbox        Glyph bounding box [l,t,r,b] in unitsPerEm
    #    unitsPerEm   Glyph units per em
    #    ItalicAngle  Italic angle in degrees ccw
    #    stemV        stem weight in 1/1000ths of a point (approximate)
    #
    # If charInfo is true, the following will also be set::
    #
    #    defaultWidth   default glyph width in 1/1000ths of a point
    #    charWidths     dictionary of character widths for every supported UCS
    #                   character code
    #
    # This will only work if the font has a Unicode cmap (platform 3,
    # encoding 1, format 4 or platform 0 any encoding format 4).  Setting
    # charInfo to false avoids this requirement
    proc ExtractInfo {{charInfo 1}} {
        variable ttfdata
        variable ttftables
        variable ttfpos
        variable ttfname
        variable BFA

        # name - Naming table
        set name_pos [lindex $ttftables(name) 1]
        set ttfpos $name_pos
        binary scan $ttfdata "@${ttfpos}SuSuSu" fmt NumRecords SDoffset
        if {$fmt != 0} {error "TTF: Unknown name table format $fmt"}
        incr ttfpos 6
        set SDoffset [expr {$name_pos + $SDoffset}]
        array set names {1 "" 2 "" 3 "" 4 "" 6 ""}
        set NIDS [array names names]
        set nameCount [llength $NIDS]

        for {set f 0} {$f < $NumRecords} {incr f} {
            binary scan $ttfdata "@${ttfpos}SuSuSuSuSuSu" PlId EncId LangId \
                    nameId length offset
            incr ttfpos 12
            if {[lsearch -exact $NIDS $nameId] < 0} {# 8.5
                continue
            }
            set npos [expr {$SDoffset + $offset}]
            set Nstr [string range $ttfdata $npos $npos+$length] ;# 8.5
            set N ""

            if {$PlId == 3 && $EncId == 1 && $LangId == 0x409} {
                # Microsoft, Unicode, US English, PS Name
                if {$length & 1} {
                    error "PostScript name is UTF-16 string of odd length"
                }
                # Try to read a string of unicode chars:
                set N [encoding convertfrom unicode $Nstr]
            } elseif {$PlId == 1 && $EncId == 0 && $LangId == 0} {
                # Macintosh, Roman, English, PS Name
                # According to OpenType spec, if PS name exists, it must exist
                # both in MS Unicode and Macintosh Roman formats. Apparently,
                # you can find live TTF fonts which only have Macintosh format.
                set N [encoding convertfrom iso8859-1 $Nstr]
            }
            if {[string length $N] && $names($nameId) == ""} {
                set names($nameId) $N
                incr nameCount -1
                if {$nameCount == 0} break
            }
        }

        set BFA($ttfname,psName) [string map {" " -} $names(6)]
        if {$BFA($ttfname,psName) eq ""} {
            error "Could not find PostScript font name"
        }

        #----------------------------------
        # head - Font header table
        set ttfpos [lindex $ttftables(head) 1]
        binary scan $ttfdata "@${ttfpos}SuSuSux6Iux2Sux16SSSSx6SuSu" \
                ver_maj ver_min fnt_rev magic \
                BFA($ttfname,unitsPerEm) xMin yMin xMax yMax \
                indexToLocFormat glyphDataFormat

        if {$ver_maj != 1} {error "Unknown head table version $ver_maj"}
        if {$magic != 0x5F0F3CF5} {error "Invalid head table magic $magic"}

        set BFA($ttfname,bbox) [list \
                [Rescale $xMin] [Rescale $yMin] [Rescale $xMax] [Rescale $yMax]]

        # OS/2 - OS/2 and Windows metrics table (needs data from head table)
        if {[info exists ttftables(OS/2)]} {
            set ttfpos [lindex $ttftables(OS/2) 1]
            binary scan $ttfdata "@${ttfpos}Sux2Sux2Sux58SS" \
                    version usWeightClass fsType sTypoAscender sTypoDescender
            incr ttfpos 88

            set BFA($ttfname,ascent) [Rescale $sTypoAscender]
            set BFA($ttfname,descent) [Rescale $sTypoDescender]

            if {$version > 1} {
                binary scan $ttfdata "@${ttfpos}Su" sCapHeight
                set BFA($ttfname,CapHeight) [Rescale $sCapHeight]
            } else {
                set BFA($ttfname,CapHeight) $BFA($ttfname,ascent)
            }
        } else {
            # Microsoft TTFs require an OS/2 table; Apple ones do not.  Try to
            # cope. The data is not very important anyway.
            set usWeightClass 500
            set BFA($ttfname,ascent) [Rescale $yMax]
            set BFA($ttfname,descent) [Rescale $yMin]
            set BFA($ttfname,CapHeight) $BFA($ttfname,ascent)
        }

        set BFA($ttfname,stemV) [expr {50 + int(pow($usWeightClass / 65.0, 2))}] ;# 8.5

        #----------------------
        # post - PostScript table (needs data from OS/2 table)
        set ttfpos [lindex $ttftables(post) 1]
        binary scan $ttfdata "@${ttfpos}SuSuSuSuSuSuIu" \
                ver_maj ver_min itan0 itan1 ulpos ulthick isFixedPitch

        set BFA($ttfname,ItalicAngle) [expr {$itan0 + $itan1 / 65536.0}]

        set flags 4 ; # "symbolic".
        if {$BFA($ttfname,ItalicAngle) != 0} {set flags [expr {$flags | 32}]}
        if {$usWeightClass >= 600} {set flags [expr {$flags | (1 << 18)}]}
        if {$isFixedPitch} {set flags [expr {$flags | 1}]}
        set BFA($ttfname,flags) $flags
        set BFA($ttfname,fixed) $isFixedPitch

        # hhea - Horizontal header table
        set ttfpos [lindex $ttftables(hhea) 1]
        binary scan $ttfdata "@${ttfpos}SuSux28SuSu" \
                ver_maj ver_min metricDataFormat numberOfHMetrics
        if {$ver_maj != 1} {error "Unknown hhea table version"}
        if {$metricDataFormat != 0} {error "Unknown horizontal metric data format"}
        if {$numberOfHMetrics == 0} {error "Number of horizontal metrics is 0"}

        # maxp - Maximum profile table
        set ttfpos [lindex $ttftables(maxp) 1]
        binary scan $ttfdata "@${ttfpos}SuSuSu" \
                ver_maj ver_min numGlyphs
        if {$ver_maj != 1} {error "Unknown maxp table version"}
        if {!$charInfo} return

        # We don't care of this earlier:
        if {$glyphDataFormat != 0} {error "Unknown glyph data format"}

        # cmap - Character to glyph index mapping table
        set ttfpos [lindex $ttftables(cmap) 1]
        set cmap_offset $ttfpos
        binary scan $ttfdata "@${ttfpos}x2Su" cmapTableCount
        incr ttfpos 4

        for {set f 0} {$f < $cmapTableCount} {incr f} {
            binary scan $ttfdata "@${ttfpos}SuSuIu" platformID encodingID offset
            incr ttfpos 8
            if {($platformID == 3 && $encodingID == 1) || ($platformID == 0)} {
                # Microsoft, Unicode OR just Unicode
                binary scan $ttfdata "@[expr {$cmap_offset+$offset}]Su" format
                if {$format == 4} {
                    set unicode_cmap_offset [expr {$cmap_offset + $offset}]
                    break
                }
            }
            # This SHOULD NOT exit loop:
            if {($platformID == 3 && $encodingID == 0)} {
                binary scan $ttfdata "@[expr {$cmap_offset+$offset}]Su" format
                if {$format == 4} {
                    set unicode_cmap_offset [expr {$cmap_offset + $offset}]
                    break
                }
            }
        }

        if {![info exists unicode_cmap_offset]} {
            error "Font does not have cmap for Unicode"
        }
        incr unicode_cmap_offset 2
        binary scan $ttfdata "@${unicode_cmap_offset}Sux2Su" length segCount

        set segCount [expr {$segCount / 2}]
        set limit [expr {$unicode_cmap_offset + $length}]
        set ttfpos [expr {$unicode_cmap_offset + 12}]
        binary scan $ttfdata "@${ttfpos}Su$segCount" endCount
        set ttfpos [expr {$ttfpos + 2*$segCount + 2}]
        binary scan $ttfdata "@${ttfpos}Su$segCount" startCount
        set ttfpos [expr {$ttfpos + 2*$segCount}]
        binary scan $ttfdata "@${ttfpos}S$segCount" idDelta
        set ttfpos [expr {$ttfpos + 2*$segCount}]
        set idRangeOffset_start $ttfpos
        binary scan $ttfdata "@${ttfpos}Su$segCount" idRangeOffset

        # Now it gets tricky.
        for {set f 0} {$f < $segCount} {incr f} {
            set r_start [lindex $startCount $f]
            set r_end   [lindex $endCount   $f]
            for {set unichar $r_start} {$unichar <= $r_end} {incr unichar} {
                set r_offset [lindex $idRangeOffset $f]
                set r_delta [lindex $idDelta $f]
                if {$r_offset == 0} {
                    set glyph [expr {($unichar + $r_delta) & 0xFFFF}]
                } else {
                    set offset [expr {($unichar - $r_start) * 2 + $r_offset}]
                    set offset [expr {$idRangeOffset_start + 2 * $f + $offset}]
                    if {$offset > $limit} {
                        # workaround for broken fonts (like Thryomanes)
                        set glyph 0
                    } else {
                        binary scan $ttfdata "@${offset}Su" glyph
                        if {$glyph != 0} {
                            set glyph [expr {($glyph + $r_delta) & 0xFFFF}]
                        }
                    }
                }
                dict set BFA($ttfname,charToGlyph) $unichar $glyph ;# 8.5
                lappend glyphToChar($glyph) $unichar
            }
        }

        #-----------------------------------------------------
        # hmtx - Horizontal metrics table
        # (needs data from hhea, maxp, and cmap tables)
        set ttfpos [lindex $ttftables(hmtx) 1]
        for {set glyph 0} {$glyph < $numberOfHMetrics} {incr glyph} {
            # advance width and left side bearing. lsb is actually signed
            # short, but we don't need it anyway (except for subsetting)
            binary scan $ttfdata "@${ttfpos}SuSu" aw lsb
            incr ttfpos 4
            lappend BFA($ttfname,hmetrics) [list $aw $lsb]
            set aws [Rescale $aw]
            if {$glyph == 0} {set BFA($ttfname,defaultWidth) $aws}
            if {[info exists glyphToChar($glyph)]} {
                foreach char $glyphToChar($glyph) {
                    dict set BFA($ttfname,charWidths) $char $aws
                }
            }
        }

        # The rest of the table only lists advance left side bearings.
        # so we reuse aw set by the last iteration of the previous loop.
        # -- BUG (in reportlab) fixed here: aw used scaled in hmetrics,
        # -- i.e. float (must be int)
        for {set glyph $numberOfHMetrics} {$glyph < $numGlyphs} {incr glyph} {
            binary scan $ttfdata "@${ttfpos}Su" lsb
            incr ttfpos 2
            lappend BFA($ttfname,hmetrics) [list $aw $lsb]
            if {[info exists glyphToChar($glyph)]} {
                foreach char $glyphToChar($glyph) {
                    dict set BFA($ttfname,charWidths) $char $aws
                }
            }
        }

        # loca - Index to location
        set ttfpos [lindex $ttftables(loca) 1]
        incr numGlyphs
        if {$indexToLocFormat == 0} {
            binary scan $ttfdata "@${ttfpos}Su$numGlyphs" glyphPositions
            foreach el $glyphPositions {
                lappend BFA($ttfname,glyphPos) [expr {$el << 1}]
            }
        } elseif {$indexToLocFormat == 1} {
            binary scan $ttfdata "@${ttfpos}Iu$numGlyphs" BFA($ttfname,glyphPos)
        } else {
            error "Unknown location table format $indexToLocFormat"
        }
    }

    proc Rescale {x} {
        variable BFA
        variable ttfname
        return [expr {$x * 1000.0 / $BFA($ttfname,unitsPerEm)}]
    }

    # Creates a ToUnicode CMap for a given subset.
    proc MakeToUnicodeCMap {fontname subset} {
        set len [llength $subset]
        set cmap "/CIDInit /ProcSet findresource begin\n"
        append cmap "12 dict begin\n"
        append cmap "begincmap\n"
        append cmap "/CIDSystemInfo\n"
        append cmap "<< /Registry ($fontname)\n"
        append cmap "/Ordering ($fontname)\n"
        append cmap "/Supplement 0\n"
        append cmap ">> def\n"
        append cmap "/CMapName /$fontname def\n"
        append cmap "/CMapType 2 def\n"
        append cmap "1 begincodespacerange\n"
        append cmap "<00> <[format %02X [expr {$len-1}]]>\n"
        append cmap "endcodespacerange\n"
        append cmap "$len beginbfchar\n"
        set f 0
        foreach uchar $subset {
            append cmap [format "<%02X> <%04X>\n" $f $uchar]
            incr f
        }
        append cmap "endbfchar\n"
        append cmap "endcmap\n"
        append cmap "CMapName currentdict /CMap defineresource pop\n"
        append cmap "end\n"
        append cmap "end\n"
        return $cmap
    }

    # Create a subset of a TrueType font. Subset is a list of unicode values.
    proc MakeTTFSubset {bfname fontname subset} {
        variable BFA
        variable BFP
        variable FontsAttrs

        set GF_ARG_1_AND_2_ARE_WORDS     [expr {1 << 0}]
        set GF_WE_HAVE_A_SCALE           [expr {1 << 3}]
        set GF_MORE_COMPONENTS           [expr {1 << 5}]
        set GF_WE_HAVE_AN_X_AND_Y_SCALE  [expr {1 << 6}]
        set GF_WE_HAVE_A_TWO_BY_TWO      [expr {1 << 7}]

        # Build a mapping of glyphs in the subset to glyph numbers in
        # the original font.  Also build a mapping of UCS codes to
        # glyph values in the new font.

        # Start with 0 -> 0: "missing character"
        set glyphMap [list 0] ; # new glyph index -> old glyph index
        set glyphSet(0) 0     ; # old glyph index -> new glyph index
        #codeToGlyph            # unicode -> new glyph index
        foreach code $subset {
            if {[dict exists $BFA($bfname,charToGlyph) $code]} {
                set originalGlyphIdx [dict get $BFA($bfname,charToGlyph) $code]
            } else {
                set originalGlyphIdx 0
            }
            if {![info exists glyphSet($originalGlyphIdx)]} {
                set glyphSet($originalGlyphIdx) [llength $glyphMap]
                lappend glyphMap $originalGlyphIdx
            }
            set codeToGlyph($code) $glyphSet($originalGlyphIdx)
        }

        # Also include glyphs that are parts of composite glyphs
        set n 0
        while {$n < [llength $glyphMap]} {
            set originalGlyphIdx [lindex $glyphMap $n]
            set glyphPos [lindex $BFA($bfname,glyphPos) $originalGlyphIdx]
            set glyphEnd [lindex $BFA($bfname,glyphPos) $originalGlyphIdx+1]
            set glyphLen [expr {$glyphEnd - $glyphPos}]
            set cpos $glyphPos
            binary scan $BFP($bfname,glyf) "@${cpos}S" numberOfContours
            if {$numberOfContours < 0} {
                # composite glyph
                incr cpos 10
                set flags $GF_MORE_COMPONENTS
                while {$flags & $GF_MORE_COMPONENTS} {
                    binary scan $BFP($bfname,glyf) "@${cpos}SuSu" flags glyphIdx
                    incr cpos 4
                    if {![info exists glyphSet($glyphIdx)]} {
                        set glyphSet($glyphIdx) [llength $glyphMap]
                        lappend glyphMap $glyphIdx
                    }

                    if {$flags & $GF_ARG_1_AND_2_ARE_WORDS} {
                        incr cpos 4
                    } else {
                        incr cpos 2
                    }

                    if {$flags & $GF_WE_HAVE_A_SCALE} {
                        incr cpos 2
                    } elseif {$flags & $GF_WE_HAVE_AN_X_AND_Y_SCALE} {
                        incr cpos 4
                    } elseif {$flags & $GF_WE_HAVE_A_TWO_BY_TWO} {
                        incr cpos 8
                    }
                }
            }
            incr n
        }

        set n [llength $glyphMap]
        set numGlyphs $n

        while {$n > 1 && \
                [lindex $BFA($bfname,hmetrics) $n 0] == \
                [lindex $BFA($bfname,hmetrics) $n-1 0]} {
            incr n -1
        }
        set numberOfHMetrics $n

        # post - PostScript
        set    t(post) "\x00\x03\x00\x00"
        append t(post) [string range $BFP($bfname,post) 4 15]
        append t(post) [string repeat "\0" 16]

        # hhea - Horizontal Header
        set    t(hhea) [string range $BFP($bfname,hhea) 0 33]
        append t(hhea) [binary format Su $numberOfHMetrics]
        append t(hhea) [string range $BFP($bfname,hhea) 36 end]

        # maxp - Maximum Profile
        set    t(maxp) [string range $BFP($bfname,maxp) 0 3]
        append t(maxp) [binary format Su $numGlyphs]
        append t(maxp) [string range $BFP($bfname,maxp) 6 end]

        # cmap - Character to glyph mapping
        set entryCount [llength $subset]
        set length [expr {10 + $entryCount * 2}]
        foreach char $subset {lappend tlist $codeToGlyph($char)}
        set t(cmap) [binary format "SuSuSuSuSuSuSuSuSuSuSuSu*" 0 1 1 0 0 12 6 \
                $length 0 0 $entryCount $tlist]

        # hmtx - Horizontal Metrics
        for {set f 0} {$f < $numGlyphs} {incr f} {
            set originalGlyphIdx [lindex $glyphMap $f]
            foreach {aw lsb} [lindex $BFA($bfname,hmetrics) $originalGlyphIdx] break
            if {$f < $numberOfHMetrics} {
                append t(hmtx) [binary format Su $aw]
            }
            append t(hmtx) [binary format Su $lsb]
        }

        # glyf - Glyph data
        set pos 0
        for {set f 0} {$f < $numGlyphs} {incr f} {
            lappend offsets $pos
            set originalGlyphIdx [lindex $glyphMap $f]
            set glyphPos [lindex $BFA($bfname,glyphPos) $originalGlyphIdx]
            set glyphEnd [lindex $BFA($bfname,glyphPos) $originalGlyphIdx+1]
            set glyphLen [expr {$glyphEnd - $glyphPos}]
            set glyphEndPos [expr {$glyphPos + $glyphLen - 1}]
            set data [string range $BFP($bfname,glyf) $glyphPos $glyphEndPos]
            # Fix references in composite glyphs
            if {$glyphLen > 2} {
                binary scan $data "S" compos
                if {$compos < 0} {
                    set pos_in_glyph 10
                    set flags $GF_MORE_COMPONENTS
                    while {$flags & $GF_MORE_COMPONENTS} {
                        binary scan $data "@${pos_in_glyph}SuSu" flags glyphIdx
                        set data "[string range $data 0 $pos_in_glyph+1][binary format Su $glyphSet($glyphIdx)][string range $data $pos_in_glyph+4 end]"
                        incr pos_in_glyph 4
                        if {$flags & $GF_ARG_1_AND_2_ARE_WORDS} {
                            incr pos_in_glyph 4
                        } else {
                            incr pos_in_glyph 2
                        }
                        if {$flags & $GF_WE_HAVE_A_SCALE} {
                            incr pos_in_glyph 2
                        } elseif {$flags & $GF_WE_HAVE_AN_X_AND_Y_SCALE} {
                            incr pos_in_glyph 4
                        } elseif {$flags & $GF_WE_HAVE_A_TWO_BY_TWO} {
                            incr pos_in_glyph 8
                        }
                    }
                }
            }
            append t(glyf) $data
            incr pos $glyphLen
            if {$pos % 4 != 0}  {
                set padding [expr {4 - $pos % 4}]
                append t(glyf) [string repeat "\0" $padding]
                incr pos $padding
            }

        }
        lappend offsets $pos

        # loca - Index to location
        if {(($pos + 1) >> 1) > 0xFFFF} {
            set indexToLocFormat 1 ; # long format
            set t(loca) [binary format "Iu*" $offsets]
        } else {
            set indexToLocFormat 0 ; # short format
            foreach offset $offsets {
                append t(loca) [binary format "Su" [expr {$offset >> 1}]]
            }
        }

        # head - Font header
        set    t(head) [string range $BFP($bfname,head) 0 7]
        append t(head) [string repeat "\0" 4]
        append t(head) [string range $BFP($bfname,head) 12 49]
        append t(head) [binary format Su $indexToLocFormat]
        append t(head) [string range $BFP($bfname,head) 52 end]
        #----------------------------------------------------------------------
        set tables [lsort -unique [concat $BFA($bfname,tables) [array names t]]]
        set numTables [llength $tables]

        set searchRange 1
        set entrySelector 0

        while {$searchRange * 2 <= $numTables} {
            set searchRange [expr {$searchRange * 2}]
            incr entrySelector
        }
        set searchRange [expr {$searchRange * 16}]
        set rangeShift [expr {$numTables * 16 - $searchRange}]

        # Header
        set res [binary format "IuSuSuSuSu" [expr {0x00010000}] $numTables \
                $searchRange $entrySelector $rangeShift]

        # Table directory
        set offset [expr {12 + $numTables * 16}]
        foreach tag $tables {
            if {$tag eq "head"} {set head_start $offset}
            if {[info exists t($tag)]} {
                set len [string length $t($tag)]
                set checksum [CalcTTFCheckSum $t($tag) 0 $len]
            } else {
                set len [string length $BFP($bfname,$tag)]
                set checksum [CalcTTFCheckSum $BFP($bfname,$tag) 0 $len]
            }
            append res [binary format a4IuIuIu $tag $checksum $offset $len]
            incr offset [expr {($len + 3) & ~3}]
        }

        # Table data.
        foreach tag $tables {
            if {[info exists t($tag)]} {
                set len [string length $t($tag)]
                append res $t($tag)
            } else {
                set len [string length $BFP($bfname,$tag)]
                append res $BFP($bfname,$tag)
            }
            append res [string repeat "\0" [expr {(4 - ($len & 3)) & 3}]]
        }

        set len [string length $res]
        set checksum [CalcTTFCheckSum $res 0 $len]
        incr head_start 7

        set checksum [expr {(0xB1B0AFBA - $checksum) & 0xFFFFFFFF}]
        set res "[string range $res 0 $head_start][binary format Iu $checksum][string range $res $head_start+5 end]"

        set FontsAttrs($fontname,data) $res
        set FontsAttrs($fontname,SubFontIdx) $BFA($bfname,SubFontIdx)
        incr BFA($bfname,SubFontIdx)
    }

    # make subfont name
    proc MakeSFNamePrefix {idx} {
        string map {0 A 1 B 2 C 3 D 4 E 5 F 6 G 7 H 8 I 9 J} [format %06d $idx]
    }

    # ----- General font support -----
    # Create Font from BaseFont:
    proc createFont {bfname fontname enc_name} {
        variable FontsAttrs
        variable BFA
        variable Fonts

        set subset [list]
        for {set f 0} {$f<256} {incr f} {lappend codes $f}
        set uchars [encoding convertfrom $enc_name [binary format cu* $codes]]
        foreach unichar [split $uchars {}]  {
            lappend subset [scan $unichar %c]
        }

        if {$BFA($bfname,FontType) eq "TTF"} {
            # Create TTF subset here:
            MakeTTFSubset $bfname $fontname $subset
            set FontsAttrs($fontname,type) TTF
        } else {
            set FontsAttrs($fontname,type) Type1
        }

        lappend Fonts $fontname
        set FontsAttrs($fontname,basefontname) $bfname
        set FontsAttrs($fontname,uniset) $subset
        set FontsAttrs($fontname,specialencoding) 0
        set FontsAttrs($fontname,encoding) $enc_name
    }

    # subset must be a list of unicode values:
    proc createFontSpecEnc {bfname fontname subset} {
        variable FontsAttrs
        variable BFA
        variable Fonts

        if {$BFA($bfname,FontType) eq "TTF"} {
            # Create TTF subset here:
            MakeTTFSubset $bfname $fontname $subset
            set FontsAttrs($fontname,type) TTF
        } else {
            set FontsAttrs($fontname,type) Type1
        }

        lappend Fonts $fontname
        set FontsAttrs($fontname,basefontname) $bfname
        set FontsAttrs($fontname,uniset) $subset
        set FontsAttrs($fontname,specialencoding) 1

        set symcode 0
        foreach ucode $subset {
            set uchar [format %c $ucode]
            dict set FontsAttrs($fontname,encoding) $uchar \
                    [binary format cu $symcode]
            incr symcode
        }
    }

    # ===== Procs for Type1 fonts processing =====

    # Create encoding differences list:
    proc MakeEncDiff {BFN fontname} {
        variable BFA

        # get WinAnsiEncoding unicodes:
        for {set f 0} {$f < 256} {incr f} {lappend bcodes $f}
        set bchars [encoding convertfrom cp1252 [binary format cu* $bcodes]]
        foreach unichar [split $bchars {}]  {
            lappend bset [scan $unichar %c]
        }

        set f 0
        set res [list]
        set eqflag 1
        foreach ucode $::pdf4tcl::FontsAttrs($fontname,uniset) bcode $bset {
            if {$ucode != $bcode} {
                if {$eqflag} {lappend res $f}
                if {[dict exists $BFA($BFN,uni2glyph) $ucode]} {
                    lappend res "/[dict get $BFA($BFN,uni2glyph) $ucode]"
                } else {
                    lappend res "/.notdef"
                }
                set eqflag 0
            } else {
                set eqflag 1
            }
            incr f
        }
        return $res
    }

    proc PfbCheck {pos data mark} {
        binary scan $data "@${pos}cucu" d0 d1
        if {($d0 != 0x80) || ($d1 != $mark)} {error "Bad pfb data at $pos"}
        if {$mark == 3} return; #PFB_EOF
        incr pos 2
        binary scan $data "@${pos}iu" l
        incr pos 4
        set npos [expr {$pos + $l}]
        if {$npos > [string length $data]} {error "pfb data is too short"}
        return $npos
    }

    # There's no need to create NEW binary stream, use font as is:
    proc ParsePFB {} {
        variable type1PFB
        variable type1name
        variable BFA
        set p1 [PfbCheck 0 $type1PFB 1]
        set p2 [PfbCheck $p1 $type1PFB 2]
        set p3 [PfbCheck $p2 $type1PFB 1]
        PfbCheck $p3 $type1PFB 3
        set BFA($type1name,Length1) $p1
        set BFA($type1name,Length2) [expr {$p2-$p1+7}]
        set BFA($type1name,Length3) [expr {$p3-$p2-5}]
        set BFA($type1name,data) $type1PFB
    }

    # Creates charWidths and mapping 'unicode=>glyph_name' for this font.
    proc ParseAFM {} {
        variable type1AFM
        variable type1name
        variable BFA
        variable GlName2Uni

        array set nmap {Ascender ascent Descender descent FontBBox bbox}
        set BFA($type1name,ascent) 1000
        set BFA($type1name,descent) 0
        set BFA($type1name,CapHeight) 1000
        set BFA($type1name,ItalicAngle) 0
        set BFA($type1name,stemV) 0
        set BFA($type1name,bbox) [list 0 0 1000 1000]

        set lineslst [split $type1AFM "\n"]
        if {[llength $lineslst] < 2} {error "AFM hasn't enough data"}

        set InMetrics 0
        set InHeader 0
        foreach line $lineslst {
            if {[string equal -nocase -length 7 $line comment]} continue
            # StartCharMetrics terminates header:
            switch -nocase -glob -- $line {
                "StartCharMetrics*" {set InMetrics 1; continue}
                "StartFontMetrics*" {set InHeader 1; continue}
                "EndCharMetrics*"   {break}
            }

            if {$InMetrics} {
                set toklst [list]
                set reslst [list]
                # Create toklst -- list of needed tokens (only starting three):
                foreach chunk [lrange [split $line ";"] 0 2] {
                    foreach el $chunk {
                        lappend toklst $el
                    }
                }
                # Convert and store tokens:
                foreach {l r} $toklst {et ss} [list C %d WX %d N %s] {
                    if {$l != $et} {error "Bad line in font AFM ($et)"}
                    if {![scan $r $ss val]} {
                        error "Incorrect '$et' value in font AFM"
                    }
                    lappend reslst $val
                }
                # Must create charWidths and font's Uni2Glyph here:
                set N  [lindex $reslst 2]
                set WX [lindex $reslst 1]

                set ucode -1
                if {$N ne ".notdef"} {
                    catch {set ucode $GlName2Uni($N)}
                } else {
                    set ucode 0
                }
                if {($ucode == -1) && [string equal -length 3 $N "uni"]} {
                    scan $N "uni%x" ucode
                }

                if {$ucode != -1} {
                    dict set BFA($type1name,charWidths) $ucode $WX
                    dict set BFA($type1name,uni2glyph) $ucode $N
                }
            } elseif {$InHeader} {
                # Split into 2 parts on first space:
                set idx [string first " " $line]
                set l [string range $line 0 $idx-1]
                set r [string range $line $idx+1 end]
                if {[info exists nmap($l)]} {
                    set l $nmap($l)
                }
                set BFA($type1name,$l) $r
            }
        }
    }

    proc createBaseType1Font {basefontname afm_data pfb_data} {
        variable type1name $basefontname
        variable type1AFM $afm_data
        variable type1PFB $pfb_data
        InitBaseType1
    }

    proc loadBaseType1Font {basefontname AFMfilename PFBfilename} {
        variable type1name $basefontname
        variable type1AFM
        variable type1PFB
        set fd [open $AFMfilename "r"]
        set type1AFM [read $fd]
        close $fd
        set fd [open $PFBfilename "rb"]
        set type1PFB [read $fd]
        close $fd
        InitBaseType1
    }

    proc InitBaseType1 {} {
        variable type1name
        variable type1AFM
        variable type1PFB
        ParseAFM
        ParsePFB
        set ::pdf4tcl::BFA($type1name,FontType) Type1
        unset -nocomplain type1PFB
        unset -nocomplain type1AFM
        unset -nocomplain type1name
    }

    # 8.4 compatiblity patch for some functionality.
    if {[llength [info commands dict]] == 0} {
        proc ::dict {subC d i} {
            if {$subC eq "get"} {
                array set x $d
                return $x($i)
            }
            return -code error "No support for dict $subC"
        }
    }
}

# Object used for generating pdf
snit::type pdf4tcl::pdf4tcl { ##nagelfar nocover
    variable pdf

    #######################################################################
    # Global option handling
    #######################################################################

    option -file      -default "" -readonly 1
    option -paper     -default a4     -validatemethod CheckPaper \
            -configuremethod SetPageOption
    option -landscape -default 0      -validatemethod CheckBoolean \
            -configuremethod SetPageOption
    option -orient    -default 1      -validatemethod CheckBoolean
    option -unit      -default p      -validatemethod CheckUnit \
            -configuremethod SetUnit -readonly 1
    option -compress  -default 0      -validatemethod CheckBoolean \
            -configuremethod SetCompress -readonly 1
    option -margin    -default 0      -validatemethod CheckMargin \
            -configuremethod SetPageOption
    option -rotate    -default 0      -validatemethod CheckRotation \
            -configuremethod SetPageOption

    # Validator for -paper
    method CheckPaper {option value} {
        set papersize [pdf4tcl::getPaperSize $value]
        if {[llength $papersize] == 0} {
            return -code error "papersize $value is unknown"
        }
    }

    # Validator for -unit
    method CheckUnit {option value} {
        if {![info exists ::pdf4tcl::units($value)]} {
            return -code error "unit $value is unknown"
        }
    }

    # Validator for -margin
    method CheckMargin {option value} {
        switch [llength $value] {
            1 - 2 - 4 {
                foreach elem $value {
                    if {[catch {pdf4tcl::getPoints $elem}]} {
                        return -code error "Bad margin value '$elem'"
                    }
                }
            }
            default {
                return -code error "Bad margin list '$value'"
            }
        }
    }

    # Validator for boolean options
    method CheckBoolean {option value} {
        if {![string is boolean -strict $value]} {
            return -code error "option $option must have a boolean value."
        }
    }

    # Validator for -rotate
    method CheckRotation {option value} {
        if { $value % 90  } {
            return -code error "Rotation $value not a multiple of 90"
        }
    }

    # Configure method for -compress
    method SetCompress {option value} {
        variable ::pdf4tcl::g
        if {$value} {
            if {$g(haveZlib)} {
                set options($option) 1
            } else {
                puts stderr "Package zlib not available. Sorry, no compression."
            }
        } else {
            set options($option) 0
        }
    }

    # Configure method for page properties
    method SetPageOption {option value} {
        set options($option) $value
        # Fill in page properies
        $self SetPageSize   $options(-paper) $options(-landscape) \
                $options(-rotate)
        $self SetPageMargin $options(-margin)
    }

    # Configure method for -unit
    method SetUnit {option value} {
        set options($option) $value
        set pdf(unit) $::pdf4tcl::units($value)
    }

    #######################################################################
    # Constructor
    #######################################################################

    constructor {args} {
        variable images
        variable fonts
        variable bitmaps
        variable patterns
        variable metadata
        #Array of type1 base fonts already included in this PDF file:
        variable type1basefonts

        set pdf(bookmarks) {}
        #set metadata(CreationDate) [string range [clock format [clock seconds] -format {D:%Y%m%d%H%M%S%z} -gmt 0] 0 end-2]

        # The unit translation factor is needed before parsing arguments
        set pdf(unit) 1.0

        $self configurelist $args

        # Document data
        set pdf(pages) {}
        set pdf(pdf_obj) 4 ;# Objects 1-3 are reserved for use in "finish"
        set pdf(out_pos) 0
        set pdf(data_start) 0
        set pdf(data_len) 0
        array set fonts {}
        array set type1basefonts {}
        set pdf(font_set) false
        set pdf(in_text_object) false
        array set images {}
        array set bitmaps {}
        array set patterns {}
        set pdf(objects) {}
        set pdf(compress) $options(-compress)
        set pdf(finished) false
        set pdf(inPage) false
        set pdf(fillColor) [list 0 0 0]
        # start without default font
        set pdf(font_size) 1
        set pdf(current_font) ""
        set pdf(line_spacing) 1.0

        # Page data
        # Fill in page properies
        $self SetPageSize   $options(-paper) $options(-landscape) \
                $options(-rotate)
        $self SetPageMargin $options(-margin)
        set pdf(orient) $options(-orient)

        # The first buffer if for collecting page data until end of page.
        # This is to support compressing whole pages.
        set pdf(ob) ""

        # Write to file directly if requested.
        set pdf(ch) ""
        if {$options(-file) ne ""} {
            if {[catch {open $options(-file) "w"} ch]} {
                return -code error "Could not open file $options(-file) for writing: $ch"
            }
            fconfigure $ch -translation binary
            set pdf(ch) $ch
        }

        # collect output in memory
        set pdf(pdf) ""

        # Start on pdfout
        $self Pdfout "%PDF-1.4\n"
        set pdf(version) 1.4
        # Add some chars >= 0x80 as recommended by the PDF standard
        # to make it easy to detect that this is not an ASCII file.
        $self Pdfout "%\xE5\xE4\xF6\n"
    }

    destructor {
        # Close any open channel
        if {[info exists pdf(ch)] && $pdf(ch) ne ""} {
            catch {$self finish}
            catch {close $pdf(ch)}
            set pdf(ch) ""
        }
    }

    # Deprecated destroy function
    method cleanup {} {
        $self destroy
    }

    #######################################################################
    # Collect PDF Output
    #######################################################################

    # Add raw data to accumulated pdf output
    method Pdfout {out} {
        append pdf(ob) $out
        incr pdf(out_pos) [string length $out]
    }

    # Add line of words to accumulated pdf output
    method Pdfoutn {args} {
        set out [join $args " "]\n
        $self Pdfout $out
    }

    # Helper to format a line consisiting of numbers and last a command
    method Pdfoutcmd {args} {
        set str ""
        foreach num [lrange $args 0 end-1] {
            append str [Nf $num] " "
        }
        append str "[lindex $args end]\n"
        $self Pdfout $str
    }

    # Move data from pdf(ob) cache to final destination.
    # Return number of bytes added
    method Flush {{compress 0}} {
        set data $pdf(ob)
        set pdf(ob) ""
        if {$compress} {
            set data [zlib compress $data]
        }
        set len [string length $data]
        if {$pdf(ch) eq ""} {
            append pdf(pdf) $data
        } else {
            puts -nonewline $pdf(ch) $data
        }
        return $len
    }

    #######################################################################
    # ?? Handling
    #######################################################################

    # If any feature requires PDF version > 1.4 they should call this
    method RequireVersion {version} {
        if {$version > $pdf(version)} {
            set pdf(version) $version
        }
    }

    #######################################################################
    # Page Handling
    #######################################################################

    # Fill in page margin from a user specified value
    method SetPageMargin {value} {
        set value2 {}
        foreach val $value {
            lappend value2 [pdf4tcl::getPoints $val $pdf(unit)]
        }
        switch -- [llength $value2] {
            1 {
                set pdf(marginleft)   [lindex $value2 0]
                set pdf(marginright)  [lindex $value2 0]
                set pdf(margintop)    [lindex $value2 0]
                set pdf(marginbottom) [lindex $value2 0]
            }
            2 {
                set pdf(marginleft)   [lindex $value2 0]
                set pdf(marginright)  [lindex $value2 0]
                set pdf(margintop)    [lindex $value2 1]
                set pdf(marginbottom) [lindex $value2 1]
            }
            4 {
                set pdf(marginleft)   [lindex $value2 0]
                set pdf(marginright)  [lindex $value2 1]
                set pdf(margintop)    [lindex $value2 2]
                set pdf(marginbottom) [lindex $value2 3]
            }
            default { ##nagelfar nocover
                # This should not happen since validation should catch it
                puts "ARARARARARAR '$value'"
            }
        }
    }

    # Fill in page data from options
    method SetPageSize {paper landscape rotation} {
        set papersize [pdf4tcl::getPaperSize $paper $pdf(unit)]
        set width  [lindex $papersize 0]
        set height [lindex $papersize 1]

        # Switch if landscape has been asked for
        if {$landscape} {
            set tmp    $width
            set width  $height
            set height $tmp
        }
        set pdf(width)  $width
        set pdf(height) $height
        set pdf(xpos)   0
        set pdf(ypos)   $height
        set pdf(rotate) $rotation
        set pdf(origxpos) 0
        set pdf(origypos) $height
    }

    # Start on a new page
    method startPage {args} {
        # Get defaults from document
        set localopts(-orient)    $options(-orient)
        set localopts(-landscape) $options(-landscape)
        set localopts(-margin)    $options(-margin)
        set localopts(-paper)     $options(-paper)
        set localopts(-rotate)    $options(-rotate)

        if {[llength $args] == 1} {
            # Single arg = paper
            $self CheckPaper -paper [lindex $args 0]
            set localopts(-paper) [lindex $args 0]
        } elseif {[llength $args] == 2 && [string is digit [join $args ""]]} {
            # Old style two numeric args = {width height}
            $self CheckPaper -paper $args
            set localopts(-paper) $args
        } elseif {[llength $args] == 3 && [string is digit [join $args ""]]} {
            # Old style three numeric args = {width height orient}
            $self CheckPaper -paper [lrange $args 0 1]
            set localopts(-paper)   [lrange $args 0 1]
            set localopts(-orient)  [lindex $args 2]
        } elseif {[llength $args] % 2 != 0} {
            # Uneven, error
            return -code error "Uneven number of arguments to startPage"
        } else {
            # Parse options
            foreach {option value} $args {
                switch -- $option {
                    -paper {
                        $self CheckPaper $option $value
                    }
                    -landscape {
                        $self CheckBoolean $option $value
                    }
                    -margin {
                        $self CheckMargin $option $value
                    }
                    -orient {
                        $self CheckBoolean $option $value
                    }
                    -rotate {
                        $self CheckRotation $option $value
                    }
                    default {
                        return -code error "Unknown option $option"
                    }
                }
                set localopts($option) $value
            }
        }

        if {$pdf(inPage)} {
            $self endPage
        }
        # Fill in page properies
        $self SetPageSize $localopts(-paper) $localopts(-landscape) \
                $localopts(-rotate)
        $self SetPageMargin $localopts(-margin)
        set pdf(orient) $localopts(-orient)

        set pdf(inPage) 1

        # dimensions
        set oid [$self GetOid]
        lappend pdf(pages) $oid
        $self Pdfout "$oid 0 obj\n"
        $self Pdfout "<</Type /Page\n"
        $self Pdfout "/Parent 2 0 R\n"
        $self Pdfout "/Resources 3 0 R\n"
        $self Pdfout [format "/MediaBox \[0 0 %g %g\]\n" $pdf(width) $pdf(height)]
        if {$pdf(rotate) != 0} {
            $self Pdfout "/Rotate $pdf(rotate)\n"
        }
        $self Pdfout "/Contents \[[$self NextOid] 0 R\]\n"
        $self Pdfout ">>\n"
        $self Pdfout "endobj\n\n"

        # start of contents
        set oid [$self GetOid]
        $self Pdfout "$oid 0 obj\n"
        # Allocate an object for the page length
        set pdf(pagelengthoid) [$self GetOid 1]
        $self Pdfout "<<\n/Length $pdf(pagelengthoid) 0 R\n"
        if {$pdf(compress)} {
            $self Pdfout "/Filter \[/FlateDecode\]\n"
        }
        $self Pdfout ">>\nstream\n"
        set pdf(data_start) $pdf(out_pos)
        set pdf(in_text_object) false

        # no font set on new pages
        set pdf(font_set) false

        # capture output
        $self Flush
    }

    # Finish a page
    method endPage {} {
        if {! $pdf(inPage)} {
            return
        }
        if {$pdf(in_text_object)} {
            $self Pdfout "\nET\n"
        }
        # get buffer
        set data_len [$self Flush $pdf(compress)]
        set pdf(out_pos) [expr {$pdf(data_start)+$data_len}]
        $self Pdfout "\nendstream\n"
        $self Pdfout "endobj\n\n"

        # Create Length object
        $self StoreXref $pdf(pagelengthoid)
        $self Pdfout "$pdf(pagelengthoid) 0 obj\n"
        incr data_len
        $self Pdfout "$data_len\n"
        $self Pdfout "endobj\n\n"
        set pdf(inPage) false

        # Dump stored objects
        $self FlushObjects
    }

    method FlushObjects {} {
        if {$pdf(inPage)} {
            return -code error "FlushObjects may not be called when in a page"
        }

        # Dump stored objects
        foreach {oid body} $pdf(objects) {
            $self StoreXref $oid
            $self Pdfout $body
        }
        set pdf(objects) {}
        $self Flush
    }

    # This must create optionally compressed PDF stream.
    # dictval must contain correct string value without << terminator.
    # Terminator and length will be added by this proc.
    proc MakeStream {dictval body compress} {
        set res $dictval
        if {$compress} {
            set body [zlib compress $body]
            append res "\n/Filter \[/FlateDecode\]"
        }
        set len [string length $body]
        append res "\n/Length $len\n>>\nstream\n"
        append res $body
        append res "\nendstream"
        return $res
    }

    # Create an object to be added to the stream at a suitable time.
    # Returns the Object Id.
    method AddObject {body} {
        set oid [$self GetOid 1]
        lappend pdf(objects) $oid "$oid 0 obj\n$body\nendobj\n"
        return $oid
    }

    # Finish document
    method finish {} {
        variable images
        variable patterns
        variable fonts
        variable metadata

        if {$pdf(finished)} {
            return
        }

        if {$pdf(inPage)} {
            $self endPage
        }
        # Object 1 is the Root of the document
        $self StoreXref 1
        $self Pdfout "1 0 obj\n"
        $self Pdfout "<<\n"
        $self Pdfout "/Type /Catalog\n"
        if {$pdf(version) > 1.4} {
            $self Pdfout "/Version $pdf(version)\n"
        }
        $self Pdfout "/Pages 2 0 R\n"
        # Determine the number of bookmarks to add to the document.
        set nbookmarks [llength $pdf(bookmarks)]
        if {$nbookmarks > 0} {
            $self Pdfout "/Outlines [$self NextOid] 0 R\n"
        }
        $self Pdfout ">>\n"
        $self Pdfout "endobj\n\n"

        # Object 2 lists the pages
        $self StoreXref 2
        $self Pdfout "2 0 obj\n"
        $self Pdfout "<<\n/Type /Pages\n"
        $self Pdfout "/Count [llength $pdf(pages)]\n"
        $self Pdfout "/Kids \["
        foreach oid $pdf(pages) {
            $self Pdfout "$oid 0 R "
        }
        $self Pdfout "\]\n"
        $self Pdfout ">>\n"
        $self Pdfout "endobj\n\n"

        # Object 3 is the Resources Object
        $self StoreXref 3
        $self Pdfout "3 0 obj\n"
        $self Pdfout "<<\n"
        $self Pdfout "/ProcSet\[/PDF /Text /ImageC\]\n"

        # font references
        if {[array size fonts] > 0} {
            $self Pdfout "/Font <<\n"
            foreach fontname [array names fonts] {
                set oid $fonts($fontname)
                $self Pdfout "/$fontname $oid 0 R\n"
            }
            $self Pdfout ">>\n"
        }

        # image references
        if {[array size images] > 0} {
            $self Pdfout "/XObject <<\n"
            foreach key [array names images] {
                set oid [lindex $images($key) 2]
                $self Pdfout "/$key $oid 0 R\n"
            }
            $self Pdfout ">>\n"
        }
        # pattern references
        if {[array size patterns] > 0} {
            $self Pdfout "/ColorSpace <<\n"
            $self Pdfout "/Cs1 \[/Pattern /DeviceRGB\]\n"
            $self Pdfout ">>\n"

            $self Pdfout "/Pattern <<\n"
            foreach key [array names patterns] {
                set oid [lindex $patterns($key) 2]
                $self Pdfout "/$key $oid 0 R\n"
            }
            $self Pdfout ">>\n"
        }

        $self Pdfout ">>\nendobj\n\n"

        if {$nbookmarks > 0} {
            set count [BookmarkCount $pdf(bookmarks) -1]

            # Create the outline dictionary.
            set oid [$self GetOid]
            $self StoreXref $oid
            $self Pdfout "$oid 0 obj\n"
            $self Pdfout "<<\n/Type /Outlines\n"
            $self Pdfout "/First [expr {$oid + 1}] 0 R\n"
            $self Pdfout "/Last [expr {$oid + $nbookmarks}] 0 R\n"
            if {$count} {$self Pdfout "/Count $count\n"}
            $self Pdfout ">>\nendobj\n\n"

            # Create the outline item dictionary for each bookmark.
            set nbookmark 0
            set parent $oid
            set previous {}
            foreach bookmark $pdf(bookmarks) {
                if {[lindex $bookmark 1] == 0} {
                    set previous [$self BookmarkObject $parent $previous [lrange $pdf(bookmarks) $nbookmark end]]
                }
                incr nbookmark
            }
        }

        # Create the PDF document information dictionary.
        if {[array exists metadata]} {
            set metadata_oid [$self GetOid]
            $self StoreXref $metadata_oid
            $self Pdfout "$metadata_oid 0 obj\n<<\n"
            foreach {name value} [array get metadata] {
                $self Pdfout "/$name ([CleanText $value $pdf(current_font)])\n"
            }
            $self Pdfout ">>\nendobj\n\n"
        }

        # Cross reference table
        set xref_pos $pdf(out_pos)
        $self Pdfout "xref\n"
        $self Pdfout "0 [$self NextOid]\n"
        $self Pdfout "0000000000 65535 f \n"
        for {set a 1} {$a<[$self NextOid]} {incr a} {
            set xref $pdf(xref,$a)
            $self Pdfout [format "%010ld 00000 n \n" $xref]
        }

        # Document trailer
        $self Pdfout "trailer\n"
        $self Pdfout "<<\n"
        $self Pdfout "/Size [$self NextOid]\n"
        $self Pdfout "/Root 1 0 R\n"
        if {[info exists metadata_oid]} {
            $self Pdfout "/Info $metadata_oid 0 R\n"
        }
        $self Pdfout ">>\n"
        $self Pdfout "\nstartxref\n"
        $self Pdfout "$xref_pos\n"
        $self Pdfout "%%EOF\n"
        $self Flush
        set pdf(finished) true
    }

    # Get finished PDF data
    method get {} {
        if {$pdf(inPage)} {
            $self endPage
        }
        if {! $pdf(finished)} {
            $self finish
        }
        return $pdf(pdf)
    }

    # Write PDF data to file
    method write {args} {
        set chan stdout
        set outfile 0
        foreach {arg value} $args {
            switch -- $arg {
                "-file" {
                    if {[catch {open $value "w"} chan]} {
                        return -code error "Could not open file $value for writing: $chan"
                    } else {
                        set outfile 1
                    }
                }
                default {
                    return -code error "unknown option $arg."
                }
            }
        }

        fconfigure $chan -translation binary
        puts -nonewline $chan [$self get]
        if {$outfile} {
            close $chan
        }
    }

    # Transform absolute user coordinates to page coordinates
    # This should take into account orientation, margins.
    method Trans {x y txName tyName} {
        upvar 1 $txName tx $tyName ty

        set px [pdf4tcl::getPoints $x $pdf(unit)]
        set py [pdf4tcl::getPoints $y $pdf(unit)]

        set tx [expr {$px + $pdf(marginleft)}]
        if {$pdf(orient)} {
            set ty [expr {$py + $pdf(margintop)}]
            set ty [expr {$pdf(height) - $ty}]
        } else {
            set ty [expr {$py + $pdf(marginbottom)}]
        }
    }

    # Transform relative user coordinates to page coordinates
    # This should take into account orientation, but not margins.
    method TransR {x y txName tyName} {
        upvar 1 $txName tx $tyName ty

        set tx [pdf4tcl::getPoints $x $pdf(unit)]
        set ty [pdf4tcl::getPoints $y $pdf(unit)]

        if {$pdf(orient)} {
            set ty [expr {- $ty}]
        }
    }

    # Returns width and height of drawable area, excluding margins.
    method getDrawableArea {} {
        set w [expr {$pdf(width)  - $pdf(marginleft) - $pdf(marginright)}]
        set h [expr {$pdf(height) - $pdf(margintop)  - $pdf(marginbottom)}]
        # Translate to current unit
        set w [expr {$w / $pdf(unit)}]
        set h [expr {$h / $pdf(unit)}]
        return [list $w $h]
    }

    #######################################################################
    # Bookmark Handling
    #######################################################################

    method bookmarkAdd {args} {
        set closed 0
        set level  0
        set title  {}

        foreach {option value} $args {
            switch -- $option {
                -title {
                    set value [string trim $value]
                    if {[string length $value] == 0} {
                        return -code error "Option $option requires a string."
                    }
                    set title $value
                }
                -level {
                    if {[string is integer -strict $value]} {
                        if {$value < 0} {
                            return -code error "Option $option requires a non-negative integer value."
                        }
                    } else {
                        return -code error "Option $option requires a non-negative integer value."
                    }
                    set level $value
                }
                -closed {
                    $self CheckBoolean $option $value
                    set closed $value
                }
                default {
                    return -code error "Unknown option $option"
                }
            }
        }

        if {$pdf(pages) == {}} {
            return -code error "No pages defined."
        }

        # Determine the object id of the current page.
        set oid [lindex $pdf(pages) end]

        # Add the bookmark to the list.
        lappend pdf(bookmarks) [list $oid $level $closed $title]
    }

    #---------------------------------------------------------------------------
    # This procedure determines the number of open items of an outline
    # dictionary object.

    proc BookmarkCount {bookmarks level} {
        set count 0

        # Increment the count if the bookmark is not closed.
        foreach bookmark $bookmarks {
            if {[lindex $bookmark 1] <= $level} {break}
            if {! [lindex $bookmark 2]} {
                incr count
            }
        }

        return $count
    }

    #---------------------------------------------------------------------------
    # This procedure creates a outline item dictionary object.

    method BookmarkObject {parent previous bookmarks} {
        set bookmark [lindex $bookmarks 0]

        set destination [lindex $bookmark 0]
        set level       [lindex $bookmark 1]
        set closed      [lindex $bookmark 2]
        set title       [lindex $bookmark 3]

        set oid [$self GetOid]
        $self StoreXref $oid

        BookmarkProperties $oid $level [lrange $bookmarks 1 end] \
                next first last count

        if {$closed} {
            set count [expr {-$count}]
        }

        $self Pdfout "$oid 0 obj\n"
        $self Pdfout "<<\n/Title ([CleanText $title $pdf(current_font)])\n"
        $self Pdfout "/Parent $parent 0 R\n"
        if {$previous != {}} {$self Pdfout "/Prev $previous 0 R\n"}
        if {$next     != {}} {$self Pdfout "/Next $next 0 R\n"}
        if {$first    != {}} {$self Pdfout "/First $first 0 R\n"}
        if {$last     != {}} {$self Pdfout "/Last $last 0 R\n"}
        if {$count} {$self Pdfout "/Count $count\n"}
        $self Pdfout "/Dest \[$destination 0 R /XYZ null null null\]\n"
        $self Pdfout ">>\n"
        $self Pdfout "endobj\n\n"

        if {$next != {}} {
            set previous $oid
        }

        # Create the bookmark objects for all bookmarks that are children of
        # this bookmark.
        if {$first != {}} {
            set parent $oid
            set prev {}
            incr level
            set n 0
            foreach bookmark [lrange $bookmarks 1 end] {
                incr n
                if {[lindex $bookmark 1] < $level} {break}
                if {[lindex $bookmark 1] == $level} {
                    set prev [$self BookmarkObject $parent $prev \
                            [lrange $bookmarks $n end]]
                }
            }
        }

        return $previous
    }

    #---------------------------------------------------------------------------
    # This procedure determines the properties for an outline item dictionary
    # object.

    proc BookmarkProperties {oid current bookmarks n f l c} {
        upvar 1 $n next $f first $l last $c count

        set next  {}
        set first {}
        set last  {}

        # Determine the number of open decendants.
        set count [BookmarkCount $bookmarks $current]

        set child [expr {$current + 1}]

        set n 0

        foreach bookmark $bookmarks {
            incr n

            set level [lindex $bookmark 1]

            if {$level < $current} {break}

            # Determine the object ID for the next bookmark at the same level.
            if {$next == {}} {
                if {$level == $current} {
                    set next [expr {$oid + $n}]
                    continue
                }

                # Determine the object ID for the first and last child
                # bookmarks.
                if {$level == $child} {
                    if {$first == {}} {
                        set first [expr {$oid + $n}]
                    }
                    set last [expr {$oid + $n}]
                }
            }
        }
    }

    #--------------------------------------------------------------------------
    # Configure method for the PDF document metadata options.
    method metadata {args} {
        variable metadata
        foreach {option value} $args {
            set value [string trim $value]
            if {[string length $value] > 0} {
                switch -- $option {
                    -author   {set metadata(Author)   $value}
                    -creator  {set metadata(Creator)  $value}
                    -keywords {set metadata(Keywords) $value}
                    -producer {set metadata(Producer) $value}
                    -subject  {set metadata(Subject)  $value}
                    -title    {set metadata(Title)    $value}
                    -creationdate {
                        if {$value == 0} {
                            set value [clock seconds]
                        }
                        set metadata(CreationDate) [string range [clock format $value -format {D:%Y%m%d%H%M%S%z} -gmt 0] 0 end-2]
                    }
                }
            }
        }
    }

    #######################################################################
    # Text Handling
    #######################################################################

    # Set current font
    method setFont {size {fontname ""} {internal 0}} {
        if {$fontname eq ""} {
            if {$pdf(current_font) eq ""} {
                return -code error "No font family set"
            }
            set fontname $pdf(current_font)
        }

        # Font already loaded?
        if {[lsearch -exact $::pdf4tcl::Fonts $fontname] < 0} { #8.5
            return -code error "Font $fontname doesn't exist"
        }

        if {!$internal} {
            set size [pdf4tcl::getPoints $size $pdf(unit)]
        }

        set pdf(current_font) $fontname
        set pdf(font_size) $size

        # Delay putting things in until we are actually on a page
        if {$pdf(inPage)} {
            $self SetupFont
        }
    }

    # Set the current font on the page
    method SetupFont {} {
        variable fonts
        variable ::pdf4tcl::BFA
        variable type1basefonts

        if {$pdf(current_font) eq ""} {
            return -code error "No font set"
        }
        set fontname $pdf(current_font)
        $self Pdfoutn "/$fontname [Nf $pdf(font_size)]" "Tf"
        $self Pdfoutcmd 0 "Tr"
        $self Pdfoutcmd $pdf(font_size) "TL"

        # Make sure a font object exists
        if {![info exists fonts($fontname)]} {
            set fonttype $::pdf4tcl::FontsAttrs($fontname,type)
            if {$fonttype eq "std"} {
                set body    "<<\n/Type /Font\n"
                append body "/Subtype /Type1\n"
                append body "/Encoding /WinAnsiEncoding\n"
                append body "/Name /$fontname\n"
                append body "/BaseFont /$fontname\n"
                append body ">>"
           } elseif {$fonttype eq "TTF"} {
                # Add truetype font objectS:
                set BFN $::pdf4tcl::FontsAttrs($fontname,basefontname)
                set SFI $::pdf4tcl::FontsAttrs($fontname,SubFontIdx)
                set BaseFN "[MakeSFNamePrefix $SFI]+$BFN"
                # 1. Font subset binary data.
                set lc [string length $::pdf4tcl::FontsAttrs($fontname,data)]
                set dictv "<<\n/Length1 $lc"
                set body [MakeStream $dictv \
                        $::pdf4tcl::FontsAttrs($fontname,data) \
                        $pdf(compress)]
                set fsoid [$self AddObject $body]
                # 2. Font subset descriptor.
                set    body "<<\n/FontName /$BaseFN\n"
                append body "/StemV [Nf $BFA($BFN,stemV)]\n"
                append body "/FontFile2 $fsoid 0 R\n"
                append body "/Ascent [Nf $BFA($BFN,ascent)]\n"
                append body "/Flags $BFA($BFN,flags)\n"
                append body "/Descent [Nf $BFA($BFN,descent)]\n"
                append body "/ItalicAngle [Nf $BFA($BFN,ItalicAngle)]\n"
                foreach n $BFA($BFN,bbox) {lappend fbbox [Nf $n]}
                append body "/FontBBox \[$fbbox\]\n"
                append body "/Type /FontDescriptor\n"
                append body "/CapHeight [Nf $BFA($BFN,CapHeight)]\n>>"
                set foid [$self AddObject $body]
                # 3. ToUnicode Cmap for subset.
                set body [MakeStream "<<" \
                        [MakeToUnicodeCMap $BaseFN \
                        $::pdf4tcl::FontsAttrs($fontname,uniset)] \
                        $pdf(compress)]
                set uoid [$self AddObject $body]
                # 4. Font object.
                # Make array of widths here:
                set Widths [list]
                foreach ucode $::pdf4tcl::FontsAttrs($fontname,uniset) {
                    set res 0.0
                    if {[dict exists $BFA($BFN,charWidths) $ucode]} {
                        set res [dict get $::pdf4tcl::BFA($BFN,charWidths) $ucode]
                    }
                    lappend Widths [Nf $res]
                }
                set body    "<<\n/FirstChar 0\n"
                append body "/LastChar [expr {[llength $Widths]-1}]\n"
                append body "/ToUnicode $uoid 0 R\n"
                append body "/FontDescriptor $foid 0 R\n"
                append body "/Name /$fontname\n"
                append body "/BaseFont /$BaseFN\n"
                append body "/Subtype /TrueType\n"
                append body "/Widths \[$Widths\]\n"
                append body "/Type /Font\n"
                append body ">>"
            } else {
                # Add type1 font objects:
                set BFN $::pdf4tcl::FontsAttrs($fontname,basefontname)
                # Font data & descriptor if not already included in PDF file:
                if {![info exists type1basefonts($BFN)]} {
                    #1. Font data:
                    set    dictv "<<\n/Length1 $BFA($BFN,Length1)"
                    append dictv "\n/Length2 $BFA($BFN,Length2)"
                    append dictv "\n/Length3 $BFA($BFN,Length3)"
                    set body [MakeStream $dictv $BFA($BFN,data) $pdf(compress)]
                    set fsoid [$self AddObject $body]
                    #2. Font descriptor:
                    set    body "<<\n/FontName /$BFN\n"
                    append body "/StemV [Nf $BFA($BFN,stemV)]\n"
                    append body "/FontFile $fsoid 0 R\n"
                    append body "/Ascent [Nf $BFA($BFN,ascent)]\n"
                    append body "/Flags 34\n"
                    append body "/Descent [Nf $BFA($BFN,descent)]\n"
                    append body "/ItalicAngle [Nf $BFA($BFN,ItalicAngle)]\n"
                    foreach n $BFA($BFN,bbox) {lappend fbbox [Nf $n]}
                    append body "/FontBBox \[$fbbox\]\n"
                    append body "/Type /FontDescriptor\n"
                    append body "/CapHeight [Nf $BFA($BFN,CapHeight)]\n>>"
                    set foid [$self AddObject $body]
                    set type1basefonts($BFN) $foid
                } else {
                    set foid $type1basefonts($BFN)
                }
                # 3. ToUnicode Cmap.
                set body [MakeStream "<<" \
                        [MakeToUnicodeCMap $BFN \
                        $::pdf4tcl::FontsAttrs($fontname,uniset)] \
                        $pdf(compress)]
                set uoid [$self AddObject $body]
                # 4. Font object:
                set Widths [list]
                foreach ucode $::pdf4tcl::FontsAttrs($fontname,uniset) {
                    set res 0.0
                    if {[dict exists $BFA($BFN,charWidths) $ucode]} {
                        set res [dict get $::pdf4tcl::BFA($BFN,charWidths) $ucode]
                    }
                    lappend Widths [Nf $res]
                }
                set body    "<<\n/FirstChar 0\n"
                append body "/LastChar [expr {[llength $Widths]-1}]\n"
                append body "/ToUnicode $uoid 0 R\n"
                append body "/FontDescriptor $foid 0 R\n"
                append body "/Name /$fontname\n"
                append body "/BaseFont /$BFN\n"
                append body "/Subtype /Type1\n"
                append body "/Widths \[$Widths\]\n"
                append body "/Type /Font\n"
                set diffs [MakeEncDiff $BFN $fontname]
                append body "/Encoding <<\n/Type /Encoding\n"
                append body "/BaseEncoding /WinAnsiEncoding\n"
                append body "/Differences \[$diffs\]\n>>\n>>"
            }
            set oid [$self AddObject $body]
            set fonts($fontname) $oid
        }
        set pdf(font_set) true
    }

    # Get metrics from current font.
    # Supported metrics are ascend, descend, fixed, bboxy, height
    method getFontMetric {metric {internal 0}} {
        if {$pdf(current_font) eq ""} {
            return -code error "No font set"
        }
        set BFN $::pdf4tcl::FontsAttrs($pdf(current_font),basefontname)
        set bbox $::pdf4tcl::BFA($BFN,bbox)
        switch $metric {
            bboxy   {set val [expr {[lindex $bbox 1] * 0.001}]}
            bboxb   {set val [expr {[lindex $bbox 1] * 0.001}]}
            bboxt   {set val [expr {[lindex $bbox 3] * 0.001}]}
            fixed   {return $::pdf4tcl::BFA($BFN,fixed)}
            height  {set val [expr {([lindex $bbox 3] - [lindex $bbox 1])* 0.001}]}
            ascend - descend {
                set val [expr {$::pdf4tcl::BFA($BFN,$metric) * 0.001}]
            }
            default {
                if {![info exists ::pdf4tcl::BFA($BFN,$metric)]} {
                    return -code error "Metric $metric doesn't exist"
                }
                return $::pdf4tcl::BFA($BFN,$metric)
            }
        }
        # Translate to current unit
        if {!$internal} {
            set val [expr {$val/ $pdf(unit)}]
        }
        return [expr {$val * $pdf(font_size)}]
    }

    # Get the width of a string under the current font.
    method getStringWidth {txt {internal 0}} {
        if {$pdf(current_font) eq ""} {
            return -code error "No font set"
        }
        set w 0.0
        foreach ch [split $txt ""] {
            set w [expr {$w + [GetCharWidth $pdf(current_font) $ch]}]
        }
        if {!$internal} {
            set w [expr {$w / $pdf(unit)}]
        }
        return [expr {$w * $pdf(font_size)}]
    }

    # Get the width of a character. "ch" must be exacly one char long.
    proc GetCharWidth {font ch} {
        if {$ch eq "\n"} {
            return 0.0
        }
        # This can't fail since ch is always 1 char long
        scan $ch %c n

        set BFN $::pdf4tcl::FontsAttrs($font,basefontname)
        set res 0.0
        catch {set res [dict get $::pdf4tcl::BFA($BFN,charWidths) $n]}
        set res [expr {$res * 0.001}]
        return $res
    }

    # Get the width of a character under the current font.
    method getCharWidth {ch {internal 0}} {
        if {$pdf(current_font) eq ""} {
            return -code error "No font set"
        }
        set len [string length $ch]
        if {$len == 0} {
            return 0.0
        } elseif {$len > 1} {
            set ch [string index $ch 0]
        }
        set width [expr {[GetCharWidth $pdf(current_font) $ch] * $pdf(font_size)}]
        if {!$internal} {
            set width [expr {$width / $pdf(unit)}]
        }
        return $width
    }

    # Set coordinate for next text command. Internal version
    method SetTextPosition {x y} {
        $self BeginTextObj
        set pdf(xpos) $x
        set pdf(ypos) $y
        $self Pdfoutcmd 1 0 0 1 $pdf(xpos) $pdf(ypos) "Tm"
    }

    proc MulVxM {vector matrix} {
        foreach {x y} $vector break
        foreach {a b c d e f} $matrix break
        lappend res [expr {$a*$x + $c*$y + $e}]
        lappend res [expr {$b*$x + $d*$y + $f}]
        return $res
    }

    proc MulMxM {m1 m2} {
        foreach {a1 b1 c1 d1 e1 f1} $m1 break
        foreach {a2 b2 c2 d2 e2 f2} $m2 break
        lappend res [expr {$a1*$a2 + $b1*$c2}]
        lappend res [expr {$a1*$b2 + $b1*$d2}]
        lappend res [expr {$c1*$a2 + $d1*$c2}]
        lappend res [expr {$c1*$b2 + $d1*$d2}]
        lappend res [expr {$e1*$a2 + $f1*$c2 + $e2}]
        lappend res [expr {$e1*$b2 + $f1*$d2 + $f2}]
        return $res
    }

    method SetTextPositionAngle {x y angle xangle yangle} {
        $self BeginTextObj
        set rad [expr {$angle*3.1415926/180.0}]
        set c [expr {cos($rad)}]
        set s [expr {sin($rad)}]
        set pdf(xpos) $x
        set pdf(ypos) $y

        if {$xangle == 0 && $yangle == 0} {
            $self Pdfoutcmd $c [expr {-$s}] $s $c $x $y "Tm"
            return
        }

        # Add skew if specified
        set tx [expr {tan($xangle*3.1415926/180.0)}]
        set ty [expr {tan($yangle*3.1415926/180.0)}]

        set mr [list $c [expr {-$s}] $s $c 0 0]
        set ms [list 1 $tx $ty 1 0 0]
        set ma [MulMxM $mr $ms]
        lset ma 4 $x
        lset ma 5 $y

        eval \$self Pdfoutcmd $ma "Tm" ;# 8.5
    }

    # Set coordinate for next text command.
    method setTextPosition {x y} {
        $self BeginTextObj
        $self Trans $x $y x y
        # Store for reference
        set pdf(origxpos) $x
        set pdf(origypos) $y
        $self SetTextPosition $x $y
    }

    # Move coordinate for next text command.
    method moveTextPosition {x y} {
        $self TransR $x $y x y
        set y [expr {$pdf(ypos) + $y}]
        set x [expr {$pdf(xpos) + $x}]
        $self SetTextPosition $x $y
    }

    # Get current test position
    method getTextPosition {} {
        # This is basically a reverse Trans
        set tx [expr {$pdf(xpos) - $pdf(marginleft)}]
        if {$pdf(orient)} {
            set ty [expr {$pdf(height) - $pdf(ypos)}]
            set ty [expr {$ty - $pdf(margintop)}]
        } else {
            set ty [expr {$pdf(ypos) - $pdf(marginbottom)}]
        }

        # Translate to current unit
        set tx [expr {$tx / $pdf(unit)}]
        set ty [expr {$ty / $pdf(unit)}]
        return [ list $tx $ty ]
    }

    # Draw text at current position, with a newline before
    # DEPRECATED!
    method drawText {str} {
        $self BeginTextObj
        if {!$pdf(font_set)} {
            $self SetupFont
        }
        $self Pdfout "([CleanText $str $pdf(current_font)]) '\n"
        # Update to next line
        set strWidth [$self getStringWidth $str 1]
        set pdf(ypos) [expr {$pdf(ypos) - $pdf(font_size) * $pdf(line_spacing)}]
        set pdf(xpos) [expr {$pdf(origxpos) + $strWidth}]
    }

    # Move text position to new line, relative to last
    # setTextPosition command.
    method newLine {{spacing {}}} {
        if {$spacing eq ""} {
            set spacing $pdf(line_spacing)
        } elseif {![string is double -strict $spacing]} {
            return -code error "Line spacing must be a number"
        }
        # Update to next line
        set y [expr {$pdf(ypos) - $pdf(font_size) * $spacing}]
        set x $pdf(origxpos)
        $self SetTextPosition $x $y
    }

    # Set Line spacing factor (which is used by method newLine
    # if no explicit spacing is given)
    method setLineSpacing {spacing} {
        if {![string is double -strict $spacing]} {
            return -code error "Line spacing must be a number"
        }
        set pdf(line_spacing) $spacing
    }

    # Return the current line spacing factor
    method getLineSpacing {} {
        return $pdf(line_spacing)
    }

    # Draw a text string
    # Returns the width of the drawn string.
    method text {str args} {
        if {!$pdf(inPage)} { $self startPage }
        set align "left"
        set angle 0
        set xangle 0
        set yangle 0
        set bg 0
        set x $pdf(xpos)
        set y $pdf(ypos)
        set posSet 0

        foreach {arg value} $args {
            switch -- $arg {
                "-align" {
                    set align $value
                }
                "-angle" {
                    set angle $value
                }
                "-xangle" {
                    set xangle $value
                }
                "-yangle" {
                    set yangle $value
                }
                "-background" - "-bg" - "-fill" {
                    if {[string is boolean -strict $value]} {
                        set bg $value
                    } else {
                        set bg [GetColor $value]
                    }
                }
                "-y" {
                    $self Trans 0 $value _ y
                    set posSet 1
                }
                "-x" {
                    $self Trans $value 0 x _
                    set posSet 1
                }
                default {
                    return -code error "unknown option $arg"
                }
            }
        }

        if {!$pdf(font_set)} {
            $self SetupFont
        }

        set strWidth [$self getStringWidth $str 1]
        if {$align == "right"} {
            set x [expr {$x - $strWidth}]
            set posSet 1
        } elseif {$align == "center"} {
            set x [expr {$x - $strWidth / 2 * cos($angle*3.1415926/180.0)}]
            set y [expr {$y - $strWidth / 2 * sin($angle*3.1415926/180.0)}]
            set posSet 1
        }
        # Draw a background box if needed.
        if {[llength $bg] > 1 || $bg} {
            set bboxb [$self getFontMetric bboxb 1]
            set bboxt [$self getFontMetric bboxt 1]
            set ytop [expr {$y + $bboxt}]
            set ybot [expr {$y + $bboxb}]
            set dh [expr {$bboxt - $bboxb}]
            $self EndTextObj
            # Temporarily shift fill color
            $self Pdfoutcmd "q"
            if {[llength $bg] > 1} {
                $self Pdfout "$bg rg\n"
            } else {
                $self Pdfout "$pdf(bgColor) rg\n"
            }
            if {$angle || $xangle || $yangle} {
                # Create rotated and skewed background polygon:
                # Translation from x,y to origin matrix:
                set mt [list 1 0 0 1 [expr {-$x}] [expr {-$y}]]
                # Rotation matrix:
                set r1 [expr {(360.0-$angle)*3.1415926/180.0}]
                set c [expr {cos($r1)}]
                set s [expr {sin($r1)}]
                set mr [list $c $s [expr {-$s}] $c 0 0]
                # Skew matrix:
                set tx [expr {tan($xangle*3.1415926/180.0)}]
                set ty [expr {tan($yangle*3.1415926/180.0)}]
                set ms [list 1 $tx $ty 1 0 0]
                # Translation from origin to x,y matrix:
                set mtb [list 1 0 0 1 $x $y]
                # Matrix of all operations:
                set ma [MulMxM $mt $mr]
                set ma [MulMxM $ma $ms]
                set ma [MulMxM $ma $mtb]
                # Four points must be translated:
                set x2 [expr {$x+$strWidth}]
                set y2 $ybot
                set p1 [MulVxM [list $x $ytop] $ma]
                set p2 [MulVxM [list $x2 $ytop] $ma]
                set p3 [MulVxM [list $x2 $y2] $ma]
                set p4 [MulVxM [list $x $y2] $ma]
                eval \$self DrawPoly 0 1 $p1 $p2 $p3 $p4
            } else {
                $self DrawRect $x $ybot $strWidth $dh 0 1
            }
            $self Pdfoutcmd "Q"
            # Position needs to be set since we left the text object
            set posSet 1
        }
        $self BeginTextObj
        if {$angle || $xangle || $yangle} {
            $self SetTextPositionAngle $x $y $angle $xangle $yangle
        } elseif {$posSet} {
            $self SetTextPosition $x $y
        }

        $self Pdfout "([CleanText $str $pdf(current_font)]) Tj\n"
        set pdf(xpos) [expr {$x + $strWidth}]
        return $strWidth
    }

    # Draw a text string at a given position.
    method DrawTextAt {x y str {align left}} {
        if {! $pdf(font_set)} {
            $self SetupFont
        }

        set strWidth [$self getStringWidth $str 1]
        if {$align == "right"} {
            set x [expr {$x - $strWidth}]
        } elseif {$align == "center"} {
            set x [expr {$x - $strWidth / 2}]
        }
        $self BeginTextObj
        $self SetTextPosition $x $y
        $self Pdfout "([CleanText $str $pdf(current_font)]) Tj\n"
    }

    method drawTextBox {x y width height txt args} {
        if {!$pdf(inPage)} { $self startPage }
        set align left
        set linesVar ""
        foreach {arg value} $args {
            switch -- $arg {
                "-align" {
                    set align $value
                }
                "-linesvar" {
                    set linesVar $value
                }
                default {
                    return -code error "unknown option $arg"
                }
            }
        }

        if {$linesVar ne ""} {
            upvar 1 $linesVar lines
        }
        set lines 0

        $self Trans  $x $y x y
        $self TransR $width $height width height

        if {!$pdf(orient)} {
            # Always have anchor position upper left
            set y [expr {$y + $height}]
        } else {
            # Restore a positive height
            set height [expr {- $height}]
        }

        $self BeginTextObj
        if {! $pdf(font_set)} {
            $self SetupFont
        }

        # pre-calculate some values
        set font_height [expr {$pdf(font_size) * $pdf(line_spacing)}]
        set space_width [$self getCharWidth " " 1]

        # Displace y to put the first line within the box
        set bboxb [$self getFontMetric bboxb 1]
        set ystart $y
        set y [expr {$y - $pdf(font_size) - $bboxb}]

        set len [string length $txt]

        # run through chars until we exceed width or reach end
        set start 0
        set pos 0
        set cwidth 0
        set lastbp 0
        set done false

        while {! $done} {
            set ch [string index $txt $pos]
            # test for breakable character
            if {[regexp "\[ \t\r\n-\]" $ch]} {
                set lastbp $pos
            }
            set w [$self getCharWidth $ch 1]
            if {($cwidth+$w)>$width || $pos>=$len || $ch=="\n"} {
                if {$pos>=$len} {
                    set done true
                } else {
                    # backtrack to last breakpoint
                    if {$lastbp != $start} {
                        set pos $lastbp
                    } else {
                        # Word longer than line.
                        # Back up one char if possible
                        if {$pos > $start} {
                            incr pos -1
                        }
                    }
                }
                set sent [string trim [string range $txt $start $pos]]
                switch -- $align {
                    "justify" {
                        # count number of spaces
                        set words [split $sent " "]
                        if {[llength $words]>1 && (!$done) && $ch!="\n"} {
                            # determine additional width per space
                            set sw [$self getStringWidth $sent 1]
                            set add [expr {($width-$sw)/([llength $words]-1)}]
                            # display words
                            $self Pdfoutcmd $add "Tw"
                            $self DrawTextAt $x $y $sent
                            $self Pdfoutcmd 0 "Tw"
                        } else {
                            $self DrawTextAt $x $y $sent
                        }
                    }
                    "right" {
                        $self DrawTextAt [expr {$x+$width}] $y $sent right
                    }
                    "center" {
                        $self DrawTextAt [expr {$x+$width/2.0}] $y $sent center
                    }
                    default {
                        $self DrawTextAt $x $y $sent
                    }
                }
                # Move y down to next line
                set y [expr {$y-$font_height}]
                incr lines

                set start $pos
                incr start
                set cwidth 0
                set lastbp $start

                # Will another line fit?
                if {($ystart - ($y + $bboxb)) > $height} {
                    return [string range $txt $start end]
                }
            } else {
                set cwidth [expr {$cwidth+$w}]
            }
            incr pos
        }
        return ""
    }

    # start text object, if not already in text
    method BeginTextObj {} {
        if {!$pdf(in_text_object)} {
            $self Pdfout "BT\n"
            set pdf(in_text_object) true
        }
    }

    # end text object, if in text, else do nothing
    method EndTextObj {} {
        if {!$pdf(inPage)} { $self startPage }
        if {$pdf(in_text_object)} {
            $self Pdfout "ET\n"
            set pdf(in_text_object) false
        }
    }

    #######################################################################
    # Graphics Handling
    #######################################################################

    # Convert any user color to PDF color
    proc GetColor {color} {
        # Remove list layers, to accept things that have been
        # multiply listified
        if {[llength $color] == 1} {
            set color [lindex $color 0]
        }
        if {[llength $color] == 3} {
            # Maybe range check them here...
            return $color
        }
        if {[regexp {^\#([[:xdigit:]]{2})([[:xdigit:]]{2})([[:xdigit:]]{2})$} \
                $color -> rHex gHex bHex]} {
            set red   [expr {[scan $rHex %x] / 255.0}]
            set green [expr {[scan $gHex %x] / 255.0}]
            set blue  [expr {[scan $bHex %x] / 255.0}]
            return [list $red $green $blue]
        }
        # Use catch both to catch bad color, and to catch Tk not present
        if {[catch {winfo rgb . $color} tkcolor]} {
            return -code error "Unknown color: $color"
        }
        foreach {red green blue} $tkcolor break
        set red   [expr {($red   & 0xFF00) / 65280.0}]
        set green [expr {($green & 0xFF00) / 65280.0}]
        set blue  [expr {($blue  & 0xFF00) / 65280.0}]
        return [list $red $green $blue]

    }

    ###<jpo 2004-11-08: replaced "on off" by "args"
    ###                 to enable resetting dashed lines
    method setLineStyle {width args} {
        $self EndTextObj
        $self Pdfoutcmd $width "w"
        $self Pdfout "\[$args\] 0 d\n"
    }

    method DrawLine {args} {
        $self EndTextObj
        set cmd "m"
        foreach {x y} $args {
            $self Pdfoutcmd $x $y $cmd
            set cmd "l"
        }
        $self Pdfoutcmd "S"
    }

    method line {x1 y1 x2 y2} {
        if {!$pdf(inPage)} { $self startPage }
        $self Trans $x1 $y1 x1 y1
        $self Trans $x2 $y2 x2 y2

        $self DrawLine $x1 $y1 $x2 $y2
    }

    ###>2004-11-03 jpo
    method qCurve {x1 y1 xc yc x2 y2} {
        $self EndTextObj
        $self Trans $x1 $y1 x1 y1
        $self Trans $xc $yc xc yc
        $self Trans $x2 $y2 x2 y2
        $self Pdfoutcmd $x1 $y1 "m"
        $self Pdfoutcmd \
                [expr {0.3333*$x1+0.6667*$xc}] \
                [expr {0.3333*$y1+0.6667*$yc}] \
                [expr {0.3333*$x2+0.6667*$xc}] \
                [expr {0.3333*$y2+0.6667*$yc}] \
                $x2 \
                $y2 "c"
        $self Pdfoutcmd "S"
    }
    ###<jpo

    # Draw a polygon
    method polygon {args} {
        $self EndTextObj

        set filled 0
        set stroke 1
        set start 1
        foreach {x y} $args {
            if {[string match {-[a-z]*} $x]} {
                switch -- $x {
                    "-filled" {
                        set filled $y
                    }
                    "-stroke" {
                        set stroke $y
                    }
                    default {
                        return -code error "unknown option $x"
                    }
                }
            } else {
                $self Trans $x $y x y
                if {$start} {
                    $self Pdfoutcmd $x $y "m"
                    set start 0
                } else {
                    $self Pdfoutcmd $x $y "l"
                }
            }
        }
        if {$filled && $stroke} {
            $self Pdfoutcmd "b"
        } elseif {$filled && !$stroke} {
            $self Pdfoutcmd "f"
        } else {
            $self Pdfoutcmd "s"
        }
    }

    method DrawOval {x y rx ry stroke filled} {
        $self EndTextObj

        set sq [expr {4.0*(sqrt(2.0)-1.0)/3.0}]
        set x0(0) [expr {$x+$rx}]
        set y0(0) $y
        set x1(0) [expr {$x+$rx}]
        set y1(0) [expr {$y+$ry*$sq}]
        set x2(0) [expr {$x+$rx*$sq}]
        set y2(0) [expr {$y+$ry}]
        set x3(0) $x
        set y3(0) [expr {$y+$ry}]
        set x1(1) [expr {$x-$rx*$sq}]
        set y1(1) [expr {$y+$ry}]
        set x2(1) [expr {$x-$rx}]
        set y2(1) [expr {$y+$ry*$sq}]
        set x3(1) [expr {$x-$rx}]
        set y3(1) $y
        set x1(2) [expr {$x-$rx}]
        set y1(2) [expr {$y-$ry*$sq}]
        set x2(2) [expr {$x-$rx*$sq}]
        set y2(2) [expr {$y-$ry}]
        set x3(2) $x
        set y3(2) [expr {$y-$ry}]
        set x1(3) [expr {$x+$rx*$sq}]
        set y1(3) [expr {$y-$ry}]
        set x2(3) [expr {$x+$rx}]
        set y2(3) [expr {$y-$ry*$sq}]
        set x3(3) [expr {$x+$rx}]
        set y3(3) $y
        $self Pdfoutcmd $x0(0) $y0(0) "m"
        for {set i 0} {$i < 4} {incr i} {
            $self Pdfoutcmd $x1($i) \
                            $y1($i) \
                            $x2($i) \
                            $y2($i) \
                            $x3($i) \
                            $y3($i) "c"
        }
        if {$filled && $stroke} {
            $self Pdfoutcmd "b"
        } elseif {$filled && !$stroke} {
            $self Pdfoutcmd "f"
        } else {
            $self Pdfoutcmd " s"
        }
    }

    method circle {x y r args} {
        if {!$pdf(inPage)} { $self startPage }
        set filled 0
        set stroke 1

        foreach {arg value} $args {
            switch -- $arg {
                "-filled" {
                    set filled $value
                }
                "-stroke" {
                    set stroke $value
                }
                default {
                    return -code error "unknown option $arg"
                }
            }
        }

        $self Trans $x $y x y
        set r [pdf4tcl::getPoints $r $pdf(unit)]

        $self DrawOval $x $y $r $r $stroke $filled
    }

    method oval {x y rx ry args} {
        if {!$pdf(inPage)} { $self startPage }
        set filled 0
        set stroke 1

        foreach {arg value} $args {
            switch -- $arg {
                "-filled" {
                    set filled $value
                }
                "-stroke" {
                    set stroke $value
                }
                default {
                    return -code error "unknown option $arg"
                }
            }
        }

        $self Trans $x $y x y
        set rx [pdf4tcl::getPoints $rx $pdf(unit)]
        set ry [pdf4tcl::getPoints $ry $pdf(unit)]

        $self DrawOval $x $y $rx $ry $stroke $filled
    }

    # rotate by phi, scale with rx/ry and move by (dx, dy)
    proc Transform {rx ry phi dx dy points} {
        set cos_phi [expr {cos($phi)}]
        set sin_phi [expr {sin($phi)}]
        set res [list]
        foreach {x y} $points {
            set xn [expr {$rx * ($x*$cos_phi - $y*$sin_phi) + $dx}]
            set yn [expr {$ry * ($x*$sin_phi + $y*$cos_phi) + $dy}]
            lappend res $xn $yn
        }
        return $res
    }

    # Create a four-point spline that forms an arc along the unit circle
    proc Simplearc {phi2} {
        set x0 [expr {cos($phi2)}]
        set y0 [expr {-sin($phi2)}]
        set x3 $x0
        set y3 [expr {-$y0}]
        set x1 [expr {0.3333*(4.0-$x0)}]
        set y1 [expr {(1.0-$x0)*(3.0-$x0)/(3.0*$y0)}]
        set x2 $x1
        set y2 [expr {-$y1}]
        return [list $x0 $y0 $x1 $y1 $x2 $y2 $x3 $y3]
    }

    method DrawArc {x0 y0 rx ry phi extend stroke filled style} {
        if {abs($extend) >= 360.0} {
            $self DrawOval $x0 $y0 $rx $ry $stroke $filled
            return
        }
        if {abs($extend) < 0.01} return
        $self EndTextObj

        set count 1
        while {abs($extend) > 90} {
            set count [expr {2*$count}]
            set extend [expr {0.5*$extend}]
        }
        set phi [expr {$phi/180.0*3.1416}]
        set extend [expr {$extend/180.0*3.1416}]
        set phi2 [expr {0.5*$extend}]
        set x [expr {$x0+$rx*cos($phi)}]
        set y [expr {$y0+$ry*sin($phi)}]
        $self Pdfoutcmd $x $y "m"
        set points [Simplearc $phi2]
        set phi [expr {$phi+$phi2}]
        for {set i 0} {$i < $count} {incr i} {
            foreach {x y x1 y1 x2 y2 x3 y3} \
                    [Transform $rx $ry $phi $x0 $y0 $points] break
            set phi [expr {$phi+$extend}]
            $self Pdfoutcmd $x1 $y1 $x2 $y2 $x3 $y3 "c"
        }
        switch $style {
            "arc" {
                set filled 0
            }
            "pieslice" {
                # Add the line to the center
                $self Pdfoutcmd $x0 $y0 "l"
                # Close the path
                $self Pdfoutcmd "h"
            }
            "chord" {
                # Close the path
                $self Pdfoutcmd "h"
            }
        }
        if {$filled && $stroke} {
            $self Pdfoutcmd "B"
        } elseif {$filled && !$stroke} {
            $self Pdfoutcmd "f"
        } else {
            $self Pdfoutcmd "S"
        }
    }

    # Draw an arc
    method arc {x0 y0 rx ry phi extend args} {
        if {!$pdf(inPage)} { $self startPage }
        set filled 0
        set stroke 1
        set style arc

        foreach {arg value} $args {
            switch -- $arg {
                "-filled" {
                    set filled $value
                }
                "-stroke" {
                    set stroke $value
                }
                "-style" {
                    set style $value
                }
                default {
                    return -code error "unknown option $arg"
                }
            }
        }

        $self Trans $x0 $y0 x0 y0
        set rx [pdf4tcl::getPoints $rx $pdf(unit)]
        set ry [pdf4tcl::getPoints $ry $pdf(unit)]

        $self DrawArc $x0 $y0 $rx $ry $phi $extend $stroke $filled $style
    }

    method arrow {x1 y1 x2 y2 sz {angle 20}} {
        if {!$pdf(inPage)} { $self startPage }
        $self Trans $x1 $y1 x1 y1
        $self Trans $x2 $y2 x2 y2
        set sz [pdf4tcl::getPoints $sz $pdf(unit)]

        $self DrawLine $x1 $y1 $x2 $y2
        set rad [expr {$angle*3.1415926/180.0}]
        set ang [expr {atan2(($y1-$y2), ($x1-$x2))}]
        $self DrawLine $x2 $y2 [expr {$x2+$sz*cos($ang+$rad)}] [expr {$y2+$sz*sin($ang+$rad)}]
        $self DrawLine $x2 $y2 [expr {$x2+$sz*cos($ang-$rad)}] [expr {$y2+$sz*sin($ang-$rad)}]
    }

    method setBgColor {args} {
        set pdf(bgColor) [GetColor $args]
    }

    method setFillColor {args} {
        if {!$pdf(inPage)} { $self startPage }
        set pdf(fillColor) [GetColor $args]
        foreach {red green blue} $pdf(fillColor) break
        $self Pdfoutcmd $red $green $blue "rg"
    }

    method setStrokeColor {args} {
        if {!$pdf(inPage)} { $self startPage }
        set pdf(strokeColor) [GetColor $args]
        foreach {red green blue} $pdf(strokeColor) break
        $self Pdfoutcmd $red $green $blue "RG"
    }

    # Draw a rectangle, internal version
    method DrawRect {x y w h stroke filled} {
        $self Pdfoutcmd $x $y $w $h "re"
        if {$filled && $stroke} {
            $self Pdfoutcmd "B"
        } elseif {$filled && !$stroke} {
            $self Pdfoutcmd "f"
        } else {
            $self Pdfoutcmd "S"
        }
    }

    # Draw a polygon, internal version
    method DrawPoly {stroke filled args} {
        set start 1
        foreach {x y} $args {
            if {$start} {
                $self Pdfoutcmd $x $y "m"
                set start 0
            } else {
                $self Pdfoutcmd $x $y "l"
            }
        }
        if {$filled && $stroke} {
            $self Pdfoutcmd "b"
        } elseif {$filled && !$stroke} {
            $self Pdfoutcmd "f"
        } else {
            $self Pdfoutcmd "s"
        }
    }

    # Draw a rectangle
    method rectangle {x y w h args} {
        $self EndTextObj

        set filled 0
        set stroke 1
        foreach {arg value} $args {
            switch -- $arg {
                "-filled" {
                    set filled $value
                }
                "-stroke" {
                    set stroke $value
                }
                default {
                    return -code error "unknown option $arg"
                }
            }
        }
        $self Trans $x $y x y
        $self TransR $w $h w h

        $self DrawRect $x $y $w $h $stroke $filled
    }

    #######################################################################
    # Image Handling
    #######################################################################

    # Add an image to the document
    method addImage {filename args} {
        if {!$pdf(inPage)} { $self startPage }
        set id ""
        set type ""
        foreach {arg val} $args {
            switch -- $arg {
                -id {
                    set id $val
                }
                -type {
                    set type $val
                }
            }
        }

        if {$type eq ""} {
            switch -glob $filename {
                *.png {
                    set type png
                }
                *.jpg - *.jpeg {
                    set type jpg
                }
                default {
                    return -code error "Unknown image type $filename"
                }
            }
        }
        switch $type {
            png {
                set id [$self AddPng $filename $id]
            }
            jpg - jpeg {
                set id [$self addJpeg $filename $id]
            }
            default {
                return -code error "Unknown image type $type"
            }
        }
        return $id
    }

    # Deprecated jpeg adder, use addImage
    method addJpeg {filename id} {
        if {!$pdf(inPage)} { $self startPage }
        variable images

        set imgOK false
        if {[catch {open $filename "r"} if]} {
            return -code error "Could not open file $filename"
        }

        fconfigure $if -translation binary
        set img [read $if]
        close $if
        binary scan $img "H4" h
        if {$h != "ffd8"} {
            return -code error "file $filename does not contain JPEG data."
        }
        set pos 2
        set img_length [string length $img]
        while {$pos < $img_length} {
            set endpos [expr {$pos+4}]
            binary scan [string range $img $pos $endpos] "H4S" h length
            set length [expr {$length & 0xffff}]
            if {$h == "ffc0"} {
                incr pos 4
                set endpos [expr {$pos+6}]
                binary scan [string range $img $pos $endpos] "cSS" depth height width
                set height [expr {$height & 0xffff}]
                set width [expr {$width & 0xffff}]
                set imgOK true
                break
            } else {
                incr pos 2
                incr pos $length
            }
        }
        if {!$imgOK} {
            return -code error "something is wrong with jpeg data in file $filename"
        }
        set    xobject "<<\n/Type /XObject\n"
        append xobject "/Subtype /Image\n"
        append xobject "/Width $width\n/Height $height\n"
        append xobject "/ColorSpace /DeviceRGB\n"
        append xobject "/BitsPerComponent $depth\n"
        append xobject "/Filter /DCTDecode\n"
        append xobject "/Length $img_length >>\n"
        append xobject "stream\n"
        append xobject $img
        append xobject "\nendstream"

        set oid [$self AddObject $xobject]

        if {$id eq ""} {
            set id image$oid
        }
        set images($id) [list $width $height $oid]
        return $id
    }

    # PNG support
    #
    # This implementation uses tricks in PDF to avoid unpacking the
    # compressed data stream.  Currently this means that interlaced
    # images are not supported.
    # Decompressing (using zlib) would be feasible I guess, but the
    # de-filtering and de-interlacing steps would be rather costly.
    # Anyone needing such png images can always load them themselves
    # and provide them as raw images.

    method AddPng {filename id} {
        variable images

        set imgOK false
        if {[catch {open $filename "r"} if]} {
            return -code error "Could not open file $filename"
        }

        fconfigure $if -translation binary
        if {[read $if 8] != "\x89PNG\r\n\x1a\n"} {
            close $if
            return -code error "file does not contain PNG data"
        }
        set img [read $if]
        close $if

        set pos 0
        set img_length [string length $img]
        set img_data ""
        set palette ""
        while {$pos < $img_length} {
            # Scan one chunk
            binary scan $img "@${pos}Ia4" length type
            incr pos 8
            set data [string range $img $pos [expr {$pos + $length - 1}]]
            incr pos $length
            binary scan $img "@${pos}I" crc
            incr pos 4

            switch $type {
                "IHDR" {
                    set imgOK 1
                    binary scan $data IIccccc width height depth color \
                            compression filter interlace
                }
                "PLTE" {
                    set palette $data
                }
                "IDAT" {
                    append img_data $data
                }
            }
        }

        if {!$imgOK} {
            return -code error "something is wrong with PNG data in file $filename"
        }
        if {[string length $img_data] == 0} {
            return -code error "PNG file does not contain any IDAT chunks"
        }
        if {$compression != 0} {
            return -code error "PNG file is of an unsupported compression type"
        }
        if {$filter != 0} {
            return -code error "PNG file is of an unsupported filter type"
        }
        if {$interlace != 0} {
            # Would need to unpack and repack to do interlaced
            return -code error "Interlaced PNG is not supported"
        }

        if {$palette ne ""} {
            # Transform the palette into a PDF Indexed color space
            binary scan $palette H* PaletteHex
            set PaletteLen [expr {[string length $palette] / 3 - 1}]
            set paletteX "\[ /Indexed /DeviceRGB "
            append paletteX $PaletteLen " < "
            append paletteX $PaletteHex
            append paletteX " > \]"
        }

        set    xobject "<<\n/Type /XObject\n"
        append xobject "/Subtype /Image\n"
        append xobject "/Width $width\n/Height $height\n"

        if {$depth > 8} {
            $self RequireVersion 1.5
        }

        switch $color {
            0 { # Grayscale
                append xobject "/ColorSpace /DeviceGray\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 1 /BitsPerComponent $depth /Columns $width>>\n"
            }
            2 { # RGB
                append xobject "/ColorSpace /DeviceRGB\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 3 /BitsPerComponent $depth /Columns $width>>\n"
            }
            3 { # Palette
                append xobject "/ColorSpace $paletteX\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 1 /BitsPerComponent $depth /Columns $width>>\n"
            }
            4 { # Gray + alpha
                $self PngInitGrayAlpha
                append xobject "/ColorSpace $pdf(png_ga) 0 R\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 2 /BitsPerComponent $depth /Columns $width>>\n"
            }
            6 { # RGBA
                $self PngInitRgba
                append xobject "/ColorSpace $pdf(png_rgba) 0 R\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 4 /BitsPerComponent $depth /Columns $width>>\n"
            }
        }

        append xobject "/Length [string length $img_data] >>\n"
        append xobject "stream\n"
        append xobject $img_data
        append xobject "\nendstream"

        set oid [$self AddObject $xobject]

        if {$id eq ""} {
            set id image$oid
        }
        set images($id) [list $width $height $oid]
        return $id
    }

    # Create the Color Space needed to display RGBA as RGB
    method PngInitRgba {} {
        if {[info exists pdf(png_rgba)]} return
        set    body "<< /FunctionType 4\n"
        append body {/Domain [ 0.0  1.0  0.0  1.0 0.0  1.0 0.0  1.0 ]} \n
        append body {/Range [ 0.0  1.0 0.0  1.0 0.0  1.0 ]} \n
        append body {/Length 5} \n
        append body {>>} \n
        append body {stream} \n
        append body {{pop}} \n
        append body {endstream}
        set oid [$self AddObject $body]

        set body    "\[ /DeviceN\n"
        append body "   \[ /Red /Green /Blue /Alpha \]\n"
        append body "    /DeviceRGB\n"
        append body "    $oid 0 R   % Tint transformation function\n"
        append body "\]"
        set pdf(png_rgba) [$self AddObject $body]
    }

    # Create the Color Space needed to display Gray+Alpha as Gray
    method PngInitGrayAlpha {} {
        if {[info exists pdf(png_ga)]} return
        set    body "<< /FunctionType 4\n"
        append body {/Domain [ 0.0  1.0  0.0  1.0 ]} \n
        append body {/Range [ 0.0  1.0 ]} \n
        append body {/Length 5} \n
        append body {>>} \n
        append body {stream} \n
        append body {{pop}} \n
        append body {endstream}
        set oid [$self AddObject $body]

        set body    "\[ /DeviceN\n"
        append body "   \[ /_Gray_ /_Alpha_ \]\n"
        append body "    /DeviceGray\n"
        append body "    $oid 0 R   % Tint transformation function\n"
        append body "\]"
        set pdf(png_ga) [$self AddObject $body]
    }

    # Incomplete gif experiment...
    method AddGif {filename id} {
        variable images

        set imgOK false
        if {[catch {open $filename "r"} if]} {
            return -code error "Could not open file $filename"
        }

        fconfigure $if -translation binary
        set sign [read $if 6]
        if {![string match "GIF*" $sign]} {
            close $if
            return -code error "file does not contain GIF data"
        }
        set img [read $if]
        close $if

        set pos 0
        set img_length [string length $img]
        set img_data ""
        set palette ""

        # Read the screen descriptor
        binary scan $img "ssccc" scrWidth scrHeight cr bg dummy
        set pos 7
        set depth [expr {($cr & 7) + 1}]
        set colorMap [expr {($cr >> 7) & 1}]
        set colorRes [expr {($cr >> 4) & 7}]
        set nColor [expr {1 << $colorRes}]

        set gMap {}
        if {$colorMap} {
            for {set t 0} {$t < $nColor} {incr t} {
                binary scan $img "@${pos}ccc" red green blue
                incr pos 3
                lappend gMap $red $green $blue
            }
        }

        while {$pos < $img_length} {
            # Scan one chunk
            binary scan $img "@${pos}Ia4" length type
            incr pos 8
            set data [string range $img $pos [expr {$pos + $length - 1}]]
            incr pos $length
            binary scan $img "@${pos}I" crc
            incr pos 4

            switch $type {
                "IHDR" {
                    set imgOK 1
                    binary scan $data IIccccc width height depth color \
                            compression filter interlace
                }
                "PLTE" {
                    set palette $data
                }
                "IDAT" {
                    append img_data $data
                }
            }
        }

        if {!$imgOK} {
            return -code error "something is wrong with PNG data in file $filename"
        }
        if {[string length $img_data] == 0} {
            return -code error "PNG file does not contain any IDAT chunks"
        }
        if {$compression != 0} {
            return -code error "PNG file is of an unsupported compression type"
        }
        if {$filter != 0} {
            return -code error "PNG file is of an unsupported filter type"
        }
        if {$interlace != 0} {
            # Would need to unpack and repack to do interlaced
            return -code error "Interlaced PNG is not supported"
        }

        if {$palette ne ""} {
            # Transform the palette into a PDF Indexed color space
            binary scan $palette H* PaletteHex
            set PaletteLen [expr {[string length $palette] / 3 - 1}]
            set paletteX "\[ /Indexed /DeviceRGB "
            append paletteX $PaletteLen " < "
            append paletteX $PaletteHex
            append paletteX " > \]"
        }

        set    xobject "<<\n/Type /XObject\n"
        append xobject "/Subtype /Image\n"
        append xobject "/Width $width\n/Height $height\n"

        if {$depth > 8} {
            $self RequireVersion 1.5
        }

        switch $color {
            0 { # Grayscale
                append xobject "/ColorSpace /DeviceGray\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 1 /BitsPerComponent $depth /Columns $width>>\n"
            }
            2 { # RGB
                append xobject "/ColorSpace /DeviceRGB\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 3 /BitsPerComponent $depth /Columns $width>>\n"
            }
            3 { # Palette
                append xobject "/ColorSpace $paletteX\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 1 /BitsPerComponent $depth /Columns $width>>\n"
            }
            4 { # Gray + alpha
                $self PngInitGrayAlpha
                append xobject "/ColorSpace $pdf(png_ga) 0 R\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 2 /BitsPerComponent $depth /Columns $width>>\n"
            }
            6 { # RGBA
                $self PngInitRgba
                append xobject "/ColorSpace $pdf(png_rgba) 0 R\n"
                append xobject "/BitsPerComponent $depth\n"
                append xobject "/Filter /FlateDecode\n"
                append xobject "/DecodeParms << /Predictor 15 /Colors 4 /BitsPerComponent $depth /Columns $width>>\n"
            }
        }

        append xobject "/Length [string length $img_data] >>\n"
        append xobject "stream\n"
        append xobject $img_data
        append xobject "\nendstream"

        set oid [$self AddObject $xobject]

        if {$id eq ""} {
            set id image$oid
        }
        set images($id) [list $width $height $oid]
        return $id
    }

    # Return the height of an image.
    method getImageHeight {id} {
        variable images
        set status {}
        if {[info exists images($id)]} {
            set status [lindex $images($id) 1]
        }
        return $status
    }

    # Return the size of an image. The size is returned as a list containing
    # the width and height of the image.
    method getImageSize {id} {
        variable images
        set status {}
        if {[info exists images($id)]} {
            set status [lrange $images($id) 0 1]
        }
        return $status
    }

    # Return the width of an image.
    method getImageWidth {id} {
        variable images
        set status {}
        if {[info exists images($id)]} {
            set status [lindex $images($id) 0]
        }
        return $status
    }

    # Place an image at the page
    method putImage {id x y args} {
        $self EndTextObj
        variable images
        foreach {width height oid} $images($id) {break}

        $self Trans $x $y x y
        set w $width
        set h $height
        set wfix 0
        set hfix 0

        foreach {arg value} $args {
            set value [pdf4tcl::getPoints $value $pdf(unit)]
            switch -- $arg {
                "-width"  {set w $value; set wfix 1}
                "-height" {set h $value; set hfix 1}
            }
        }
        if {$wfix && !$hfix} {
            set h [expr {$height*$w/$width}]
        }
        if {$hfix && !$wfix} {
            set w [expr {$width*$h/$height}]
        }

        if {$pdf(orient)} {
            set y [expr {$y-$h}]
        }
        $self Pdfoutcmd "q"
        $self Pdfoutcmd $w 0 0 $h $x $y "cm"
        $self Pdfout "/$id Do\nQ\n"
    }

    # Add a raw image to the document, to be placed later
    method addRawImage {img_data args} {
        if {!$pdf(inPage)} { $self startPage }
        variable images
        # Determine the width and height of the image, which is
        # a list of lists(rows).
        set width [llength [lindex $img_data 0]]
        set height [llength $img_data]

        set id ""
        foreach {arg value} $args {
            switch -- $arg {
                "-id"     {set id $value}
            }
        }

        set    xobject "<<\n/Type /XObject\n"
        append xobject "/Subtype /Image\n"
        append xobject "/Width $width\n/Height $height\n"
        append xobject "/ColorSpace /DeviceRGB\n"
        append xobject "/BitsPerComponent 8\n"
        append xobject "/Length [expr {$width * $height * 3}]>>\n"
        append xobject "stream\n"

        # Iterate on each row of the image data.
        set img ""
        foreach rawRow $img_data {
            # Remove spaces and # characters
            set row [string map "# {} { } {}" $rawRow]
            # Convert data to binary format and
            # add to data stream.
            append img [binary format H* $row]
        }

        append xobject $img
        append xobject "\nendstream"

        set oid [$self AddObject $xobject]

        if {$id eq ""} {
            set id image$oid
        }
        set images($id) [list $width $height $oid]
        return $id
    }

    # Place a raw image at the page
    method putRawImage {img_data x y args} {
        $self EndTextObj
        # Determine the width and height of the image, which is
        # a list of lists(rows).
        set width [llength [lindex $img_data 0]]
        set height [llength $img_data]

        $self Trans $x $y x y
        set w $width
        set h $height
        set wfix 0
        set hfix 0
        foreach {arg value} $args {
            set value [pdf4tcl::getPoints $value $pdf(unit)]
            switch -- $arg {
                "-width"  {set w $value; set wfix 1}
                "-height" {set h $value; set hfix 1}
            }
        }

        if {$wfix && !$hfix} {
            set h [expr {$height*$w/$width}]
        }
        if {$hfix && !$wfix} {
            set w [expr {$width*$h/$height}]
        }

        if {$pdf(orient)} {
            set y [expr {$y-$h}]
        }
        $self Pdfoutcmd "q"
        $self Pdfoutcmd $w 0 0 $h $x $y "cm"
        $self Pdfoutcmd "BI"
        $self Pdfoutn   "/W [Nf $width]"
        $self Pdfoutn   "/H [Nf $height]"
        $self Pdfoutn   "/CS /RGB"
        $self Pdfoutn   "/BPC 8"
        $self Pdfoutcmd "ID"

        # Iterate on each row of the image data.
        foreach rawRow $img_data {
            # Remove spaces and # characters
            set row [string map "# {} { } {}" $rawRow]
            # Convert data to binary format and
            # add to data stream.
            $self Pdfout [binary format H* $row]
        }

        $self Pdfout    \n
        $self Pdfoutcmd "EI"
        $self Pdfoutcmd "Q"
    }

    # Add a bitmap to the document, as a pattern
    method AddBitmap {bitmap args} {
        variable bitmaps
        variable patterns

        set id ""
        set pattern ""
        foreach {arg value} $args {
            switch -- $arg {
                "-id"      {set id $value}
                "-pattern" {set pattern $value}
            }
        }

        # Load the bitmap file
        if {[string index $bitmap 0] eq "@"} {
            set filename [string range $bitmap 1 end]
        } else {
            # Internal bitmap
            set filename [file join $pdf4tcl::dir "bitmaps" ${bitmap}.xbm]
        }
        if {![file exists $filename]} {
            return -code error "No such bitmap $bitmap"
        }
        set ch [open $filename "r"]
        set bitmapdata [read $ch]
        close $ch
        if {![regexp {_width (\d+)} $bitmapdata -> width]} {
            return -code error "Not a bitmap $bitmap"
        }
        if {![regexp {_height (\d+)} $bitmapdata -> height]} {
            return -code error "Not a bitmap $bitmap"
        }
        if {![regexp {_bits\s*\[\]\s*=\s*\{(.*)\}} $bitmapdata -> rawdata]} {
            return -code error "Not a bitmap $bitmap"
        }
        set bytes [regexp -all -inline {0x[a-fA-F0-9]{2}} $rawdata]
        set bytesPerLine [expr {[llength $bytes] / $height}]

        set bits ""
        foreach byte $bytes {
            # Reverse bit order
            for {set t 0} {$t < 8} {incr t} {
                append bits [expr {1 & $byte}]
                set byte [expr {$byte >> 1}]
            }
        }
        set bitstream [binary format B* $bits]

        if {$pattern eq ""} {
            # The Image Mask Object can be used as transparency Mask
            # for something else, e.g. when drawing the bitmap itself
            # with transparent background.

            set    xobject "<<\n/Type /XObject\n"
            append xobject "/Subtype /Image\n"
            append xobject "/Width $width\n/Height $height\n"
            append xobject {/ImageMask true /Decode [ 1 0 ]} \n
            append xobject "/BitsPerComponent 1\n"
            append xobject "/Length [string length $bitstream]\n"
            append xobject ">>\nstream\n"
            append xobject $bitstream
            append xobject "\nendstream"

            set imoid [$self AddObject $xobject]
            if {$id eq ""} {
                set id bitmap$imoid
            }
            set bitmaps($id) [list $width $height $imoid $bitstream]
            return $id
        } else {
            # Inline image within the Pattern Object
            set    stream "q\n"
            append stream "$width 0 0 $height 0 0 " "cm" \n
            append stream "BI\n"
            append stream "/W [Nf $width]\n"
            append stream "/H [Nf $height]\n"
            append stream {/IM true /Decode [ 1 0 ]} \n
            append stream "/BPC 1\n"
            append stream "ID\n"
            append stream $bitstream
            append stream ">\nEI\nQ"

            # The Pattern Object can be used as a stipple Mask with the Cs1
            # Colorspace.

            if {[llength $pattern] == 4} {
                foreach {xscale yscale xoffset yoffset} $pattern break
            } else {
                set xscale 1
                set yscale 1
                set xoffset 0
                set yoffset 0
            }

            set xobject "<<\n/Type /Pattern\n"
            append xobject "/PatternType 1\n"
            append xobject "/PaintType 2\n"
            append xobject "/TilingType 1\n"
            append xobject "/BBox \[ 0 0 $width $height \]\n"
            append xobject "/XStep $width\n"
            append xobject "/YStep $height\n"
            append xobject "/Matrix \[ $xscale 0 0 $yscale $xoffset $yoffset \] \n"
            append xobject "/Resources <<\n"
            append xobject ">>\n"
            append xobject "/Length [string length $stream]\n"
            append xobject ">>\n"
            append xobject "stream\n"
            append xobject $stream
            append xobject "\nendstream"

            set oid [$self AddObject $xobject]

            if {$id eq ""} {
                set id pattern$oid
            }
            set patterns($id) [list $width $height $oid]
            return $id
        }
    }

    #######################################################################
    # Canvas Handling
    #######################################################################

    method canvas {path args} {
        $self EndTextObj

        set sticky "nw"
        $self Trans 0 0 x y
        set width ""
        set height ""
        set bbox [$path bbox all]
        set bg 0
        foreach {arg value} $args {
            switch -- $arg {
                "-width"  {set width  [pdf4tcl::getPoints $value $pdf(unit)]}
                "-height" {set height [pdf4tcl::getPoints $value $pdf(unit)]}
                "-sticky" {set sticky $value}
                "-y"      {$self Trans 0 $value _ y}
                "-x"      {$self Trans $value 0 x _}
                "-bbox"   {set bbox $value}
                "-bg"     {set bg $value}
                default {
                    return -code error "unknown option $arg"
                }
            }
        }
        if {$bbox eq ""} {
            # Nothing to display
            return
        }
        if {$width eq ""} {
            set width [expr {$pdf(width) - \
                    $pdf(marginright) - $x}]
        }
        if {$height eq ""} {
            if {$pdf(orient)} {
                set height [expr {$y - $pdf(marginbottom)}]
            } else {
                set height [expr {$pdf(height) - $pdf(margintop) - $y}]
            }
        }
        if {[llength $bbox] != 4} {
            return -code error "-bbox must be a four element list"
        }
        foreach {bbx1 bby1 bbx2 bby2} $bbox break
        set bbw [expr {$bbx2 - $bbx1}]
        set bbh [expr {$bby2 - $bby1}]

        set stickyw [string match "*w*" $sticky]
        set stickye [string match "*e*" $sticky]
        set stickyn [string match "*n*" $sticky]
        set stickys [string match "*s*" $sticky]
        set fillx [expr {$stickyw && $stickye}]
        set filly [expr {$stickyn && $stickys}]

        # Now calculate offset and scale between canvas coords
        # and pdf coords.

        set xscale  [expr {$width / $bbw}]
        set yscale  [expr {$height / $bbh}]

        if {$xscale > $yscale && !$fillx} {
            set xscale $yscale
        }
        if {$yscale > $xscale && !$filly} {
            set yscale $xscale
        }

        set xoffset [expr {$x - $bbx1 * $xscale}]
        if {!$fillx && !$stickyw} {
            # Move right
            set xoffset [expr {$xoffset + ($width - $bbw * $xscale)}]
        }

        if {$pdf(orient)} {
            set yoffset $y
        } else {
            set yoffset [expr {$y + $height}]
        }
        set yoffset [expr {$yoffset + $bby1 * $yscale}]
        if {!$filly && !$stickyn} {
            # Move down
            set yoffset [expr {$yoffset - ($height - $bbh * $yscale)}]
        }

        # Canvas coordinate system starts in upper corner
        # Thus we need to flip the y axis
        set yscale [expr {-$yscale}]

        # Set up clean graphics modes

        $self Pdfoutcmd "q"
        $self Pdfoutcmd 1.0 "w"
        $self Pdfout "\[\] 0 d\n"
        $self Pdfoutcmd 0 0 0 "rg"
        $self Pdfoutcmd 0 0 0 "RG"
        $self Pdfoutcmd 0 "J" ;# Butt cap style
        $self Pdfoutcmd 0 "j" ;# Miter join style
        # Miter limit; Tk switches from miter to bevel at 11 degrees
        $self Pdfoutcmd [expr {1.0/sin(11.0/180.0*3.14159265/2.0)}] "M"
        # Store scale. Used to get the correct size of stipple patterns.
        set pdf(canvasscale) [list [Nf $xscale] [Nf [expr {-$yscale}]] \
                [Nf $xoffset] [Nf $yoffset]]

        # Use better resolution for the scale since that can be small numbers
        $self Pdfoutn [Nf $xscale 6] 0 0 [Nf $yscale 6] \
                [Nf $xoffset] [Nf $yoffset] "cm"

        # Clip region
        $self Pdfoutcmd $bbx1 $bby1 "m"
        $self Pdfoutcmd $bbx1 $bby2 "l"
        $self Pdfoutcmd $bbx2 $bby2 "l"
        $self Pdfoutcmd $bbx2 $bby1 "l"
        #$self Pdfoutcmd $bbx1 $bby1 $bbw $bbh "re"
        $self Pdfoutcmd "W"
        if {$bg} {
            # Draw the region in background color if requested
            foreach {red green blue} [GetColor [$path cget -background]] break
            $self Pdfoutcmd $red $green $blue "rg"
            $self Pdfoutcmd "f"
            $self Pdfoutcmd 0 0 0 "rg"
        } else {
            $self Pdfoutcmd "n"
        }

        #set enclosed [$path find enclosed $bbx1 $bby1 $bbx2 $bby2]
        set overlapping [$path find overlapping $bbx1 $bby1 $bbx2 $bby2]
        foreach id $overlapping {
            set coords [$path coords $id]
            CanvasGetOpts $path $id opts
            if {[info exists opts(-state)] && $opts(-state) eq "hidden"} {
                continue
            }
            # Save graphics state for each item
            $self Pdfoutcmd "q"

            $self CanvasDoItem $path $id $coords opts

            # Restore graphics state after the item
            $self Pdfoutcmd "Q"
        }
        # Restore graphics state after the canvas
        $self Pdfoutcmd "Q"
    }

    # Handle one canvas item
    method CanvasDoItem {path id coords optsName} {
        upvar 1 $optsName opts
        variable images
        variable bitmaps

        # Not implemented: line/polygon -splinesteps
        # Not implemented: stipple offset
        # Limited: Stipple scale and offset does not match screen display
        # Limited: window item needs Img, and needs to be mapped

        switch [$path type $id] {
            rectangle {
                foreach {x1 y1 x2 y2} $coords break
                set w [expr {$x2 - $x1}]
                set h [expr {$y2 - $y1}]

                $self CanvasStdOpts opts
                set stroke [expr {$opts(-outline) ne ""}]
                set filled [expr {$opts(-fill) ne ""}]

                $self DrawRect $x1 $y1 $w $h $stroke $filled
            }
            line {
                # For a line, -fill means the stroke colour
                set opts(-outline)        $opts(-fill)
                set opts(-outlinestipple) $opts(-stipple)
                set opts(-outlineoffset)  $opts(-offset)
                $self CanvasStdOpts opts

                set arrows {}
                if {$opts(-arrow) eq "first" || $opts(-arrow) eq "both"} {
                    lappend arrows [lindex $coords 2] [lindex $coords 3] \
                            [lindex $coords 0] [lindex $coords 1] 0
                }
                if {$opts(-arrow) eq "last" || $opts(-arrow) eq "both"} {
                    lappend arrows [lindex $coords end-3] [lindex $coords end-2] \
                            [lindex $coords end-1] [lindex $coords end] [expr {[llength $coords] - 2}]
                }
                if {[llength $arrows] > 0} {
                    foreach {shapeA shapeB shapeC} $opts(-arrowshape) break
                    # Adjust like Tk does
                    set shapeA [expr {$shapeA + 0.001}]
                    set shapeB [expr {$shapeB + 0.001}]
                    set shapeC [expr {$shapeC + $opts(-width) / 2.0 + 0.001}]

                    set fracHeight [expr {($opts(-width)/2.0)/$shapeC}]
                    set backup  [expr {$fracHeight * $shapeB + \
                            $shapeA * (1.0 - $fracHeight)/2.0}]
                    foreach {x1 y1 x2 y2 ix} $arrows {
                        set poly [list 0 0 0 0 0 0 0 0 0 0 0 0]
                        lset poly 0  $x2
                        lset poly 10 $x2
                        lset poly 1  $y2
                        lset poly 11 $y2
                        set dx [expr {$x2 - $x1}]
                        set dy [expr {$y2 - $y1}]
                        set length [expr {hypot($dx, $dy)}]
                        if {$length == 0} {
                            set sinTheta 0.0
                            set cosTheta 0.0
                        } else {
                            set sinTheta [expr {$dy / $length}]
                            set cosTheta [expr {$dx / $length}]
                        }
                        set  vertX  [expr {[lindex $poly 0] - $shapeA * $cosTheta}]
                        set  vertY  [expr {[lindex $poly 1] - $shapeA * $sinTheta}]
                        set  temp   [expr {                   $shapeC * $sinTheta}]
                        lset poly 2 [expr {[lindex $poly 0] - $shapeB * $cosTheta + $temp}]
                        lset poly 8 [expr {[lindex $poly 2] - 2 * $temp}]
                        set  temp   [expr {                   $shapeC * $cosTheta}]
                        lset poly 3 [expr {[lindex $poly 1] - $shapeB * $sinTheta - $temp}]
                        lset poly 9 [expr {[lindex $poly 3] + 2 * $temp}]
                        lset poly 4 [expr {[lindex $poly 2] * $fracHeight + $vertX * (1.0-$fracHeight)}]
                        lset poly 5 [expr {[lindex $poly 3] * $fracHeight + $vertY * (1.0-$fracHeight)}]
                        lset poly 6 [expr {[lindex $poly 8] * $fracHeight + $vertX * (1.0-$fracHeight)}]
                        lset poly 7 [expr {[lindex $poly 9] * $fracHeight + $vertY * (1.0-$fracHeight)}]

                        # Adjust line end to draw it under the arrow
                        lset coords $ix [expr {[lindex $coords $ix] - $backup * $cosTheta}]
                        incr ix
                        lset coords $ix [expr {[lindex $coords $ix] - $backup * $sinTheta}]

                        # Draw polygon
                        set cmd "m"
                        foreach {x y} $poly {
                            $self Pdfoutcmd $x $y $cmd
                            set cmd "l"
                        }
                        $self Pdfoutcmd "f"
                    }
                }

                # Draw lines
                if {([string is true -strict $opts(-smooth)] || \
                        $opts(-smooth) eq "bezier") && [llength $coords] > 4} {
                    $self CanvasBezier $coords
                } elseif {$opts(-smooth) eq "raw"} {
                    $self CanvasRawCurve $coords
                } else {
                    set cmd "m"
                    foreach {x y} $coords {
                        $self Pdfoutcmd $x $y $cmd
                        set cmd "l"
                    }
                }
                $self Pdfoutcmd "S"
            }
            oval {
                foreach {x1 y1 x2 y2} $coords break
                set x  [expr {($x2 + $x1) / 2.0}]
                set y  [expr {($y2 + $y1) / 2.0}]
                set rx [expr {($x2 - $x1) / 2.0}]
                set ry [expr {($y2 - $y1) / 2.0}]

                $self CanvasStdOpts opts
                set stroke [expr {$opts(-outline) ne ""}]
                set filled [expr {$opts(-fill) ne ""}]

                $self DrawOval $x $y $rx $ry $stroke $filled
            }
            arc {
                foreach {x1 y1 x2 y2} $coords break
                set x  [expr {($x2 + $x1) / 2.0}]
                set y  [expr {($y2 + $y1) / 2.0}]
                set rx [expr {($x2 - $x1) / 2.0}]
                # Flip y-axis
                set ry [expr {-($y2 - $y1) / 2.0}]

                # Canvas draws arc with bevel style
                if {![info exists opts(-joinstyle)]} {
                    set opts(-joinstyle) bevel
                }
                $self CanvasStdOpts opts
                set stroke [expr {$opts(-outline) ne ""}]
                set filled [expr {$opts(-fill) ne ""}]

                set phi $opts(-start)
                set extend $opts(-extent)

                $self DrawArc $x $y $rx $ry $phi $extend $stroke $filled \
                        $opts(-style)
            }
            polygon {
                $self CanvasStdOpts opts
                set stroke [expr {$opts(-outline) ne ""}]
                set filled [expr {$opts(-fill) ne ""}]

                if {[string is true -strict $opts(-smooth)] || \
                            $opts(-smooth) eq "bezier"} {
                    # Close the coordinates if necessary
                    if {[lindex $coords 0] != [lindex $coords end-1] || \
                                [lindex $coords 1] != [lindex $coords end]} {
                        lappend coords [lindex $coords 0] [lindex $coords 1]
                    }
                    $self CanvasBezier $coords
                } elseif {$opts(-smooth) eq "raw"} {
                    $self CanvasRawCurve $coords
                } else {
                    set cmd "m"
                    foreach {x y} $coords {
                        $self Pdfoutcmd $x $y $cmd
                        set cmd "l"
                    }
                }
                if {$filled && $stroke} {
                    $self Pdfoutcmd "b"
                } elseif {$filled && !$stroke} {
                    $self Pdfoutcmd "f"
                } else {
                    $self Pdfoutcmd "s"
                }
            }
            text {
                # Width is not a stroke option here
                array unset opts -width
                $self CanvasStdOpts opts

                set lines [CanvasGetWrappedText $path $id underline]
                foreach {x y} $coords break
                foreach {x1 y1 x2 y2} [$path bbox $id] break

                $self CanvasSetFont $opts(-font)
                set fontsize $pdf(font_size)
                # Next, figure out if the text fits within the bbox
                # with the current font, or it needs to be scaled.
                set widest 0.0
                foreach line $lines {
                    set width [$self getStringWidth $line 1]
                    if {$width > $widest} {
                        set widest $width
                    }
                }
                set xscale [expr {$widest / ($x2 - $x1)}]
                set yscale [expr {([llength $lines] * $fontsize) / \
                        ($y2 - $y1)}]
                # Scale down if the font is too big
                if {$xscale > 1.001} {
                    $self setFont [expr {$fontsize / $xscale}] "" 1
                    set fontsize $pdf(font_size)
                    set widest [expr {$widest / $xscale}]
                }

                # Now we have selected an appropriate font and size.

                # Move x/y to point nw/n/ne depending on anchor
                # and justification
                set width $widest
                set height [expr {$fontsize * [llength $lines]}]
                if {[string match "s*" $opts(-anchor)]} {
                    set y [expr {$y - $height}]
                } elseif {![string match "n*" $opts(-anchor)]} {
                    set y [expr {$y - ($height / 2.0)}]
                }
                if {[string match "*w" $opts(-anchor)]} {
                    set xanchor 0
                } elseif {[string match "*e" $opts(-anchor)]} {
                    set xanchor 2
                } else {
                    set xanchor 1
                }
                set xjustify [lsearch {left center right} $opts(-justify)]
                set x [expr {$x + ($xjustify - $xanchor) * $width / 2.0}]

                # Displace y to base line of font
                set bboxt [$self getFontMetric bboxt 1]
                set y [expr {$y + $bboxt + $fontsize}]
                set lineNo 0
                set ulcoords {}
                foreach line $lines {
                    set width [$self getStringWidth $line 1]
                    set x0 [expr {$x - $xjustify * $width / 2.0}]

                    # Since we have put the coordinate system  upside
                    # down to follow canvas coordinates we need a
                    # negative y scale here to get the text correct.

                    $self Pdfoutcmd 1 0 0 -1 $x0 $y "Tm"
                    $self Pdfout "([CleanText $line $pdf(current_font)]) Tj\n"

                    if {$underline != -1} {
                        if {[lindex $underline 0] eq $lineNo} {
                            set index [lindex $underline 1]
                            set ulx [$self getStringWidth [string range $line \
                                               0 [expr {$index - 1}]] 1]
                            set ulw [$self getStringWidth [string index $line $index] 1]
                            lappend ulcoords [expr {$x0 + $ulx}] \
                                    [expr {$y - $bboxt}] $ulw
                        }
                    }
                    incr lineNo
                    set y [expr {$y + $fontsize}]
                }
                $self EndTextObj

                # Draw any underline
                foreach {x y w} $ulcoords {
                    $self Pdfoutcmd $x $y "m"
                    $self Pdfoutcmd [expr {$x + $w}] $y "l"
                    $self Pdfoutcmd "S"
                }
            }
            bitmap {
                set bitmap $opts(-bitmap)
                if {$bitmap eq ""} {
                    return
                }
                set id bitmap_canvas_[file rootname [file tail $bitmap]]
                if {![info exists bitmaps($id)]} {
                    $self AddBitmap $bitmap -id $id
                }
                foreach {width height imoid stream} $bitmaps($id) break
                foreach {x1 y1} $coords break
                # Since the canvas coordinate system is upside
                # down we must flip back to get the image right.
                # We do this by adjusting y and y scale.
                switch $opts(-anchor) {
                    nw { set dx 0.0 ; set dy 1.0 }
                    n  { set dx 0.5 ; set dy 1.0 }
                    ne { set dx 1.0 ; set dy 1.0 }
                    e  { set dx 1.0 ; set dy 0.5 }
                    se { set dx 1.0 ; set dy 0.0 }
                    s  { set dx 0.5 ; set dy 0.0 }
                    sw { set dx 0.0 ; set dy 0.0 }
                    w  { set dx 0.0 ; set dy 0.5 }
                    default { set dx 0.5 ; set dy 0.5 }
                }
                set x [expr {$x1 - $width  * $dx}]
                set y [expr {$y1 + $height * $dy}]

                set bg $opts(-background)
                if {$bg eq ""} {
                    # Dummy background to see if masking fails
                    set bg $opts(-foreground)
                }
                # Build a two-color palette
                set colors [concat [GetColor $bg] [GetColor $opts(-foreground)]]
                set PaletteHex ""
                foreach color $colors {
                    append PaletteHex [format %02x \
                            [expr {int(round($color * 255.0))}]]
                }
                set paletteX "\[ /Indexed /DeviceRGB "
                append paletteX "1 < "
                append paletteX $PaletteHex
                append paletteX " > \]"

                # An image object for this bitmap+color
                set    xobject "<<\n/Type /XObject\n"
                append xobject "/Subtype /Image\n"
                append xobject "/Width $width\n/Height $height\n"
                append xobject "/ColorSpace $paletteX\n"
                append xobject "/BitsPerComponent 1\n"
                append xobject "/Length [string length $stream]\n"
                if {$opts(-background) eq ""} {
                    append xobject "/Mask $imoid 0 R\n"
                }
                append xobject ">>\n"
                append xobject "stream\n"
                append xobject $stream
                append xobject "\nendstream"

                set newoid [$self AddObject $xobject]
                set newid image$newoid
                set images($newid) [list $width $height $newoid]

                # Put the image on the page
                $self Pdfoutcmd $width 0 0 [expr {-$height}] $x $y "cm"
                $self Pdfout "/$newid Do\n"
            }
            image {
                set image $opts(-image)
                if {$image eq ""} {
                    return
                }
                set id image_canvas_$image
                if {![info exists images($id)]} {
                    $self addRawImage [$image data] -id $id
                }
                foreach {width height oid} $images($id) break
                foreach {x1 y1} $coords break
                # Since the canvas coordinate system is upside
                # down we must flip back to get the image right.
                # We do this by adjusting y and y scale.
                switch $opts(-anchor) {
                    nw { set dx 0.0 ; set dy 1.0 }
                    n  { set dx 0.5 ; set dy 1.0 }
                    ne { set dx 1.0 ; set dy 1.0 }
                    e  { set dx 1.0 ; set dy 0.5 }
                    se { set dx 1.0 ; set dy 0.0 }
                    s  { set dx 0.5 ; set dy 0.0 }
                    sw { set dx 0.0 ; set dy 0.0 }
                    w  { set dx 0.0 ; set dy 0.5 }
                    default { set dx 0.5 ; set dy 0.5 }
                }
                set x [expr {$x1 - $width  * $dx}]
                set y [expr {$y1 + $height * $dy}]

                $self Pdfoutcmd $width 0 0 [expr {-$height}] $x $y "cm"
                $self Pdfout "/$id Do\n"
            }
            window {
                catch {package require Img}
                if {[catch {image create photo -format window -data $opts(-window)} image]} {
                    set image ""
                }
                if {$image eq ""} {
                    # Get a size even if it is unmapped
                    foreach width [list [winfo width $opts(-window)] \
                                        $opts(-width) \
                                        [winfo reqwidth $opts(-window)]] {
                        if {$width > 1} break
                    }
                    foreach height [list [winfo height $opts(-window)] \
                                         $opts(-height) \
                                         [winfo reqheight $opts(-window)]] {
                        if {$height > 1} break
                    }
                } else {
                    set id [$self addRawImage [$image data]]

                    foreach {width height oid} $images($id) break
                }
                foreach {x1 y1} $coords break
                # Since the canvas coordinate system is upside
                # down we must flip back to get the image right.
                # We do this by adjusting y and y scale.
                switch $opts(-anchor) {
                    nw { set dx 0.0 ; set dy 1.0 }
                    n  { set dx 0.5 ; set dy 1.0 }
                    ne { set dx 1.0 ; set dy 1.0 }
                    e  { set dx 1.0 ; set dy 0.5 }
                    se { set dx 1.0 ; set dy 0.0 }
                    s  { set dx 0.5 ; set dy 0.0 }
                    sw { set dx 0.0 ; set dy 0.0 }
                    w  { set dx 0.0 ; set dy 0.5 }
                    default { set dx 0.5 ; set dy 0.5 }
                }
                set x [expr {$x1 - $width  * $dx}]
                set y [expr {$y1 + $height * $dy}]

                if {$image eq ""} {
                    # Draw a black box
                    $self Pdfoutcmd $x [expr {$y - $height}] \
                            $width $height "re"
                    $self Pdfoutcmd "f"
                } else {
                    $self Pdfoutcmd $width 0 0 [expr {-$height}] $x $y "cm"
                    $self Pdfout "/$id Do\n"
                }
            }
        }
    }

    method CanvasBezier {coords} {
        # Is it a closed curve?
        if {[lindex $coords 0] == [lindex $coords end-1] && \
                    [lindex $coords 1] == [lindex $coords end]} {
            set closed 1

            set x0 [expr {0.5  * [lindex $coords end-3] + 0.5  *[lindex $coords 0]}]
            set y0 [expr {0.5  * [lindex $coords end-2] + 0.5  *[lindex $coords 1]}]
            set x1 [expr {0.167* [lindex $coords end-3] + 0.833*[lindex $coords 0]}]
            set y1 [expr {0.167* [lindex $coords end-2] + 0.833*[lindex $coords 1]}]
            set x2 [expr {0.833* [lindex $coords 0]     + 0.167*[lindex $coords 2]}]
            set y2 [expr {0.833* [lindex $coords 1]     + 0.167*[lindex $coords 3]}]
            set x3 [expr {0.5  * [lindex $coords 0]     + 0.5  *[lindex $coords 2]}]
            set y3 [expr {0.5  * [lindex $coords 1]     + 0.5  *[lindex $coords 3]}]
            $self Pdfoutcmd $x0 $y0 "m"
            $self Pdfoutcmd $x1 $y1 $x2 $y2 $x3 $y3 "c"
        } else {
            set closed 0
            set x3 [lindex $coords 0]
            set y3 [lindex $coords 1]
            $self Pdfoutcmd $x3 $y3 "m"
        }
        set len [llength $coords]
        for {set i 2} {$i < ($len - 2)} {incr i 2} {
            foreach {px1 py1 px2 py2} [lrange $coords $i [expr {$i + 3}]] break
            set x1 [expr {0.333*$x3 + 0.667*$px1}]
            set y1 [expr {0.333*$y3 + 0.667*$py1}]

            if {!$closed && $i == ($len - 4)} {
                # Last of an open curve
                set x3 $px2
                set y3 $py2
            } else {
                set x3 [expr {0.5 * $px1 + 0.5 * $px2}]
                set y3 [expr {0.5 * $py1 + 0.5 * $py2}]
            }
            set x2 [expr {0.333 * $x3 + 0.667 * $px1}]
            set y2 [expr {0.333 * $y3 + 0.667 * $py1}]
            $self Pdfoutcmd $x1 $y1 $x2 $y2 $x3 $y3 "c"
        }
    }

    method CanvasRawCurve {coords} {
        set x3 [lindex $coords 0]
        set y3 [lindex $coords 1]
        $self Pdfoutcmd $x3 $y3 "m"

        set len [llength $coords]
        # Is there a complete set of segements in the list?
        set add [expr {($len - 2) % 6}]
        if {$add != 0} {
            eval lappend coords [lrange $coords 0 [expr {$add - 1}]]
        }
        for {set i 0} {$i < ($len - 8)} {incr i 6} {
            foreach {px1 py1 px2 py2 px3 py3 px4 py4} \
                    [lrange $coords $i [expr {$i + 7}]] break
            if {$px1 == $px2 && $py1 == $py2 && $px3 == $px4 && $py3 == $py4} {
                # Straight line
                $self Pdfoutcmd $px4 $py4 "l"
            } else {
                $self Pdfoutcmd $px2 $py2 $px3 $py3 $px4 $py4 "c"
            }
        }
    }

    method CanvasGetBitmap {bitmap offset} {
        # The pattern is unique for the scale for this canvas
        foreach {xscale yscale xoffset yoffset} $pdf(canvasscale) break
        # Adapt to offset
        if {[regexp {^(\#?)(.*),(.*)$} $offset -> pre ox oy]} {
            set xoffset [expr {$xoffset + $ox * $xscale}]
            set yoffset [expr {$yoffset - $oy * $yscale}]
        } else {
            # Not supported yet
        }

        set scale [list $xscale $yscale $xoffset $yoffset]
        set tail [string map {. x} [join $scale _]]
        set id pattern_canvas_[file rootname [file tail $bitmap]]_$tail
        if {![info exists patterns($id)]} {
            $self AddBitmap $bitmap -id $id -pattern $scale
        }
        return $id
    }

    # Setup the graphics state from standard options
    method CanvasStdOpts {optsName} {
        upvar 1 $optsName opts
        variable patterns

        # Stipple for fill color
        set fillstippleid ""
        if {[info exists opts(-stipple)] && $opts(-stipple) ne ""} {
            set fillstippleid [$self CanvasGetBitmap $opts(-stipple) \
                    $opts(-offset)]
        }
        # Stipple for stroke color
        set strokestippleid ""
        if {[info exists opts(-outlinestipple)] && \
                $opts(-outlinestipple) ne ""} {
            # Outlineoffset is a 8.5 feature
            if {[info exists opts(-outlineoffset)]} {
                set offset $opts(-outlineoffset)
            } else {
                set offset $opts(-offset)
            }
            set strokestippleid [$self CanvasGetBitmap $opts(-outlinestipple) \
                    $offset]
        }
        # Outline controls stroke color
        if {[info exists opts(-outline)] && $opts(-outline) ne ""} {
            $self CanvasStrokeColor $opts(-outline) $strokestippleid
        }
        # Fill controls fill color
        if {[info exists opts(-fill)] && $opts(-fill) ne ""} {
            $self CanvasFillColor $opts(-fill) $fillstippleid
        }
        # Line width
        if {[info exists opts(-width)]} {
            $self Pdfoutcmd $opts(-width) "w"
        }
        # Dash pattern and offset
        if {[info exists opts(-dash)] && $opts(-dash) ne ""} {
            # FIXA: Support "..." and such
            $self Pdfout "\[$opts(-dash)\] $opts(-dashoffset) d\n"
        }
        # Cap style
        if {[info exists opts(-capstyle)] && $opts(-capstyle) ne "butt"} {
            switch $opts(-capstyle) {
                projecting {
                    $self Pdfoutcmd 2 "J"
                }
                round {
                    $self Pdfoutcmd 1 "J"
                }
            }
        }
        # Join style
        if {[info exists opts(-joinstyle)] && $opts(-joinstyle) ne "miter"} {
            switch $opts(-joinstyle) {
                bevel {
                    $self Pdfoutcmd 2 "j"
                }
                round {
                    $self Pdfoutcmd 1 "j"
                }
            }
        }
    }

    # Set the fill color from a Tk color
    method CanvasFillColor {color {bitmapid ""}} {
        foreach {red green blue} [GetColor $color] break
        if {$bitmapid eq ""} {
            $self Pdfoutcmd $red $green $blue "rg"
        } else {
            $self Pdfout "/Cs1 cs\n"
            #$self Pdfoutcmd $red $green $blue "scn"
            $self Pdfoutcmd $red $green $blue "/$bitmapid scn"
        }
    }

    # Set the stroke color from a Tk color
    method CanvasStrokeColor {color {bitmapid ""}} {
        foreach {red green blue} [GetColor $color] break
        if {$bitmapid eq ""} {
            $self Pdfoutcmd $red $green $blue "RG"
        } else {
            $self Pdfout "/Cs1 CS\n"
            $self Pdfoutcmd $red $green $blue "/$bitmapid SCN"
        }
    }

    # Helper to extract configuration from a canvas item
    proc CanvasGetOpts {path id arrName} {
        upvar 1 $arrName arr
        array unset arr
        foreach item [$path itemconfigure $id] {
            set arr([lindex $item 0]) [lindex $item 4]
        }
        if {![info exists arr(-state)]} {
            return
        }
        if {$arr(-state) eq "" || $arr(-state) eq "normal"} {
            return
        }
        # Translate options depending on state
        foreach item [array names arr] {
            if {[regexp -- "^-${state}(.*)\$" $item -> orig]} {
                if {[info exists arr(-$orig)]} {
                    set arr(-$orig) $arr($item)
                }
            }
        }
    }

    # Get the text from a text item, as a list of lines
    # This takes and line wrapping into account
    proc CanvasGetWrappedText {w item ulName} {
        upvar 1 $ulName underline
        set text  [$w itemcget $item -text]
        set width [$w itemcget $item -width]
        # Underline is a 8.5 feature
        if {[catch {$w itemcget $item -underline} underline]} {
            set underline -1
        }

        # Simple non-wrapping case. Only divide on newlines.
        if {$width == 0} {
            set lines [split $text \n]
            if {$underline != -1} {
                set isum 0
                set lineNo 0
                foreach line $lines {
                    set iend [expr {$isum + [string length $line]}]
                    if {$underline < $iend} {
                        set underline [list $lineNo [expr {$underline - $isum}]]
                        break
                    }
                    incr lineNo
                    set isum [expr {$iend + 1}]
                }
            }
            return $lines
        }

        # Run across the text's left side and look for all indexes
        # that start a line.

        foreach {x1 y1 x2 y2} [$w bbox $item] break
        set firsts {}
        for {set y $y1} {$y < $y2} {incr y} {
            lappend firsts [$w index $item @$x1,$y]
        }
        set firsts [lsort -integer -unique $firsts]

        # Extract each displayed line
        set prev 0
        set res {}
        foreach index $firsts {
            if {$prev != $index} {
                set line [string range $text $prev [expr {$index - 1}]]
                if {[string index $line end] eq "\n"} {
                    set line [string trimright $line \n]
                } else {
                    # If the line does not end with \n it is wrapped.
                    # Then spaces should be discarded
                    set line [string trimright $line]
                }
                lappend res $line
            }
            set prev $index
        }
        # The last chunk
        lappend res [string range $text $prev end]
        if {$underline != -1} {
            set lineNo -1
            set prev 0
            foreach index $firsts {
                if {$underline < $index} {
                    set underline [lindex $lineNo [expr {$underline - $prev}]]
                    break
                }
                set prev $index
                incr lineNo
            }
        }
        return $res
    }

    # Given a Tk font, figure out a reasonable font to use and set it
    # as current font.
    # In the future we could give more user options for controlling this.
    method CanvasSetFont {font} {
        array unset fontinfo
        array set fontinfo [font actual $font]
        array set fontinfo [font metrics $font]
        # Any fixed font maps to courier
        if {$fontinfo(-fixed)} {
            set fontinfo(-family) courier
        }
        set bold [expr {$fontinfo(-weight) eq "bold"}]
        set italic [expr {$fontinfo(-slant) eq "italic"}]

        switch -glob [string tolower $fontinfo(-family)] {
            *courier* - *fixed* {
                set family Courier
                if {$bold && $italic} {
                    append family -BoldOblique
                } elseif {$bold} {
                    append family -Bold
                } elseif {$italic} {
                    append family -BoldOblique
                }
            }
            *times* {
                if {$bold && $italic} {
                    set family Times-BoldItalic
                } elseif {$bold} {
                    set family Times-Bold
                } elseif {$italic} {
                    set family Times-Italic
                } else {
                    set family Times-Roman
                }
            }
            *helvetica* - *arial* - default {
                set family Helvetica
                if {$bold && $italic} {
                    append family -BoldOblique
                } elseif {$bold} {
                    append family -Bold
                } elseif {$italic} {
                    append family -BoldOblique
                }
            }
        }
        set fontsize $fontinfo(-linespace)
        $self BeginTextObj
        $self setFont $fontsize $family 1
    }

    #######################################################################
    # Helper fuctions
    #######################################################################

    # helper function: mask parentheses and backslash
    proc CleanText {in fn} {
        variable ::pdf4tcl::FontsAttrs
        if {$FontsAttrs($fn,specialencoding)} {
            # Convert using special encoding of font subset:
            set out ""
            foreach uchar [split $in {}] {
                append out [dict get $FontsAttrs($fn,encoding) $uchar]
            }
        } else {
            set out [encoding convertto $FontsAttrs($fn,encoding) $in]
        }
        return [string map {( \\( ) \\) \\ \\\\} $out]
    }

    # helper function: consume and return an object id
    method GetOid {{noxref 0}} {
        if {!$noxref} {
            $self StoreXref
        }
        set res $pdf(pdf_obj)
        incr pdf(pdf_obj)
        return $res
    }

    # helper function: return next object id (without incrementing)
    method NextOid {} {
        return $pdf(pdf_obj)
    }

    # helper function: set xref of (current) oid to current out_pos
    method StoreXref {{oid {}}} {
        if {$oid eq ""} {
            set oid $pdf(pdf_obj)
        }
        set pdf(xref,$oid) $pdf(out_pos)
    }

    # helper function for formatting floating point numbers
    proc Nf {n {deci 3}} {
        # Up to 3 decimals
        set num [format %.*f $deci $n]
        # Remove surplus decimals
        set num [string trimright [string trimright $num "0"] "."]
        # Small negative numbers might become -0
        if {$num eq "-0"} {
            set num "0"
        }
        return $num
    }
}

# vim: tw=0
