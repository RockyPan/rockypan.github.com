## object-c的消息调用机制
id returnValue = [receivedObject messageName:parameter];

receivedObject是接收消息的对象，messageName是消息名也叫selector，selector加上相应的parameter才是一个完整的message。

对应的C方法为：
<return_type> Class_selector(id self, SEL_cmd, ...)

每个类的class对象中会存储一个表，表项为，selector名字及对应的真正的c方法的函数指针。

实际调用的是这个方法。
void objc_msgSend(id self, SEL cmd, ...)

上面的调用实际上将被转换为：
id returnValue = objc-msgSend(receivedObject, @selector(messageName:), parameter);

该方法首先在receivedObject的class对象中查找是否有相应的selector，如果找到就调用，如果没有找到，就往上找receivedObject的父类是否有实现相应的selector，找到则调用。如果一直找到根类还是没找到，

为了防止消息发送时的性能损失，由其是向一个实现了很多方法的类或是层次结构很复杂的类发送消息。objc-msgSend会将找到的selector使用快速哈希表进行缓存，每个类一个缓存表。这样除了第一次调用会走一个比较复杂的决议流程，后续的调用不会有太大的性能问题。

objc_msgSend在找到相应的selector的函数地址后，不是用call指令，而是直接跳到相应的方法执行，这样可以降低栈溢出的风险。也意味着我们在消息中打断点，在调用堆栈中不会看到objc_msgSend的身影。（这里要验证一下，最好是能看下相应的汇编代码。)

应该始终用introspection的方法来判断对象的关系，而不是通过判断class方法的返回值是否相等，因为对象本身可能通过一些手段(message forwarding)动态的改变了introspection方法的实现，导致两种方式的结果会不一样。
