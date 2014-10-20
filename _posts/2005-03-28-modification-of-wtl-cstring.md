---
layout: post
title: WTL::CString中的一点缺陷及修改
category: 技术
tags: [C++]
keywords: C++, WTL, CString
---

## `WTL::CString`中的一点缺陷及修改

在以前我做过的一个使用了WTL的项目中碰到过一个很有趣的问题。我们先是做了一个原型版，是一个单独的EXE。后来将它分成了不同的模块，除了界面部分，其他模块都用DLL实现。在无界面的DLL模块中大量使用了`WTL::CString`类，因为这个实现比MFC的`CString`实现要快，功能也更加全面。

可是在集成的时候我们就发现很多跨DLL边界传递的`WTL::CString`对象会出错，经常是在释放的时候出现内存错误。

后来经过跟踪和看WTL的源码，找到了原因。

WTL是在ATL基础上搭建的一个Win32界面框架。相当的精致小巧，效率和直接用SDK写相差无几。除此也还提供了很多实用的工具类，比如：`WTL::CString`。WTL提供的是一堆.H文件，没有CPP文件，也就是说WTL没有单独的编译单元，而是附在包含它的用户编译单元上。

`WTL::CString`的定义和实现全部在`include\Atlmisc.h`文件中。 

首先我们来看看它的部分实现。我把`WTL::CString`的构造部分抽取出来。

```
_declspec(selectany) int rgInitData[] = { -1, 0, 0, 0 };
_declspec(selectany) CStringData* _atltmpDataNil = (CStringData*)&rgInitData;
_declspec(selectany) LPCTSTR _atltmpPchNil = (LPCTSTR)(((BYTE*)&rgInitData) + sizeof(CStringData));

inline CString::CString()
{
    Init();
}

inline void CString::Init()
{
    m_pchData = _GetEmptyString().m_pchData;
}

static const CString& __stdcall _GetEmptyString()
{
    return *(CString*)&_atltmpPchNil;
}
```

当生成一个`WTL::CString`的实例（不论是在heap，stack或静态数据段中），并赋了值之后，WTL会在heap上申请一块内存，内存的结构如下：

```
+----+
|信息|
+----+ <- m_pchData
|数据|
+----+
```

"信息"块的内容为：

```
struct CStringData
{
    long nRefs; // reference count
    int nDataLength;
    int nAllocLength;
};
```

记录了这块内存被引用的次数，有效字符串的长度，字符缓冲区的总长度。整个内存块的长度为`(nAllocLength + sizeof(CStringData))`。 

"数据"块中保存的是真正有效的字符串。 `m_pchData`是`WTL::CString`类中唯一的一个数据成员。指向具体的字符串数据，类型为`LPTSTR`。 

采用这种结构和实现方式可以提供很高的效率。 

在对字符串进行复制时，实际只是使新的`WTL::CString`对象中的`m_pchData`指向原来的数据(即只拷贝了`m_pchData`成员)，并增加了`nRefs`的值。改变时再先拷贝整个字符串，改变相应的引用计数，再改写，即"写时复制"。对于取字符串大小这类函数也可以非常高效的只返回`nDataLength`的值。

我们再来看看我所遇到的问题在哪里？ 

从`WTL::CString`的默认构造函数我们可以很容易看出，对于空的字符串，它让`m_pchData`指向了在全局数据区中的一块内存`rgInitData[2]`，即`rgInitData`的第三个元素。这个地址代表相应的`WTL::CString`对象是个空字符串。使用了`_declspec(selectany)`编译指令保证了`rgInitData`在模块范围内是唯一的。我想用全局数据段中的一个地址表示空字符串，而不是将这块内存`new`到heap中，通过`CStringData`中的一个特定量来表示空字符串，也是出于效率的考虑。这样可以在heap中省下很多"空"的内存块。但是这个实现和一般的用户假设不一样，一般用户总会认为`new`出的数据应该在heap上。而`WTL::CString`中其他若干的实现也依赖于这个特定的实现技术，而不是普通的用户假设。

现在我们来看这个问题的具体表现。 假设一个应用引用了两个DLL，A和B。当应用启动初始化完后，DLL A和B位于同一个进程地址空间。

如果在DLL A中`new`了一个空的字符串对象，再传到DLL B中，再在DLL B中释放了这个对象。这时就会发生内存错误，而这本来应该是合法的，因为A和B共用了同一个heap。通过跟踪发现错误在析构函数中。

```
inline CString::~CString()
{
    if (GetData() != _atltmpDataNil)
    {
        if (InterlockedDecrement(&GetData()->nRefs) <= 0) delete[] (BYTE*)GetData();
    }
}

inline CStringData* CString::GetData() const
{
    return ((CStringData*)m_pchData) - 1;
}
```

我们可以看到释放时通过比较`WTL::CString`对象的`m_pchData`是不是指在全局数据区的代表空字符串的地址上来判断字符串是否为空。如果不为空，是就表示数据是在heap上，如果递减引用为0的话，就`delete`这块内存。 

现在的问题是`_atltmpDataNil`实际也就是``rgInitData`，只是模块范围内是唯一的，在我们上面的例子中DLL A和DLL B是两个不同的模块，他们各含一个`rgInitData`。这样在DLL A中`new`出的空字符串在传到DLL B中，并直接被`delete`时，就会出错，析构函数的`(if (GetData() != _atltmpDataNil))`这句本应为假，此时却为真，这样会在执行`(delete[] (BYTE*)GetData();)`这句时出错，试图`delete`全局数据区中内存当然会出错。

我当时用的是WTL7.0版，如是我又去找到了最新的WTL7.1版，发现还是没有解决这个问题，这样就只能自己来改了。本来想将标志为空的`CStringData`实例`new`到heap中去，这样可以避免上述的问题。但这样一是要改比较多的代码，另外对于多个空的`WTL:CString`实例，要产生多个标志，浪费了内存。最后找到了一个比较简单的解决方法。

```
_declspec(selectany) int rgInitData[] = { -1, 0, 0, 0 };
```

-1对应`CStringData`结构的`nRefs`字段，即引用计数器的初始值。我们可以通过对这个值进行比较，而不是对地址进行比较来确认是否是空的字符串。但是-1有特殊的意义，可以看看`WTL::CString::LockBuffer()`成员函数，当`nRefs`为-1时表示锁定缓冲区。因为我选用了一个比较大的负整数，-10001代表空的字符串。并将这个数做为`WTL::CStringData::nRefs`的初值。 将原来的

```
_declspec(selectany) int rgInitData[] = { -1, 0, 0, 0 };
_declspec(selectany) CStringData* _atltmpDataNil = (CStringData*)&rgInitData;
_declspec(selectany) LPCTSTR _atltmpPchNil = (LPCTSTR)(((BYTE*)&rgInitData) + sizeof(CStringData));
```

修改为：

```
#define NULLSTRING -10001 //PK test 2004-03-08
_declspec(selectany) int rgInitData[] = { NULLSTRING, 0, 0, 0 }; //PK test 2004-03-08
_declspec(selectany) CStringData* _atltmpDataNil = (CStringData*)&rgInitData;
_declspec(selectany) LPCTSTR _atltmpPchNil = (LPCTSTR)(((BYTE*)&rgInitData) + sizeof(CStringData));
```

然后再将原来根据地址是否相同来判断一个字符串是否为空的代码，全部修改为根据`WTL::CStringData::nRefs`的值是否为`NULLSTRING`来判断，即可。共有以下五处：（注意，注释掉的是原来的代码，我加上去的代码后面也用注释做了标记）

```
inline void CString::Release()
{
    //if (GetData() != _atltmpDataNil)
    if (GetData()->nRefs != NULLSTRING) //PK test 2004-03-08
    {
        ATLASSERT(GetData()->nRefs != 0);
        if (InterlockedDecrement(&GetData()->nRefs) <= 0) delete[] (BYTE*)GetData();
        Init();
    }
}

inline void PASCAL CString::Release(CStringData* pData)
{
    //if (pData != _atltmpDataNil)
    if (pData->nRefs != NULLSTRING)
    {
        ATLASSERT(pData->nRefs != 0);
        if (InterlockedDecrement(&pData->nRefs) <= 0) delete[] (BYTE*)pData;
    }
}

inline CString::~CString()
// free any attached data
{
    //if (GetData() != _atltmpDataNil)
    if (GetData()->nRefs != NULLSTRING)
    {
        if (InterlockedDecrement(&GetData()->nRefs) <= 0) delete[] (BYTE*)GetData();
    }
}

inline const CString& CString::operator =(const CString& stringSrc)
{
    if (m_pchData != stringSrc.m_pchData)
    {
        //if ((GetData()->nRefs < 0 && GetData() != _atltmpDataNil) || stringSrc.GetData()->nRefs < 0)
        if ((GetData()->nRefs < 0 && GetData()->nRefs != NULLSTRING) || stringSrc.GetData()->nRefs < 0) //PK test 2004-03-08
        {
            // actual copy necessary since one of the strings is locked
            AssignCopy(stringSrc.GetData()->nDataLength, stringSrc.m_pchData);
        }
        else
        {
            // can just copy references around
            Release();
            ATLASSERT(stringSrc.GetData() != _atltmpDataNil);
            m_pchData = stringSrc.m_pchData;
            InterlockedIncrement(&GetData()->nRefs);
        }
    }
    return *this;
}

inline void CString::UnlockBuffer()
{
    ATLASSERT(GetData()->nRefs == -1);
    //if (GetData() != _atltmpDataNil)
    if (GetData()->nRefs != NULLSTRING) //PK 2004-03-08
        GetData()->nRefs = 1;
}
```

共五处，修改后使用到目前为止，一直没有发现内存泄漏。

关于这个问题我曾经和我的同事争论过。到底我上面说的使用方法是一种非法的使用方法，还是这个问题是应该属于`WTL::CString`设计上的一个缺陷呢。我认为应该是一个缺陷，理由很简单，对于这类底层功能的封装，应该要给用户也就是开发人员以正确的引导，让他们不易进行错误的使用。而这些功能的内部实现也应该站在用户可能的假设上来进行，离开这个就很容易存在设计或实现上的缺陷。比如这个问题，用户在使用时，因为对于空的`WTL::CString`实例，是`new`出来的，所以很正常的会认为，它可以跨模块的边界传递不会出现问题。而`WTL::CString`的实现并没有尊重这一假设，所以我认为这应该是`WTL::CString`实现上的一个缺陷。


> 评论人：PK   2005-09-19 21:00:13
不好意思，你8月2日在我的blog上留了言，因这阵很忙没有上去看。
至于你问的问题要具体看你用的String类的实现。
如果你有源码，你可跟踪一下。
建议你可以用WTL::CString,即使你不用WTL的其他功能。这个字符串类是我见过的实现的相当好的一个。
或者用STD里的string。

> 评论人：freew   2005-08-02 14:20:54
内容里不显示邮箱，我的邮箱是c_bird@sina.com，谢谢赐教！！

> 评论人：freew   2005-08-02 14:18:56
很高兴看到这样的文章
我可以请教一个问题吗，我是在一个dll里面放了一个仿照WTL CString
的一个字符串处理类(开源的)，因为我做的是一个字符串处理的程序，
所以我的程序里大量的用了这个String类，也有内存泄漏。程序结构是这样的，
界面和dll的工作是分离的，界面调用dll的一个接口，请问这与
您说的那个问题有关系吗？