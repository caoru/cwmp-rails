class Command
  include ActiveModel::Model
   
  attr_accessor :method, :requestId, :parameters
  #validates :command, :parameters, :presence: true

  def initialize()
    @method = nil
    @requestId = nil
    @parameters = []
  end

  def clear
    @method = nil
    @requestId = nil
    @parameters.clear
  end
       
end
