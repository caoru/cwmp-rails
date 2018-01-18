class Cpe
  include ActiveModel::Model
   
  attr_accessor :ip, :port, :path, :username, :password, :config, :log
  #validates :command, :parameters, :presence: true

  def initialize()
    @ip = Settings.get["cpe"]["ip"]
    @port = Settings.get["cpe"]["port"]
    @path = Settings.get["cpe"]["path"]
    @username = Settings.get["cpe"]["username"]
    @password = Settings.get["cpe"]["password"]
    @config = Settings.get["cpe"]["config"]
    @log = Settings.get["cpe"]["log"]
  end

  def from_hash(hash)
    hash.each do |k,v|
      self.instance_variable_set("@#{k}", v)
    end
  end

  def full_path
    return "http://" + @ip + ":" + @port.to_s + @path
  end
       
end
