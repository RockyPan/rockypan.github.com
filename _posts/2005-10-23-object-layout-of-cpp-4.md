---
layout: post
title: C++对象布局及多态实现的探索(四)
category: 技术
tags: [C++]
keywords: C++, 内存对象布局
---

## C++对象布局及多态实现的探索(四)

### 类型动态转换和类型强制转换 

为了验证前面提到过的类型动态转换(即`dynamic_cast`转换)，以及对象类型的强制转换。我们利用前面定义的`C041`、`C042`及`C082`类来进行验证。 运行下列代码：

```
c082.C041::c_ = 0x05;
PRINT_VTABLE_ITEM(c041, 0, 0)
PRINT_DETAIL(C041, ((C041)c082))
PRINT_VTABLE_ITEM(((C041)c082), 0, 0)
PRINT_VTABLE_ITEM(c082, 5, 0)
C042 * pt = dynamic_cast(&c082);
PRINT_VTABLE_ITEM(*pt, 0, 0)
```

第2行和第5行是为了对照方便而打印原对象中的信息。第3、4行把`C082`对象类型进行强制转换并分别打印转换后的对象内存信息及虚表信息。第6行我们用`dynamic_cast`进行了一次动态类型转换，从子类的指针转型为右父类的指针，再把指针指向的对象的信息打印出来。

结果为：

```
c041   : objadr:0012FA74 vpadr:0012FA74 vtadr:0045B364 vtival(0):0041DF1E
The detail of C041 is 64 b3 45 00 05
((C041)c082) : objadr:0012F2A3 vpadr:0012F2A3 vtadr:0045B364 vtival(0):0041DF1E
c082   : objadr:0012FA50 vpadr:0012FA55 vtadr:0045B36C vtival(0):0041D483
*pt    : objadr:0012FA55 vpadr:0012FA55 vtadr:0045B36C vtival(0):0041D483
```

首先我们比较最后两行，从`objadr`列我们可以知道`pt`指向的并不是`c082`对象的起始地址，而是指向了`c082`的第2个虚表指针的所在地址(因为最后一行的`objadr`值等于倒数第2行的`vpadr`的值)。倒数第二行的`vpadr`值是`c082`对象的第2个虚表指针(我们在输出时指定了偏移值5)。而这个地址正是`c082`对象中属于从`C042`类继承而来的部分，即在进行动态类型转换时，除了改变类型信息，编译器还调整了指针的位置，以确保转换语义的正确性。所以我们可以知道，对指向有复杂继承结构的类对象的指针进行类型转换(一般在继承树中向上或向下转换)时，必须使用`dynamic_cast`，它会正确的处理指针位置的调整，如果转换是非法的，它会返回一个`NULL`指针。使用`dynamic_cast`时记得要做这个检查，文中为了简略把这些检查省去了。这种检查可以通过宏来定义，以便于在`release`版中去掉，提高效率。

再将`((C041)c082)`和`c082`两行的输出进行对照，可以发现对对象进行向上的类型强制转换实际上编译器生成了一个新的临时对象，因为它们的`objadr`列不一样了，这表明它们已经不是同一个对象。再观察`c041`、`((C041)c082)`及`c082`三行的`vtadr`和`vtival(0)`，前两行相比是一样的，而后两行相比就不一样了。这也说明编译器在处理强制转换时，实际上是`new`了一个新的`C041`对象出来。因为对象的强制类型转换不象指针的动态类型转换，指针的动态类型转换同时要确保多态的语义，所以只需要调整指针位置。而对象强制类型转换，还要调整虚表中的条目值，因为对象类型转换不需要多态的行为。`c082`类的第一个虚表的第一个条目中存放的是`C082::foo()`函数的地址，做了对象类型转换后，应该调整为`C041::foo()`才对，做这种调整过于复杂，所以编译器干脆`new`了一个新的`C041`的临时对象出来。对比这三行的最后二列即知。我不知道这是否是C++标准规范中定义的行为，改天查到我再更新上来。

在`new`出新对象的同时，编译器还将原对象中属于父类部分的数据成员的值拷贝了过来。注意代码的第1行，`c082.C041::c_ = 0x05;`，我们先把`c082`对象中从`C041`类继承过来的数据成员的值改写为`0x05`，原来是的值是`0x01`，由`C041`的构造函数初始化。我们观察输出的第2行，上面说了这个被打印的对象并非`c082`而是编译器`new`出的来的临时对象，可以注意到对象的最后一字节为`0x05`，即数据成员的值。所以我们知道编译器除了`new`出新的临时对象外，还把原对象中相应的数据成员的值也复制了过来。

这和我以前的认识有点偏差，直观上我一直以为这种转换不会产生新的对象，不过仔细想想编译器的这种作法也是对的，如果不产生新的对象，就意味着它要象前述的那样动态的改变虚表中条目的值。但`new`出临时对象，也意味着使用下列的语句调用，可能产生意想不到的结果。

```
((C041)c082).somefun();
```

如果`somefun`函数会改变对象的状态，那么上边的代码执行后，`c082`的状态并不会被改变。因为`somefun`实际改变的是临时对象，在执行完后该临时对象就扔掉了。这和直观的认识有所差异，一般会认为这个调用会作用于`c082`对象上。为了验证我们声明以下两个类。

```
struct C010
{
    C010() : c_(0x01) {}
    void foo() { c_ = 0x02; }
    char c_;
};

struct C013 : public C010
{
    C013() : c1_(0x01) {}
    void foo() { c1_ = 0x02; }
    char c1_;
};
```

两个类为继承关系，各有一个同名的普通成员函数，该函数改写类的相应成员变量。我们做以下的调用：

```
C013 obj;
obj.foo();
((C010)obj).foo();
```

第1个`foo`调用，改变的是`c1_`值，最后一行的调用改变的是`c_`的值。直观上容易认为上述代码执行后`obj.c_`和`obj.c1_`的值均为`0x02`。但我们在调试环境的局部变量窗口中把`obj`对象展开可以发现`obj.c1_`为`0x02`，但`obj.c_`为`0x01`。原因就是前面所说的`((C010)obj)`实际产生了一个临时对象，所以最后一行的调用没有作用到`obj`对象上。

更进一步的想想，如果我们在一个类上运用了单件`(singleton)`模式，而这个类又有一个继承结构，当在程序中想利用对对象进行向上转型来调用父类的方法时，应该会出现编译时错误，因为父类临时对象无法构造。在这里有个前提，父类的构造函数应该用`protected`进行保护，而不是用`private`，否则子类根本无法构造。这种我没有验证了，因为用这种方法调用实在是比较蠢的作法，但不排除这种可能性。向上例中最后一行正确的调用方法应该是：

```
obj.C010::foo();
```

这样就可以调用到父类中被覆盖的函数，而且也是作用在正确的对象上。

(未完待续)