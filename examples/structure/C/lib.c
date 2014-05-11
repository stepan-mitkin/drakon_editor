#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#include "lib.h"

struct int_list {
	tobject base;
	int* buffer;
	int allocated;
	int length;
};

static type_info_t int_list_t = { 
	OBJECT_SIGNATURE,
	"int_list",
	(destructor_fun)int_list_destroy
};


struct string8 {
	tobject base;
	char* buffer;
	int allocated;
	int length;
};

static type_info_t string8_t = { 
	OBJECT_SIGNATURE,
	"string8",
	(destructor_fun)string8_destroy
};

struct string16 {
	tobject base;
	char16* buffer;
	int allocated;
	int length;
};


static type_info_t string16_t = { 
	OBJECT_SIGNATURE,
	"string16",
	(destructor_fun)string16_destroy
};

struct hashtable {
	tobject base;
	obj_list* buckets; // own
	int count;
	int own;
	hash_fun hash;
	equal_fun equal;
};

static type_info_t hashtable_t = { 
	OBJECT_SIGNATURE,
	"hashtable",
	(destructor_fun)hashtable_destroy
};


#define MAX_LOAD_FACTOR 10.0f
#define MIN_TABLE_SIZE 20


// Returns ownership
string8* string8_create(void)
{
	string8* me = allocate_memory(sizeof(string8));
	me->base.type = &string8_t;
	return me;
}

int cstring_length(const char* str, int limit)
{
	int i;
	ENSURE(limit >= 0 && limit <= MAX_CSTR)
	
	if (str == 0) return 0;
	for (i = 0; i < limit; i++)
	{
		if (str[i] == 0) return i;
	}
	
	return limit;
}

// Returns ownership
string8* string8_from_buffer(const char* buffer, int length)
{
	int i, allocated;
	string8* me = 0; // Own
	ENSURE(length >= 0)
	me = string8_create();
	if (length > 0 && buffer != 0)
	{
		allocated = length + 1;
		me->buffer = allocate_memory(allocated);
		me->allocated = allocated;
		me->length = length;
		for (i = 0; i < length; i++)
		{
			me->buffer[i] = buffer[i];
		}
		me->buffer[length] = 0;
	}
	return me;
}

int 
string8_equal(const string8* left, const string8* right)
{
	if (left == right) return 1;
	if (!left)
	{
		return right->length == 0;
	}
	if (!right)
	{
		return left->length == 0;
	}
	if (left->length != right->length) return 0;
	if (left->length == 0) return 1;
	if (memcmp(left->buffer, right->buffer, left->length) == 0)
	{
		return 1;
	}
	return 0;
}

unsigned int
string8_hash(const string8* me)
{
	if (!me) return 0;
	if (me->length == 0) return 0;
	
	return qhashmurmur3_32(
						   me->buffer,
						   me->length
						   );
}


// Returns ownership
string8* string8_from_cstr(const char* str, int limit)
{
	int length;
	ENSURE(limit >= 0)
	ENSURE(limit <= MAX_CSTR)
	
	length = cstring_length(str, limit);
	if (length > 0)
	{
		return string8_from_buffer(str, length);
	}
	else
	{
		return string8_create();
	}
}

void string8_destroy(
					 string8* me // Takes ownership
					 )
{
	if (!me) return;
	ENSURE(me->base.type == &string8_t)
	free_memory(me->buffer, me->allocated);
	free_memory(me, sizeof(string8));
}

// Returns ownership
string8* string8_clone(
					   const string8* obj
					   )
{
	if (obj && obj->length > 0)
	{
		return string8_from_buffer(obj->buffer, obj->length);
	}
	else
	{
		return string8_create();
	}
}


void string8_add(string8* me, char element)
{
	int new_alloc;
	int old_length = me->length;
	ENSURE(me->length >= 0)
	ENSURE(me->length == 0 || me->length < me->allocated)
	
	if (me->buffer == 0)
	{
		new_alloc = 16;
		me->buffer = allocate_memory(new_alloc);
		ENSURE(me->buffer)
		me->allocated = new_alloc;		
	}
	else if (me->length + 1 == me->allocated)
	{
		new_alloc = me->allocated * 2;
		me->buffer = reallocate_memory(me->buffer, 1, me->allocated, new_alloc);
		me->allocated = new_alloc;		
	}

	me->length++;
	me->buffer[old_length] = element;
	me->buffer[me->length] = 0;	
}

void string8_clear(string8* me)
{
	if (me->buffer)
	{
		me->buffer[0] = 0;
		me->length = 0;
	}
}

char string8_get(const string8* me, int index)
{
	ENSURE(index >= 0 && index < me->length)
	return me->buffer[index];
}

void string8_set(string8* me, int index, char element)
{
	ENSURE(index >= 0 && index < me->length)
	me->buffer[index] = element;
}

int string8_length(const string8* me)
{
	return me->length;
}

void string8_print(
				   const string8* me
				   )
{
	if (me->buffer)
	{
		printf("%s\n", me->buffer);
	}
	else
	{
		printf("<empty>\n");
	}
}


const char* string8_buffer(const string8* me)
{
	return me->buffer;
}

void string8_split_lines(
						 const string8* src,
						 obj_list* dst // list of own string8
						 )
{
	int begin, end; // inclusive
	int i;
	char c;
	string8* current;
	int length;
	
	begin = 0;
	end = -1;
	for (i = 0; i < src->length; i++)
	{
		c = src->buffer[i];
		if (c == 13) continue;
		if (c == 10)
		{
			length = end - begin + 1;
			current = string8_from_buffer(src->buffer + begin, length);
			obj_list_add(dst, current);
			begin = i + 1;
			end = -1;
		}
		else
		{
			end = i;
		}
	}

	// Last line
	if (end != -1)
	{
		length = end - begin + 1;
		current = string8_from_buffer(src->buffer + begin, length);
		obj_list_add(dst, current);
	}
}

void object_destroy(
					void* me // Takes ownership
					)
{
	tobject* obj;
	if (!me) return;
	obj = (tobject*)me;
	ENSURE(obj->type->signature == OBJECT_SIGNATURE);
	obj->type->destroy(me);
}


struct obj_list {
	tobject base;
	int own;
	void** buffer;
	int length;
	int allocated;
};

static type_info_t obj_list_type = {
	OBJECT_SIGNATURE,
	"obj_list",
	(destructor_fun)obj_list_destroy
};

// Returns ownership
obj_list* obj_list_create(int own)
{
	obj_list* me = allocate_memory(sizeof(obj_list));
	ENSURE(me)
	memset(me, 0, sizeof(obj_list));	
	me->base.type = &obj_list_type;
	me->own = own;
	return me;
}

void obj_list_destroy(
					  obj_list* me // Takes ownership
					  )
{
	int i;
	void* item;
	if (!me) return;
	ENSURE(me->base.type == &obj_list_type)
	if (me->own)
	{
		for (i = 0; i < me->length; i++)
		{
			item = me->buffer[i];
			object_destroy(item);
		}
	}
	free_memory(me->buffer, me->allocated * sizeof(void*));
	free_memory(me, sizeof(obj_list));
}

void obj_list_add(obj_list* me, void* item)
{
	int new_alloc;
	ENSURE(me->length <= me->allocated)
	
	if (me->buffer == 0)
	{
		new_alloc = 16;
		me->buffer = allocate_memory(new_alloc * sizeof(void*));
		ENSURE(me->buffer)
		me->allocated = new_alloc;		
	}
	else if (me->length == me->allocated)
	{
		new_alloc = me->allocated * 2;
		me->buffer = reallocate_memory(me->buffer, sizeof(void*), me->allocated, new_alloc);
		me->allocated = new_alloc;
	}
	
	me->buffer[me->length] = item;
	me->length++;
}


void obj_list_remove(obj_list* me, void* item)
{
	int i;
	for (i = 0; i < me->length; i++)
	{
		if (me->buffer[i] == item)
		{
			obj_list_remove_at(me, i);
			return;
		}
	}
}

void obj_list_clear(obj_list* me)
{
	obj_list_resize(me, 0);
}

int obj_list_contains(
					  const obj_list* me,
					  const void* item // null
					  )
{
	int i;
	for (i = 0; i < me->length; i++)
	{
		if (me->buffer[i] == item) return 1;
	}
	return 0;
}

int obj_list_length(const obj_list* me)
{
	return me->length;
}

void* obj_list_get(obj_list* me, int index)
{
	ENSURE(index >= 0 && index < me->length)
	return me->buffer[index];
}

void obj_list_set(
				  obj_list* me, 
				  int index, 
				  void* item // own if the container owns items
				  )
{
	void* old;
	ENSURE(index >= 0 && index < me->length)
	if (me->own)
	{
		old = me->buffer[index];
		if (old != item)
		{
			object_destroy(old);
		}
	}
	me->buffer[index] = item;
}

void obj_list_remove_at(obj_list* me, int index)
{
	int count;
	void* old;
	int i;
	ENSURE(index >= 0 && index < me->length)
	if (me->own)
	{
		old = me->buffer[index];
		object_destroy(old);
	}
	count = me->length - 1;
	for (i = index; i < count; i++)
	{
		me->buffer[i] = me->buffer[i + 1];
	}
	me->buffer[count] = 0;
	me->length--;
}

void obj_list_resize(obj_list* me, int new_size)
{
	int i;
	int wipe_size, wipe_count;
	void** wipe_start;
	ENSURE(new_size >= 0)
	if (new_size == me->length) return;
	if (new_size > me->allocated)
	{
		me->buffer = reallocate_memory(
										 me->buffer, 
										 sizeof(void*), 
										 me->allocated, 
										 new_size
										 );
		me->allocated = new_size;
	}
	else if (new_size < me->length)
	{
		wipe_start = me->buffer + new_size;
		wipe_count = me->length - new_size;
		wipe_size = wipe_count * sizeof(void*);
		if (me->own)
		{
			for (i = 0; i < wipe_count; i++)
			{
				object_destroy(wipe_start[i]);
			}
		}
		memset(wipe_start, 0, wipe_size);
	}
	me->length = new_size;
}

int obj_list_find_first(const obj_list* me, equal_fun equal, const void* needle)
{
	int i;
	const void* current;
	for (i = 0; i < me->length; i++)
	{
		current = me->buffer[i];
		if (equal(current, needle)) return i;
	}
	return -1;
}

int obj_list_foreach(obj_list* me, visitor_fun visitor, void* user)
{
	void** current;
	void** end;
	ENSURE(visitor)
	if (me->length == 0) return 0;
	end = me->buffer + me->length;
	for (current = me->buffer; current != end; current++)
	{
		if (visitor(*current, user)) return 1;
	}
	return 0;
}


void halt(const char* cond, const char* file, int line)
{
	printf("\n===== HALT =====\n");
	printf("condition: %s\n", cond);
	printf("%s: %d\n", file, line);
	abort();
}



void* allocate_memory(size_t amount)
{
	void* block = malloc(amount);
	ENSURE(block)
	memset(block, 0, amount);
	return block;
}

void* reallocate_memory(void* old, size_t object_size, size_t old_count, size_t count)
{
	char* wipe_area;
	void* new_block;
	size_t new_size;
	size_t wipe_size;
	

	ENSURE(object_size > 0)
	ENSURE(old_count >= 0)
	ENSURE(count > 0)
	
	if (old_count == count)
	{
		return old;
	}
	
	if (old_count == 0)
	{
		return allocate_memory(count * object_size);
	}
	
	if (old_count < count)
	{
		new_size = count * object_size;
		new_block = realloc(old, new_size);
		ENSURE(new_block)
		wipe_area = (char*)new_block + object_size * old_count;
		wipe_size = (count - old_count) * object_size;
		memset(wipe_area, 0, wipe_size);
		return new_block;
	}
	
	wipe_area = (char*)old + object_size * count;
	wipe_size = (old_count - count) * object_size;
	memset(wipe_area, 0, wipe_size);	
	
	return old;
}

void free_memory(void* mem, size_t amount)
{
	if (!mem) return;
	memset(mem, 0, amount);
	free(mem);
}

static obj_list* create_array(int count)
{
	obj_list* arr = obj_list_create(1);
	obj_list_resize(arr, count);
	return arr;
}

hashtable* hashtable_create(int own, hash_fun hash, equal_fun eq)
{
	hashtable* table;
	
	ENSURE(hash)
	ENSURE(eq)
	
	table = allocate_memory(sizeof(hashtable));
	table->base.type = &hashtable_t;
	table->buckets = create_array(MIN_TABLE_SIZE);
	table->hash = hash;
	table->equal = eq;
	table->count = 0;
	table->own = own;
	
	return table;
}


static float get_load_factor(const hashtable* tree)
{
	int buckets = obj_list_length(tree->buckets);
	return (float)tree->count / buckets;
}

static int find_index(const obj_list* buckets, unsigned int hash)
{
	int buckets_count = obj_list_length(buckets);
	return (int)(hash % (unsigned int)buckets_count);
}

static void* find_in_bucket(hashtable* obj, obj_list* bucket, const void* key)
{
	int found = obj_list_find_first(bucket, obj->equal, key);
	if (found == -1) return 0;
	return obj_list_get(bucket, found);
}

static void* remove_from_bucket(hashtable* obj, obj_list* bucket, const void* key)
{
	void* old;
	int found = obj_list_find_first(bucket, obj->equal, key);
	if (found == -1) return 0;
	old = obj_list_get(bucket, found);
	obj_list_remove_at(bucket, found);
	return old;
}

static int add_to_buckets(hashtable* obj, obj_list* buckets, void* item, 
						  unsigned int hash)
{
	int index;
	obj_list* bucket;
	ENSURE(obj)
	ENSURE(buckets)
	ENSURE(item)
	
	index = find_index(buckets, hash);
	bucket = obj_list_get(buckets, index);
	if (!bucket)
	{
		bucket = obj_list_create(0);
		obj_list_set(buckets, index, bucket);
	}
	else if (find_in_bucket(obj, bucket, item))
	{
		return 0;
	}
	
	obj_list_add(bucket, item);
	return 1;
}

static obj_list* find_bucket_for_key(hashtable* obj, const void* key)
{
	unsigned int hash = obj->hash(key);
	int index = find_index(obj->buckets, hash);
	return obj_list_get(obj->buckets, index);	
}

static void move_items_from_bucket(hashtable* obj, obj_list* old_bucket, obj_list* new_buckets)
{
	void* item;
	int i;
	unsigned int hash;
	int count = obj_list_length(old_bucket);
	
	for (i = 0; i < count; i++)
	{
		item = obj_list_get(old_bucket, i);
		hash = obj->hash(item);
		add_to_buckets(obj, new_buckets, item, hash);
	}
}

static void rehash(hashtable* obj, int new_size)
{
	obj_list* new_buckets;
	obj_list* current;
	int i;
	int count;
	
	ENSURE(obj)
	ENSURE(new_size > 0)
	
	new_buckets = create_array(new_size);
	count = obj_list_length(obj->buckets);
	for (i = 0; i < count; i++)
	{
		current = obj_list_get(obj->buckets, i);
		if (!current) continue;
		move_items_from_bucket(obj, current, new_buckets);
	}
	obj_list_destroy(obj->buckets);
	obj->buckets = new_buckets;
}

static void rehash_up(hashtable* obj)
{
	int new_count = obj_list_length(obj->buckets) * 2;
	rehash(obj, new_count);
}

static int destroyer(void* item, void* ignored)
{
	object_destroy(item);
	return 0;
}

void hashtable_destroy(hashtable* obj)
{	
	if (!obj) return;
	ENSURE(obj->base.type == &hashtable_t)	
	
	if (obj->own)
	{
		hashtable_foreach(obj, destroyer, 0);
	}
	
	obj_list_destroy(obj->buckets);
	free_memory(obj, sizeof(hashtable));
}

int hashtable_count(const hashtable* obj)
{
	ENSURE(obj)
	return obj->count;
}

void* hashtable_get(hashtable* obj, const void* key)
{
	obj_list* bucket;
	
	ENSURE(obj)
	ENSURE(key)
	
	bucket = find_bucket_for_key(obj, key);
	if (!bucket) return 0;
	
	return find_in_bucket(obj, bucket, key);
}

int hashtable_put(hashtable* obj, void* item)
{
	float load_factor;
	unsigned int hash;
	
	ENSURE(obj)
	ENSURE(item)
	
	hash = obj->hash(item);
	if (!add_to_buckets(obj, obj->buckets, item, hash)) return 0;
	
	obj->count++;
	load_factor = get_load_factor(obj);
	if (load_factor > MAX_LOAD_FACTOR)
	{
		rehash_up(obj);
	}
	
	return 1;
}

int hashtable_remove(hashtable* obj, const void* key)
{
	void* old;
	obj_list* bucket;
	
	ENSURE(obj)
	ENSURE(key)
	
	bucket = find_bucket_for_key(obj, key);
	if (!bucket) return 0;
	old = remove_from_bucket(obj, bucket, key);
	if (!old) return 0;
	if (obj->own)
	{
		object_destroy(old);
	}
	obj->count--;
	return 1;
}

typedef struct hashtable_for_each_state {
	visitor_fun visitor;
	void* data;
} hashtable_for_each_state;

static int
foreach_in_bucket(
				   void* item,
				   void* for_each_data)
{
	obj_list* bucket = item;
	hashtable_for_each_state* state = for_each_data;
	
	if (!bucket) return 0;
	
	return obj_list_foreach(bucket, state->visitor, state->data);
}

int
hashtable_foreach(
				   hashtable* obj,
				   visitor_fun visitor,
				   void* user_data)
{
	hashtable_for_each_state state = { visitor, user_data };
	return obj_list_foreach(obj->buckets, foreach_in_bucket, &state);
}



int_list* // own
int_list_create()
{
	int_list* me = allocate_memory(sizeof(int_list));
	me->base.type = &int_list_t;
	
	return me;
}

void int_list_destroy(
					  int_list* me // own. can be null
					  )
{
	if (!me) return;
	ENSURE(me->base.type == &int_list_t)
	free_memory(me->buffer, me->allocated);
	free_memory(me, sizeof(int_list));
}

void int_list_add(int_list* me, int element)
{
	int new_allocated;
	if (me->allocated == me->length)
	{
		if (me->allocated == 0)
		{
			new_allocated = 16;
		}
		else
		{
			new_allocated = me->allocated * 2;
		}
		me->buffer = reallocate_memory(
										 me->buffer,
										 sizeof(int),
										 me->allocated,
										 new_allocated);
		me->allocated = new_allocated;
	}
	me->buffer[me->length] = element;
	me->length++;
}

int int_list_get(const int_list* me, int index)
{
	ENSURE(index >= 0 && index < me->length)
	return me->buffer[index];
}

void int_list_set(int_list* me, int index, int element)
{
	ENSURE(index >= 0 && index < me->length)
	me->buffer[index] = element;
}

int int_list_length(const int_list* me)
{
	return me->length;
}


void int_list_resize(int_list* me, int new_size)
{
	ENSURE(new_size >= 0)
	if (new_size == me->length) return;
	if (new_size > me->allocated)
	{
		me->buffer = reallocate_memory(
										 me->buffer,
										 sizeof(int),
										 me->allocated,
										 new_size);
		me->allocated = new_size;
	}
	me->length = new_size;
}

void int_list_remove_at(int_list* me, int index)
{
	int i, last, current;
	ENSURE(index >= 0 && index < me->length)
	
	last = me->length - 1;
	for (i = index; i < last; i++)
	{
		current = me->buffer[i + 1];
		me->buffer[i] = current;
	}
	me->length--;
}

void array_table_init(array_table* me, const char* name)
{
	int allocate = 20;
	me->name = name;
	me->items = allocate_memory(sizeof(void*) * allocate);
	me->count = 0;
	me->allocated = allocate;
	me->next = 1;
	me->free_slots = int_list_create();
}

void array_table_cleanup(array_table* me)
{
	free_memory(me->items, sizeof(void*) * me->allocated);
	int_list_destroy(me->free_slots);
}

int array_table_insert(array_table* me, void* item)
{
	int index;
	int last, new_allocate;
	int free_count;
	
	ENSURE(item)
	
	free_count= int_list_length(me->free_slots);
	
	if (free_count > 0)
	{
		last = free_count - 1;
		index = int_list_get(me->free_slots, last);
		int_list_remove_at(me->free_slots, last);
	}
	else if (me->next < me->allocated)
	{
		index = me->next;
		me->next++;
	}
	else
	{
		new_allocate = me->allocated * 2;
		me->items = reallocate_memory(
										me->items,
										sizeof(void*),
										me->allocated,
										new_allocate);
		me->allocated = new_allocate;
		index = me->next;
		me->next++;		
	}
	
	me->items[index] = item;
	me->count++;
	return index;
}

void array_table_delete(array_table* me, int key)
{
	void* item;
	ENSURE(key >= 0 && key < me->next)
	item = me->items[key];
	if (item)
	{
		me->items[key] = 0;
		int_list_add(me->free_slots, key);
		me->count--;		
	}
}


/**
 * Get 32-bit Murmur3 hash.
 *
 * @param data      source data
 * @param nbytes    size of data
 *
 * @return 32-bit unsigned hash value.
 *
 * @code
 *  unsigned int hashval = qhashmurmur3_32((void*)"hello", 5);
 * @endcode
 *
 * @code
 *  MurmurHash3 was created by Austin Appleby  in 2008. The cannonical
 *  implementations are in C++ and placed in the public.
 *
 *    https://sites.google.com/site/murmurhash/
 *
 *  Seungyoung Kim has ported it's cannonical implementation to C language
 *  in 2012 and published it as a part of qLibc component.
 * @endcode
 */
unsigned int qhashmurmur3_32(const void *data, int nbytes)
{
    unsigned int c1;
    unsigned int c2;
	
    int nblocks;
    const unsigned int *blocks;
    const unsigned char *tail;
	
    unsigned int h;
	
    int i;
    unsigned int k;
	
	const char* cdata;
	
    if (data == NULL || nbytes == 0) return 0;
	
    c1 = 0xcc9e2d51;
    c2 = 0x1b873593;
	
	cdata = (const char*)data;
	
    nblocks = nbytes / 4;
    blocks = (const unsigned int *)(cdata);
    tail = (const unsigned char *)(cdata + (nblocks * 4));
	
    h = 0;
	
    for (i = 0; i < nblocks; i++) {
        k = blocks[i];
		
        k *= c1;
        k = (k << 15) | (k >> (32 - 15));
        k *= c2;
		
        h ^= k;
        h = (h << 13) | (h >> (32 - 13));
        h = (h * 5) + 0xe6546b64;
    }
	
    k = 0;
    switch (nbytes & 3) {
        case 3:
            k ^= tail[2] << 16;
        case 2:
            k ^= tail[1] << 8;
        case 1:
            k ^= tail[0];
            k *= c1;
            k = (k << 13) | (k >> (32 - 15));
            k *= c2;
            h ^= k;
    };
	
    h ^= nbytes;
	
    h ^= h >> 16;
    h *= 0x85ebca6b;
    h ^= h >> 13;
    h *= 0xc2b2ae35;
    h ^= h >> 16;
	
	return h;
}


// Returns ownership
string16* string16_create(void)
{
	string16* me = allocate_memory(sizeof(string16));
	me->base.type = &string16_t;
	return me;
}

static string16* // Returns ownership
string16_create_with_size(int length)
{
	int allocated;
	string16* me;
	me = string16_create();
	
	if (length > 0)
	{
		allocated = length + 1;
		me->buffer = allocate_memory(allocated * sizeof(char16));
		me->allocated = allocated;
		me->length = length;	
	}
	
	return me;
}

// Returns ownership
string16* string16_from_buffer(const char16* buffer, int length)
{
	int i;
	string16* me = 0; // Own
	ENSURE(length >= 0)
	me = string16_create_with_size(length);
	if (length > 0 && buffer != 0)
	{
		for (i = 0; i < length; i++)
		{
			me->buffer[i] = buffer[i];
		}
		me->buffer[length] = 0;
	}
	return me;
}

int 
string16_equal(const string16* left, const string16* right)
{
	if (left == right) return 1;
	if (!left)
	{
		return right->length == 0;
	}
	if (!right)
	{
		return left->length == 0;
	}
	if (left->length != right->length) return 0;
	if (left->length == 0) return 1;
	if (memcmp(left->buffer, right->buffer, left->length * sizeof(char16)) == 0)
	{
		return 1;
	}
	return 0;
}

unsigned int
string16_hash(const string16* me)
{
	if (!me) return 0;
	if (me->length == 0) return 0;
	
	return qhashmurmur3_32(
						   me->buffer,
						   me->length * sizeof(char16)
						   );
}


// Returns ownership
string16* string16_from_cstr(const char* str, int limit)
{
	string16* me;
	int length;
	int i;
	ENSURE(limit >= 0)
	ENSURE(limit <= MAX_CSTR)
	
	length = cstring_length(str, limit);
	me = string16_create_with_size(length);
	if (length > 0)
	{
		for (i = 0; i < length; i++)
		{
			me->buffer[i] = (char16)str[i];
		}
		me->buffer[length] = 0;
	}
	
	return me;
}

void string16_destroy(
					  string16* me // Takes ownership
					  )
{
	if (!me) return;
	ENSURE(me->base.type == &string16_t)
	free_memory(me->buffer, me->allocated * sizeof(char16));
	free_memory(me, sizeof(string16));
}

// Returns ownership
string16* string16_clone(
						 const string16* obj
						 )
{
	if (obj && obj->length > 0)
	{
		return string16_from_buffer(obj->buffer, obj->length);
	}
	else
	{
		return string16_create();
	}
}


void string16_add(string16* me, char16 element)
{
	int new_alloc;
	int old_length = me->length;
	ENSURE(me->length >= 0)
	ENSURE(me->length == 0 || me->length < me->allocated)
	
	if (me->buffer == 0)
	{
		new_alloc = 16;
		me->buffer = allocate_memory(new_alloc * sizeof(char16));
		ENSURE(me->buffer)
		me->allocated = new_alloc;		
	}
	else if (me->length + 1 == me->allocated)
	{
		new_alloc = me->allocated * 2;
		me->buffer = reallocate_memory(me->buffer, sizeof(char16), me->allocated, new_alloc);
		me->allocated = new_alloc;		
	}
	
	me->length++;
	me->buffer[old_length] = element;
	me->buffer[me->length] = 0;
}

void string16_clear(string16* me)
{
	if (me->buffer)
	{
		me->buffer[0] = 0;
		me->length = 0;
	}
}

char16 string16_get(const string16* me, int index)
{
	ENSURE(index >= 0 && index < me->length)
	return me->buffer[index];
}

void string16_set(string16* me, int index, char16 element)
{
	ENSURE(index >= 0 && index < me->length)
	me->buffer[index] = element;
}

int string16_length(const string16* me)
{
	return me->length;
}


const char16* string16_buffer(const string16* me)
{
	return me->buffer;
}

void string16_split_lines(
						  const string16* src,
						  obj_list* dst // list of own string16
						  )
{
	int begin, end; // inclusive
	int i;
	char16 c;
	string16* current;
	int length;
	
	begin = 0;
	end = -1;
	for (i = 0; i < src->length; i++)
	{
		c = src->buffer[i];
		if (c == 13) continue;
		if (c == 10)
		{
			length = end - begin + 1;
			current = string16_from_buffer(src->buffer + begin, length);
			obj_list_add(dst, current);
			begin = i + 1;
			end = -1;
		}
		else
		{
			end = i;
		}
	}
	
	// Last line
	if (end != -1)
	{
		length = end - begin + 1;
		current = string16_from_buffer(src->buffer + begin, length);
		obj_list_add(dst, current);
	}
}

int // -1 less, 0 equal, 1 greater
string16_compare(
				 const string16* left, // null
				 const string16* right // null
				 )
{
	int length;
	int i;
	char16 lc, rc;
	if (left == right) return 0;
	if (left == 0) return -1;
	if (right == 0) return 1;
	if (left->length < right->length)
	{
		length = left->length;
	}
	else
	{
		length = right->length;
	}
	for (i = 0; i < length; i++)
	{
		lc = left->buffer[i];
		rc = right->buffer[i];
		if (lc < rc) return -1;
		if (lc > rc) return 1;
	}
	
	if (left->length < right->length)
	{
		return -1;
	}
	
	if (left->length > right->length)
	{
		return 1;
	}
	
	return 0;
}
