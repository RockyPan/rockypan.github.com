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

看上去比较符合要求。可惜，这个协议在新版本的osx sdk中被废掉了。取而代之的是`NSControlTextEditingDelegate`协议。这个协议中没有上述的方法了，也只能在结束编辑时得到内容改变的通知。

### 方案三 使用Notification

### 方案四 使用KVO

### NSTextField控件的特殊性

NSTextField这个控件比较特殊，它不像NSTextView。它本身只做显示和占位，并不能处理输入。处理输入的总是NSTextView控件。当使用NSTextField