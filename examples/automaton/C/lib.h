#ifndef LIB_H20140209
#define LIB_H20140209

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
void* reallocate_memory(void* old, size_t new_amount);
void free_memory(void* mem);

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

// Returns ownership
obj_list* obj_list_create(int own);
void obj_list_destroy(
	obj_list* self // Takes ownership
);

void obj_list_add(obj_list* self, void* item);
int obj_list_length(const obj_list* self);
void* obj_list_get(obj_list* self, int index);

#endif