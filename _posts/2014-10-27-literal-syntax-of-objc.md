---
layout: post
title: object-c 字符常量运用
category: 技术
tags: [objc, iOS, OSX]
keywords: object-c, 字符常量, Literal Syntax
---

## object-c 字符常量运用

“语法笨重，代码拖沓冗长”，一直是object-c被人诟病的地方。创建常用的Foundation对象时，使用字符常量来代替方法调用的方式可以大大的精简代码，增强可读性。甚至更加安全（后面会提到）。本文根据《Effective Object-C 2.0 - 52 Specific Ways to Improve Your iOS and OS X Programs》中第三条整理而成，留做参考。

### 普通常量构造

这部分没啥好说的，直接看代码：

```
NSString *someString = @"Effective Objective-C 2.0";

NSNumber *intNumber = @1;
NSNumber *floatNumber = @2.5f; 
NSNumber *doubleNumber = @3.14159; 
NSNumber *boolNumber = @YES; 
NSNumber *charNumber = @'a';
NSNumber *expressionNumber = @(5 * 6.32f);￼
```

值得注意的是最后一行，通过表达式来创建。

### 数组`NSArray`

先看例子：

```
NSArray *animals = @[@"cat", @"dog", @"mouse", @"badger"];
```

所有字符常量写法只是语法糖而已，也就是说编译器在编译时还是会把它们转换成对相应的初始化方法的调用，因此如果有错误发生，无论是编译时或运行时，看到的错误信息是相应的初始化方法的信息，这点不要感到意外，在后面的出错信息中可以看到。

另外，前面为什么说常量方式有时更安全？看下面的例子：

```
id object1 = /* ... */; 
id object2 = /* ... */; 
id object3 = /* ... */;

NSArray *arrayA = [NSArray arrayWithObjects: object1, object2, object3, nil];
NSArray *arrayB = @[object1, object2, object3];
```

如果上面的`object2`的值为`nil`，那么`arrayB`在构造时会抛出异常，`arrayA`会成功构造，但只包含一个元素，即`object1`。因为碰到`nil`时它就会忽略后面的参数提前结束初始化。

根据”速错理论“，代码中只要有错误就应该让它尽快显式的出错，这样修复它的成本是最低的。像上述的arrayA创建，少了二个元素但是成功的初始化了，这种到后面可能导致程序出现错误，而且查错的成本会非常高。

`arrayB`初始化抛出的异常。

```
*** Terminating app due to uncaught exception 
'NSInvalidArgumentException', reason: '*** 
-[__NSPlaceholderArray initWithObjects:count:]: attempt to insert nil object from objects[0]'
```

从`arrayB`构造时抛出的异常我们可以看出，它实际调用的是[initWithOjbects:count:]方法，因为是带count的版本，所以比`arrayA`更安全。

### 字典`NSDictionary`

同样看例子：

```
NSDictionary *personData = @{@"firstName" : @"Matt",
                              @"lastName" : @"Galloway", 
                                   @"age" : @28};
```

要注意的地方和`NSArray`一样。

另外“键-值对”的写法是：key:value，而在初始化方法中是：value:key。显然常量写法中使用的“键-值对”顺序更符合直觉。不知道为什么会设计成这个样子。

### Mutable版本

常量方式创建出来的对象显然都是不变量，如果你需要的就是可变版本，那没办法，自己加一个`[mutableCopy]`调用。

```
SMutableArray *mutable = [@[@1, @2, @3, @4, @5] mutableCopy];
```

只是这样比直接创建多了一个临时变量和相应的初始化方法调用。只要不是用在性能热点的地方，还是建议上述的方法，更可读。
