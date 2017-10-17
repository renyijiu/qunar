require 'json'
require 'parallel'
require 'redis'

require './request.rb'
require './config.rb'

# TODO: 增加redis，保存状态，断点继续机制

class Qunar
  def initialize
    @redis = Redis.new(host: "127.0.0.1", port: 6380, db: 15)
  end

  def spider
    visited_cities = JSON.parse(@redis.get('visited_cities') || '[]') # [], 获取已经爬取过的城市列表
    puts "当前已经访问过的城市： #{visited_cities}"
    
    # 获取城市列表
    config = Config.new
    cities = config.get_cities - visited_cities

    base_url = "http://piao.qunar.com/ticket/list.json?from=mpl_search_suggest"

    # 4进程运行程序
    Parallel.map(cities, in_processes: 4) do |city|
      current_worker = Parallel.worker_number
      his_status = JSON.parse(@redis.get(current_worker) || '{}') # {city => page},保存的历史状态

      page = his_status.fetch(city, 1)
      flag = 1

      while true
        url = URI.encode("#{base_url}&page=#{page}&keyword=#{city}")
        puts "当前URL： #{url}"

        begin
          res = get_list(url)
          puts "记录状态： #{res}"

          unless res || page <= 50 # 只取前50页数据
            record_visited(city)
            his_status.delete(city)

            break
          end
          puts "当前页数：#{page}"          
          puts "数据写入成功..."

          sleep rand(50)
        rescue => e
          puts "错误信息： #{e}"

          if flag <= 3
            puts "第#{flag}次重试..."
            sleep(10 * flag)            
            
            flag += 1
            retry
          end
        end
        
        page += 1        
        flag = 1

        # 保存当前状态
        his_status[city] = page
        @redis.set(current_worker, his_status.to_json)
      end
    end

    puts "结束..."
  end


  private

  def format_data(data)
    name = data.fetch("sightName", "")
    points = data.fetch("point", "0, 0").split(",").map(&:to_f)
    sale_counts = data.fetch("saleCount", 0)

    return nil if sale_counts < 500

    {
      name: name,
      value: [points, sale_counts].flatten
    }
  end

  def get_list(url)
    custom = Custom.new
    
    begin
      # data = custom.get_with_proxy(url)
      data = custom.get(url)
      res = JSON.parse(data.body)
      return false if res.empty?

      write_tag = write_file(res)
      return false unless write_tag
    rescue => e
      puts "当前数据：#{data || ""}, 错误信息: #{e}"

      raise "出现错误"
    end

    true
  end

  def write_file(res)
    list = res.dig("data", "sightList")
    return false if list.empty?

    File.open('./data/data.txt', 'a+') do |f|
      list.each do |sight|
        data = format_data(sight)

        next unless data
        puts "当前数据： #{data}"

        f.puts data.to_json
      end
    end

    true
  end

  def record_visited(city)
    cities = JSON.parse(@redis.get('visited_cities') || '[]')

    cities += [city]
    @redis.set('visited_cities', cities.to_json)
  end

end
