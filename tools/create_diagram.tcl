set dia {{type beginend text Untitled selected 1 x 170 y 60 w 100 h 20 a 60 b 0 item_id 1} {type beginend text End selected 1 x 660 y 510 w 60 h 20 a 60 b 0 item_id 2} {type vertical text {} selected 1 x 170 y 80 w 0 h 520 a 0 b 0 item_id 3} {type vertical text {} selected 1 x 420 y 120 w 0 h 480 a 0 b 0 item_id 4} {type vertical text {} selected 1 x 660 y 120 w 0 h 380 a 0 b 0 item_id 5} {type horizontal text {} selected 1 x 170 y 120 w 490 h 0 a 0 b 0 item_id 6} {type arrow text {} selected 1 x 20 y 120 w 150 h 480 a 400 b 1 item_id 7} {type branch text {branch 1} selected 1 x 170 y 170 w 50 h 30 a 60 b 0 item_id 8} {type address text {branch 2} selected 1 x 170 y 550 w 50 h 30 a 60 b 0 item_id 9} {type branch text {branch 2} selected 1 x 420 y 170 w 50 h 30 a 60 b 0 item_id 10} {type branch text {branch 3} selected 1 x 660 y 170 w 50 h 30 a 60 b 0 item_id 11} {type address text {branch 3} selected 1 x 420 y 550 w 50 h 30 a 60 b 0 item_id 12}}


foreach item $dia {
  array set elements $item

  puts -nonewline "lappend result \[ list insert items item_id \$item_id diagram_id \$id "
  puts -nonewline "type '$elements(type)' text \"'$elements(text)'\" selected 0 x $elements(x) y $elements(y) "
  puts "w $elements(w) h $elements(h) a $elements(a) b $elements(b) \]"
  puts "incr item_id"
}
