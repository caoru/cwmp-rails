class ApplicationController < ActionController::Base
  include Response
  #include Settings
  protect_from_forgery with: :exception
  COMMANDS = Array.new 
  CPE = Cpe.new
  ACS = Acs.new
  TRXML = Trxml.new
  MESSAGES = Hash.new
end
