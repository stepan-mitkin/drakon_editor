BODY
struct NAME {
	Object Super; // Contains a pointer to the type info.
	
	
PTR_FIELD
	ITEM PROP; // Can be null.


VALUE_FIELD
	ITEM PROP;


OWN_FIELD
	ITEM* PROP; // Ownership. Can be null.


BODY_END
};

void NAME_Destroy(NAME* me);

TypeInfo gNAME = { 
	"NAME", 
	(ObjectDestructorFun)NAME_Destroy,
	0
};


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


CTR_BODY
)
{
	NAME* me = Allocator_Allocate(sizeof(NAME), 1);
	me->Super.Type = &gNAME;


FIELD_ASSIGN
	me->PROP = ARG;


CTR_END
	return me;
}


FUN_START
)
{


FUN_END
}


DTR

// Destroys an instance of NAME
void
NAME_Destroy(
	NAME* me // Takes ownership. Can be null.
)
{
	if (me == 0) return;



CUSTOM_DTR
	NAME_Destructor(me);


OWN_DESTROY
	ITEM_Destroy(me->PROP);


DTR_END
	Allocator_Free(me);
}


VALUE_GETTER_NORMAL

ITEM
NAME_GetPROP(
	const NAME* me
)
{
	assert(me);
	return me->PROP;
}


VALUE_GETTER_PTR

ITEM
NAME_GetPROP(
	NAME* me
)
{
	assert(me);
	return me->PROP;
}
	

OWN_GETTER

ITEM*
NAME_GetPROP(
	NAME* me
)
{
	assert(me);
	return me->PROP;
}


INLINE_GETTER

ITEM*
NAME_GetPROP(
	NAME* me
)
{
	assert(me);
	return &me->PROP;
}


VALUE_SETTER

void
NAME_SetPROP(
	NAME* me,
	ITEM value // Can be null (for pointers).
)
{
	assert(me);
	me->PROP = value;
}



OWN_SETTER

void
NAME_SetPROP(
	NAME* me,
	ITEM* value // Takes ownership. Can be null.
)
{
	assert(me);
	ITEM* old = me->PROP;
	if (old != value)
	{
		me->PROP = value;
		ITEM_Destroy(old);
	}
}


OWN_TAKER

ITEM* // Returns ownership. Can be null.
NAME_TakePROP(
	NAME* me
)
{
	assert(me);
	ITEM* old = me->PROP;
	me->PROP = 0;
	return old;
}





