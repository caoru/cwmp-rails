class Acs
  include ActiveModel::Model
   
  attr_accessor :name, :username, :password, :firmware_prefix, :default_model
  #validates :command, :parameters, :presence: true

  def initialize()
    @name = Settings.get["acs"]["name"]
    @username = Settings.get["acs"]["username"]
    @password = Settings.get["acs"]["password"]
    @firmware_prefix = Settings.get["acs"]["firmware_prefix"]
    @default_model = Settings.get["acs"]["default_model"]
  end

  def from_hash(hash)
    hash.each do |k,v|
      self.instance_variable_set("@#{k}", v)
    end
  end

  def users
    return { @username => @password }
  end

end
