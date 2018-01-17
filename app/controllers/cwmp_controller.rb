require 'digest/md5'

class CwmpController < ApplicationController

  #protect_from_forgery with: :null_session
  skip_before_action :verify_authenticity_token
  before_action :authenticate

  def cwmp
    content_length = request.headers["Content-Length"].to_i
    clazz_name = ""

    if content_length > 0
      xml_doc = Nokogiri::XML(request.raw_post)
      method = ""

      xml_doc.xpath("//SOAP-ENV:Body").children.each do |entry|
        if entry.class == Nokogiri::XML::Element
          method = entry.name
          break
        end
      end

      received = Time.now

      message = CwmpMessage.new(xml_doc)
      message.epoch = received.to_f
      message.ip = request.remote_ip
      message.received = received
      message.direction = "ctoa"
      MESSAGES[message.epoch] = message

      xml_doc.xpath("//SOAP-ENV:Header").before('<RemoteIp>' + request.remote_ip + '</RemoteIp>')
      xml_doc.xpath("//SOAP-ENV:Header").before('<Received>' + received.to_s + '</Received>')
      xml_doc.xpath("//SOAP-ENV:Header").before('<Epoch>' + received.to_f.to_s + '</Epoch>')

      send_notification_response(xml_doc, method)

      clazz_name = 'CwmpHelper::' + method
      clazz = clazz_name.constantize.new
      xml_string = clazz.process(xml_doc)

      if !xml_string.nil?
        response = Nokogiri::XML(xml_string)

        send_notification_request(response)

        render :xml => response

        return
      end
    end

    unless COMMANDS.empty?
      command = COMMANDS.shift
      clazz_name = 'CwmpHelper::' + command.method
      clazz = clazz_name.constantize.new
      xml_string = clazz.process(command)

      if !xml_string.nil?
        response = Nokogiri::XML(xml_string)

        send_notification_request(response)

        render :xml => response

        return
      end
    end

    head 204
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

    def send_notification_request(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      received = Time.now

      method = ""

      xml_doc.xpath("//SOAP-ENV:Body").children.each do |entry|
        if entry.class == Nokogiri::XML::Element
          method = entry.name
          break
        end
      end

      message = CwmpMessage.new(xml_doc)
      message.epoch = received.to_f
      message.ip = CPE.ip
      message.received = received
      message.direction = "atoc"
      MESSAGES[message.epoch] = message

      log_string = sprintf("<span class=\"atoc\">A->C</span> %s <span class=\"ip\">%s</span> ID: %s <span class=\"method\">%s</span>",
                           received, CPE.ip, id, method)

      html = sprintf("<a class=\"list-group-item message\" onclick=\"javascript:getXml(%s);return false;\">%s</a>", received.to_f.to_s, log_string)
      ActionCable.server.broadcast "trlog", html: html
    end

    def send_notification_response(xml_doc, method)
      id = xml_doc.xpath("//cwmp:ID").text
      epoch = xml_doc.xpath("//SOAP-ENV:Epoch").text
      received = xml_doc.xpath("//SOAP-ENV:Received").text
      remote_ip = xml_doc.xpath("//SOAP-ENV:RemoteIp").text

      if method == "Inform"
        oui = xml_doc.xpath("//OUI").text
        product_class = xml_doc.xpath("//ProductClass").text
        serial_number = xml_doc.xpath("//SerialNumber").text
        event_codes = xml_doc.xpath("//EventCode")
        event_code_string = ""

        log_string = sprintf("<span class=\"ctoa\">C->A</span> %s <span class=\"ip\">%s</span> ID: %s <span class=\"identity\">%s-%s-%s</span> Event: ",
                             received, remote_ip, id, oui, product_class, serial_number)

        event_codes.each do |event_code|
          if event_code_string.length > 0
            event_code_string.concat("; ") #unless event_code_string.length
          end
          event_code_string.concat(event_code.text)
        end

        log_string.concat(event_code_string)
        log_string.concat(" <span class=\"method\">Inform</span>")
      else
        log_string = sprintf("<span class=\"ctoa\">C->A</span> %s <span class=\"ip\">%s</span> ID: %s <span class=\"method\">%s</span>",
                             received, remote_ip, id, method)
      end

      html = sprintf("<a class=\"list-group-item message\" onclick=\"javascript:getXml(%s);return false;\">%s</a>", epoch, log_string)
      ActionCable.server.broadcast "trlog", html: html
    end
end
