
IF own value

// Compares an item to a key value.
typedef int
(*NAME_Comparer)(
	ITEM item,			// Current item. Can be null (for pointers).
	const void* userKey
);

// Performs an operation on an item.
typedef int
(*NAME_Visitor)(
	ITEM item, 			// Current item. Can be null (for pointers).
	void* userData		// A pointer to the user-defined data. Can be null.
);

END

IF inline

// Compares an item to a key value.
typedef int
(*NAME_Comparer)(
	ITEM* item,			// Current item.
	const void* userKey
);

// Performs an operation on an item.
typedef int
(*NAME_Visitor)(
	ITEM* item, 			// Current item.
	void* userData		// A pointer to the user-defined data. Can be null.
);


END

/////////////////////////////
// NAME
/////////////////////////////
// Creates an instance of NAME.
NAME* // Returns ownership.
NAME_Create(void);

// Casts an Object to NAME
// aborts() if the Object is null or not an instance of NAME
NAME*
NAME_FromObject(
	void* obj
	);


IF own

// Removes an object from its slot
// and clears the slot.
ITEM // Returns ownership. Can be null.
NAME_Take(
	NAME* me,
	int index // index >= 0 and index < size
	);

// Puts an object into an existing array slot.
// The old object in the slot gets destroyed.
void
NAME_Put(
	NAME* me,
	int index, // index >= 0 and index < size
	ITEM item  // Takes ownership. Can be null.
);

// Gets an item at an index.
ITEM 
NAME_Get(
	NAME* me,
	int index // index >= 0 and index < size
);

END

IF value own

// Returns a pointer to the underlying buffer.
// This pointer gets invalidated after destruction and resize of the array.
ITEM* // Returns null if size == 0.
NAME_Buffer(
	NAME* me 
);

END

IF value

// Removes an item from the list at an index.
void
NAME_Remove(
	NAME* me,
	int index // index >= 0 and index < size
);


// Gets an item at an index.
ITEM
NAME_Get(
	const NAME* me,
	int index // index >= 0 and index < size
);



// Puts an object into an existing array slot.
void
NAME_Put(
	NAME* me,
	int index, // index >= 0 and index < size
	ITEM item  // Can be null (for pointers).
);

END

IF inline

// Returns a pointer to the memory location for an array item.
// This pointer gets invalidated after destruction and resize of the array.
ITEM*
NAME_Get(
	NAME* me,
	int index // index >= 0 and index < size
);

END

// Destroys the list.
// Invalidates previously returned pointers.
void
NAME_Destroy(
	NAME* me // Takes ownership. Can be null.
);


// Resizes the array.
// Invalidates previously returned pointers.
void
NAME_Resize(
	NAME* me,
	int size // size >= 0
);

// Returns the size of the array (the number of available slots).
int
NAME_Size(
	const NAME* me
);

// Appends an item to the end of the array.
// Invalidates previously returned pointers.
void
NAME_Add(
	NAME* me,
	ITEM item // Can be null (for pointers).
IF own
	          // Takes ownership.
END
);

// Finds the first item that compares to the provided user-defined key as 'equal'.
// Returns -1 if no matching items have been found.
int 
NAME_FindFirst(
	const NAME* me,
	NAME_Comparer comparer,
	const void* userKey
);

// Applies a visitor callback to each of the items, including nulls.
void
NAME_ForEach(
	NAME* me,
	NAME_Visitor visitor,
	void* userData		// Can be null.
);
