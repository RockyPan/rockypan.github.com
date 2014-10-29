---
layout: post
title: 监听NSTextField控件值的改变
category: 技术
tags: [ios&osx]
keywords: ios开发, KVO, 控件监听, NSTextField, NSTextView
---

## 监听`NSTextField`控件值的改变

### 背景

想实现的功能很简单，就是想监听界面中某一个`NSTextField`控件内容的改变。需要是实时的监听，而不是编辑完后按回车或焦点改变时才得到通知。

本来以为很简单的事，结果还是费了一些周折，因此把过程中用过的方案和学到的东西记下来。



### 方案一 使用Action机制

直接添加一个Action方法

```
- (IBAction)text1Changing:(id)sender;

- (IBAction)text1Changing:(id)sender {
    NSTextField * tf = (NSTextField *)sender;
    NSLog(@"text1: %@", [tf stringValue]);
}
```

然后把控件的`Connection`面板的`Sent Actions`项中的`Selector`关联到这个方法就OK了。

但这个方法只有在结束输入的时候才会触发。我想在输入的同时不停的得到改变值就不行。

另：上述方法缺省是在`NSTextField`控件中输入`enter`键时触发，如果希望在控件失入焦点时也触发，在控件的`Attributes`面板中将`Action`选项的内容改为`Sent On End Editing`即可。

### 方案二 使用Delegate

本来在`NSTextFieldDelegate`协议中有个方法

```
- (void)textDidChange:(NSNotification *)aNotification
```

看上去比较符合要求。可惜，这个协议在新版本的osx sdk中被废掉了。取而代之的是`NSControlTextEditingDelegate`协议。这个协议中没有上述的方法了，也就只能在结束编辑时得到内容改变的通知。

### 方案三 使用Notification

使用这个方案要注意一点，`NSTextField`控件是没有通知的，发出通知的实际是`NSTextView`控件。具体请参考后文[`NSTextField`控件的特殊性](#SPECIFICITY_TEXTFIELD)部分的说明。

首先在接口文件中声明两个`NSTextField`的属性。

``` 
@property (weak) IBOutlet NSTextField *text3;
@property (weak) IBOutlet NSTextField *text4;
```

然后在实现文件中，先进行通知处理的注册，后面是通知的处理代码。

```
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:NSTextDidChangeNotification object:nil];
    // [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:NSTextDidChangeNotification object:self.text3];
}

- (void) textChanged:(NSNotification *) notification {

    NSLog(@"invoke textChanged:");

    if ([[notification object] delegate] == self.text3) {
        NSLog(@"text3 changed: %@", [self.text3 stringValue]);
        self.text4.stringValue = self.text3.stringValue;
    }
}
```

如果我们只关心`text3`控件内容的变化，最方便的方法是在调用`[addObserver:selector:name:object:]`方法进行注册时，将最后的`object`参数指定为`text3`，就像注释掉的那行那样。让通知中心来替我们做过滤。但可惜真正触发通知的控件并不是`NSTextField`，所以这个方法行不通，只能在通知处理方法中进行判断来过滤。具体原因见[`NSTextField`控件的特殊性](#SPECIFICITY_TEXTFIELD)。

另外通过`NSTextField`控件的`stringValue`属性来改变它的内容，不会触发上述的通知。原因很简单，因为根本没有通过`NSTextView`控件。

### 方案四 使用KVO



### <a name="SPECIFICITY_TEXTFIELD" id="SPECIFICITY_TEXTFIELD">`NSTextField`控件的特殊性</a>

`NSTextField`这个控件比较特殊，它不像`NSTextView`。它本身只做显示和占位，并不能处理输入。处理输入的总是`NSTextView`控件。

官文档的`NSWindow`部分有说到这个。每个`window`有一个叫`field editor`的属性，实际上它是一个`NSTextView`，它会按需创建，被`window`上的所有轻量输入控件所共享，用来处理文字输入。这些控件就包括`NSTextField`，`NSTextFieldCell`等。

也就是说当`window`上的某一个`NSTextField`控件得到焦点时，实际上是把一个公用的`NSTextView`控件摆到了相应的`NSTextField`控件所在的位置，输入全部发生在`NSTextView`控件中。同时在`NSTextView`被激活用于输入时，会把对应的`NSTextField`对象设置为它的`delegate`。当输入完成，失去焦点时，`NSTextView`控件功成身退被隐藏起来，刚输入的文字则传给相应的`NSTextField`控件，它负责具体的显示。

这就是为什么方案三中注册观察器时不能设置最后那个`object`参数。把`NSTextField`对象设进去肯定没用，因为通知根本不是由它产生的。在那个时间点也得不到`window`的`field editor`，因为它是按需创建的。这也是为什么方案三中要通过`[[notification object] delegate] == self.text3`，来判断通知的来源。



