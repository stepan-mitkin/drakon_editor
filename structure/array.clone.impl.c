
IF value inline

NAME*
NAME_Clone(
	const NAME* old
)
{
	NAME* obj;
	if (!old) return 0;
	obj = NAME_Create();
	NAME_Resize(obj, old->Size);
	memcpy(obj->Items, old->Items, old->Size * sizeof(ITEM));
	
	return obj;
}

END

IF own
NAME*
NAME_Clone(
	const NAME* old
)
{
	int i;
	NAME* obj;
	if (!old) return 0;
	obj = NAME_Create();
	NAME_Resize(obj, old->Size);
	for (i = 0; i < old->Size; i++)
	{
		obj->Items[i] = ITEM_Clone(old->Items[i]);
	}	
	return obj;
}

END
