# LIVE --> 路线 转码H264必须是YUV格式

AVFunction
VideoToolBox：https://blog.csdn.net/ruoxinliu/article/details/53765041
AudioToolBox:IOS使用AudioToolbox实现音频编解码:https://www.jianshu.com/p/27df093f0e2e
ffmpeg
GPUImage / OpenGL / GLKit / 

ffmpeg在不同系统中的安装与简单裁剪
音频基础知识，如频率、采样大小和通道数等
音频的压缩原理
如何从不同的设备上采集音频数据
如何对音频进行不同的编解码
视频的基础知识
H264编码原理
如何从不同设备上采集视频数据
熟悉YUV的一些常见格式（YUV420、NV21，YV12的不同）
如何将YUV数据编码为H264/H265、VP8/VP9等。    
FLV/RTMP/HLS/MP4协议要十分清楚

# 学习

1.[研发直播APP的收获-iOS](https://www.jianshu.com/p/d99e83cab39a)
2.[基于LFLiveKit的直播项目](https://www.jianshu.com/p/b397867367dd)
3.[最简单的iOS直播推流](https://www.jianshu.com/p/30b82f1e61a9)
4.[音视频已强势崛起，我们该如何快速入门音视频技术？](https://zhuanlan.zhihu.com/p/122578544)
5.[本地rtmp服务](https://www.cnblogs.com/yajunLi/p/6412821.html) 
6.[1小时学会：最简单的iOS直播推流](https://www.jianshu.com/p/30b82f1e61a9)
7.[ios实现H264裸流封装为FLV格式](https://blog.csdn.net/tiberx/article/details/42025907)

# 推流
视频捕获：系统方法捕获，GPUImage捕获，CMSampleRef解析
美颜滤镜：GPUImage，
视频变换：libyuv
软编码：faac，x264
硬编码：VideoToolbox(aac/h264)
libaw：C语言函数库
flv协议及编码  然后将aac和h264音视频帧合成flv格式
推流协议：librtmp，rtmp重连，rtmp各种状态回调




# 拉流
brew tap denji/homebrew-nginx

brew install nginx-full --with-rtmp-module

nginx

brew install ffmpeg


修改：nginx.conf

添加
rtmp {
    server {
        listen 1935;
        application rtmplive {
            live on;
            max_connections 1024;
        }
        application hls{
            live on;
            hls on;
            hls_path /usr/local/var/www/hls;
            hls_fragment 1s;
        }
    }
}

重启：nginx -s reload
VLC安装测试拉流
百度搜索VCL
file  文件夹下面 点击：openNetwork 

需要关闭防火墙











