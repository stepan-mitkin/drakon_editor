#ifndef LIB_H20140209
#define LIB_H20140209
#include <stdlib.h>

//// Object system ////
#define OBJECT_SIGNATURE 0xA0A0A0

typedef void (*destructor_fun)(void* self);

typedef struct type_info_t {
	int signature;
	const char* name;
	destructor_fun destroy;
} type_info_t;


typedef struct tobject {
	type_info_t* type;
} tobject;

void object_destroy(
	void* self // Takes ownership
);

//// Memory ////
void* allocate_memory(size_t amount);
void* reallocate_memory(void* old, size_t object_size, size_t old_count, size_t count);
void free_memory(void* mem, size_t amount);

/// Misc utils ////
void halt(const char* cond, const char* file, int line);
#define ENSURE(cond) if (!(cond)) { halt(#cond, __FILE__, __LINE__); }

int cstring_length(const char* str, int limit);

//// string8 ////
typedef struct string8 string8;

// Returns ownership
string8* string8_create(void);


// Returns ownership
string8* string8_from_buffer(const char* str, int length);

int 
string8_equal(
			  const string8* lelf, // null
			  const string8* right // null
			  );

unsigned int
string8_hash(
			  const string8* self // null
			  );

#define MAX_CSTR 10000
// Returns ownership
string8* string8_from_cstr(const char* str, int limit);

void string8_destroy(
	string8* self // Takes ownership
);

// Returns ownership
string8* string8_clone(
	const string8* self
);

void string8_print(
	const string8* self
);



void string8_add(string8* self, char element);
void string8_clear(string8* self);
char string8_get(const string8* self, int index);
void string8_set(string8* self, int index, char element);
int string8_length(const string8* self);
const char* string8_buffer(const string8* self);

//// obj_list ////

typedef struct obj_list obj_list;

typedef int (*equal_fun)(const void* current, const void* criterion);
typedef unsigned int (*hash_fun)(const void* item);
typedef int (*visitor_fun)(void* item, void* user);

// Returns ownership
obj_list* obj_list_create(int own);
void obj_list_destroy(
	obj_list* self // Takes ownership
);

void obj_list_add(obj_list* self, void* item);
void obj_list_remove(obj_list* self, void* item);
int obj_list_length(const obj_list* self);
void* obj_list_get(obj_list* self, int index);
void obj_list_set(
				  obj_list* self, 
				  int index, 
				  void* item // own if the container owns items
				  );
void obj_list_clear(obj_list* self);
void obj_list_remove_at(obj_list* self, int index);
void obj_list_resize(obj_list* self, int new_size);
int obj_list_find_first(const obj_list* self, equal_fun equal, const void* needle);
int obj_list_foreach(obj_list* self, visitor_fun visitor, void* user);
int obj_list_contains(
					  const obj_list* self,
					  const void* item // null
					  );

//// hashtable ////

typedef struct hashtable hashtable;

hashtable* // ownership
hashtable_create(int own, hash_fun hash, equal_fun eq);
void hashtable_destroy(
					   hashtable* obj // takes ownership. can be null
					   );
int hashtable_count(const hashtable* obj);
void* hashtable_get(hashtable* obj, const void* key);
int hashtable_put(hashtable* obj, void* item);
int hashtable_remove(hashtable* obj, const void* key);
int // returns 1 if the visitor has requested to stop iteration
hashtable_foreach(
				  hashtable* obj,
				  visitor_fun visitor,
				  void* user_data);

//// int_list ///

typedef struct int_list int_list;

int_list* // own
int_list_create(void);

void int_list_destroy(
					  int_list* self // own. can be null
					  );

void int_list_add(int_list* self, int element);
int int_list_get(const int_list* self, int index);
void int_list_set(int_list* self, int index, int element);
int int_list_length(const int_list* self);
void int_list_resize(int_list* self, int new_size);
void int_list_remove_at(int_list* self, int index);

typedef struct array_table array_table;

typedef struct row_base {
	int id;
	array_table* table;
} row_base;


typedef int (*ensure_cd_fun)(
							 void* base,
							 void* record,
							 obj_list* deletion_list
							 );

typedef void (*dd_fun)(
							 void* base,
							 void* record,
							 obj_list* deletion_list,
							 int unlink
							 );


/// array_table
struct array_table {
	const char* name;
	void** items; // own
	int count; // number of items in the container
	int allocated;
	int next; // next free slot in 'items'
	int_list* free_slots; // own
	ensure_cd_fun ensure_can_delete;
	dd_fun do_delete;
};

void array_table_init(array_table* self, const char* name);
void array_table_cleanup(array_table* self);
int array_table_insert(array_table* self, void* item);
void array_table_delete(array_table* self, int key);

unsigned int qhashmurmur3_32(const void *data, int nbytes);

#endif