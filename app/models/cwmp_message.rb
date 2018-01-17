class CwmpMessage
  include ActiveModel::Model
  attr_accessor :epoch, :id, :received, :ip, :oui, :class, :serial, :events, :method, :direction, :xml

  def initialize(xml_doc)
      @id = xml_doc.xpath("//cwmp:ID").text
      @oui = xml_doc.xpath("//OUI").text
      @class = xml_doc.xpath("//ProductClass").text
      @serial = xml_doc.xpath("//SerialNumber").text
      event_codes = xml_doc.xpath("//EventCode")
      @events = ""
      @xml = xml_doc.to_s

      xml_doc.xpath("//SOAP-ENV:Body").children.each do |entry|
        if entry.class == Nokogiri::XML::Element
          @method = entry.name
          break
        end
      end

      event_codes.each do |event_code|
        if @events.length > 0
          @events.concat("; ") #unless @events.length
        end
        @events.concat(event_code.text)
      end

  end

end
