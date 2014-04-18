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
	string8* self = allocate_memory(sizeof(string8));
	self->base.type = &string8_t;
	return self;
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
	string8* self = 0; // Own
	ENSURE(length >= 0)
	self = string8_create();
	if (length > 0 && buffer != 0)
	{
		allocated = length + 1;
		self->buffer = allocate_memory(allocated);
		self->allocated = allocated;
		self->length = length;
		for (i = 0; i < length; i++)
		{
			self->buffer[i] = buffer[i];
		}
		self->buffer[length] = 0;
	}
	return self;
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
string8_hash(const string8* self)
{
	if (!self) return 0;
	if (self->length == 0) return 0;
	
	return qhashmurmur3_32(
						   self->buffer,
						   self->length
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
					 string8* self // Takes ownership
					 )
{
	if (!self) return;
	ENSURE(self->base.type == &string8_t)
	free_memory(self->buffer, self->allocated);
	free_memory(self, sizeof(string8));
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


void string8_add(string8* self, char element)
{
	int new_alloc;
	int old_length = self->length;
	ENSURE(self->length >= 0)
	ENSURE(self->length == 0 || self->length < self->allocated)
	
	if (self->buffer == 0)
	{
		new_alloc = 16;
		self->buffer = allocate_memory(new_alloc);
		ENSURE(self->buffer)
		self->allocated = new_alloc;		
	}
	else if (self->length + 1 == self->allocated)
	{
		new_alloc = self->allocated * 2;
		self->buffer = reallocate_memory(self->buffer, 1, self->allocated, new_alloc);
		self->allocated = new_alloc;		
	}

	self->length++;
	self->buffer[old_length] = element;
}

void string8_clear(string8* self)
{
	if (self->buffer)
	{
		self->buffer[0] = 0;
		self->length = 0;
	}
}

char string8_get(const string8* self, int index)
{
	ENSURE(index >= 0 && index < self->length)
	return self->buffer[index];
}

void string8_set(string8* self, int index, char element)
{
	ENSURE(index >= 0 && index < self->length)
	self->buffer[index] = element;
}

int string8_length(const string8* self)
{
	return self->length;
}

void string8_print(
				   const string8* self
				   )
{
	if (self->buffer)
	{
		printf("%s\n", self->buffer);
	}
	else
	{
		printf("<empty>\n");
	}
}


const char* string8_buffer(const string8* self)
{
	return self->buffer;
}


void object_destroy(
					void* self // Takes ownership
					)
{
	tobject* obj;
	if (!self) return;
	obj = (tobject*)self;
	ENSURE(obj->type->signature == OBJECT_SIGNATURE);
	obj->type->destroy(self);
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
	obj_list* self = allocate_memory(sizeof(obj_list));
	ENSURE(self)
	memset(self, 0, sizeof(obj_list));	
	self->base.type = &obj_list_type;
	self->own = own;
	return self;
}

void obj_list_destroy(
					  obj_list* self // Takes ownership
					  )
{
	int i;
	void* item;
	if (!self) return;
	ENSURE(self->base.type == &obj_list_type)
	if (self->own)
	{
		for (i = 0; i < self->length; i++)
		{
			item = self->buffer[i];
			object_destroy(item);
		}
	}
	free_memory(self->buffer, self->allocated * sizeof(void*));
	free_memory(self, sizeof(obj_list));
}

void obj_list_add(obj_list* self, void* item)
{
	int new_alloc;
	ENSURE(self->length <= self->allocated)
	
	if (self->buffer == 0)
	{
		new_alloc = 16;
		self->buffer = allocate_memory(new_alloc * sizeof(void*));
		ENSURE(self->buffer)
		self->allocated = new_alloc;		
	}
	else if (self->length == self->allocated)
	{
		new_alloc = self->allocated * 2;
		self->buffer = reallocate_memory(self->buffer, sizeof(void*), self->allocated, new_alloc);
		self->allocated = new_alloc;
	}
	
	self->buffer[self->length] = item;
	self->length++;
}


void obj_list_remove(obj_list* self, void* item)
{
	int i;
	for (i = 0; i < self->length; i++)
	{
		if (self->buffer[i] == item)
		{
			obj_list_remove_at(self, i);
			return;
		}
	}
}

void obj_list_clear(obj_list* self)
{
	obj_list_resize(self, 0);
}

int obj_list_contains(
					  const obj_list* self,
					  const void* item // null
					  )
{
	int i;
	for (i = 0; i < self->length; i++)
	{
		if (self->buffer[i] == item) return 1;
	}
	return 0;
}

int obj_list_length(const obj_list* self)
{
	return self->length;
}

void* obj_list_get(obj_list* self, int index)
{
	ENSURE(index >= 0 && index < self->length)
	return self->buffer[index];
}

void obj_list_set(
				  obj_list* self, 
				  int index, 
				  void* item // own if the container owns items
				  )
{
	void* old;
	ENSURE(index >= 0 && index < self->length)
	if (self->own)
	{
		old = self->buffer[index];
		if (old != item)
		{
			object_destroy(old);
		}
	}
	self->buffer[index] = item;
}

void obj_list_remove_at(obj_list* self, int index)
{
	int count;
	void* old;
	int i;
	ENSURE(index >= 0 && index < self->length)
	if (self->own)
	{
		old = self->buffer[index];
		object_destroy(old);
	}
	count = self->length - 1;
	for (i = index; i < count; i++)
	{
		self->buffer[i] = self->buffer[i + 1];
	}
	self->buffer[count] = 0;
	self->length--;
}

void obj_list_resize(obj_list* self, int new_size)
{
	int i;
	int wipe_size, wipe_count;
	void** wipe_start;
	ENSURE(new_size >= 0)
	if (new_size == self->length) return;
	if (new_size > self->allocated)
	{
		self->buffer = reallocate_memory(
										 self->buffer, 
										 sizeof(void*), 
										 self->allocated, 
										 new_size
										 );
		self->allocated = new_size;
	}
	else if (new_size < self->length)
	{
		wipe_start = self->buffer + new_size;
		wipe_count = self->length - new_size;
		wipe_size = wipe_count * sizeof(void*);
		if (self->own)
		{
			for (i = 0; i < wipe_count; i++)
			{
				object_destroy(wipe_start[i]);
			}
		}
		memset(wipe_start, 0, wipe_size);
	}
	self->length = new_size;
}

int obj_list_find_first(const obj_list* self, equal_fun equal, const void* needle)
{
	int i;
	const void* current;
	for (i = 0; i < self->length; i++)
	{
		current = self->buffer[i];
		if (equal(current, needle)) return i;
	}
	return -1;
}

int obj_list_foreach(obj_list* self, visitor_fun visitor, void* user)
{
	void** current;
	void** end;
	ENSURE(visitor)
	if (self->length == 0) return 0;
	end = self->buffer + self->length;
	for (current = self->buffer; current != end; current++)
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
	int_list* self = allocate_memory(sizeof(int_list));
	self->base.type = &int_list_t;
	
	return self;
}

void int_list_destroy(
					  int_list* self // own. can be null
					  )
{
	if (!self) return;
	ENSURE(self->base.type == &int_list_t)
	free_memory(self->buffer, self->allocated);
	free_memory(self, sizeof(int_list));
}

void int_list_add(int_list* self, int element)
{
	int new_allocated;
	if (self->allocated == self->length)
	{
		if (self->allocated == 0)
		{
			new_allocated = 16;
		}
		else
		{
			new_allocated = self->allocated * 2;
		}
		self->buffer = reallocate_memory(
										 self->buffer,
										 sizeof(int),
										 self->allocated,
										 new_allocated);
		self->allocated = new_allocated;
	}
	self->buffer[self->length] = element;
	self->length++;
}

int int_list_get(const int_list* self, int index)
{
	ENSURE(index >= 0 && index < self->length)
	return self->buffer[index];
}

void int_list_set(int_list* self, int index, int element)
{
	ENSURE(index >= 0 && index < self->length)
	self->buffer[index] = element;
}

int int_list_length(const int_list* self)
{
	return self->length;
}


void int_list_resize(int_list* self, int new_size)
{
	ENSURE(new_size >= 0)
	if (new_size == self->length) return;
	if (new_size > self->allocated)
	{
		self->buffer = reallocate_memory(
										 self->buffer,
										 sizeof(int),
										 self->allocated,
										 new_size);
		self->allocated = new_size;
	}
	self->length = new_size;
}

void int_list_remove_at(int_list* self, int index)
{
	int i, last, current;
	ENSURE(index >= 0 && index < self->length)
	
	last = self->length - 1;
	for (i = index; i < last; i++)
	{
		current = self->buffer[i + 1];
		self->buffer[i] = current;
	}
	self->length--;
}

void array_table_init(array_table* self, const char* name)
{
	int allocate = 20;
	self->name = name;
	self->items = allocate_memory(sizeof(void*) * allocate);
	self->count = 0;
	self->allocated = allocate;
	self->next = 1;
	self->free_slots = int_list_create();
}

void array_table_cleanup(array_table* self)
{
	free_memory(self->items, sizeof(void*) * self->allocated);
	int_list_destroy(self->free_slots);
}

int array_table_insert(array_table* self, void* item)
{
	int index;
	int last, new_allocate;
	int free_count;
	
	ENSURE(item)
	
	free_count= int_list_length(self->free_slots);
	
	if (free_count > 0)
	{
		last = free_count - 1;
		index = int_list_get(self->free_slots, last);
		int_list_remove_at(self->free_slots, last);
	}
	else if (self->next < self->allocated)
	{
		index = self->next;
		self->next++;
	}
	else
	{
		new_allocate = self->allocated * 2;
		self->items = reallocate_memory(
										self->items,
										sizeof(void*),
										self->allocated,
										new_allocate);
		self->allocated = new_allocate;
		index = self->next;
		self->next++;		
	}
	
	self->items[index] = item;
	self->count++;
	return index;
}

void array_table_delete(array_table* self, int key)
{
	void* item;
	ENSURE(key >= 0 && key < self->next)
	item = self->items[key];
	if (item)
	{
		self->items[key] = 0;
		int_list_add(self->free_slots, key);
		self->count--;		
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

