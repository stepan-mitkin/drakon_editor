/* Autogenerated with DRAKON Editor 1.32 */
#ifndef C_DEMO_H84201
#define C_DEMO_H84201
/* Since C does not come with a decent standard library,
   we must provide our own primitives.
   Символы Юникод
*/
struct String;
struct ObjectArray;
struct IntArray;
typedef void (*ObjectDestructor)(void* object);
typedef int (*ObjectComparer)(const void* left, const void* right);
struct IntArray* Fibonacci(
    int n
);
int IntArray_Count(
    const struct IntArray* object
);
struct IntArray* IntArray_Create(
    int size
);
void IntArray_Delete(
    struct IntArray* object
);
int IntArray_Get(
    const struct IntArray* object,
    int index
);
void IntArray_Put(
    struct IntArray* object,
    int index,
    int value
);
void* Memory_Allocate(
    int numOfObjects,
    int objectSize
);
void Memory_Free(
    void* buffer
);
int ObjectArray_Count(
    const struct ObjectArray* object
);
struct ObjectArray* ObjectArray_Create(
    int size,
    ObjectDestructor elementDestructor
);
void ObjectArray_Delete(
    struct ObjectArray* object
);
void* ObjectArray_Get(
    struct ObjectArray* object,
    int index
);
void ObjectArray_Put(
    struct ObjectArray* object,
    int index,
    void* value
);
void QuickSort(
    struct ObjectArray* collection,
    int begin,
    int end,
    ObjectComparer comparer
);
int String_Compare(
    const struct String* left,
    const struct String* right
);
void String_Delete(
    struct String* object
);
struct String* String_FromCString(
    const char* text
);
const char* String_GetBuffer(
    const struct String* object
);
void UnexpectedBranch(
    int switchValue
);
int main(
    int argc,
    char** argv
);
/* End of header file. */
#endif
