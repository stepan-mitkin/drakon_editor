
CTR_START

/////////////////////////////
// NAME
/////////////////////////////

// Creates an instance of NAME
NAME* // Returns ownership.
NAME_Create(


PTR_ARG
	ITEM ARG // Can be null.


VALUE_ARG
	ITEM ARG


OWN_ARG
	ITEM* ARG // Takes ownership. Can be null.
	
	
FUN_END
);


DTR

// Destroys an instance of NAME
void
NAME_Destroy(
	NAME* me // Takes ownership. Can be null.
);


VALUE_GETTER_NORMAL

// Gets the PROP property of NAME.
ITEM
NAME_GetPROP(
	const NAME* me
);


VALUE_GETTER_PTR

// Gets the PROP property of NAME.
ITEM // Can be null.
NAME_GetPROP(
	NAME* me
);
	

OWN_GETTER

// Gets the PROP property of NAME.
ITEM* // Can be null.
NAME_GetPROP(
	NAME* me
);


INLINE_GETTER

// Gets the address of the PROP property of NAME.
ITEM*
NAME_GetPROP(
	NAME* me
);


VALUE_SETTER

// Sets the PROP property of NAME.
void
NAME_SetPROP(
	NAME* me,
	ITEM value // Can be null (for pointers).
);


OWN_SETTER

// Sets the PROP property of NAME.
void
NAME_SetPROP(
	NAME* me,
	ITEM* value // Takes ownership. Can be null.
);


OWN_TAKER

// Removes the ownership for the PROP property of NAME.
// Clears the field.
// Returns the old object.
ITEM* // Returns ownership. Can be null.
NAME_TakePROP(
	NAME* me
);




