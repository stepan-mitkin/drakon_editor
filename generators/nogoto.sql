
create table nodes
(
	item_id integer primary key,
	type text,
	text_lines text,
	marked integer,
	is_dummy integer,
	real_item integer,
	continue_item integer,
	loop_break integer,
	if_stop integer,
	loop_id integer
);

create table links
(
	link_id integer primary key,
	src integer,
	ordinal integer,
	dst integer,
	link_type text
);

create unique index links_by_src_ordinal on links(src, ordinal);
create index links_by_dst on links(dst);

