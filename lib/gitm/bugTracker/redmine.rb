module Gitm

    require 'gitm/bugTracker/abstract_bug_tracker'

    class Redmine < AbstractBugTracker

        # Override connect method from abstract
        def connect
            Issue.site = self.url
            if self.auth_method == AUTH_METHOD_BASIC
                Issue.user = self.login
                Issue.password = self.passwd
            elsif self.auth_method == AUTH_METHOD_KEY
                Issue.headers['X-Redmine-API-Key'] = self.key
            end
        end

        def find_issue(issue_number)
            issue = Issue.find(issue_number)
            issue
        end

        def show_issue_list(issues)
            rows = []
            head = %w{ID Status Priority Author Subject}
            rows << head
            issues.each{ |ticket|
                begin
                    issue = Issue.find(ticket)
                    row = []
                    row.push(issue.id)
                    row.push(issue.status.name)
                    row.push(issue.priority.name)
                    row.push(issue.author.name)
                    row.push(issue.subject)
                    rows << row
                rescue
                    Display::show "#{ticket} not found", :error
                end
            }
            table = Terminal::Table.new :rows => rows
            puts table
        end

        def self.create_settings
            settings= Hash.new
            settings['type']='redmine'
            Display::show 'Enter bug tracker name', :notice
            name=gets
            settings['name']=name.chomp!
            settings['url']=ask('Enter bug tracker url (with / at the end) : ') { |q| q.echo = true }
            Display::show 'choose authentication method :', :notice
            Display::show '1) login/password', :notice
            Display::show '2) api-key', :notice
            choice_not_done=true
            while choice_not_done
                auth_method=ask('Enter you\'re choice') { |q| q.echo = true }
                case auth_method
                    when '1'
                        settings['login']=ask('Enter Login: ') { |q| q.echo = true }
                        settings['passwd']=ask('Enter password: ') { |q| q.echo = '*' }
                        choice_not_done=false
                    when '2'
                        settings['key']=ask('Enter api-key: ') { |q| q.echo = true }
                        choice_not_done=false
                    else
                        Display::show 'Choose 1 or 2', :error
                end
            end
            settings
        end
    end
end