
#define NAME_INITIAL_SIZE 10

struct NAME
{
	Object Super;
	ITEM* Items;
	int Allocated;
	int Size;
};

TypeInfo gNAME = { 
	"NAME", 
	(ObjectDestructorFun)NAME_Destroy,
	0
};



NAME*
NAME_Create(void)
{
	NAME* object = Allocator_Allocate(sizeof(NAME), 1);
	object->Super.Type = &gNAME;
	
	return object;
}

NAME*
NAME_FromObject(
	void* obj
	)
{
	NAME* tObj;
	if (!obj) abort();
	tObj = (NAME*)obj;
	if (tObj->Super.Type != &gNAME) abort();
	return tObj;
}

IF own

ITEM
NAME_Take(
	NAME* me,
	int index)
{
	ITEM item;
	assert(me);
	assert(index >= 0 && index < me->Size);
	item = me->Items[index];
	me->Items[index] = 0;
	return item;
}

void
NAME_Put(
	NAME* me,
	int index,
	ITEM item)
{
	ITEM old;
	assert(me);
	assert(index >= 0 && index < me->Size);
	
	old = me->Items[index];
	if (old != item) 
	{
		ITEM_Destroy(old);
		me->Items[index] = item;
	}
}

static void NAME_DestroyRange(NAME* me, int begin, int end)
{
	int i;
	assert(begin >= 0 && end <= me->Size);
	for (i = begin; i < end; i++)
	{
		ITEM_Destroy(me->Items[i]);
	}
}

ITEM 
NAME_Get(
	NAME* me,
	int index
)
{
	assert(me);
	assert(index >= 0 && index < me->Size);
	
	return me->Items[index];
}

END

IF value own

ITEM*
NAME_Buffer(
	NAME* me
)
{
	assert(me);
	return me->Items;
}

END


IF value

ITEM
NAME_Get(
	const NAME* me,
	int index
)
{
	assert(me);
	assert(index >= 0 && index < me->Size);
	
	return me->Items[index];
}


void
NAME_Put(
	NAME* me,
	int index,
	ITEM item
)
{
	assert(me);
	assert(index >= 0 && index < me->Size);
	
	me->Items[index] = item;
}

void
NAME_Remove(
	NAME* me,
	int index
)
{
	int i;
	int last;
	assert(me);
	assert(index >= 0 && index < me->Size);
	last = me->Size - 1;
	for (i = index; i < last; i++)
	{
		me->Items[i] = me->Items[i + 1];
	}
	memset(me->Items + last, 0, sizeof(ITEM));
	me->Size--;
}


END

IF inline

ITEM*
NAME_Get(
	NAME* me,
	int index
)
{
	assert(me);
	assert(index >= 0 && index < me->Size);
	
	return me->Items + index;
}

END


void
NAME_Destroy(
	NAME* me
)
{
	if (me == 0)
	{
		return;
	}
	
	assert(me->Super.Type == &gNAME);
	
IF own

	NAME_DestroyRange(me, 0, me->Size);

END	

	Allocator_Free(me->Items);
	Allocator_Free(me);
}



static void NAME_Allocate(
	NAME* me,
	int newAllocated
)
{
	if (me->Allocated == 0)
	{
		me->Items = Allocator_Allocate(
			sizeof(ITEM),
			newAllocated);
	}
	else
	{
		me->Items = Allocator_Reallocate(
			me->Items, 
			sizeof(ITEM),
			me->Allocated,
			newAllocated);
	}
		
	me->Allocated = newAllocated;
}

void
NAME_Resize(
	NAME* me,
	int size
)
{
	int newAllocated;
	int addition;
	ITEM* additionStart;
	
	assert(me);
	assert(me->Super.Type == &gNAME);
	assert(size >= 0);
	
	if (size == me->Size)
	{
		return;
	}
	
	if (size > me->Size)
	{
		if (size > me->Allocated)
		{
			newAllocated = size;
			NAME_Allocate(me, newAllocated);
		}
	} 
	else
	{
IF own

		NAME_DestroyRange(me, size, me->Size);
END	
		addition = (me->Size - size) * sizeof(ITEM);
		additionStart = me->Items + size;
		memset(additionStart, 0, addition);
	}

	me->Size = size;		
}


int
NAME_Size(
	const NAME* me
)
{
	assert(me);
	return me->Size;
}


void
NAME_Add(
	NAME* me,
	ITEM item
)
{
	int index;
	assert(me);
	assert(me->Size <= me->Allocated);
	
	index = me->Size;
	
	if (me->Size == me->Allocated)
	{
		if (me->Allocated == 0)
		{
			NAME_Allocate(me, NAME_INITIAL_SIZE);
		}
		else
		{
			NAME_Allocate(me, me->Allocated * 2);
		}
	}
	
	me->Size++;
	me->Items[index] = item;
}

IF own value

int 
NAME_FindFirst(
	const NAME* me,
	NAME_Comparer comparer,
	const void* userKey
)
{
	int i;
	ITEM current;
	
	assert(me);
	assert(comparer);
	
	for (i = 0; i < me->Size; i++)
	{
		current = me->Items[i];
		if (comparer(current, userKey))
		{
			return i;
		}
	}
	
	return -1;
}

// Applies a visitor callback to each of the items, including nulls.
void
NAME_ForEach(
	NAME* me,
	NAME_Visitor visitor,
	void* userData		// Can be null.
)
{
	ITEM* current;
	ITEM* end;
	
	assert(me);
	assert(visitor);
	
	current = me->Items;
	end = current + me->Size;
	
	while (current < end)
	{
		if (visitor(*current, userData))
		{
			return;
		}
		current++;
	}
}

END

IF inline

int 
NAME_FindFirst(
	const NAME* me,
	NAME_Comparer comparer,
	const void* userKey
)
{
	int i;
	ITEM* current;
	
	assert(me);
	assert(comparer);
	
	for (i = 0; i < me->Size; i++)
	{
		current = me->Items + i;
		if (comparer(current, userKey))
		{
			return i;
		}
	}
	
	return -1;
}

// Applies a visitor callback to each of the items, including nulls.
void
NAME_ForEach(
	NAME* me,
	NAME_Visitor visitor,
	void* userData		// Can be null.
)
{
	ITEM* current;
	ITEM* end;
	
	assert(me);
	assert(visitor);
	
	current = me->Items;
	end = current + me->Size;
	
	while (current < end)
	{
		if (visitor(current, userData))
		{
			return;
		}
		current++;
	}
}


END
