module Gitm

    require 'gitm/bugTracker/abstract_bug_tracker'

    class Jira < AbstractBugTracker

        def connect
            ActiveSupport::Inflector.inflections do |inflect|
                inflect.irregular 'issues', 'issue'
            end
            Issue.site = "#{self.url}/rest/api/2/"
            Issue.user = self.login
            Issue.password = self.passwd
        end

        def find_issue(issue_number)
            issue = Issue.find(issue_number)
            issue
        end

        def show_issue_list(issues)
            rows = []
            rows << %w{Id sprint Assignee Priority status summary}
            issues.each{ |ticket|
                begin
                    issue = Issue.find(ticket)
                    row = []
                    row.push(issue.key)
                    row.push(/name=(.*?),/.match(issue.fields.customfield_11452[0])[1]) # sprint
                    row.push(issue.fields.assignee.name)
                    row.push(issue.fields.priority.name)
                    row.push(issue.fields.status.name)
                    row.push(issue.fields.summary)
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
            settings['type']='jira'
            Display::show 'Enter bug tracker name', :notice
            name=gets
            settings['name']=name.chomp!
            settings['url']=ask('Enter bug tracker url (with / at the end) : ') { |q| q.echo = true }
            settings['login']=ask('Enter Login: ') { |q| q.echo = true }
            settings['passwd']=ask('Enter password: ') { |q| q.echo = '*' }
            settings
        end
    end
end
