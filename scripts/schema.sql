
create table diagrams
(
	diagram_id integer primary key,
	name text unique,
	origin text,
	description text,
	zoom double
);

create table state
(
	row integer primary key,
	current_dia integer,
	description text
);

create table items
(
	item_id integer primary key,
	diagram_id integer,
	type text,
	text text,
	selected integer,
	x integer,
	y integer,
	w integer,
	h integer,
	a integer,
	b integer,
	aux_value integer,
	color text,
	format text,
	text2 text
);

create table diagram_info
(
	diagram_id integer,
	name text,
	value text,
	primary key (diagram_id, name)
);

create table tree_nodes
(
	node_id integer primary key,
	parent integer,
	type text,
	name text,
	diagram_id integer
);

create index items_per_diagram on items (diagram_id);

insert into state (current_dia, row) values ('', 1);
	
create unique index node_for_diagram on tree_nodes (diagram_id);
