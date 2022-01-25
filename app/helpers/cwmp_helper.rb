module CwmpHelper
  class CwmpRequest
    def isRequest
      return true
    end
  end

  class CwmpResponse
    def isRequest
      return false
    end
  end

  class Inform < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text

      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" 
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:InformResponse>
                     <MaxEnvelopes>1</MaxEnvelopes>
                     </cwmp:InformResponse>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     id)

      return xml
    end
  end

  class Fault < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      parameter = Parameter.new
      parameter.name = xml_doc.xpath("//cwmp:Fault/FaultCode").text
      parameter.value = xml_doc.xpath("//cwmp:Fault/FaultString").text

      data = parameter.name + ": " + parameter.value
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      xml_doc.xpath("//SetParameterValuesFault").each do |entry|
        name = entry.xpath("ParameterName").text
        faultCode = entry.xpath("FaultCode").text
        faultString = entry.xpath("FaultString").text

        data = name + ", " + faultCode + ": " + faultString
        ActionCable.server.broadcast "parameters:get", {id: id, data: data}
      end

      return nil
    end
  end

  class TransferComplete < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text

      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" 
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:TransferCompleteResponse>
                     </cwmp:TransferCompleteResponse>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     id)


      return xml
    end
  end

  class Fault401 < CwmpResponse
    def process
      xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
            <SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
            xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
            xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
            xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
            xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
            <SOAP-ENV:Body>
            <SOAP-ENV:Fault>
            <faultcode>SOAP-ENV:Client</faultcode>
            <faultstring>HTTP Error: 401 Unauthorized</faultstring>
            </SOAP-ENV:Fault>
            </SOAP-ENV:Body>
            </SOAP-ENV:Envelope>"

      return xml
    end
  end

=begin
  class GetRPCMethods < CwmpRequest
    def process(command)
      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:GetRPCMethods>
                     </cwmp:GetRPCMethods>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId)

      return xml
    end
  end

  class GetRPCMethodsResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      xml_doc.xpath("//MethodList").each do |entry|
        parameter = Parameter.new
        parameter.name = entry.text

        data = parameter.name
        ActionCable.server.broadcast "parameters:get", {id: id, data: data}
      end

      return nil
    end
  end
=end
  
  class GetRPCMethods < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text

      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" 
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:GetRPCMethodsResponse>
                     <MethodList SOAP-ENC:arrayType=\"xsd:string[10]\">
                     <string>GetRPCMethods</string>
                     <string>SetParameterValues</string>
                     <string>GetParameterValues</string>
                     <string>GetParameterNames</string>
                     <string>SetParameterAttributes</string>
                     <string>GetParameterAttributes</string>
                     <string>AddObject</string>
                     <string>DeleteObject</string>
                     <string>Reboot</string>
                     <string>FactoryReset</string>
                     <string>Download</string>
                     <string>Upload</string>
                     </MethodList>
                     </cwmp:GetRPCMethodsResponse>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     id)

      return xml
    end
  end

  class GetAllQueuedTransfers < CwmpRequest
    def process(command)
      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:GetAllQueuedTransfers>
                     </cwmp:GetAllQueuedTransfers>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId)

      return xml
    end
  end

  class GetAllQueuedTransfersResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      index = 0

      xml_doc.xpath("//TransferList/AllQueuedTransferStruct").each do |entry|
        data = ""
        data.concat("Index: " + index.to_s + "\n")
        data.concat("CommandKey: " + entry.xpath("CommandKey").text + "\n")
        data.concat("State: " + entry.xpath("State").text + "\n")
        data.concat("IsDownload: " + entry.xpath("IsDownload").text + "\n")
        data.concat("FileType: " + entry.xpath("FileType").text + "\n")
        data.concat("FileSize: " + entry.xpath("FileSize").text + "\n")
        data.concat("TargetFileName: " + entry.xpath("TargetFileName").text + "\n")

        index += 1

        ActionCable.server.broadcast "parameters:get", {id: id, data: data}
      end

      if index == 0
        ActionCable.server.broadcast "parameters:get", {id: id, data: "Empty Result"}
      end

      return nil
    end
  end
  
  class GetParameterValues < CwmpRequest
    def process(command)
      parameter_string = ""

      command.parameters.each do |parameter|
        parameter_string.concat(sprintf("<string>%s</string>", parameter.name))
      end

      xml = sprintf("<SOAP-ENV:Envelope
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:GetParameterValues>
                     <ParameterNames SOAP-ENC:arrayType=\"xsd:string[%d]\">
                     %s
                     </ParameterNames>
                     </cwmp:GetParameterValues>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     #Time.now.to_i,
                     command.parameters.length,
                     parameter_string)

      return xml
    end
  end

  class GetParameterValuesResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      isEmpty = true

      xml_doc.xpath("//ParameterList/ParameterValueStruct").each do |entry|
        parameter = Parameter.new
        parameter.name = entry.xpath("Name").text
        parameter.value = entry.xpath("Value").text

        data = parameter.name + ": " + parameter.value
        ActionCable.server.broadcast "parameters:get", {id: id, data: data}

        isEmpty = false
      end

      if isEmpty
        ActionCable.server.broadcast "parameters:get", {id: id, data: "Empty Result"}
      end

      return nil
    end
  end
  
  class GetParameterNames < CwmpRequest
    def process(command)
      xml = sprintf("<SOAP-ENV:Envelope
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:GetParameterNames>
                     <ParameterPath xsi:type=\"xsd:string\">%s</ParameterPath>
                     <NextLevel xsi:type=\"xsd:boolean\">0</NextLevel>
                     </cwmp:GetParameterNames>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     command.parameters[0].name)

      return xml
    end
  end

  class GetParameterNamesResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      xml_doc.xpath("//ParameterList/ParameterInfoStruct").each do |entry|
        parameter = Parameter.new
        parameter.name = entry.xpath("Name").text
        parameter.value = entry.xpath("Writable").text

        data = parameter.name + ": " + parameter.value
        ActionCable.server.broadcast "parameters:get", {id: id, data: data}
      end

      return nil
    end
  end
  
  class SetParameterValues < CwmpRequest
    def process(command)
      parameter_string = ""

      command.parameters.each do |parameter|
        parameter_string.concat(sprintf("<ParameterValueStruct>
                                        <Name>%s</Name>
                                        <Value xsi:type=\"xsd:%s\">%s</Value>
                                        </ParameterValueStruct>",
                                        parameter.name,
                                        parameter.type,
                                        parameter.value))
      end

      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:SetParameterValues>
                     <ParameterList SOAP-ENC:arrayType=\"cwmp:ParameterValueStruct[%d]\">
                     %s
                     </ParameterList>
                     <ParameterKey/>
                     </cwmp:SetParameterValues>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     command.parameters.length,
                     parameter_string)

      return xml
    end
  end

  class SetParameterValuesResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      data = "Status: " + xml_doc.xpath("//Status").text
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      return nil
    end
  end

  class GetParameterAttributes < CwmpRequest
    def process(command)
      parameter_string = ""

      command.parameters.each do |parameter|
        parameter_string.concat(sprintf("<string>%s</string>", parameter.name))
      end

      xml = sprintf("<SOAP-ENV:Envelope
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:GetParameterAttributes>
                     <ParameterNames SOAP-ENC:arrayType=\"xsd:string[%d]\">
                     %s
                     </ParameterNames>
                     </cwmp:GetParameterAttributes>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     #Time.now.to_i,
                     command.parameters.length,
                     parameter_string)

      return xml
    end
  end

  class GetParameterAttributesResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      xml_doc.xpath("//ParameterAttributeStruct").each do |entry|
        name = entry.xpath("Name").text
        notification = entry.xpath("Notification").text
        access_list = ""

        data = name
        ActionCable.server.broadcast "parameters:get", {id: id, data: data}

        entry.xpath("AccessList/string").each do |access|
          access_list.concat(",") unless access_list.length
          access_list.concat(access.text)
        end

        data = "  Notification: " + notification.to_s + ", AccessList: " + access_list
        ActionCable.server.broadcast "parameters:get", {id: id, data: data}
      end

      return nil
    end
  end
  
  class SetParameterAttributes < CwmpRequest
    def process(command)
      parameter_string = ""

      command.parameters.each do |parameter|
        parameter_string.concat(sprintf("<SetParameterAttributesStruct>
                                        <Name>%s</Name>
                                        <NotificationChange>true</NotificationChange>
                                        <Notification>%s</Notification>
                                        </SetParameterAttributesStruct>",
                                        parameter.name,
                                        parameter.value))
      end

      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:SetParameterAttributes>
                     <ParameterList SOAP-ENC:arrayType=\"cwmp:SetParameterAttributesStruct[%d]\">
                     %s
                     </ParameterList>
                     <ParameterKey/>
                     </cwmp:SetParameterAttributes>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     command.parameters.length,
                     parameter_string)

      return xml
    end
  end

  class SetParameterAttributesResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text

      data = "Request Processed..."
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      return nil
    end
  end
  
  class AddObject < CwmpRequest
    def process(command)
      objectName = command.parameters[0].name

      xml = sprintf("<SOAP-ENV:Envelope
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:AddObject>
                     <ObjectName>%s.</ObjectName>
                     <ParameterKey />
                     </cwmp:AddObject>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     objectName)

      return xml
    end
  end

  class AddObjectResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      response = xml_doc.xpath("//cwmp:AddObjectResponse")

      data = "InstanceNumber: " + response.xpath("InstanceNumber").text
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      data = "Status: " + response.xpath("Status").text
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      return nil
    end
  end

  class DeleteObject < CwmpRequest
    def process(command)
      objectName = command.parameters[0].name

      xml = sprintf("<SOAP-ENV:Envelope
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:DeleteObject>
                     <ObjectName>%s.</ObjectName>
                     <ParameterKey />
                     </cwmp:DeleteObject>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     objectName)

      return xml
    end
  end

  class DeleteObjectResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      data = "Status: " + xml_doc.xpath("//Status").text
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      return nil
    end
  end

  class Reboot < CwmpRequest
    def process(command)
      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:Reboot>
                     <CommandKey/>
                     </cwmp:Reboot>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId)

      return xml
    end
  end

  class RebootResponse < CwmpResponse
    def process(xml_doc)
      return nil
    end
  end

  class FactoryReset < CwmpRequest
    def process(command)
      xml = sprintf("<?xml version=\"1.0\" encoding=\"UTF-8\"?>
                     <SOAP-ENV:Envelope
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:FactoryReset/>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId)

      return xml
    end
  end

  class FactoryResetResponse < CwmpResponse
    def process(xml_doc)
      return nil
    end
  end

  class Download < CwmpRequest
    def process(command)
      type = ""
      url = ""
      username = ""
      password = ""

      command.parameters.each do |parameter|
        if parameter.name == "type"
          type = parameter.value
        elsif parameter.name == "url"
          url = parameter.value
        elsif parameter.name == "username"
          username = parameter.value
        elsif parameter.name == "password"
          password = parameter.value
        end
      end

      xml = sprintf("<SOAP-ENV:Envelope
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:Download>
                     <CommandKey/>
                     <FileType xsi:type=\"xsd:string\">%s</FileType>
                     <URL xsi:type=\"xsd:string\">%s</URL>
                     <Username xsi:type=\"xsd:string\">%s</Username>
                     <Password xsi:type=\"xsd:string\">%s</Password>
                     <FileSize/>
                     <TargetFileName/>
                     <DelaySeconds xsi:type=\"xsd:unsignedInt\">0</DelaySeconds>
                     <SuccessURL/>
                     <FailureURL/>
                     </cwmp:Download>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     type,
                     url,
                     username,
                     password)

      return xml
    end
  end

  class DownloadResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      data = "Status: " + xml_doc.xpath("//Status").text
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      return nil
    end
  end

  class Upload < CwmpRequest
    def process(command)
      type = ""
      url = ""
      username = ""
      password = ""

      command.parameters.each do |parameter|
        if parameter.name == "type"
          type = parameter.value
        elsif parameter.name == "url"
          url = parameter.value
        elsif parameter.name == "username"
          username = parameter.value
        elsif parameter.name == "password"
          password = parameter.value
        end
      end

      xml = sprintf("<SOAP-ENV:Envelope
                     xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\"
                     xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\"
                     xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
                     xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"
                     xmlns:cwmp=\"urn:dslforum-org:cwmp-1-0\">
                     <SOAP-ENV:Header>
                     <cwmp:ID SOAP-ENV:mustUnderstand=\"1\">%s</cwmp:ID>
                     </SOAP-ENV:Header>
                     <SOAP-ENV:Body>
                     <cwmp:Upload>
                     <CommandKey/>
                     <FileType xsi:type=\"xsd:string\">%s</FileType>
                     <URL xsi:type=\"xsd:string\">%s</URL>
                     <Username xsi:type=\"xsd:string\">%s</Username>
                     <Password xsi:type=\"xsd:string\">%s</Password>
                     <DelaySeconds xsi:type=\"xsd:unsignedInt\">0</DelaySeconds>
                     </cwmp:Upload>
                     </SOAP-ENV:Body>
                     </SOAP-ENV:Envelope>",
                     command.requestId,
                     type,
                     url,
                     username,
                     password)

      return xml
    end
  end

  class UploadResponse < CwmpResponse
    def process(xml_doc)
      id = xml_doc.xpath("//cwmp:ID").text
      data = "Status: " + xml_doc.xpath("//Status").text
      ActionCable.server.broadcast "parameters:get", {id: id, data: data}

      return nil
    end
  end

end

