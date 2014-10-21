---
layout: post
title: 监听NSTextField控件值的改变
category: 技术
tags: [ios&osx]
keywords: ios开发, KVO, 控件监听
---

## 监听`NSTextField`控件值的改变

### 背景

想实现的功能很简单，当一个`NSTextField`控件的内容改变时设置`Button`的状态，同时会设置另一个`TextField`控件的内容。

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

### 方案二 