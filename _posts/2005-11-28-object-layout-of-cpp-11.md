---
layout: post
title: C++对象布局及多态实现的探索(十一)
category: 技术
tags: [C++]
keywords: C++, 内存对象布局
---

## C++对象布局及多态实现的探索(十一)

### 菱形结构的虚继承(3)

最后我们看看，如果在上篇例子的基础上，子类及左、右父类都各自定义了自己的虚函数，这时的情况又会怎样。

```
struct C140 : public virtual C041
{
    C140() : c_(0x02) {}
    virtual void foo() { c_ = 0x11; }
    char c_;
};

struct C160 : public virtual C041
{
    C160() : c_(0x02) {}
    virtual void foo() { c_ = 0x12; }
    virtual void f160() { c_ = 0x12; }
    char c_;
};

struct C161 : public virtual C041
{
    C161() : c_(0x03) {}
    virtual void foo() { c_ = 0x13; }
    virtual void f161() { c_ = 0x13; }
    char c_;
};

struct C170 : public C160, public C161
{
    C170() : c_(0x04) {}
    virtual void foo() { c_ = 0x14; }
    virtual void f170() { c_ = 0x14; }
    char c_;
};
```

首先运行如下的代码，看看内存的布局。

```
PRINT_SIZE_DETAIL(C041)
PRINT_SIZE_DETAIL(C160)
PRINT_SIZE_DETAIL(C161)
PRINT_SIZE_DETAIL(C170)
```

结果为：

```
The size of C041 is 5
The detail of C041 is f0 b2 45 00 01
The size of C160 is 18
The detail of C160 is 84 b3 45 00 88 b3 45 00 02 00 00 00 00 80 b3 45 00 01
The size of C161 is 18
The detail of C161 is 98 b3 45 00 9c b3 45 00 03 00 00 00 00 94 b3 45 00 01
The size of C170 is 28
The detail of C170 is b0 b3 45 00 c8 b3 45 00 02 ac b3 45 00 bc b3 45 00 03 04 00 00 00 00 a8 b3 45 00 01
```

`C170`对象的布局为：

```
|C160,9             |C161,9             |C170,1 |zero,4 |C041,5   |
|vp,4 |op,4,19 |m,1 |vp,4 |op,4,10 |m,1 |m,1    |       |vp,4 |m1 |
```

(注：为了不折行，我用了缩写。`op`代表偏移值指针、`m`代表成员变量、`vp`代表虚表指针。第一个数字是该区域的大小，即字节数。只有偏移值指针有第二个数字，第二个数字就是偏移值指针指向的偏移值的大小。)

左右父类由于各自定义了自己的新的虚函数，因此都拥有了自己的虚表指针。奇怪的是子类虽然也定义了自己的新的虚函数，我们在上面的布局中却看到它并没有自己的虚表指针。那么它应该是和顶层类或是某一父类共用了虚表。我们可以在后面通过对调用的跟踪来找到答案。

另一个奇怪的地方是在左右父类中的偏移值指针指向的偏移值不再是到祖父类的偏移量，而是变成了到祖父类之前的4字节0值的偏移量。同时在前面第八篇中我们说过偏移值指针指向的地址的前4个字节为零，接下来的4个字节才是真正的偏移量。在这个例子中，前4个字节不再为0，而是`0xFFFFFFFC`，即整数-4。

照例我们先通过对象来调用一下。

```
C170 obj;
PRINT_OBJ_ADR(obj);
obj.foo();
```

结果为：

```
obj's address is : 0012F54C
```

最后一行调用对应的汇编指令为：

```
004245B8  lea         ecx,[ebp+FFFFF687h]
004245BE  call        0041D122
```

ecx中的值(即`this`指针的值)为`0x0012F563`，和前面一样是指向祖父类的起始部分。同样函数中的指令也是通过将`this-5`字节来定位到正确的成员变量的地址，这里不再列出函数的汇编指令。

再看看调用它自己新定义的虚函数。

```
obj.f170();
```

对应的汇编指令为：

```
004245C3  lea         ecx,[ebp+FFFFF670h]
004245C9  call        0041D127
```

让我非常惊奇的是这次this指针的值居然是`0x0012F54C`。和前面的对象地址输出是一样的，也就是指向了整个对象的起始位置。这就让人非常的奇怪了，在同一个对象上调用的两个虚函数，编译器为它们传递的`this`指针却是不同的。

让我们跟到函数中，看它怎样取得正确的成员变量的地址。

```
00426F80  push        ebp
00426F81  mov         ebp,esp
00426F83  sub         esp,0CCh
00426F89  push        ebx
00426F8A  push        esi
00426F8B  push        edi
00426F8C  push        ecx
00426F8D  lea         edi,[ebp+FFFFFF34h]
00426F93  mov         ecx,33h
00426F98  mov         eax,0CCCCCCCCh
00426F9D  rep stos    dword ptr [edi]
00426F9F  pop         ecx
00426FA0  mov         dword ptr [ebp-8],ecx
00426FA3  mov         eax,dword ptr [ebp-8]
00426FA6  mov         byte ptr [eax+12h],14h
00426FAA  pop         edi
00426FAB  pop         esi
00426FAC  pop         ebx
00426FAD  mov         esp,ebp
00426FAF  pop         ebp
00426FB0  ret
```

看看第15行可以知道，是直接在`this`指针上加了18字节(即16进制的12h)来定位到子类的成员变量。

由于函数中的指令是以这种方式来定位子类成员变量，所以即使我们是通过指针来调用，不同的只是怎样定位函数地址，而`this`指针的值是肯定不会变的。我们来验证一下。

```
C170 * pt = &obj;
pt->f170();
```

第二行代码对应的汇编指令如下：

```
004245DA  mov         eax,dword ptr [ebp+FFFFF664h]
004245E0  mov         edx,dword ptr [eax]
004245E2  mov         esi,esp
004245E4  mov         ecx,dword ptr [ebp+FFFFF664h]
004245EA  call        dword ptr [edx+4]
004245ED  cmp         esi,esp
004245EF  call        0041DDF2
```

第一行把整个对象的起始地址放到eax中，第2行把eax当指针，并把所指地址放到edx中。对象的起始地址正好也是左父类中的虚表指针，第5行进行调用的时候果然是把edx指向的地址后移了4字节后取值，做为函数地址。这也就回答了前面的一个问题，子类没有虚表，它的虚表实际合并到了左父类的虚表中，左父类定义了一个自己的虚函数，占用了虚函数表的第一个条目，子类的虚函数则占用了第二个条目。因此在寻址时要加上4个字节。ecx中的`this`指针值和我们前面估计一样，是整个对象的起始地址。

最后我们看看怎样得到祖父类地址。

```
pt->C041::c_ = 0x33;
```

对应的汇编指令为：

```
004245F4  mov         eax,dword ptr [ebp+FFFFF664h]
004245FA  mov         ecx,dword ptr [eax+4]
004245FD  mov         edx,dword ptr [ecx+4]
00424600  mov         eax,dword ptr [ebp+FFFFF664h]
00424606  mov         byte ptr [eax+edx+8],33h
```

首先把对象的起始地址赋给eax。第2行把`eax+4`字节后得到的指针指向的地址赋给ecx，这个值就是偏移值指针指向的地址。果然第3行把它`+4`字节后取值，再赋给edx。这时edx的值为`13h`，照理这应该是到祖父类区域的偏移值，但实际是只到我们在对象布局中列出的4字节0值，也就是真正的祖父类起始地址的前4个字节。我们在前面讨论`C170`的对象布局时已经提到这个问题。所以我们看到第5行定位到成员变量时再加了8字节，以跳过4字节的0值为4字节的祖父类的虚表指针，而不是只加4字节跳过虚表指针。在`C150`对象中我们可以看到偏移值是直接跳过4字节0值，定位到祖父类起始地址的。

我们始终没有清楚的解释过祖父类之前的4字节0值及偏移值指针指向地址的前4字节的语义。有可能是出于兼容的原因，也有可能是为编译器提供一些薄记信息。而且，引入虚继承后的对象继承的拓朴结构可以比我们讨论过的菱形结构要复杂得多。这两个值也可能是用来处理更复杂的继承结构。要想通过表象去揣测出使用它们的动机太困难了。

(未完待续)
