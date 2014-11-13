
## 未归类杂项

### switch语句中慎用default子句

如果用switch来处理一个状态机，case子句是枚举值。则不要用default子句。没有default子句时，当在枚举中加入新值，又忘记增加相应的case分支时，compiler一般会产生一个warning，指出并不是所有的枚举值都被处理了。

利用这个特性可以防止在新增状态时漏掉相应的处理分支。尤其是状态定义和处理分支散布在不同的地方。

### object-c 属性property

如果不希望compiler生成相应的accessor和变量，可以用@dynamic关键字。比如属性的值是动态生成的时比较有用，NSManagedObject使用了这个技术。

#### 属性的内存管理

1. assign 
   用于非object-c对象的赋值。通常用于一些C结构体什么的。基本上就是直接的赋值语句。
2. strong
   表达强拥有关系。老对象会被release，新对象会被retain。
3. weak
   表达弱引用关系。赋值时老对象不会被release，新对象也不会被retain。表面看有点像assign，区别在于weak针对的是object-c对象，而且当相应的对象失效后，属性的值会被置nil。相当的安全。
4. unsafe_unretained
   语义上和assign相同，但用一般用在对象指针上。和weak的区别是，指针指向的对象失效后不会被置nil，相当于产生一个野指针，所以是不安全的。
5. copy
   复制对象，防止在赋值后对象的内容被改变。一般从用于NSString对象。

#### MarkDown的一些补充

有几个特性MarkDown不支持，用到了还真不方便。但是可以自己写html标签来扩展。比如：

1. 文字剧中
   Jekyll会让生成的图片居中，但图片的说明文字不能居中，页面比较宽时很丑。可以直接在文字前后加`<center>`标签来让文字居中。
2. 页面内跳转引用
   在写比较长的文章时这个会很有用。先在要锚定的文字前后加标签`<a name="md-anchor" id="md-anchor"></a>`，在要跳转的地方就可以直接用MarkDown的链接方式`[文内链接](#md-anchor)`。

#### others

使用`isEqualToString:`方法比`isEqual:`要快，因为后者还要先判断参数的类型是否是NSString。

---

如果要对对象进行比较，要重载`isEqual:`和`hash`两个方法。对于`isEqual:`返回YES的两个对象它们的hash方法返回的值必须相同。但是hash相同的对象不一定要相等。

hash函数的性能不能太差，将对象添加到集合对象时，hash方法会被频繁的调用，比较容易出现性能问题。

designated initializer
只有designated initializer可以访问内部的数据，这样当需要修改内部数据的形式，或是修改对内部数据的访问时，只需要更改一个地方。其他的initializer方法都调用designated initializer。
在继承体系中要保证designated initializer的调用链，即子类的designated initializer调用父类的designated initializer。
如果子类的designated initializer和父类的designated initializer不同名，子类一般需要重载父类的designated initializer并做相应的适配处理。

需要查看UI控件的层次结构时可以用以下命令打印出view上的UI控件的层次结构：
po [self.view recursiveDescription]


由于objc的动态特性，实际上是没有所谓的私有方法。因此类中的私有方法最好加个前缀进行区分，方便代码的阅读和调度。但是千万注意不要直接用单下划线做前缀，因为这个命名法被ios的sdk使用了。如果用单下划线做前缀来写私有方法，很容易和框架的基类中的私有方法冲突，覆盖掉父类的私有方法。而且这种总是很难查出来。

ARC缺省不是异常安全的，这意味着在异常发生时，相应的代码块内的对象不会被正确的调用release。通过添加编译选项-fobjc-arc-exceptions，可以做到异常安全，但是要付出性能上的代价，即使并没有异常发生。所以这个选项默认是关闭的。

一般只有在有无法挽回，不能继续运行的错误出现时才主动的抛出异常。否则应该通过返回nil或错误码，或者是NSError对象来反馈出错信息。NSError包含三个信息，Error domain，错误分类；Error code，该分类下的错误码；及一个dictionary，包含更多的出错描述信息。一般来说将错误信息传到delegate中时多用NSError对象。

要自定义copy的语义，不要重载copy方法，而应该实现NSCopying协议。
如果对象有mutable和immutable两个版本除了NSCopying还要实现NSMutableCopying协议。
copy协议中的拷贝行为默认是浅拷贝，如果要实现深拷贝，自己在接口中添加相应的方法。

一般在处理标志位逻辑的做法是，申明枚举常量来定义标志位，然后用一个无符号整数来存放标志位数据，使用时通过位运算来进行对比检测。
更好的做法是使用以下方法：
struct {
    unsigned int flagA : 1 ;
    unsigned int flagB : 1 ;
    unsigned int flagC : 1 ;
    unsigned int flagD : 1 ;
} XXX_Status;

category中的方法名一定要加上一个独特的前缀。runtime在加载时会将所有category中的方法加入到相应的class对象的方法列表中，因此category中的同名方法会覆盖主类中的方法，不同category中的同名方法全部会被最后一个加载的category中的方法覆盖。而且这种问题特别难查。

在interface中定义成readonly的property，可以在class-continuation category中重新定义成read-write。这样对外是只读的，对内是读写的。这种方式相对于在内部直接访问低层数据的好处是，可以触发KVO。




