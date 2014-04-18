#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

#include "lib.h"

struct string8 {
	tobject base;
	char* buffer;
	int allocated;
	int length;
};

static type_info_t string8_type = { 
	OBJECT_SIGNATURE,
	"string8",
	(destructor_fun)string8_destroy
};

// Returns ownership
string8* string8_create(void)
{
	string8* self = allocate_memory(sizeof(string8));
	ENSURE(self)
	memset(self, 0, sizeof(string8));	
	self->base.type = &string8_type;
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
	if (!self) return 0;
	if (length > 0 && buffer != 0)
	{
		allocated = length + 1;
		self->buffer = allocate_memory(allocated);
		ENSURE(self->buffer)
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
	ENSURE(self->base.type == &string8_type)
	free_memory(self->buffer);
	memset(self, 0, sizeof(string8));
	free_memory(self);
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
		self->buffer = reallocate_memory(self->buffer, new_alloc);
		ENSURE(self->buffer)
		self->allocated = new_alloc;		
	}

	self->length++;
	self->buffer[old_length] = element;
	self->buffer[self->length] = 0;
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
	free_memory(self->buffer);
	memset(self, 0, sizeof(obj_list));
	free_memory(self);
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
		self->buffer = reallocate_memory(self->buffer, new_alloc * sizeof(void*));
		ENSURE(self->buffer)
		self->allocated = new_alloc;
	}
	
	self->buffer[self->length] = item;
	self->length++;
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


void halt(const char* cond, const char* file, int line)
{
	printf("\n===== HALT =====\n");
	printf("condition: %s\n", cond);
	printf("%s: %d\n", file, line);
	abort();
}



void* allocate_memory(size_t amount)
{
	return malloc(amount);
}

void* reallocate_memory(void* old, size_t new_amount)
{
	return realloc(old, new_amount);
}

void free_memory(void* mem)
{
	free(mem);
}
