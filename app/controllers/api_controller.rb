require 'socket'

class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate, only: [:download_file, :upload_file]

  def get_token
    token = random_token = SecureRandom.urlsafe_base64(nil, false)

    json_response({ :token => token })
  end

  def get_url
    url = ""

    ip = Socket.ip_address_list.detect{|intf| intf.ipv4_private?}

    if ip
      address = ip.ip_address
    else
      address = host
    end

    operation = params[:operation]
    type = params[:type]

    if operation == "upload"
      url = request.protocol + address.to_s + ":" + request.server_port.to_s + "/" + operation + "/" + type
    else
      if type == "firmware"
        records = Dir.glob(CPE.firmware + "/Oi*.img")
        url = request.protocol + address + ":" + request.server_port.to_s + "/" +
              operation + "/" + type + "/" + records[0].to_s.gsub(CPE.firmware + "/", "")
      elsif type == "config"
        url = request.protocol + address + ":" + request.server_port.to_s + "/" +
              operation + "/" + type + "/" + CPE.ip + ".xml"
      end
    end
    
    json_response({ :result => "true", :url => url })
  end

  def download_file
    type = params[:type]
    name = params[:name]
    full_name = CPE.file_root + "/" + type + "/" + name

    unless File.file?(full_name)
      head 404
      return
    end

    send_file full_name
  end

  def upload_file
    type = params[:type]
    content_length = request.headers["Content-Length"].to_i
    remote_ip = request.remote_ip
    write_length = 0

    if type == "config"
      file_name = Rails.root.join(CPE.config, remote_ip + ".xml")
      FileUtils::mkdir_p CPE.config unless Dir.exist?(CPE.config)
    elsif type == "log"
      file_name = Rails.root.join(CPE.log, remote_ip + ".log")
      FileUtils::mkdir_p CPE.log unless Dir.exist?(CPE.log)
    end

    File.open(file_name, 'w') do |f|
      write_length += f.write request.raw_post
    end

    if content_length == write_length
      head 200
    else
      head 500
    end
  end

  def get_settings
    json_response({ :result => "true", :cpe => CPE.instance_values, :acs => ACS.instance_values })
  end

  def put_settings
    CPE.from_hash params[:cpe].instance_values["parameters"]
    ACS.from_hash params[:acs].instance_values["parameters"]

    Settings.get["cpe"] = CPE.instance_values
    Settings.get["acs"] = ACS.instance_values
    Settings.save

    json_response({ :result => "true", :cpe => CPE.instance_values, :acs => ACS.instance_values })
  end

  def get_cpe
    json_response({ :result => "true", :cpe => CPE.instance_values })
  end

  def put_cpe
    CPE.from_hash params[:cpe].instance_values["parameters"]
    Settings.get["cpe"] = CPE.instance_values
    Settings.save

    json_response({ :result => "true", :cpe => CPE.instance_values })
  end

  def get_acs
    json_response({ :result => "true", :acs => ACS.instance_values })
  end

  def put_acs
    ACS.from_hash params[:acs].instance_values["parameters"]
    Settings.get["acs"] = CPE.instance_values
    Settings.save

    json_response({ :result => "true", :acs => ACS.instance_values })
  end

  def get_model
    if params[:tr].nil?
      head 204, content_type: "text/html"
      return
    end

    tree = TRXML.models[params[:tr]]
    json_response(tree)
  end

  def get_values
    request_cpe("GetParameterValues", params)
  end

  def set_values
    request_cpe("SetParameterValues", params)
  end

  def get_names
    request_cpe("GetParameterNames", params)
  end

  def get_attributes
    request_cpe("GetParameterAttributes", params)
  end

  def set_attributes
    request_cpe("SetParameterAttributes", params)
  end

  def add_object
    request_cpe("AddObject", params)
  end

  def delete_object
    request_cpe("DeleteObject", params)
  end

  def get_rpc_method
    request_cpe("GetRPCMethods", params)
  end

  def get_all_queued_transfers
    request_cpe("GetAllQueuedTransfers", params)
  end

  def reboot
    request_cpe("Reboot", params)
  end

  def factory_reset
    request_cpe("FactoryReset", params)
  end

  def post_download
    request_cpe("Download", params)
  end

  def post_upload
    request_cpe("Upload", params)
  end

  def get_message
    epoch = params[:epoch]
    message = MESSAGES[epoch.to_f]

    respond_to do |format|
      format.html
      format.json do
        json_response({ :result => "true", :xml => message.xml })
        return
      end
      format.xml do
        unless message.nil?
          render xml: message.xml
          return
        end
      end
    end

    render html: "Can't found message"
  end

  def get_messages
    response = { :result => "true" }
    messages = []
    MESSAGES.each do |key, value|
      message = {}
      message[:id] = value.id
      message[:received] = value.received
      message[:epoch] = value.epoch
      message[:ip] = value.ip
      message[:oui] = value.oui
      message[:class] = value.class
      message[:serial] = value.serial
      message[:events] = value.events
      message[:method] = value.method
      message[:direction] = value.direction

      if value.method == "Inform"
        message[:string] = 
          sprintf("<span class=\"ctoa\">C->A</span> <span class=\"timestamp\">%s</span> <span class=\"ip\">%s</span> <span class=\"cwmpid\">ID: %s</span> <span class=\"identity\">%s-%s-%s</span> Event: %s <span class=\"method\">Inform</span>",
                  value.received,
                  value.ip,
                  value.id,
                  value.oui,
                  value.class,
                  value.serial,
                  value.events)
      elsif value.direction == "ctoa"
        message[:string] = 
          sprintf("<span class=\"ctoa\">C->A</span> <span class=\"timestamp\">%s</span> <span class=\"ip\">%s</span> <span class=\"cwmpid\">ID: %s</span> <span class=\"method\">%s</span>",
                  value.received,
                  value.ip,
                  value.id,
                  value.method)
      else
        message[:string] = 
          sprintf("<span class=\"atoc\">A->C</span> <span class=\"timestamp\">%s</span> <span class=\"ip\">%s</span> <span class=\"cwmpid\">ID: %s</span> <span class=\"method\">%s</span>",
                  value.received,
                  value.ip,
                  value.id,
                  value.method)
      end

      messages.push(message)
    end

    response[:messages] = messages

    json_response(response)
  end

  def delete_messages
    MESSAGES.clear
    ActionCable.server.broadcast "trlog", html: "clear"
  end

  private

    def authenticate
      ret = authenticate_or_request_with_http_digest(ACS.name) do |username|
        ACS.users[username]
      end

      unless ret.class == TrueClass
        headers["Content-Length"] = ret.length.to_s
      end

      return ret
    end

    def request_cpe(method, params)
      response = { :result => "true" }

      if COMMANDS.empty?
        c = HTTPClient.new

        c.set_auth(CPE.full_path, CPE.username, CPE.password)

        begin
          p c.get(CPE.full_path)
        rescue Exception => e
          response[:result] = "false"
          response[:error] = e
        end
      end
      
      if response[:result] == "true"
        command = create_command(params)
        command.method = method 
        COMMANDS.push(command)
      end

      json_response(response)
    end

    def create_command(params)
      command = Command.new
      command.requestId = params[:requestId]

      if params[:parameters].nil?
        return command
      end

      params[:parameters].each do |key, value|
        parameter = Parameter.new

        parameter.name = value[:name]
        parameter.value = value[:value]
        parameter.type = value[:type]
        command.parameters.push(parameter)
      end

      return command
    end

end
