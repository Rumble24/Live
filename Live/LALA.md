## WKWebView
1.https://www.jianshu.com/p/a7d24a872125
2.http://www.cocoachina.com/articles/28999

### 优化白屏的问题
1.主要解决方案就是在 即将白屏的时候我们 调用reload方案
2.webViewWebContentProcessDidTerminate。和判断有没有WKCompositingView


### 优化加载速度的问题
1.使用wkwebview在iOS11.0新出的WKURLSchemeHandler 来拦截经常加载的css/js文件 然后使用本地加载的方式加载文件
2..预加载 我们在app启动的时候先预加载webview
3.使用loadHTMLStr的方式 加载webview

### 优化H5缓存问题
使用 Last-Modified 和 etag 加入到请求头里面 然后 设置请求的缓存 加载本地的请求



## [面试海量数据处理题总结](https://blog.csdn.net/v_july_v/article/details/6279498/)


## 脚本查找项目中无用资源脚本原理

### 查找图片
bundle 、 主项目中 、 Assets.xcassets
bundle 一般不清理
主项目中 遍历项目中除了Assets.xcassets，Pods，.bundle的文件即可，查找到扩展名为png、jpg、jepg等文件保存下来即可
Assets.xcassets Assets.xcassets中的图片图片获取需要注意，实际文件图片名和Assets.xcassets中名字可能不一样，图片资源加到Assets.xcassets是可以修改名称的，实际使用的是Assets.xcassets中的名称

记得取得是imageset结尾的文件名
imageName去项目.h、.m、.xib、.storyboard、.swift中去找，匹配到相关的字符串我们认为该图片用到了

### 查找没有用的类 
主要是取到所有的类 然后 取到import的类。然后我们取他们的差值


