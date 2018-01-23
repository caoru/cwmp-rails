class Trxml
  include ActiveModel::Model
   
  attr_accessor :path, :xmls, :models
  #validates :command, :parameters, :presence: true

  def initialize()
    @models = {}
    @path = Settings.get["trxml"]["path"]
    @xmls = Settings.get["trxml"]["xmls"]

    create_models
  end

  private

    def create_models
      @xmls.each do |key, value|
        @models[key] = create_model get_full_path(key)
      end
    end

    def create_model(file_name)
      xml_doc = Nokogiri::XML(File.open(file_name))

      tree = []
    
      xml_doc.xpath("//object").each do |entry|
        object_name = entry["name"]

        unless !object_name.nil?
          next
        end

        #node = create_node(tree, object_name)
        node = create_node(tree, entry)

        child = []
        entry.xpath("parameter").each do |child_entry|
          name = child_entry["name"]
          access = child_entry["access"]
          type = child_entry.xpath("syntax/*")[0].name

          if type == "dataType"
            type = child_entry.xpath("syntax/*")[0]["ref"]
          elsif type == "list"
            type = "string(list)"
          end

          enums = []
          child_entry.xpath("syntax/string/enumeration").each do |enumeration_entry|
            if enumeration_entry["access"] != "readOnly"
              #data = { "value" => enumeration_entry["value"], "text" => enumeration_entry["value"] }
              #enums.push(data)
              enums.push(enumeration_entry["value"].to_s + "|" + enumeration_entry["value"].to_s)
            end
          end

          icon = "glyphicon glyphicon-stop"
          if access == "readOnly"
            icon = "glyphicon glyphicon-info-sign"
          elsif access == "readWrite"
            icon = "glyphicon glyphicon-pencil"
          end
          display_name = name + " (" + type + ")"

          child.push({:text => display_name,
                      :access => access,
                      :type => type,
                      :enums => enums,
                      :nodeType => 'leaf',
                      :name => name,
                      :icon => icon})
        end
        node[:nodes] = child
      end

      return tree
    end

    def get_full_path(key)
      return @path.to_s + @xmls[key].to_s
    end

    def create_node(tree, entry)
      name = entry["name"]
      access = entry["access"]
      node = tree
      result_node = []
      object_name = ""

      name.split('.').each do |str|
        item = {}

        if object_name.length > 0
          object_name += "."
        end
        object_name += str

        result = search_tree_text(node, str)
        if result.nil?
          item[:text] = str
          item[:nodes] = []
          item[:name] = str
          item[:type] = "object"
          item[:access] = access
          if str == "{i}"
            item[:nodeType] = "instance"
          else
            item[:nodeType] = "node"
          end
          node.push(item)
          node = item[:nodes]
          result_node = item
        else
          if result[:nodes].nil?
            result[:nodes] = []
          end
          node = result[:nodes]
          result_node = result
        end
      end

      return result_node
    end

    def search_tree_text(array, text)
      array.each do |entry|
        if entry[:text] == text
          return entry
        end
      end

      return nil
    end
end
