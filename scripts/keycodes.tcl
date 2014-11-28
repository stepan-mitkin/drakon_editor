namespace eval ui {

proc linux_keycodes { } {
	return {
		0 19
		1 10
		2 11
		3 12
		4 13
		5 14
		6 15
		7 16
		8 17
		9 18
		Alt_L 64
		BackSpace 22
		Caps_Lock 66
		Control_L 37
		Delete 119
		Down 116
		End 115
		Escape 9
		F1 67
		F10 76
		F11 95
		F12 96
		F2 68
		F3 69
		F4 70
		F5 71
		F6 72
		F7 73
		F8 74
		F9 75
		Home 110
		ISO_Level3_Shift 108
		Insert 118
		Left 113
		Menu 135
		Next 117
		Prior 112
		Return 36
		Right 114
		Shift_L 50
		Shift_R 62
		Super_L 133
		Tab 23
		Up 111
		a 38
		apostrophe 48
		b 56
		backslash 51
		bracketleft 34
		bracketright 35
		c 54
		comma 59
		d 40
		e 26
		equal 21
		f 41
		g 42
		grave 49
		h 43
		i 31
		j 44
		k 45
		l 46
		m 58
		minus 20
		n 57
		o 32
		p 33
		period 60
		q 24
		r 27
		s 39
		semicolon 47
		slash 61
		space 65
		t 28
		u 30
		v 55
		w 25
		x 53
		y 29
		z 52
	}
}

proc windows_keycodes { } {
	return {
		0 96
		1 97
		2 98
		3 99
		4 100
		5 101
		6 102
		7 103
		8 104
		9 105
		Alt_L 18
		Alt_R 18
		App 93
		BackSpace 8
		Control_L 17
		Control_R 17
		Delete 46
		Down 40
		End 35
		Escape 27
		F1 112
		F10 121
		F11 122
		F12 123
		F2 113
		F3 114
		F4 115
		F5 116
		F6 117
		F7 118
		F8 119
		F9 120
		Home 36
		Insert 45
		Left 37
		Next 34
		Num_Lock 144
		Prior 33
		Return 13
		Right 39
		Shift_L 16
		Shift_R 16
		Up 38
		Win_L 91
		Win_R 92
		a 65
		asterisk 106
		b 66
		backslash 220
		bracketleft 219
		bracketright 221
		c 67
		comma 188
		d 68
		e 69
		equal 187
		f 70
		g 71
		h 72
		i 73
		j 74
		k 75
		l 76
		m 77
		minus 109
		n 78
		o 79
		p 80
		period 190
		plus 107
		q 81
		quoteleft 192
		quoteright 222
		r 82
		s 83
		semicolon 186
		slash 191
		space 32
		t 84
		u 85
		v 86
		w 87
		x 88
		y 89
		z 90
	}
}

proc mac_keycodes { } {
	return {
		0 1900592
		1 1179697
		2 1245234
		3 1310771
		4 1376308
		5 1507381
		6 1441846
		7 1703991
		8 1835064
		9 1638457
		BackSpace 3342463
		Caps_Lock 65536
		Down 8255233
		Escape 3473435
		F1 8058628
		F2 7927557
		F3 6551302
		F4 7796487
		F5 6354696
		F6 6420233
		F7 6485770
		F8 6616843
		Left 8124162
		Return 2359309
		Right 8189699
		Tab 3145737
		Up 8320768
		a 97
		b 720994
		backslash 2752604
		bracketleft 2162779
		bracketright 1966173
		c 524387
		comma 2818092
		d 131172
		e 917605
		equal 1572925
		f 196710
		g 327783
		h 262248
		i 2228329
		j 2490474
		k 2621547
		l 2424940
		m 3014765
		minus 1769517
		n 2949230
		o 2031727
		p 2293872
		period 3080238
		q 786545
		quoteleft 3276896
		quoteright 2555943
		r 983154
		s 65651
		semicolon 2687035
		slash 2883631
		space 3211296
		t 1114228
		u 2097269
		v 589942
		w 852087
		x 458872
		y 1048697
		z 393338
	}
}

proc key_codes { } {
	global tcl_platform
	if { [ is_mac ] } {
		return [ mac_keycodes ]
	} elseif { [ is_windows ] } {
		return [ windows_keycodes ]
	} else {
		return [ linux_keycodes ]
	}
}

}

