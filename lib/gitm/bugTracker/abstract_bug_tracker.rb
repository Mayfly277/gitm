
module Gitm

    require 'active_resource'
    require 'net/http'
    require 'gitm/display'
    require 'terminal-table'
    require 'highline/import'


    class AbstractBugTracker
        attr_accessor :url
        attr_accessor :login
        attr_accessor :passwd
        attr_accessor :key
        attr_accessor :auth_method

        AUTH_METHOD_BASIC = :basic
        AUTH_METHOD_KEY   = :key

        def initialize(url, login=nil, passwd=nil, api_key=nil)
            self.url = url
            self.login = login
            self.passwd = passwd
            self.key = api_key
            if api_key.nil?
                self.auth_method = AUTH_METHOD_BASIC
            else
                self.auth_method = AUTH_METHOD_KEY
            end
            self.connect
        end

        def connect
            Issue.site = self.url
            Issue.user = self.login
            Issue.password = self.passwd
        end

        # TO override
        def show_issue_list(issues)
        end

        # TO override
        def self.create_settings
        end

    end

    # Issue model on the client side
    class Issue < ActiveResource::Base
    end
end