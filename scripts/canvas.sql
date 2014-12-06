
create table item_shadows
(
	item_id integer primary key,
	type text,
	x integer,
	y integer,
	w integer,
	h integer,
	a integer,
	b integer,
	selected integer
);

create table primitives
(
	prim_id integer primary key,
	item_id integer,
	layer_id integer,
	role text,
	ordinal integer,
	above integer,
	below integer,
	ext_id integer,
	type text,
	rect text
);

create index primitive_by_item_layer on primitives (item_id, layer_id);

create unique index primitive_by_item_role on primitives (item_id, role, ordinal);

create table layers
(
	ordinal integer primary key,
	name text unique,
	lowest integer,
	topmost integer,
	prim_count integer
);

insert into layers (ordinal, name, lowest, topmost, prim_count) values (1, 'lines', 0, 0, 0);
insert into layers (ordinal, name, lowest, topmost, prim_count) values (2, 'icons', 0, 0, 0);
insert into layers (ordinal, name, lowest, topmost, prim_count) values (3, 'handles', 0, 0, 0);