---
layout: post
title: C++对象布局及多态实现的探索(二)
category: 技术
tags: [C++]
keywords: C++, 内存对象布局
---

## C++对象布局及多态实现的探索(二)

###带虚函数的类的对象布局(1) 

如果类中存在虚函数时，情况会怎样呢？我们知道当一个类中有虚函数时，编译器会为该类产生一个虚函数表，并在它的每一个对象中插入一个指向该虚函数表的指针，通常这个指针是插在对象的起始位置。所谓的虚函数表实际就是一个指针数组，其中的指针指向真正的函数起始地址。我们来验证一下，定义一个无成员变量的类C040，内含一个虚函数。

```
struct C040
{
    virtual void foo() {}
};
```
　　
运行如下代码打印它的大小及对象中的内容。

```
PRINT_SIZE_DETAIL(C040)
```
　　
结果为：

```
The size of C040 is 4
The detail of C040 is 40 b4 45 00
```
　　
果然它的大小为4字节，即含有一个指针，指针指向的地址为0x0045b440。

同样再定义一个空类C050，派生自类C040。

```
struct C050 : C040
{
};
```
　　
由于虚函数会被继承，且维持为虚函数。那么类C050的对象中同样应该含有一个指向C050的虚函数表的指针。

运行如下代码打印它的大小及对象中的内容。

```
PRINT_SIZE_DETAIL(C050)
```
　　
结果为：

```
The size of C050 is 4
The detail of C050 is 44 b4 45 00
```
　　
果然它的大小也为4字节，即含有一个指向虚函数表(后称虚表)的指针(后称虚表指针)。

虚表是类级别的，类的所有对象共享同一个虚表。我们可以生成类C040的两个对象，然后通过观察对象的地址、虚表指针地址、虚表地址、及虚表中的条目的值(即所指向的函数地址)来进行验证。 运行如下代码：

```
C040 obj1, obj2;
PRINT_VTABLE_ITEM(obj1, 0, 0)
PRINT_VTABLE_ITEM(obj2, 0, 0)
```
　　
结果如下：
```
obj1  : objadr:0012FDC4 vpadr:0012FDC4 vtadr:0045B440 vtival(0):0041D834
obj2  : objadr:0012FDB8 vpadr:0012FDB8 vtadr:0045B440 vtival(0):0041D834
```
　　
(注：第一列为对象名，第二列(objadr)为对象的内存地址，第三列(vpadr)为虚表指针地址，第四列(vtadr)为虚表的地址，第五列(vtival(n))为虚表中的条目的值，n为条目的索引，从0开始。后同)

果然对象地址不同，虚表指针(vpadr)位于对象的起始位置，所以它的地址和对象相同。两个对象的虚表指针指向的是同一个虚表，因此(vtadr)的值相同，虚表中的第一条目(vtival(0))的值当然也一样。

接下来，我们再观察类C040和从它派生的类C050的对象，这两个类各有自己的虚表，但由于C050没有重写继承自C040的虚函数，所以它们的虚表中的条目的值，即指向的虚函数的地址应该是一样的。

运行如下代码：

```
C040 c040;
C050 c050;
PRINT_VTABLE_ITEM(c040, 0, 0)
PRINT_VTABLE_ITEM(c050, 0, 0)
```
　　
结果为：

```
c040   : objadr:0012FD4C vpadr:0012FD4C vtadr:0045B448 vtival(0):0041D834
c050   : objadr:0012FD40 vpadr:0012FD40 vtadr:0045B44C vtival(0):0041D834
```
　　
果然这次我们可以看到虽然前几列皆不相同，但最后一列的值相同。即它们共享同一个虚函数。

定义一个C043类，包含两个虚函数。再定义一个C071类，从C043派生，并重写继承的第一个虚函数。

```
struct C043
{
    virtual void foo1() {}
    virtual void foo2() {}
};

struct C071 : C043
{
    virtual void foo1() {}
};
```
　　
我们可以预料到，C043和C071各有一个包含两个条目的虚表，由于C071派生自C043，并且重写了第一个虚函数。那么这两个类的虚表的第一个条目值是不同的，而第二项应该是相同的。运行如下代码。

```
C043 c043;
C071 c071;
PRINT_SIZE_DETAIL(C071)
PRINT_VTABLE_ITEM(c043, 0, 0)
PRINT_VTABLE_ITEM(c071, 0, 0)
PRINT_VTABLE_ITEM(c043, 0, 1)
PRINT_VTABLE_ITEM(c071, 0, 1)
```
　　
结果为：

```
The size of C071 is 4
The detail of C071 is 5c b4 45 00
c043   : objadr:0012FCD4 vpadr:0012FCD4 vtadr:0045B450 vtival(0):0041D4F1
c071   : objadr:0012FCC8 vpadr:0012FCC8 vtadr:0045B45C vtival(0):0041D811
c043   : objadr:0012FCD4 vpadr:0012FCD4 vtadr:0045B450 vtival(1):0041DFE1
c071   : objadr:0012FCC8 vpadr:0012FCC8 vtadr:0045B45C vtival(1):0041DFE1
```
　　
观察第3、4行的最后一列，即两个类的虚表的第一个条目，由于C071重写了foo1函数，所以这个值不一样。而第5、6行的最后一列为两个类的虚表的第二个条目，由于C071并没有重写它，所以这两个值是相同的。和我们之间的猜测是一致的。

（未完待续）