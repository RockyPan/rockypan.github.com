---
layout: post
title: C++对象布局及多态实现的探索(十)
category: 技术
tags: [C++]
keywords: C++, 内存对象布局
---

## C++对象布局及多态实现的探索(十)

### 菱形结构的虚继承(2)

我们再看一个例子，这个例子的继承结构和上一篇中是一样的，也是菱形结构。不同的是，每一个类都重写了顶层类声明的虚函数。代码如下：

```
struct C041
{
    C041() : c_(0x01) {}
    virtual void foo() { c_ = 0x02; }
    char c_;
};

struct C140 : public virtual C041
{
    C140() : c_(0x02) {}
    virtual void foo() { c_ = 0x11; }
    char c_;
};

struct C141 : public virtual C041
{
    C141() : c_(0x03) {}
    virtual void foo() { c_ = 0x12; }
    char c_;
};

struct C150 : public C140, public C141
{
    C150() : c_(0x04) {}
    virtual void foo() { c_ = 0x21; }
    char c_;
};
```

首先我们运行下面的代码，看看它们的内存布局。

```
PRINT_SIZE_DETAIL(C041)
PRINT_SIZE_DETAIL(C140)
PRINT_SIZE_DETAIL(C141)
PRINT_SIZE_DETAIL(C150)
```

结果为：

```
The size of C041 is 5
The detail of C041 is f0 c2 45 00 01
The size of C140 is 14
The detail of C140 is 48 c3 45 00 02 00 00 00 00 44 c3 45 00 01
The size of C141 is 14
The detail of C141 is 58 c3 45 00 03 00 00 00 00 54 c3 45 00 01
The size of C150 is 20
The detail of C150 is 74 c3 45 00 02 68 c3 45 00 03 04 00 00 00 00 64 c3 45 00 01
```

和前面的布局不同之处在于，共享部分和前面的非共享部分之间多了4字节的0值。只有共享部分有虚表指针，这是因为派生类都没有定义自己的虚函数，只是重写了顶层类的虚函数。我们分析一下`C150`的对象布局。

```
|C140,5         |C141,5         |C150,1 |zero,4 |C041,5     |
|ospt,4,15 |m,1 |ospt,4,10 |m,1 |m,1    |4      |vtpt,4 |m1 |
```

(注：为了不折行，我用了缩写。`ospt`代表偏移值指针、`m`代表成员变量、`vtpt`代表虚表指针。第一个数字是该区域的大小，即字节数。只有偏移值指针有第二个数字，第二个数字就是偏移值指针指向的偏移值的大小。)

再看函数的调用：

```
C150 obj;
PRINT_OBJ_ADR(obj)
obj.foo();
```

输出的对象地址为：

```
obj's address is : 0012F624
```

最后一行函数调用的代码对应的汇编代码为：

```
00423F74  lea         ecx,[ebp+FFFFF757h]　
00423F7A  call        0041DCA3
```

单步执行后，我们可以看到ecx中的值为：`0x0012F633`，这个地址也就是`obj`对象布局中的祖父类部分的起始地址。通过上面的布局分析我们知道`C150`起始的偏移值指针指向的值为15，即对象起始到共享部分(祖父类部分)的偏移值。上面输出的`obj`起始地址为`0x0012F624`加上十进制的15后，正好是我们看到的ecx中的值`0x0012f633`。

由于函数调用是作用于对象上，我们看到第二行的`call`指令是直接到地址的。

在这里令人困惑的问题是，我们知道ecx是用来传递`this`指针的。在前一篇中，我们分析了在`C110`对象上的`foo`方法调用。在那个例子中，由于`foo`是顶层类中定义的虚函数，并且没有被下面的派生类重写，因此通过子类对象调用这个方法时，编译器产生的代码是通过子类起始的偏移指针指向的偏移值来计算出祖父类部分的起始地址，并将这个地址做为`this`指针所指向的地址。但是在`C150`类中，`foo`不再是从祖父类继承的，而是被子类自己所重写。照理这时的`this`指针应该指向子类的起始地址，也就是`0x0012F62E`，而不是ecx中的值`0x0012F633`。

我们跟进去看看`C150::foo()`的汇编代码，看它是怎样通过指向祖父类部分的`this`指针，来定位到子类的成员变量。

```
00426C00  push        ebp
00426C01  mov         ebp,esp
00426C03  sub         esp,0CCh
00426C09  push        ebx
00426C0A  push        esi
00426C0B  push        edi
00426C0C  push        ecx
00426C0D  lea         edi,[ebp+FFFFFF34h]
00426C13  mov         ecx,33h
00426C18  mov         eax,0CCCCCCCCh
00426C1D  rep stos    dword ptr [edi]
00426C1F  pop         ecx
00426C20  mov         dword ptr [ebp-8],ecx
00426C23  mov         eax,dword ptr [ebp-8]
00426C26  mov         byte ptr [eax-5],21h
00426C2A  pop         edi
00426C2B  pop         esi
00426C2C  pop         ebx
00426C2D  mov         esp,ebp
00426C2F  pop         ebp
00426C30  ret
```

果然，由于此时指针指向的不是子类的起始部分(而是祖父类的起始部分)，因为是通过减于一个偏移值为向前定位成员变量的地址的。注意第15行，这时eax中存放的是`this`指针的值，写入值的地址是`[eax-5]`，结合前面的对象布局和对象的内存输出，我们可以知道`this`指针的值(此时指向祖父类`C041`的起始部分)减去5个字节(4字节的0值和1字节的成员变量值)后，刚好是子类`C150`的起始地址。

为什么不直接用子类的地址而是通过祖父类的起始地址间接的进行定位？这牵涉到编译内部的实现限制和对一系统问题的全面的理解。只是通过分析现象很难找到答案。

我们再通过指针来调用一次。

```
C150 * pt = &obj;
pt->foo();
```

第二行代码对应的汇编指令为：

```
00423F8B  mov         eax,dword ptr [ebp+FFFFF73Ch]
00423F91  mov         ecx,dword ptr [eax]
00423F93  mov         edx,dword ptr [ecx+4]
00423F96  mov         eax,dword ptr [ebp+FFFFF73Ch]
00423F9C  mov         ecx,dword ptr [eax]
00423F9E  mov         eax,dword ptr [ebp+FFFFF73Ch]
00423FA4  add         eax,dword ptr [ecx+4]
00423FA7  mov         ecx,dword ptr [ebp+FFFFF73Ch]
00423FAD  mov         edx,dword ptr [ecx+edx]
00423FB0  mov         esi,esp
00423FB2  mov         ecx,eax
00423FB4  call        dword ptr [edx]
00423FB6  cmp         esi,esp
00423FB8  call        0041DDF2
```

喔！更加迂回了。这段代码非常的低效，里面很多明显的冗余指令，如第1、4、6行，2、5行等，如果打开了优化开关可能这段指令的效率会好很多。

第9行通过祖父类的虚表指针得到了函数地址，第11行同样把祖父类部分的起始地址`0x0012F633`做为`this`指针指向的地址存入ecx。

最后我们做个指针的动态转型再调用一次：

```
C141 * pt1 = dynamic_cast(pt);
pt1->foo();
```

第1行代码对应的汇编指令如下：

```
00423FBD  cmp         dword ptr [ebp+FFFFF73Ch],0
00423FC4  je          00423FD7
00423FC6  mov         eax,dword ptr [ebp+FFFFF73Ch]
00423FCC  add         eax,5
00423FCF  mov         dword ptr [ebp+FFFFF014h],eax
00423FD5  jmp         00423FE1
00423FD7  mov         dword ptr [ebp+FFFFF014h],0
00423FE1  mov         ecx,dword ptr [ebp+FFFFF014h]
00423FE7  mov         dword ptr [ebp+FFFFF730h],ecx
```

这里实际做了一个`pt`是否为零的判断，第4条指令把`pt`指向的地址后移了5字节，最后赋给了`pt1`。这样`pt1`就指向了右父类部分的地址位置，也就是`C141`的起始位置。

第2行代码对应的汇编指令为：

```
00423FED  mov         eax,dword ptr [ebp+FFFFF730h]
00423FF3  mov         ecx,dword ptr [eax]
00423FF5  mov         edx,dword ptr [ecx+4]
00423FF8  mov         eax,dword ptr [ebp+FFFFF730h]
00423FFE  mov         ecx,dword ptr [eax]
00424000  mov         eax,dword ptr [ebp+FFFFF730h]
00424006  add         eax,dword ptr [ecx+4]
00424009  mov         ecx,dword ptr [ebp+FFFFF730h]
0042400F  mov         edx,dword ptr [ecx+edx]
00424012  mov         esi,esp
00424014  mov         ecx,eax
00424016  call        dword ptr [edx]
00424018  cmp         esi,esp
0042401A  call        0041DDF2
```

由于是通过偏移值指针进行运算，最后在调用时ecx和edx的值和前面通过`pt`指针调用时是一样的，这也是正确的多态行为。

(未完待续)
