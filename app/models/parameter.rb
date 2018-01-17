class Parameter
  include ActiveModel::Model

  attr_accessor :name, :value, :type
  #validates :presence: true
       
  def initialize()
    @name = nil
    @value = nil
    @type = nil
  end

end
