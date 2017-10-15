class Config

  # 获取城市列表信息
  def get_cities
    cities = []
  
    File.open('./config/city.txt', 'r') do |f|
      data = f.read
      cities = data.split
    end
  
    return cities
  end

end