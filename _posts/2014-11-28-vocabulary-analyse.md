---
layout: post
title: 统计单词频率的工具
category: 技术
tags: [其他]
keywords: 英语学习, shell脚本, 阅读, 单词
---

## 统计单词频率的工具

### 英文小说词汇分析

阅读英文小说的一大障碍就是词汇量。但是在读某一本小说时，除掉非常普通的常用单词外，出于作者的用词习惯，小说的特定类型，有些词在小说中出现的频率会非常的高。这些词可以认为是这本小说的核心词汇。如果能把这些核心词汇事先掌握，那么读这本小说的时候会轻松得多。好过碰到一个生字就记一个生字，很多人包括我自己以前就是这么干的。

我以《傲慢与偏见》的英文版小说为例。小说是我在网上下载的，不同版本的字数可能会不一样。

```
$ wc pride.txt
   12116  121887  697943 pride.txt

$ cat pride.txt | tr -cs A-Za-z '\n' | tr A-Z a-z | wc
  122736  122736  658618
```

`wc`统计得到全书共121887个单词。但为了计算统一，我们取第二方式得到的122736个单词。差别在于第二方式下：`I'm`、`don't`这种会被拆开算成两个单词，还有`good-looking`这类合成词，所以算出的单词数会比直接用`wc`要多一些。

```
$ cat pride.txt | tr -cs A-Za-z '\n' | tr A-Z a-z | sort | uniq | wc
    6288    6288   53496
```

通过上面的命令得到小说中使用的单词数为6288个。

```
$ cat pride.txt | tr -cs A-Za-z '\n' | tr A-Z a-z | sort | uniq -c | awk '{ if ($1 >= 5) {++count; total += $1 } } END { printf("count:%d total:%d\n", count, total) }'
count:2042 total:115327
```

上面的命令统计了出现次数大于5的单词的个数为2042个，这些单词共出现了115327次。`115327/122736*100%＝93.96%`，这2042个单词就占到了全书的差不多94%。

另外这2042个单词中还有很多是很常见的高频词，像`is`、`a`、`the`、等等。我自已维护了一个高频单词表，凡是我已经100%掌握的单词，我就放到这个表中。如果我再用这个单词表过滤一遍。最终剩下大概300多个单词。

这样我可以先有针对性的记一下这300来个单词，再看小说时就会顺畅的多，不会时不时被查生词打断。虽然用kindle或是pad可以方便的在阅读时查看生词。但不管怎么方便都会破坏深度沉浸阅读的体验。所以能事先掌握小说中高频词是最好的选择。

---

### 工具实现

我把这个功能利用shell脚本写了个工具，有兴趣的可以到[这里](https://github.com/RockyPan/vocabulary_analyse)下载。我是在mac上写的，linux下通用，windows下就要另想办法了。

一共是三个文件，其中两个是脚本。`ignores.txt`是已经掌握的单词列表文件。我上传了一个我自己的，你可以删掉，自己用后面提到的脚本弄一个适合自己的。

使用时用以下命令：

```
./word_list.sh proide.txt words.txt
```

第一个参数是输入文件，即待分析的小说文件，必须是纯文本文件。第二个参数是输出的单词列表文件。第二个参数可忽略，忽略后会使用输入文件后加`.wlist`后缀为输出文件名。

脚本在分析时会将在`ignores.txt`文件列出的单词忽略掉。你可以根据自己的情况将自己已经熟知的单词加入到`ignores.txt`文件中。使用`add_ignores.sh`脚本可以方便的往`ignores.txt`文件中添加单词。使用时直接将单词列表做为参数即可：

```
./add_ignores.sh the my is am a an do does did
```

单词列表能接受多长和系统环境有关，我没试过极限，一般一次加几十个没出过问题。添加的单词会自动去重不用担心重复添加。

---

一般的经典英文小说都可以在网上找到纯文本的电子文档。就算找不到，也可以用工具从PDF、epub、mobi文件中导出来。可以先用这种方式把核心词汇表导出来，然后该用kindle就用kindle看，该用pad就用pad看。

---

### 缺陷

同一个单词的不同形态被算成了不同的单词，比如动词的过去式，第三人称单数，不同时态，名词的复数，等等。这样造成一些词的权重被分散了。这个问题，后续有时间了加一段脚本来解决。

### 后续功能

还有个比较有用的功能就是把一些规则的词性变化的单词归拢起来放到一起。比较加了后缀-tion，-ly，-or，-er等的，这种归到一起更加方便有针对性的分析和学习。

这个功能放到后面实现吧。
