#ifndef LIB_H20140209
#define LIB_H20140209
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif
	
//// Object system ////
#define OBJECT_SIGNATURE 0xA0A0A0

typedef struct obj_list obj_list;
typedef struct string8 string8;
typedef struct string16 string16;
	
typedef unsigned short char16;

typedef void (*destructor_fun)(void* me);

typedef struct type_info_t {
	int signature;
	const char* name;
	destructor_fun destroy;
} type_info_t;


typedef struct tobject {
	type_info_t* type;
} tobject;

void object_destroy(
	void* me // Takes ownership
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
			  const string8* me // null
			  );

#define MAX_CSTR 10000
// Returns ownership
string8* string8_from_cstr(const char* str, int limit);

void string8_destroy(
	string8* me // Takes ownership
);

// Returns ownership
string8* string8_clone(
	const string8* me
);

void string8_print(
	const string8* me
);



void string8_add(string8* me, char element);
void string8_clear(string8* me);
char string8_get(const string8* me, int index);
void string8_set(string8* me, int index, char element);
int string8_length(const string8* me);
const char* string8_buffer(const string8* me);
void string8_split_lines(
						 const string8* src,
						 obj_list* dst // list of own string8
						 );

//// string16 ////


// Returns ownership
string16* string16_create(void);


// Returns ownership
string16* string16_from_buffer(const char16* str, int length);

int 
string16_equal(
			   const string16* lelf, // null
			   const string16* right // null
			   );

int // -1 less, 0 equal, 1 greater
string16_compare(
			   const string16* lelf, // null
			   const string16* right // null
			   );

unsigned int
string16_hash(
			  const string16* me // null
			  );


// Returns ownership
string16* string16_from_cstr(const char* str, int limit);

void string16_destroy(
					  string16* me // Takes ownership
					  );

// Returns ownership
string16* string16_clone(
						 const string16* me
						 );

void string16_print(
					const string16* me
					);



void string16_add(string16* me, char16 element);
void string16_clear(string16* me);
char16 string16_get(const string16* me, int index);
void string16_set(string16* me, int index, char16 element);
int string16_length(const string16* me);
const char16* string16_buffer(const string16* me);
void string16_split_lines(
						  const string16* src,
						  obj_list* dst // list of own string16
						  );	


//// obj_list ////



typedef int (*equal_fun)(const void* current, const void* criterion);
typedef unsigned int (*hash_fun)(const void* item);
typedef int (*visitor_fun)(void* item, void* user);

// Returns ownership
obj_list* obj_list_create(int own);
void obj_list_destroy(
	obj_list* me // Takes ownership
);

void obj_list_add(obj_list* me, void* item);
void obj_list_remove(obj_list* me, void* item);
int obj_list_length(const obj_list* me);
void* obj_list_get(obj_list* me, int index);
void obj_list_set(
				  obj_list* me, 
				  int index, 
				  void* item // own if the container owns items
				  );
void obj_list_clear(obj_list* me);
void obj_list_remove_at(obj_list* me, int index);
void obj_list_resize(obj_list* me, int new_size);
int obj_list_find_first(const obj_list* me, equal_fun equal, const void* needle);
int obj_list_foreach(obj_list* me, visitor_fun visitor, void* user);
int obj_list_contains(
					  const obj_list* me,
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
					  int_list* me // own. can be null
					  );

void int_list_add(int_list* me, int element);
int int_list_get(const int_list* me, int index);
void int_list_set(int_list* me, int index, int element);
int int_list_length(const int_list* me);
void int_list_resize(int_list* me, int new_size);
void int_list_remove_at(int_list* me, int index);

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

void array_table_init(array_table* me, const char* name);
void array_table_cleanup(array_table* me);
int array_table_insert(array_table* me, void* item);
void array_table_delete(array_table* me, int key);

unsigned int qhashmurmur3_32(const void *data, int nbytes);

#ifdef __cplusplus
}
#endif
		
	
#endif