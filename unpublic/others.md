
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


