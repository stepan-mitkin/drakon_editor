#include <stdio.h>
#include <string.h>
#include "lib.h"


static int test_int_count = 0;

typedef struct test_int {
	tobject base;
	int value;
	int* ref_count;
} test_int;


static unsigned int int_hash(const void* obj)
{
	const int* ip = obj;
	if (!ip) return 0;
	return (unsigned int)*ip;
}



static unsigned int test_int_hash(const void* obj)
{
	const test_int* item;
	if (obj == 0) return 0;
	item = obj;
	return (unsigned int)item->value;
}

static int test_int_equal(
						  const void* left,
						  const void* right
						  )
{
	const test_int* tleft;
	const test_int* tright;
	if (left == right) return 1;
	if (!left || !right) return 0;
	tleft = left;
	tright = right;
	if (tleft->value == tright->value)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}

static void test_int_destroy(test_int* self);

static type_info_t test_int_t = { 
	OBJECT_SIGNATURE,
	"test_int",
	(destructor_fun)test_int_destroy
};

static void test_int_destroy(test_int* self)
{
	if (!self) return;
	ENSURE(self->base.type == &test_int_t)
	(*self->ref_count)--;
	free_memory(self, sizeof(test_int));
}

static test_int* test_int_create(int value)
{
	test_int* self = allocate_memory(sizeof(test_int));
	self->base.type = &test_int_t;
	self->ref_count = &test_int_count;
	self->value = value;
	(*self->ref_count)++;
	return self;
}

#define DATA_SIZE1 1000
static int int_equal(const void* left, const void* right)
{
	const int* left_i = left;
	const int* right_i = right;
	if (left_i == 0) return 0;
	if (*left_i == *right_i) return 1;
	return 0;
}

static int int_adder(void* item, void* user)
{
	const int* i = item;
	int* total = user;
	*total += *i;
	return 0;
}

static void obj_list_own_test(void)
{
	test_int* t;
	obj_list* list;
	
	test_int_count = 0;
	list = obj_list_create(1);
	ENSURE(obj_list_length(list) == 0)
	
	obj_list_resize(list, 3);
	
	ENSURE(obj_list_get(list, 0) == 0)
	ENSURE(obj_list_get(list, 1) == 0)
	ENSURE(obj_list_get(list, 2) == 0)	
	
	ENSURE(obj_list_length(list) == 3)
	
	obj_list_set(list, 2, test_int_create(50));
	
	ENSURE(test_int_count == 1)	
	obj_list_add(list, test_int_create(100));
	obj_list_add(list, test_int_create(100));	
	ENSURE(test_int_count == 3)
	ENSURE(obj_list_length(list) == 5)	
	
	obj_list_resize(list, 3);
	ENSURE(obj_list_length(list) == 3)
	t = obj_list_get(list, 2);
	ENSURE(t->value == 50)
	ENSURE(test_int_count == 1)
	
	obj_list_set(list, 2, test_int_create(55));
	ENSURE(test_int_count == 1)
	t = obj_list_get(list, 2);
	ENSURE(t->value == 55)
	obj_list_set(list, 0, test_int_create(60));
	obj_list_set(list, 1, test_int_create(61));
	ENSURE(test_int_count == 3)
	
	t = obj_list_get(list, 0);
	ENSURE(t->value == 60)
	t = obj_list_get(list, 1);
	ENSURE(t->value == 61)
	t = obj_list_get(list, 2);
	ENSURE(t->value == 55)
	
	obj_list_remove_at(list, 1);
	ENSURE(test_int_count == 2)
	ENSURE(obj_list_length(list) == 2)
	
	t = obj_list_get(list, 0);
	ENSURE(t->value == 60)
	t = obj_list_get(list, 1);
	ENSURE(t->value == 55)
	
	
	object_destroy(list);
	ENSURE(test_int_count == 0)	
}

static void obj_list_remove_test(void)
{
	int i1 = 1;
	int i2 = 2; 
	int i3 = 3;
	int i4 = 4;
	
	obj_list* list = obj_list_create(0);
	obj_list_add(list, &i1);
	obj_list_add(list, &i2);
	obj_list_add(list, &i3);	
	
	ENSURE(obj_list_length(list) == 3)
	ENSURE(obj_list_get(list, 0) == &i1)
	ENSURE(obj_list_get(list, 1) == &i2)
	ENSURE(obj_list_get(list, 2) == &i3)
	
	obj_list_remove(list, 0);

	ENSURE(obj_list_length(list) == 3)
	ENSURE(obj_list_get(list, 0) == &i1)
	ENSURE(obj_list_get(list, 1) == &i2)
	ENSURE(obj_list_get(list, 2) == &i3)

	obj_list_remove(list, &i4);
	
	ENSURE(obj_list_length(list) == 3)
	ENSURE(obj_list_get(list, 0) == &i1)
	ENSURE(obj_list_get(list, 1) == &i2)
	ENSURE(obj_list_get(list, 2) == &i3)

	obj_list_remove(list, &i2);
	
	ENSURE(obj_list_length(list) == 2)
	ENSURE(obj_list_get(list, 0) == &i1)
	ENSURE(obj_list_get(list, 1) == &i3)
	
	
	object_destroy(list);
}

static void obj_list_basic_test(void)
{
	int c;
	int* current;
	int i;
	int* data; // own
	obj_list* list; // own
	list = obj_list_create(0);
	data = allocate_memory(DATA_SIZE1 * sizeof(int));
	
	ENSURE(obj_list_length(list) == 0)
	ENSURE(obj_list_contains(list, &i) == 0)
	ENSURE(obj_list_contains(list, data + 1) == 0)	
	
	for (i = 0; i < DATA_SIZE1; i++)
	{
		obj_list_add(list, data + i);
		data[i] = i * 10;
	}

	ENSURE(obj_list_contains(list, &i) == 0)
	ENSURE(obj_list_contains(list, data + 1) == 1)	
	
	
	ENSURE(obj_list_length(list) == DATA_SIZE1)	

	for (i = 0; i < DATA_SIZE1; i++)
	{
		current = obj_list_get(list, i);
		ENSURE(current == data + i)
		ENSURE(*current == i * 10)
	}
	
	obj_list_resize(list, 10);
	
	ENSURE(obj_list_length(list) == 10)
	for (i = 0; i < 10; i++)
	{
		current = obj_list_get(list, i);
		ENSURE(current == data + i)
		ENSURE(*current == i * 10)
	}
	
	obj_list_remove_at(list, 2);
	ENSURE(obj_list_length(list) == 9)
	current = obj_list_get(list, 1);
	ENSURE(*current == 10)
	current = obj_list_get(list, 2);	
	ENSURE(*current == 30)
	current = obj_list_get(list, 3);
	ENSURE(*current == 40)
	
	obj_list_resize(list, 2000);
	ENSURE(obj_list_get(list, 9) == 0)
	ENSURE(obj_list_get(list, 1000) == 0)	
	ENSURE(obj_list_get(list, 1999) == 0)
	current = obj_list_get(list, 1);
	ENSURE(*current == 10)
	current = obj_list_get(list, 2);	
	ENSURE(*current == 30)
	current = obj_list_get(list, 3);
	ENSURE(*current == 40)
	
	c = 40;
	ENSURE(obj_list_find_first(list, int_equal, &c) == 3)
	c = 0;
	ENSURE(obj_list_find_first(list, int_equal, &c) == 0)
	c = 8000;
	ENSURE(obj_list_find_first(list, int_equal, &c) == -1)
	
	obj_list_set(list, 20, &c);
	current = obj_list_get(list, 20);
	ENSURE(*current == 8000)
	
	obj_list_resize(list, DATA_SIZE1);
	for (i = 0; i < obj_list_length(list); i++)
	{
		data[i] = i * 20;
		obj_list_set(list, i, data + i);
	}
	c = 0;
	ENSURE(obj_list_foreach(list, int_adder, &c) == 0)
	ENSURE(c == 9990000)
	
	free_memory(data, DATA_SIZE1 * sizeof(int));
	object_destroy(list);
}

static void check_string8(const string8* str, const char* expected)
{
	char c;
	int i;
	const char* buffer = string8_buffer(str);
	int length = string8_length(str);
	int exp_length = strlen(expected);
	ENSURE(length == exp_length)
	if (length == 0)
	{
		ENSURE(buffer == 0 || *buffer == 0)
	}
	else
	{
		for (i = 0; i <= length; i++)
		{
			ENSURE(buffer[i] == expected[i])
			if (i < length)
			{
				c = string8_get(str, i);
				ENSURE(c == expected[i])
			}
		}
	}	
	ENSURE(strcmp(buffer, expected) == 0)
}

static void string8_basic_test(void)
{
	int i;
	string8* s1; // own
	string8* s2; // own
	
	s1 = string8_create();
	ENSURE(string8_length(s1) == 0)
	string8_add(s1, 'h');
	string8_add(s1, 'i');
	ENSURE(string8_length(s1) == 2)	
	check_string8(s1, "hi");
	s2 = string8_clone(s1);
	ENSURE(string8_length(s2) == 2)	
	check_string8(s2, "hi");
	string8_clear(s2);
	ENSURE(string8_length(s2) == 0)	
	check_string8(s2, "");
	
	for (i = 0; i < 20; i++)
	{
		string8_add(s1, ' ');
	}
	ENSURE(string8_length(s1) == 22)	
	check_string8(s1, "hi                    ");
	
	object_destroy(s2);
	
	s2 = string8_from_buffer("hello, there", 5);
	check_string8(s2, "hello");
	string8_set(s2, 0, 'H');
	check_string8(s2, "Hello");	
	object_destroy(s2);	
	
	s2 = string8_from_cstr("DRAKON", 100);
	check_string8(s2, "DRAKON");
	object_destroy(s1);
	object_destroy(s2);
}

static void string8_equal_test(void)
{
	string8* e1 = string8_create();
	string8* e2 = string8_from_cstr("hi", 10);
	string8* hi = string8_from_cstr("hi", 10);
	string8* hi2 = string8_from_cstr("hi", 10);	
	string8* bye = string8_from_cstr("bye", 10);
	
	string8_clear(e2);
	
	ENSURE(string8_equal(0, 0));
	ENSURE(string8_equal(e1, 0));
	ENSURE(string8_equal(0, e1));
	ENSURE(string8_equal(e2, 0));
	ENSURE(string8_equal(0, e2));
	ENSURE(string8_equal(e1, e1));
	ENSURE(string8_equal(e1, e2));	
	ENSURE(string8_equal(e2, e1));
	ENSURE(string8_equal(e2, e2));
	
	ENSURE(!string8_equal(e1, hi));
	ENSURE(!string8_equal(hi, bye));
	ENSURE(string8_equal(hi, hi2));
	ENSURE(string8_equal(hi, hi));
	
	object_destroy(e1);
	object_destroy(e2);
	object_destroy(hi);
	object_destroy(hi2);
	object_destroy(bye);	
}

static void string8_split_lines_empty_empty(void)
{
	string8* text = string8_from_cstr("", 100);
	obj_list* list = obj_list_create(1);
	
	string8_split_lines(text, list);
	
	ENSURE(obj_list_length(list) == 0)
	
	object_destroy(list);
	object_destroy(text);
}

static void string8_split_lines_1line_1item(void)
{
	string8* text = string8_from_cstr("hello", 100);
	obj_list* list = obj_list_create(1);
	
	string8_split_lines(text, list);
	
	ENSURE(obj_list_length(list) == 1)
	check_string8(obj_list_get(list, 0), "hello");
	
	object_destroy(list);
	object_destroy(text);
}

static void string8_split_lines_3lines_3items(void)
{
	string8* text = string8_from_cstr("one\r\ntwo\nthree", 100);
	obj_list* list = obj_list_create(1);
	
	string8_split_lines(text, list);
	
	ENSURE(obj_list_length(list) == 3)
	check_string8(obj_list_get(list, 0), "one");
	check_string8(obj_list_get(list, 1), "two");
	check_string8(obj_list_get(list, 2), "three");
	object_destroy(list);
	object_destroy(text);
}


static void string8_split_lines_3lines_trail_3items(void)
{
	string8* text = string8_from_cstr("one\r\ntwo\nthree\n", 100);
	obj_list* list = obj_list_create(1);
	
	string8_split_lines(text, list);
	

	ENSURE(obj_list_length(list) == 3)
	check_string8(obj_list_get(list, 0), "one");
	check_string8(obj_list_get(list, 1), "two");
	check_string8(obj_list_get(list, 2), "three");
	
	object_destroy(list);
	object_destroy(text);
}


static void string8_hash_test(void)
{
	string8* e1 = string8_create();
	string8* e2 = string8_from_cstr("hi", 10);
	string8* hi = string8_from_cstr("hi", 10);
	string8* hi2 = string8_from_cstr("hi", 10);	
	string8* bye = string8_from_cstr("bye", 10);

	string8_clear(e2);
	
	ENSURE(string8_hash(0) == 0)
	ENSURE(string8_hash(e1) == 0)
	ENSURE(string8_hash(e2) == 0)
	ENSURE(string8_hash(hi) != 0)
	ENSURE(string8_hash(hi) == string8_hash(hi2))
	ENSURE(string8_hash(bye) != string8_hash(hi))
	
	object_destroy(e1);
	object_destroy(e2);
	object_destroy(hi);
	object_destroy(hi2);
	object_destroy(bye);	
}

static void hash_table_basic_test(void)
{
	int total = 0;
	int* ip;
	int i;
	hashtable* t1 = hashtable_create(0, int_hash, int_equal);
	int* data = allocate_memory(sizeof(int) * DATA_SIZE1);
	int* data2 = allocate_memory(sizeof(int) * DATA_SIZE1);	

	ENSURE(hashtable_count(t1) == 0)
	
	for (i = 0; i < DATA_SIZE1; i++)
	{
		data[i] = i * 10;
		data2[i] = i * 10;		
		ENSURE(hashtable_put(t1, data + i))
	}
	ENSURE(hashtable_count(t1) == DATA_SIZE1)
	
	i = 30;
	ENSURE(hashtable_get(t1, &i) == data + 3)
	i = -30;
	ENSURE(hashtable_get(t1, &i) == 0)
	
	ENSURE(hashtable_remove(t1, &i) == 0)
	
	for (i = 0; i < DATA_SIZE1; i++)
	{
		ip = hashtable_get(t1, data2 + i);
		ENSURE(ip == data + i)
		ENSURE(*ip == i * 10);
	}
	
	ENSURE(hashtable_foreach(t1, int_adder, &total) == 0)
	ENSURE(total = 999000)

	for (i = 0; i < DATA_SIZE1; i++)
	{
		hashtable_remove(t1, data2 + i);
		ip = hashtable_get(t1, data2 + i);
		ENSURE(ip == 0)
	}

	ENSURE(hashtable_count(t1) == 0)	
	
	free_memory(data, sizeof(int) * DATA_SIZE1);
	free_memory(data2, sizeof(int) * DATA_SIZE1);	
	object_destroy(t1);
}

static void hash_table_own_test(void)
{
	int i;
	test_int* ti;
	hashtable* tab; // own
	test_int* key; // own
	test_int_count = 0;
	tab = hashtable_create(1, test_int_hash, test_int_equal);
	key = test_int_create(0);

	for (i = 0; i < DATA_SIZE1; i++)
	{
		ENSURE(hashtable_put(tab, test_int_create(i)))
		key->value = i;
		ti = hashtable_get(tab, key);
		ENSURE(ti->value == i)
	}
	ENSURE(hashtable_count(tab) == DATA_SIZE1)
	ENSURE(test_int_count == DATA_SIZE1 + 1)

	key->value = 2000;
	ENSURE(hashtable_get(tab, key) == 0)
	
	for (i = 0; i < DATA_SIZE1; i++)
	{
		key->value = i;
		ti = hashtable_get(tab, key);
		ENSURE(ti->value == i)
		hashtable_remove(tab, key);
		ti = hashtable_get(tab, key);
		ENSURE(ti == 0)
	}
	
	ENSURE(test_int_count == 1)

	for (i = 0; i < DATA_SIZE1; i++)
	{
		ENSURE(hashtable_put(tab, test_int_create(i)))
	}

	ENSURE(hashtable_count(tab) == DATA_SIZE1)
	ENSURE(test_int_count == DATA_SIZE1 + 1)

	object_destroy(tab);
	ENSURE(test_int_count == 1)	
	object_destroy(key);
	ENSURE(test_int_count == 0)
}

static void int_list_basic_test(void)
{
	int i, c;
	int_list* li = int_list_create();
	
	ENSURE(int_list_length(li) == 0)
	for (i = 0; i < DATA_SIZE1; i++)
	{
		int_list_add(li, i * 10);
		ENSURE(int_list_get(li, i) == i * 10)
	}
	
	ENSURE(int_list_length(li) == DATA_SIZE1)	

	for (i = 0; i < DATA_SIZE1; i++)
	{
		int_list_set(li, i, i * 5);
	}
	
	int_list_resize(li, DATA_SIZE1 * 3);
	ENSURE(int_list_length(li) == DATA_SIZE1 * 3);
	for (i = DATA_SIZE1; i < DATA_SIZE1 * 3; i++)
	{
		int_list_set(li, i, i * 5);
	}
	
	for (i = 0; i < DATA_SIZE1 * 3; i++)
	{
		c = int_list_get(li, i);
		ENSURE(c == i * 5)
	}
	
	object_destroy(li);
}

static void int_list_remove_at_test(void)
{
	int_list* li = int_list_create(); // own
	
	int_list_add(li, 10);
	int_list_add(li, 20);
	int_list_add(li, 30);
	int_list_add(li, 40);
	int_list_add(li, 50);
	
	ENSURE(int_list_length(li) == 5)
	
	ENSURE(int_list_get(li, 0) == 10)
	ENSURE(int_list_get(li, 1) == 20)
	ENSURE(int_list_get(li, 2) == 30)
	ENSURE(int_list_get(li, 3) == 40)
	ENSURE(int_list_get(li, 4) == 50)	
	
	int_list_remove_at(li, 4);

	ENSURE(int_list_length(li) == 4)
	
	ENSURE(int_list_get(li, 0) == 10)
	ENSURE(int_list_get(li, 1) == 20)
	ENSURE(int_list_get(li, 2) == 30)
	ENSURE(int_list_get(li, 3) == 40)

	int_list_remove_at(li, 1);
	
	ENSURE(int_list_length(li) == 3)
	
	ENSURE(int_list_get(li, 0) == 10)
	ENSURE(int_list_get(li, 1) == 30)
	ENSURE(int_list_get(li, 2) == 40)

	int_list_remove_at(li, 0);
	
	ENSURE(int_list_length(li) == 2)
	
	ENSURE(int_list_get(li, 0) == 30)
	ENSURE(int_list_get(li, 1) == 40)

	int_list_remove_at(li, 0);
	int_list_remove_at(li, 0);	

	ENSURE(int_list_length(li) == 0)	
	
	object_destroy(li);
}

static void array_table_test(void)
{
	test_int* current;
	int i;
	array_table table;
	array_table_init(&table, "test_ints");
	
	ENSURE(array_table_insert(&table, test_int_create(0)) == 1)
	ENSURE(array_table_insert(&table, test_int_create(1)) == 2)
	ENSURE(array_table_insert(&table, test_int_create(2)) == 3)
	ENSURE(table.items[0] == 0)
	
	for (i = 3; i < DATA_SIZE1; i++)
	{
		ENSURE(array_table_insert(&table, test_int_create(i)) == i + 1)
	}

	for (i = 1; i <= DATA_SIZE1; i++)
	{
		current = table.items[i];
		ENSURE(current->value == i - 1)
	}
	
	current = table.items[20];
	test_int_destroy(current);
	current = 0;
	
	array_table_delete(&table, 20);
	ENSURE(table.count == DATA_SIZE1 - 1)
	ENSURE(table.items[20] == 0)
	array_table_delete(&table, 20);
	ENSURE(table.count == DATA_SIZE1 - 1)
	
	ENSURE(array_table_insert(&table, test_int_create(444)) == 20)
	ENSURE(table.count == DATA_SIZE1)	
	current = table.items[20];
	ENSURE(current->value == 444)
	
	for (i = 1; i <= DATA_SIZE1; i++)
	{
		current = table.items[i];		
		if (current)
		{
			array_table_delete(&table, i);
			test_int_destroy(current);
		}
	}
	array_table_cleanup(&table);
}

static void check_string16(const string16* str, const char* expected)
{
	char16 c;
	int i;
	const char16* buffer = string16_buffer(str);
	int length = string16_length(str);
	int exp_length = strlen(expected);
	ENSURE(length == exp_length)
	if (length == 0)
	{
		ENSURE(buffer == 0 || *buffer == 0)
	}
	else
	{
		for (i = 0; i <= length; i++)
		{
			ENSURE(buffer[i] == (char16)expected[i])
			if (i < length)
			{
				c = string16_get(str, i);
				ENSURE(c == (char16)expected[i])
			}
		}
	}
}

static void string16_from_buffer_empty_empty(void)
{
	char16 c;
	string16* s; // own
	c = 'm';
	s = string16_from_buffer(&c, 0);
	check_string16(s, "");
	
	object_destroy(s);
}

static void string16_from_buffer_content(void)
{
	string16* s; // own
	char16 buffer[] = { 'h', 'e', 'l', 'l', 'o' };
	s = string16_from_buffer(buffer, 5);
	check_string16(s, "hello");
	
	object_destroy(s);
}

static void string16_equal_same_yes(void)
{
	string16* s = string16_from_cstr("hi", 10);
	
	ENSURE(string16_equal(s, s))
	ENSURE(string16_equal(0, 0))
	
	object_destroy(s);
}

static void string16_equal_left0_righte_yes(void)
{
	string16* s = string16_from_cstr("", 10);
	
	ENSURE(string16_equal(0, s))
	
	object_destroy(s);
}

static void string16_equal_lefte_right0_yes(void)
{
	string16* s = string16_from_cstr("", 10);
	
	ENSURE(string16_equal(s, 0))
	
	object_destroy(s);
}

static void string16_equal_diff_length_no(void)
{
	string16* a = string16_from_cstr("a", 10);
	string16* ab = string16_from_cstr("ab", 10);	
	
	ENSURE(!string16_equal(a, ab))
	
	object_destroy(a);
	object_destroy(ab);	
}

static void string16_equal_empty_empty_yes(void)
{
	string16* a = string16_from_cstr("", 10);
	string16* ab = string16_from_cstr("", 10);	
	
	ENSURE(string16_equal(a, ab))
	
	object_destroy(a);
	object_destroy(ab);	
}

static void string16_equal_equal_yes(void)
{
	string16* ab = string16_from_cstr("ab", 10);
	string16* ab2 = string16_from_cstr("ab", 10);	
	
	ENSURE(string16_equal(ab, ab2))
	
	object_destroy(ab);
	object_destroy(ab2);	
}

static void string16_equal_not_equal_no(void)
{
	string16* ab = string16_from_cstr("abc", 10);
	string16* ab2 = string16_from_cstr("auc", 10);	
	
	ENSURE(!string16_equal(ab, ab2))
	
	object_destroy(ab);
	object_destroy(ab2);	
}

static void string16_hash_null_0(void)
{
	string16* s = 0;
	
	ENSURE(string16_hash(s) == 0)
}

static void string16_hash_empty_0(void)
{
	string16* s = string16_from_cstr("", 10);
	
	ENSURE(string16_hash(s) == 0)
	
	object_destroy(s);
}

static void string16_hash_same_equal(void)
{
	string16* s = string16_from_cstr("hi", 10);
	
	ENSURE(string16_hash(s) == string16_hash(s))
	
	object_destroy(s);
}

static void string16_hash_equal_equal(void)
{
	string16* s = string16_from_cstr("hello", 10);
	string16* s2 = string16_from_cstr("hello", 10);
	
	ENSURE(string16_hash(s2) == string16_hash(s))
	
	object_destroy(s);
	object_destroy(s2);	
}

static void string16_hash_not_equal_diff(void)
{
	string16* s = string16_from_cstr("hello", 10);
	string16* s2 = string16_from_cstr("hellb", 10);
	
	ENSURE(string16_hash(s2) != string16_hash(s))
	
	object_destroy(s);
	object_destroy(s2);	
}

static void string16_from_cstr_empty(void)
{
	string16* s = string16_from_cstr("", 10);
	
	check_string16(s, "");
	object_destroy(s);
}

static void string16_from_cstr_null(void)
{
	string16* s = string16_from_cstr(0, 10);
	
	check_string16(s, "");
	object_destroy(s);
}


static void string16_from_cstr_content(void)
{
	string16* s = string16_from_cstr("hello, kitty", 100);
	
	check_string16(s, "hello, kitty");
	object_destroy(s);
}

static void string16_clone_null_empty(void)
{
	string16* c = string16_clone(0);
	
	check_string16(c, "");
	object_destroy(c);	
}

static void string16_clone_empty_empty(void)
{
	string16* s = string16_from_cstr("", 10);
	string16* c = string16_clone(s);
	
	check_string16(c, "");
	object_destroy(c);	
	object_destroy(s);		
}

static void string16_clone_content_equal(void)
{
	string16* s = string16_from_cstr("hello", 10);
	string16* c = string16_clone(s);
	
	check_string16(c, "hello");
	ENSURE(string16_equal(s, c))
	object_destroy(c);	
	object_destroy(s);		
}

static void string16_add_long(void)
{
	string16* s = string16_create();
	
	string16_add(s, '1');
	string16_add(s, '2');
	string16_add(s, '3');
	string16_add(s, '4');
	string16_add(s, '5');
	string16_add(s, '6');
	string16_add(s, '7');
	string16_add(s, '8');
	string16_add(s, '9');
	string16_add(s, '0');
	string16_add(s, 'a');
	string16_add(s, 'b');
	string16_add(s, 'c');
	string16_add(s, 'd');
	string16_add(s, 'e');
	string16_add(s, 'f');
	string16_add(s, 'g');
	string16_add(s, 'h');
	string16_add(s, 'i');
	string16_add(s, 'j');
	string16_add(s, 'k');
	
	check_string16(s, "1234567890abcdefghijk");
	
	object_destroy(s);
}

static void string16_add_after_ascii(void)
{
	string16* s = string16_from_cstr("hello", 10);
	string16_add(s, ',');
	string16_add(s, ' ');
	string16_add(s, 'k');
	string16_add(s, 'i');
	string16_add(s, 't');
	string16_add(s, 't');
	string16_add(s, 'y');
	check_string16(s, "hello, kitty");
	
	object_destroy(s);
}

static void string16_clear_empty_empty(void)
{
	string16* s = string16_create();
	string16_clear(s);
	
	check_string16(s, "");
	object_destroy(s);
}

static void string16_clear_content_empty(void)
{
	string16* s = string16_from_cstr("full", 10);
	string16_clear(s);
	
	check_string16(s, "");
	object_destroy(s);
}

static void string16_set_content(void)
{
	string16* s = string16_from_cstr("number 1", 10);

	string16_set(s, 7, '2');
	
	check_string16(s, "number 2");
	object_destroy(s);	
}

static void string16_split_lines_empty_empty(void)
{
	string16* text = string16_from_cstr("", 100);
	obj_list* list = obj_list_create(1);
	
	string16_split_lines(text, list);
	
	ENSURE(obj_list_length(list) == 0)
	
	object_destroy(list);
	object_destroy(text);
}

static void string16_split_lines_1line_1item(void)
{
	string16* text = string16_from_cstr("hello", 100);
	obj_list* list = obj_list_create(1);
	
	string16_split_lines(text, list);
	
	ENSURE(obj_list_length(list) == 1)
	check_string16(obj_list_get(list, 0), "hello");
	
	object_destroy(list);
	object_destroy(text);
}

static void string16_split_lines_3lines_3items(void)
{
	string16* text = string16_from_cstr("one\r\ntwo\nthree", 100);
	obj_list* list = obj_list_create(1);
	
	string16_split_lines(text, list);
	
	ENSURE(obj_list_length(list) == 3)
	check_string16(obj_list_get(list, 0), "one");
	check_string16(obj_list_get(list, 1), "two");
	check_string16(obj_list_get(list, 2), "three");
	object_destroy(list);
	object_destroy(text);
}


static void string16_split_lines_3lines_trail_3items(void)
{
	string16* text = string16_from_cstr("one\r\ntwo\nthree\n", 100);
	obj_list* list = obj_list_create(1);
	
	string16_split_lines(text, list);
	
	
	ENSURE(obj_list_length(list) == 3)
	check_string16(obj_list_get(list, 0), "one");
	check_string16(obj_list_get(list, 1), "two");
	check_string16(obj_list_get(list, 2), "three");
	
	object_destroy(list);
	object_destroy(text);
}

static void string16_compare_both_null_0(void)
{
	string16* left = 0;
	string16* right = 0;
	
	ENSURE(string16_compare(left, right) == 0)
}

static void string16_compare_same_0(void)
{
	string16* left = string16_from_cstr("hi", 10); // own
	string16* right = left;
	
	ENSURE(string16_compare(left, right) == 0)
	
	object_destroy(left);
}

static void string16_compare_left_null_less(void)
{
	string16* left = 0;	
	string16* right = string16_from_cstr("hi", 10); // own
	
	ENSURE(string16_compare(left, right) == -1)
	
	object_destroy(left);
	object_destroy(right);	
}

static void string16_compare_right_null_greater(void)
{
	string16* left = string16_from_cstr("hi", 10); // own
	string16* right = 0;
	
	ENSURE(string16_compare(left, right) == 1)
	
	object_destroy(left);
	object_destroy(right);	
}

static void string16_compare_equal_equal(void)
{
	string16* left = string16_from_cstr("hi", 10); // own
	string16* right = string16_from_cstr("hi", 10); // own
	
	ENSURE(string16_compare(left, right) == 0)
	
	object_destroy(left);
	object_destroy(right);	
}

static void string16_compare_less_less(void)
{
	string16* left = string16_from_cstr("hia", 10); // own
	string16* right = string16_from_cstr("hib", 10); // own
	
	ENSURE(string16_compare(left, right) == -1)
	ENSURE(string16_compare(right, left) == 1)
	
	object_destroy(left);
	object_destroy(right);	
}

static void string16_compare_greater_greater(void)
{
	string16* left = string16_from_cstr("hib", 10); // own
	string16* right = string16_from_cstr("hia", 10); // own
	
	ENSURE(string16_compare(left, right) == 1)
	ENSURE(string16_compare(right, left) == -1)
	
	object_destroy(left);
	object_destroy(right);	
}

static void string16_compare_shorter_less(void)
{
	string16* left = string16_from_cstr("hi", 10); // own
	string16* right = string16_from_cstr("hib", 10); // own
	
	ENSURE(string16_compare(left, right) == -1)
	ENSURE(string16_compare(right, left) == 1)
	
	object_destroy(left);
	object_destroy(right);	
}

static void string16_compare_longer_greater(void)
{
	string16* left = string16_from_cstr("hia", 10); // own
	string16* right = string16_from_cstr("hi", 10); // own
	
	ENSURE(string16_compare(left, right) == 1)
	ENSURE(string16_compare(right, left) == -1)
	
	object_destroy(left);
	object_destroy(right);	
}

static void string16_compare_empty_less(void)
{
	string16* left = string16_from_cstr("", 10); // own
	string16* right = string16_from_cstr("hi", 10); // own
	
	ENSURE(string16_compare(left, right) == -1)
	ENSURE(string16_compare(right, left) == 1)
	
	object_destroy(left);
	object_destroy(right);	
}


static void string16_test(void)
{
	string16_from_buffer_empty_empty();
	string16_from_buffer_content();
	string16_equal_same_yes();
	string16_equal_left0_righte_yes();
	string16_equal_lefte_right0_yes();
	string16_equal_diff_length_no();
	string16_equal_empty_empty_yes();
	string16_equal_equal_yes();
	string16_equal_not_equal_no();
	string16_hash_null_0();
	string16_hash_empty_0();
	string16_hash_same_equal();
	string16_hash_equal_equal();
	string16_hash_not_equal_diff();
	string16_from_cstr_empty();
	string16_from_cstr_null();
	string16_from_cstr_content();
	string16_clone_null_empty();
	string16_clone_empty_empty();
	string16_clone_content_equal();
	string16_add_long();
	string16_add_after_ascii();
	string16_clear_empty_empty();
	string16_clear_content_empty();
	string16_set_content();
	string16_split_lines_empty_empty();	
	string16_split_lines_1line_1item();
	string16_split_lines_3lines_3items();
	string16_split_lines_3lines_trail_3items();	
	string16_compare_both_null_0();
	string16_compare_same_0();
	
	string16_compare_left_null_less();
	string16_compare_right_null_greater();
	string16_compare_equal_equal();
	string16_compare_less_less();
	string16_compare_greater_greater();
	string16_compare_shorter_less();
	string16_compare_longer_greater();
	string16_compare_empty_less();
}


void lib_test(void)
{
	printf("lib_test\n");
	obj_list_basic_test();
	obj_list_own_test();
	obj_list_remove_test();
	string8_basic_test();
	hash_table_basic_test();
	hash_table_own_test();
	int_list_basic_test();
	int_list_remove_at_test();
	array_table_test();
	string8_equal_test();
	string8_hash_test();
	
	
	string8_split_lines_empty_empty();	
	string8_split_lines_1line_1item();
	string8_split_lines_3lines_3items();
	string8_split_lines_3lines_trail_3items();

	string16_test();
}
