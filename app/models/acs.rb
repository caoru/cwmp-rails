class Acs
  include ActiveModel::Model
   
  attr_accessor :name, :username, :password
  #validates :command, :parameters, :presence: true

  def initialize()
    @name = Settings.get["acs"]["name"]
    @username = Settings.get["acs"]["username"]
    @password = Settings.get["acs"]["password"]
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
