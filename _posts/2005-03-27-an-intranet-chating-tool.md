---
layout: post
title: 一个在局域网内聊天传输文件的工具源码
category: 技术
tags: [C++, 网络]
keywords: C++, 网络编程, 聊天工具, 局域网, 源代码
---

## 一个在局域网内聊天传输文件的工具源码

开发这个小软件的最初目的是为了同事间的联络。以前公司内部可以用"企业QQ"，后来不知何故不让用了。结果让大家很不方便，有时一些工作上的讨论，通过邮件太慢，面对面跑去问效率太低。所以我就想写一个工具，让大家可以方便沟通。

关键是要避免使用服务器，一是对于做为服务器的机器，如果比较耗资源，会影响工作，就没人愿意做服务器。另外服务器一死了，大家都没得用。所以就做了个点对点的。只是没有专门的服务器，有些功能实现起来还是比较麻烦的。

因为本来是想内部用的，所以有很多功能都写得比较死。比如一些配置信息：用于广播的地址我是写死在代码中的（我用的是子网地址，不清楚的可以改为255.255.255.255），TCP和UDP的端口也都是写死在代码中的（不过都在单一的地方定义，比较好改）。发信息用的是UDP协议，没有做确认机制，因为在局域网内几乎不会掉包。收发文件用的是TCP协议。大部分功能在家里开发，家里只有两台电脑，调试很不方便，所以可能还有一些BUG。

本想自己写一个漂亮点的显示消息的控件，加上多格式字体和贴图支持。只是最近比较忙，所以一直没做。

本来是想写得很简单，后来慢慢的加了些功能，所以结构并不是很合理。

代码是在win2k/winxp+VC7.1下写的，应该在VC6下也可以编译，不过我没有试过。 有一定的注释和说明，代码的可读性比较强。

主要功能：

1. 可以进行群聊。
2. 点中名字前的复选框要以说消消话。
3. 可以群发文件，可以发给指定的人（选中复选框），也可以发给所有人。
4. 选中某人，点"blacklist"可以将它加到黑名单中。此人的所有发言及发文件将被单向滤掉。但他前不知道。选中黑名单中的人，点击"blacklist"，可以将此人从黑名单中去掉。
5. 支持在线改名。名字冲突时后起名的需要改名。
6. 支持和QQ一样的表情系统。
7. 按上slt+shift+z可以将程序呼出。
8. 所有聊天记录自动保存在"history.dat"文件中。
9. 当探测到局域网内有更高版本时，会自动提醒升级。

其他更多的说明，及工作原理，消息结构等请见源码名中的相应文档。

> 评论人：PK 2007-08-17 19:40:09 呵呵！我正准备在近期把这个软件用ACE重写一遍了。

> 评论人：www_119_119 2007-08-16 22:47:51 谢谢，问题已经全部解决了，正在学习代码中。 再次感谢！

> 评论人：www_119_119 2007-08-16 22:19:00 谢谢你有时间帮助我，这个问题我已经解决了。 我的版本是Version 7.1.3091 WTL的版本是WTL8.0 但是我又碰到了一个新的问题。 
```
------ 已启动生成: 项目: NetTalkN, 配置: Debug Win32 ------ 
。。。。和vchelp上derke一样的警告（省略了）。。。。。。。。。 
正在生成代码... 
正在链接... 
LINK : warning LNK4075: 忽略“/EDITANDCONTINUE”(由于“/INCREMENTAL:NO”规范) 
LINK : warning LNK4199: 已忽略 /DELAYLOAD:OleAcc.dll；未找到来自 OleAcc.dll 的导入 
maindlg.obj : error LNK2019: 无法解析的外部符号 __imp__GetSaveFileNameA@4 ，该符号在函数 "public: int __thiscall WTL::CFileDialogImpl〈class WTL::CFileDialog〉::DoModal(struct HWND__ *)" (?DoModal@?$CFileDialogImpl@VCFileDialog@WTL@@@WTL@@QAEHPAUHWND__@@@Z) 中被引用 
maindlg.obj : error LNK2019: 无法解析的外部符号 __imp__GetOpenFileNameA@4 ，该符号在函数 "public: int __thiscall WTL::CFileDialogImpl〈class WTL::CFileDialog〉::DoModal(struct HWND__ *)" (?DoModal@?$CFileDialogImpl@VCFileDialog@WTL@@@WTL@@QAEHPAUHWND__@@@Z) 中被引用 
.\Debug/NetTalkN.exe : 
fatal error LNK1120: 2 个无法解析的外部命令 NetTalkN 
- 3 错误，6 警告 生成: 0 已成功, 1 已失败, 0 已跳过
``` 
感觉好像是包含文件的问题，呵呵，还在找办法。 再次谢谢。 

> 评论人：PK 2007-08-16 21:26:56 我没有碰到过这个问题，但根据错误提示应该是包含的文件不对。可能是包含的WTL的版本有问题，你用的是什么编译环境及WTL版本？

> 评论人：www_119_119 2007-08-16 20:50:01 你好： 我想问一下，我编译的时候怎么报这个错，我正在找原因。 
```
------ 已启动生成: 项目: NetTalkN, 配置: Debug Win32 ------ 
正在编译... 
maindlg.CPP e:\VC Project\NetChat\maindlg.h(81) : 
error C2660: “CMainDlg::OnTimer” : 函数不接受 1 个参数 main.cpp e:\VC Project\NetChat\maindlg.h(81) : 
error C2660: “CMainDlg::OnTimer” : 函数不接受 1 个参数 aboutdlg.cpp e:\VC Project\NetChat\maindlg.h(81) : 
error C2660: “CMainDlg::OnTimer” : 函数不接受 1 个参数 
正在生成代码... 生成日志保存在“file://e:\VC Project\NetChat\Debug\BuildLog.htm”中 NetTalkN 
- 3 错误，0 警告 
---------------------- 完成 --------------------- 
生成: 0 已成功, 1 已失败, 0 已跳过 
```
如果你有时间赐教的话，我的邮箱www_119_119@163.ccom qq 64423306

> 评论人：潘畅 2005-10-12 09:17:37 凯,我今天上过您的博客网了. 我真喜欢读那些关于崽崽的文章,写得文笔流畅优美自然.我还是最喜欢看您写的东西. 我想复制这些文章,发到宝宝网站,或留下您的博客网址,您介意吗? 

> 评论人：PK 2005-04-09 22:16:43 还下到的话，请访问这个网址： http://www.vchelp.net/itbookreview/view_paper.asp?paper_id=1389

> 评论人：匿名网友 2005-04-03 23:30:20 blogchina好像有些问题，附件down不下来，能法一份到我邮箱里吗？谢谢