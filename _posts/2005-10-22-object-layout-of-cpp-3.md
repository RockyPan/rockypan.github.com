---
layout: post
title: C++对象布局及多态实现的探索(三)
category: 技术
tags: [C++]
keywords: C++, 内存对象布局
---

## C++对象布局及多态实现的探索(三)

### 带虚函数的类的对象布局(2) 

接下来我们看看多重继承。定义两个类，各含一个虚函数，及一个数据成员。再从这两个类派生一个空子类。

```
struct C041
{
    C041() : c_(0x01) {}
    virtual void foo() { c_ = 0x02; }
    char c_;
};

struct C042
{
    C042() : c_(0x02) {}
    virtual void foo2() {}
    char c_;
};

struct C051 : public C041, public C042
{
};
```

运行如下代码：

```
PRINT_SIZE_DETAIL(C041)
PRINT_SIZE_DETAIL(C042)
PRINT_SIZE_DETAIL(C051)
```

结果为：

```
The size of C041 is 5
The detail of C041 is 64 b3 45 00 01
The size of C042 is 5
The detail of C042 is 68 b3 45 00 02
The size of C051 is 10
The detail of C051 is 6c b4 45 00 01 68 b4 45 00 02
```

注意，首先我们观察`C051`的对象输出，发现它的大小为10字节，这说明它有两个虚表指针，从导出的内存数据我们可以推断，首先是一个虚表指针，然后是从`C041`继承的成员变量，值也是我们在`C041`的构造函数中赋的值`0x01`，然后又是一个虚表指针，再是从`C042`继承的成员变量，值为`0x02`。 

为了验证，我们再运行如下代码：

```
C041 c041;
C042 c042;
C051 c051;
PRINT_VTABLE_ITEM(c041, 0, 0)
PRINT_VTABLE_ITEM(c042, 0, 0)
PRINT_VTABLE_ITEM(c051, 0, 0)
PRINT_VTABLE_ITEM(c051, 5, 0)
```

注意最后一行的第二个参数，5。它是从对象起始地址开始到虚表指针的偏移值(按字节计算)，从上面的对象内存输出我们看到`C041`的大小为5字节，因此`C051`中第二个虚表指针的起始位置距对象地址的偏移为5字节。输出的结果为： 

(注：这个偏移值是通过观察而判断出来的，并不通用，而且它依赖于我们前面所说的编译器在生成代码时所用的结构成员对齐方式，我们将这个值设为1。如果设为其他值会影响对象的大小及这个偏移值。参见第一篇起始处的说明。下同。)

```
c041   : objadr:0012FB88 vpadr:0012FB88 vtadr:0045B364 vtival(0):0041DF1E
c042   : objadr:0012FB78 vpadr:0012FB78 vtadr:0045B368 vtival(0):0041D43D
c051   : objadr:0012FB64 vpadr:0012FB64 vtadr:0045B46C vtival(0):0041DF1E
c051   : objadr:0012FB64 vpadr:0012FB69 vtadr:0045B468 vtival(0):0041D43D
```

这下我们可以看`C051`的两个虚表指针指向两个不现的虚表(第3、4行的`vtadr`列)，而虚表中的条目的值分别等于`C041`和`C042`(即它的两个父类)的虚表条目的值(第1、3行和2、4行的`vtival`列的值相同)。 

为什么子类要有两个虚表，而不是将它们合并为一个。主要是在处理类型的动态转换时这种对象布局更方便调整指针，后面我们看到这样的例子。 

如果子类重写父类的虚函数会怎么样？前面的类`C071`我们已经看到过一次了。我们再定义一个从`C041`和`C042`派生的类`C082`，并重写这两个父类中的虚函数，同时再增加一个虚函数。

```
struct C041
{
    C041() : c_(0x01) {}
    virtual void foo() { c_ = 0x02; }
    char c_;
};

struct C042
{
    C042() : c_(0x02) {}
    virtual void foo2() {}
    char c_;
};

struct C082 : public C041, public C042
{
    C082() : c_(0x03) {}
    virtual void foo() {}
    virtual void foo2() {}
    virtual void foo3() {}
    char c_;
};
```

运行和上面类似的代码：

```
PRINT_SIZE_DETAIL(C082)
C041 c041;
C042 c042;
C082 c082;
PRINT_VTABLE_ITEM(c041, 0, 0)
PRINT_VTABLE_ITEM(c042, 0, 0)
PRINT_VTABLE_ITEM(c082, 0, 0)
PRINT_VTABLE_ITEM(c082, 5, 0)
```

结果为：

```
The size of C082 is 11
The detail of C082 is 70 b3 45 00 01 6c b3 45 00 02 03
c041   : objadr:0012FA74 vpadr:0012FA74 vtadr:0045B364 vtival(0):0041DF1E
c042   : objadr:0012FA64 vpadr:0012FA64 vtadr:0045B368 vtival(0):0041D43D
c082   : objadr:0012FA50 vpadr:0012FA50 vtadr:0045B370 vtival(0):0041D87A
c082   : objadr:0012FA50 vpadr:0012FA55 vtadr:0045B36C vtival(0):0041D483
```

果然`C082`的两个虚表中的条目值都和父类的不一样了(`vtival`列)，指向了重写后的新函数地址。观察`C082`的大小和对象内存，我们可以知道它并没有为新定义的虚函数`foo3`生成新的虚表。那么`foo3`的函数地址到底是加到了类的第一个虚表，还是第二个虚表中？在调试状态下，我们在“局部变量”窗口中展开`c082`对象。可以看到两个虚表及其中的条目，但两个虚表都只能看到第一个条目。这应该是VC7.1IDE的一个小BUG。看来我们只有另想办法来验证。我们先把两个虚表中的第二个条目位置上的值打印出来。运行如下代码。

```
PRINT_VTABLE_ITEM(c082, 0, 1)
PRINT_VTABLE_ITEM(c082, 5, 1)
```

结果如下：

```
c082   : objadr:0012FA50 vpadr:0012FA50 vtadr:0045B370 vtival(1):0041D32F
c082   : objadr:0012FA50 vpadr:0012FA55 vtadr:0045B36C vtival(1):0041D87A
```

然后我们调用一下`foo3`函数：

```
c082.foo3();
```

查看它的汇编代码：

```
004225F3  lea         ecx,[ebp+FFFFFB74h]
004225F9  call        0041D32F
```

第2条`call`指令后的地址就是`foo3`的函数地址了(实际上是一个跳转指令)，对照前面的输出我们就可以知道，子类新定义的虚函数对应的虚表条目加入到了子类的第一个虚表中，并位于继承自父类的虚表条目之后。 

(未完待续)
