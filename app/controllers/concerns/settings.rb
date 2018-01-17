class Settings
  SETTINGS_FILENAME = "config/settings.yml"

  def Settings.get
    require 'yaml'

    @@settings ||= nil
    unless File.exists? SETTINGS_FILENAME
      File.open(SETTINGS_FILENAME, 'w') { |file| file.write({}.to_yaml) }
    end
    new_settings_time = File.ctime(SETTINGS_FILENAME)
    if @@settings.nil? || new_settings_time > @@settings_time
      @@settings_time = new_settings_time
      Rails.logger.info "Settings changed, reloading"
      settings_default ||= YAML.load_file 'config/settings.defaults.yml'
      begin
        settings_user ||= YAML.load_file SETTINGS_FILENAME
      rescue Exception => e
        Rails.logger.info "Unable to load configuration, using defaults. Reason: #{e}"
        settings_user = {}
      end
      @@settings = settings_default.merge settings_user
    end
    @@settings
  end

  def Settings.save
    require 'yaml'

    File.open SETTINGS_FILENAME, 'w' do |file|
      file.write @@settings.to_yaml
    end
  end

  def Settings.method_missing(m, *args, &block)
    out = get[m.to_s]
    if @@settings.has_key? m.to_s
      out
    else
      throw NoMethodError.new("Setting does not exist", m, args)
    end
  end
end

