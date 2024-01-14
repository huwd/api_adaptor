module ApiAdaptor
  module Variables
    def self.app_name
      ENV["APP_NAME"] || "Ruby ApiAdaptor App"
    end

    def self.app_version
      ENV["APP_VERSION"] || "Version not stated"
    end

    def self.app_contact
      ENV["APP_CONTACT"] || "Contact not stated"
    end
  end
end
