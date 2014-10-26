---
layout: post
title: C++对象布局及多态实现的探索(六)
category: 技术
tags: [C++]
keywords: C++, 内存对象布局
---

## C++对象布局及多态实现的探索(六)

### 虚函数调用

我们再看看虚成员函数的调用。类`C041`中含有虚成员函数，它的定义如下：

```
struct C041
{
    C041() : c_(0x01) {}
    virtual void foo() { c_ = 0x02; }
    char c_;
};
```

执行如下代码：

```
C041 obj;
PRINT_DETAIL(C041, obj)
PRINT_VTABLE_ITEM(obj, 0, 0)
obj.foo();
C041 * pt = &obj;
pt->foo();
```

结果如下：

```
The detail of C041 is 14 b3 45 00 01
obj    : objadr:0012F824 vpadr:0012F824 vtadr:0045B314 vtival(0):0041DF1E
```

我们打印出了`C041`的对象内存布局及它的虚表信息。 先看看`obj.foo();`的汇编代码：

```
004230DF  lea         ecx,[ebp+FFFFF948h]
004230E5  call        0041DF1E
```

和前面第五篇中看过的普通的成员函数调用产生的汇编代码一样。这说明了通过对象进行函数调用，即使被调用的函数是虚函数也是静态绑定，即在编译时决议出函数的地址。不会有多态的行为发生。

我们跟踪进去看看函数的汇编代码。

```
004263F0  push        ebp
004263F1  mov         ebp,esp
004263F3  sub         esp,0CCh
004263F9  push        ebx
004263FA  push        esi
004263FB  push        edi
004263FC  push        ecx
004263FD  lea         edi,[ebp+FFFFFF34h]
00426403  mov         ecx,33h
00426408  mov         eax,0CCCCCCCCh
0042640D  rep stos    dword ptr [edi]
0042640F  pop         ecx
00426410  mov         dword ptr [ebp-8],ecx
00426413  mov         eax,dword ptr [ebp-8]
00426416  mov         byte ptr [eax+4],2
0042641A  pop         edi
0042641B  pop         esi
0042641C  pop         ebx
0042641D  mov         esp,ebp
0042641F  pop         ebp
00426420  ret
```

值得注意的是第14、15行。第14行把`this`指针的值移到eax寄存器中，第15行给类的第一个成员变量赋值，这时我们可以看到在取变量的地址时用的是`[eax+4]`，即跳过了对象布局最前面的4字节的虚表指针。

接下来我们看看通过指针进行的虚函数调用`pt->foo();`，产生的汇编代码如下：

```
004230F6  mov         eax,dword ptr [ebp+FFFFF900h]
004230FC  mov         edx,dword ptr [eax]
004230FE  mov         esi,esp
00423100  mov         ecx,dword ptr [ebp+FFFFF900h]
00423106  call        dword ptr [edx]
```

第1行把`pt`指向的地址移入eax寄存器，这样eax中就保存了对象的内存地址，同时也是类的虚表指针的地址。第2行取eax中指针指向的值(注意不是eax的值)到edx寄存器中，实际上也就是虚表的地址。执行完这两条指令后，我们看看eax和edx中的值，果然和我们前面打印的`obj`的虚表信息中的`vpadr`和`vtadr`的值是一样的，分别为`0x0012F824`和`0x0045B314`。第4行同样用ecx寄存器来保存并传递对象地址，即`this`指针的值。第5行的`call`指令，我们可以看到目的地址不象通过对象来调用那样，是一个直接的函数地址。而是将edx中的值做为指针来进行间接调用。前面我们已经知道edx中存放的实际是虚表的地址，我们也知道虚表实际是一个指针数组。这样第5行的调用实际就是取到虚表中的第一个条目的值，即`C041::foo()`函数的地址。如果被调用的虚函数对应的虚表条目的索引不是0，将会看到edx后加上一个索引号乘4后的偏移值。继承跟踪可以发现，`ptr[edx]`的值为`0x0041DF1E`，也和我们打印的`vtival(0)`的值相同。前面已经提到过，这个地址实际也不是真正的函数地址，是一个跳转指令，继续执行就到了真正的函数代码部分(即前面列出的代码)。

我们在上面看到的这个过程，就是动态绑定的过程。因为我们是通过指针来调用虚成员函数，所以会产生动态绑定，即使指针的类型和对象的类型是一样的。为了保证多态的语义，编译器在产生`call`指令时，不象静态绑定时那样，是在编译时决议出一个确定的地址值。相反它是通过用发出调用的指针指向的对象中的虚指针，来迂回的找到对象所对应类型的虚表，及虚表中相应条目中存放的函数地址。这样具体调用哪个函数就与指针的类型是无关的，只与具体的对象相关，因为虚指针是存放在具体的对象中，而虚表只和对象的类型相关。这也就是多态会发生的原因。

请回忆一下前面(第二篇中)讨论过的`C071`类，当子类重写从父类继承的虚函数时，子类的虚表内容的变化，及和父类虚表内容的区别(请参照第二篇中打印的子类和父类的虚表信息)。具体的通过指向子类对象的父类指针来调用被子类重写过的虚函数时的调用过程，请有兴趣的朋友自己调试一下，这里不再列出。

另外前面在第四篇中我们讨论了指针的类型动态转换。我们在这里再利用`C041`、`C042`及`C051`类，来看看指针的类型动态转换。这几个类的定义请参见第三篇。类`C051`从`C041`和`C042`多重继承而来，且后两个类都有虚函数。执行如下代码：

```
C051 obj;
C041 * pt1 = dynamic_cast(&obj);
C042 * pt2 = dynamic_cast(&obj);
pt1->foo();
pt2->foo2();
```

第一个动态转型对应的汇编代码为：

```
00404B59  lea         eax,[ebp+FFFFF8ECh]
00404B5F  mov         dword ptr [ebp+FFFFF8E0h],eax
```

因为不需要调整指针位置，所以很直接，取出对象的地址后直接赋给了指针。

第二个动态转型牵涉到了指针位置的调整，我们来看看它的汇编代码：

```
00404B65  lea         eax,[ebp+FFFFF8ECh]
00404B6B  test        eax,eax
00404B6D  je          00404B7D
00404B6F  lea         ecx,[ebp+FFFFF8F1h]
00404B75  mov         dword ptr [ebp+FFFFF04Ch],ecx
00404B7B  jmp         00404B87
00404B7D  mov         dword ptr [ebp+FFFFF04Ch],0
00404B87  mov         edx,dword ptr [ebp+FFFFF04Ch]
00404B8D  mov         dword ptr [ebp+FFFFF8D4h],edx
```

代码要复杂的多。`&obj`运算后得到的是一个指针，前三行指令就是判断这个指针是否为`NULL`。奇怪的是第4行并没有根据eax中的地址(即对象的起始地址)来进行指针的位置调整，而是直接把`[ebp+FFFFF8F1h]`的地址取到ecx寄存器中。第1行指令中的`[ebp+FFFFF8ECh]`实际是得到对象的地址，ebp所加的那个数实际是个负数(补码)也就是对象的偏移地址。对比两个数发现相差5字节，这样实际上第4行是直接得到了指针调整后的地址，即将指针指向了对象中的属于`C042`的部分。后面的代码又通过一个临时变量及edx寄存器把调整后的指针值最终存到了`pt2`指针中。

这些代码实际可以优化成二行：

```
lea eax, [ebp+FFFFF8F1h]
mov dword ptr [ebp+FFFFF8d4h], eax
```

在第三篇中我们提到`C051`类有两个虚表，相应对象中有也两个虚表指针，之所以不合并为一个，就是为了处理指针的类型动态转换。结合前面对于多态的讨论，我们就可以理解得更清楚了。`pt2->foo2();`调用时，对象的类型还是`C051`，但经过指针动态转换`pt2`指向了对象中属于`C042`的部分的起始，也就是第二个虚表指针。这样在进行函数调用时就不需要再做额外的处理了。我们看看`pt1->foo();`及`pt2->foo2();`产生的汇编码即知。

```
00404B93  mov         eax,dword ptr [ebp+FFFFF8E0h]
00404B99  mov         edx,dword ptr [eax]
00404B9B  mov         esi,esp
00404B9D  mov         ecx,dword ptr [ebp+FFFFF8E0h]
00404BA3  call        dword ptr [edx]
00404BA5  cmp         esi,esp
00404BA7  call        0041DDDE
00404BAC  mov         eax,dword ptr [ebp+FFFFF8D4h]
00404BB2  mov         edx,dword ptr [eax]
00404BB4  mov         esi,esp
00404BB6  mov         ecx,dword ptr [ebp+FFFFF8D4h]
00404BBC  call        dword ptr [edx]
00404BBE  cmp         esi,esp
00404BC0  call        0041DDDE
```

前7行为`pt1->foo();`，后7行为`pt2->foo2();`。唯一不同的是指针指向的地址不同，调用机制是一样的。

(未完待继)
