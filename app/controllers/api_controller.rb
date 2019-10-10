require 'socket'

class ApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate, only: [:download_file, :upload_file]

  def get_token
    token = random_token = SecureRandom.urlsafe_base64(nil, false)

    json_response({ :token => token })
  end

  def get_url
    urls = []
    ips = []

    Socket.ip_address_list.each do |entry|
      if entry.ipv4? && !entry.ipv4_loopback? && entry.ip_address.class == String
        ips.push(entry.ip_address)
      end
    end

    operation = params[:operation]
    type = params[:type]

    if operation == "upload"
      ips.each do |entry|
        url = request.protocol + entry + ":" + request.server_port.to_s + "/" + operation + "/" + type
        urls.push(url)
      end
    else
      records = nil

      if type == "firmware"
        records = Dir.glob(CPE.firmware + "/" + ACS.firmware_prefix + "*")
      elsif type == "config"
        records = Dir.glob(CPE.config + "/" + CPE.ip + ".xml")
      end

      if records.nil?
        url = "Not supported.";
        urls.push(url)
      elsif records.empty?
        url = "File not exist, upload file.";
        urls.push(url)
      else
        ips.each do |entry|
          url = request.protocol + entry + ":" + request.server_port.to_s + "/" +
                operation + "/" + type + "/" + records[0].to_s.gsub(CPE.file_root + "/" + type + "/", "")
          urls.push(url)
        end
      end
    end
    
    json_response({ :result => "true", :urls => urls })
  end

  def download_file
    type = params[:type]
    name = params[:name]
    full_name = CPE.file_root + "/" + type + "/" + name

    unless File.file?(full_name)
      head 404
      return
    end

    headers["Content-Length"] = File.size(full_name)

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

  def upload_file_acs
    if params[:type] == "firmware"
      file_name = Rails.root.join(CPE.firmware, params[:file].original_filename)
      FileUtils::mkdir_p CPE.firmware unless Dir.exist?(CPE.firmware)
    elsif params[:type] == "config"
      file_name = Rails.root.join(CPE.config, params[:file].original_filename)
      FileUtils::mkdir_p CPE.config unless Dir.exist?(CPE.config)
    end

    File.open(file_name,'wb') do |file|
      file.write(params[:file].read)
    end

    head 200
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

  def post_model
    if params[:tr].nil? || params[:file].nil? 
      head 500
      return
    end

    model = TRXML.models[params[:tr]]

    save_model(model, params[:file])

    head 200
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
    id = params[:id]

    message = Message.find(id)

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

    def save_model(model, file)
      indent = 3
      file = File.open(file, 'w')

      write_header(file)

      write_indent(indent, file)
      file.write "<parameters>\n"

      process_node(model, indent + 2, file)

      write_indent(indent, file)
      file.write "</parameters>\n"

      write_tail(file)

      file.close
    end

    def write_indent(indent, file)
      for counter in 0..indent
        file.write " " 
      end
    end

    def write_parameter_name(name, indent, file)
      write_indent(indent, file)
      file.write "<parameterName>" + name + "</parameterName>\n"
    end

    def write_parameter_type(type, indent, file)
      write_indent(indent, file)
      file.write "<parameterType>"

      if type == "unsignedInt"
        file.write "unsignedInt"
      elsif type == "boolean"
        file.write "boolean"
      elsif type == "object"
        file.write "object"
      else
        file.write "string"
      end

      file.write"</parameterType>\n"
    end

    def write_parameter(entry, indent, file)
      write_parameter_name(entry[:name], indent, file)
      write_parameter_type(entry[:type], indent, file)
    end

    def process_node(node, indent, file)
      node.each do |entry|
        nodeType = entry[:nodeType]

        if nodeType == "node"
          write_indent(indent, file)
          file.write "<parameter>\n"

          write_parameter(entry, indent + 2, file)

          write_indent(indent + 2, file)
          file.write "<array>"
          if entry[:nodes].length == 0
            file.write "false"
          elsif entry[:nodes][0][:nodeType] == "instance"
            file.write "true"
          else
            file.write "false"
          end
          file.write "</array>\n"

          write_indent(indent + 2, file)
          file.write "<parameters>\n"
          if entry[:nodes].length == 0
          elsif entry[:nodes][0][:nodeType] == "instance"
            process_node(entry[:nodes][0][:nodes], indent + 4, file)
          else
            process_node(entry[:nodes], indent + 4, file)
          end
          write_indent(indent + 2, file)
          file.write "</parameters>\n"

          write_indent(indent, file)
          file.write "</parameter>\n"
        elsif nodeType == "leaf"
          write_indent(indent, file)
          file.write "<parameter>\n"

          write_parameter(entry, indent + 2, file)

          write_indent(indent, file)
          file.write "</parameter>\n"
        end
      end
    end

    def write_header(file)
      file.write "<deviceType xmlns=\"urn:dslforum-org:hdm-0-0\" " +
                 "xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" " +
                 "xsi:schemaLocation=\"urn:dslforum-org:hdm-0-0 deviceType.xsd\">\n"
      file.write "  <protocol>DEVICE_PROTOCOL_DSLFTR069v1</protocol>\n"
      file.write "  <manufacturer>Kaonmedia</manufacturer>\n"
      file.write "  <manufacturerOUI>808C97</manufacturerOUI>\n"
      file.write "  <productClass>DG2201</productClass>\n"
      file.write "  <modelName>DG2201</modelName>\n"
      file.write "  <dataModel>\n"
      file.write "    <attributes>\n"
      file.write "      <attribute>\n"
      file.write "        <attributeName>notification</attributeName>\n"
      file.write "        <attributeType>int</attributeType>\n"
      file.write "        <minValue>0</minValue>\n"
      file.write "        <maxValue>2</maxValue>\n"
      file.write "      </attribute>\n"
      file.write "      <attribute>\n"
      file.write "        <attributeName>accessList</attributeName>\n"
      file.write "        <attributeType>string</attributeType>\n"
      file.write "        <array>true</array>\n"
      file.write "        <attributeLength>64</attributeLength>\n"
      file.write "      </attribute>\n"
      file.write "      <attribute>\n"
      file.write "        <attributeName>visibility</attributeName>\n"
      file.write "        <attributeType>string</attributeType>\n"
      file.write "        <attributeLength>64</attributeLength>\n"
      file.write "      </attribute>\n"
      file.write "    </attributes>\n"
    end

    def write_tail(file)
      file.write "  </dataModel>\n"
      file.write "  <baselineConfiguration>\n"
      file.write "    <parameterValues>\n"
      file.write "      <parameterValue>\n"
      file.write "        <parameterName>InternetGatewayDevice</parameterName>\n"
      file.write "        <parameterValues>\n"
      file.write "          <parameterValue>\n"
      file.write "            <parameterName>DeviceInfo</parameterName>\n"
      file.write "            <parameterValues>\n"
      file.write "              <parameterValue>\n"
      file.write "                <parameterName>SoftwareVersion</parameterName>\n"
      file.write "                <attributeValues>\n"
      file.write "                  <attributeValue>\n"
      file.write "                    <attributeName>notification</attributeName>\n"
      file.write "                    <value>2</value>\n"
      file.write "                  </attributeValue>\n"
      file.write "                </attributeValues>\n"
      file.write "              </parameterValue>\n"
      file.write "              <parameterValue>\n"
      file.write "                <parameterName>ProvisioningCode</parameterName>\n"
      file.write "                <attributeValues>\n"
      file.write "                  <attributeValue>\n"
      file.write "                    <attributeName>notification</attributeName>\n"
      file.write "                    <value>2</value>\n"
      file.write "                  </attributeValue>\n"
      file.write "                </attributeValues>\n"
      file.write "              </parameterValue>\n"
      file.write "            </parameterValues>\n"
      file.write "          </parameterValue>\n"
      file.write "          <parameterValue>\n"
      file.write "            <parameterName>ManagementServer</parameterName>\n"
      file.write "            <parameterValues>\n"
      file.write "              <parameterValue>\n"
      file.write "                <parameterName>ConnectionRequestURL</parameterName>\n"
      file.write "                <attributeValues>\n"
      file.write "                  <attributeValue>\n"
      file.write "                    <attributeName>notification</attributeName>\n"
      file.write "                    <value>2</value>\n"
      file.write "                  </attributeValue>\n"
      file.write "                </attributeValues>\n"
      file.write "              </parameterValue>\n"
      file.write "            </parameterValues>\n"
      file.write "          </parameterValue>\n"
      file.write "          <parameterValue>\n"
      file.write "            <parameterName>LANDevice</parameterName>\n"
      file.write "            <parameterValues>\n"
      file.write "              <parameterValue>\n"
      file.write "                <parameterName>WLANConfiguration</parameterName>\n"
      file.write "                <parameterValues>\n"
      file.write "                  <parameterValue>\n"
      file.write "                    <parameterName>Enable</parameterName>\n"
      file.write "                    <attributeValues>\n"
      file.write "                      <attributeValue>\n"
      file.write "                        <attributeName>notification</attributeName>\n"
      file.write "                        <value>2</value>\n"
      file.write "                      </attributeValue>\n"
      file.write "                    </attributeValues>\n"
      file.write "                  </parameterValue>\n"
      file.write "                </parameterValues>\n"
      file.write "              </parameterValue>\n"
      file.write "            </parameterValues>\n"
      file.write "          </parameterValue>\n"
      file.write "          <parameterValue>\n"
      file.write "            <parameterName>WANDevice</parameterName>\n"
      file.write "            <parameterValues>\n"
      file.write "              <parameterValue>\n"
      file.write "                <parameterName>WANConnectionDevice</parameterName>\n"
      file.write "                <parameterValues>\n"
      file.write "                  <parameterValue>\n"
      file.write "                    <parameterName>WANIPConnection</parameterName>\n"
      file.write "                    <parameterValues>\n"
      file.write "                      <parameterValue>\n"
      file.write "                        <parameterName>ExternalIPAddress</parameterName>\n"
      file.write "                        <attributeValues>\n"
      file.write "                          <attributeValue>\n"
      file.write "                            <attributeName>notification</attributeName>\n"
      file.write "                            <value>2</value>\n"
      file.write "                          </attributeValue>\n"
      file.write "                        </attributeValues>\n"
      file.write "                      </parameterValue>\n"
      file.write "                    </parameterValues>\n"
      file.write "                  </parameterValue>\n"
      file.write "                  <parameterValue>\n"
      file.write "                    <parameterName>WANPPPConnection</parameterName>\n"
      file.write "                    <parameterValues>\n"
      file.write "                      <parameterValue>\n"
      file.write "                        <parameterName>ExternalIPAddress</parameterName>\n"
      file.write "                        <attributeValues>\n"
      file.write "                          <attributeValue>\n"
      file.write "                            <attributeName>notification</attributeName>\n"
      file.write "                            <value>2</value>\n"
      file.write "                          </attributeValue>\n"
      file.write "                        </attributeValues>\n"
      file.write "                      </parameterValue>\n"
      file.write "                    </parameterValues>\n"
      file.write "                  </parameterValue>\n"
      file.write "                </parameterValues>\n"
      file.write "              </parameterValue>\n"
      file.write "            </parameterValues>\n"
      file.write "          </parameterValue>\n"
      file.write "        </parameterValues>\n"
      file.write "      </parameterValue>\n"
      file.write "    </parameterValues>\n"
      file.write "  </baselineConfiguration>\n"
      file.write "</deviceType>\n"
    end

end

