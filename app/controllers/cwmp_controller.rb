require 'digest/md5'
require 'fileutils'

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
      id = xml_doc.xpath("//cwmp:ID").text.to_i

      method = ""

      xml_doc.xpath("//SOAP-ENV:Body").children.each do |entry|
        if entry.class == Nokogiri::XML::Element
          method = entry.name
          break
        end
      end

      @message = Message.new
      @message.cwmp_id = id
      @message.ip = CPE.ip
      @message.method = method
      @message.direction = "atoc"
      @message.timestamp = Time.now
      @message.xml = xml_doc.to_s
      @message.save

      log_string = sprintf("<span class=\"atoc\">A->C</span> <span class=\"timestamp\">%s</span> <span class=\"ip\">%s</span> <span class=\"cwmpid\">ID: %s</span> <span class=\"method\">%s</span>",
                           @message.timestamp.localtime, CPE.ip, id, method)

      html = sprintf("<a class=\"list-group-item message\" href=\"/api/cpe/message.xml?id=%d\" target=\"_blank\">%s</a>", @message.id, log_string)
      ActionCable.server.broadcast "messages", html: html
    end

    def send_notification_response(xml_doc, method)
      id = xml_doc.xpath("//cwmp:ID").text.to_i

      @message = Message.new
      @message.cwmp_id = id
      @message.ip = request.remote_ip
      @message.method = method
      @message.direction = "ctoa"
      @message.timestamp = Time.now
      @message.xml = xml_doc.to_s

      if method == "Inform"
        oui = xml_doc.xpath("//OUI").text
        product_class = xml_doc.xpath("//ProductClass").text
        serial_number = xml_doc.xpath("//SerialNumber").text
        event_codes = xml_doc.xpath("//EventCode")
        event_code_string = ""

        log_string = sprintf("<span class=\"ctoa\">C->A</span> <span class=\"timestamp\">%s</span> <span class=\"ip\">%s</span> <span class=\"cwmpid\">ID: %s</span> <span class=\"identity\">%s-%s-%s</span> Event: ",
                             @message.timestamp.localtime, request.remote_ip, id, oui, product_class, serial_number)

        event_codes.each do |event_code|
          if event_code_string.length > 0
            event_code_string.concat("; ") #unless event_code_string.length
          end
          event_code_string.concat(event_code.text)
        end

        @message.oui = oui
        @message.product_class = product_class
        @message.serial = serial_number
        @message.events = event_code_string

        log_string.concat(event_code_string)
        log_string.concat(" <span class=\"method\">Inform</span>")
      else
        log_string = sprintf("<span class=\"ctoa\">C->A</span> <span class=\"timestamp\">%s</span> <span class=\"ip\">%s</span> <span class=\"cwmpid\">ID: %s</span> <span class=\"method\">%s</span>",
                             @message.timestamp.localtime, request.remote_ip, id, method)
      end

      @message.save

      html = sprintf("<a class=\"list-group-item message\" href=\"/api/cpe/message.xml?id=%d\" target=\"_blank\">%s</a>", @message.id, log_string)
      ActionCable.server.broadcast "messages", html: html
    end
end
