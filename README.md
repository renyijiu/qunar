# Demo

微博上看到一篇[爬取去哪儿并做简单数据分析](https://github.com/otakurice/notravellist)的文章，感觉挺有意思的，就写了一个demo

简单的多进程，错误重试，当前状态保存，代理IP

## Requirements

1. json
2. redis
3. parallel
4. httparty

## Code

1. request.rb 包装请求函数
2. qunar.rb 主逻辑，包含请求数据，解析数据，存入txt
3. config.rb 编写读取配置
4. main.rb 运行入口文件

## Run

运行redis服务，端口6380

```ruby
ruby main.rb
```
