class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token

  def get_token
    token = random_token = SecureRandom.urlsafe_base64(nil, false)

    json_response({ :token => token })
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
          sprintf("<span class=\"ctoa\">C->A</span> %s <span class=\"ip\">%s</span> ID: %s <span class=\"identity\">%s-%s-%s</span> Event: %s <span class=\"method\">Inform</span>",
                  value.received,
                  value.ip,
                  value.id,
                  value.oui,
                  value.class,
                  value.serial,
                  value.events)
      elsif value.direction == "ctoa"
        message[:string] = 
          sprintf("<span class=\"ctoa\">C->A</span> %s <span class=\"ip\">%s</span> ID: %s <span class=\"method\">%s</span>",
                  value.received,
                  value.ip,
                  value.id,
                  value.method)
      else
        message[:string] = 
          sprintf("<span class=\"atoc\">A->C</span> %s <span class=\"ip\">%s</span> ID: %s <span class=\"method\">%s</span>",
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
