

module Gitm
    require 'fileutils'

    class Settings

        attr_reader :settings

        CONFIG_DIR = "#{ENV['HOME']}/.config/gitm/"
        CONFIG_FILE = "#{ENV['HOME']}/.config/gitm/config.yml"

        def initialize
            if !File.exist?(CONFIG_FILE)
                Display::show 'No settings file found', :error
                @settings=Hash.new
            else
                @settings= YAML.load_file(CONFIG_FILE)
            end
        end

        def create_settings
            @settings=Hash.new
            Display::show 'Start settings file creation', :info
            Display::show 'Do you want to add a bug tracker ? (Y/n)', :notice
            add_bug_tracker=gets
            if "#{add_bug_tracker}" == "Y"
                self.add_bug_tracker
            end
        end

        def add_bug_tracker
            Display::show 'What tracker you want to add ? (jira/redmine)', :notice
            bug_tracker_type=gets
            bug_tracker_type.chomp!
            Display::show "You choose : #{bug_tracker_type}"
            if @settings['bugtrackers'].nil?
                @settings['bugtrackers']=Hash.new
            end
            case bug_tracker_type
                when 'jira'
                    jira_settings=Gitm::Jira.create_settings
                    @settings['bugtrackers'][jira_settings['name']]=jira_settings
                when 'redmine'
                    redmine_settings=Gitm::Redmine.create_settings
                    @settings['bugtrackers'][redmine_settings['name']]=redmine_settings
                else
                    Display::show 'Unknow entry', :error
                    exit
            end
            self.save_settings
        end

        def add_repository_link(repositories)
            if @settings['repositories'].nil?
                @settings['repositories']=[]
            end
            repositories.git_repo_list.each { |repository|
                path=repository.workdir
                repo_setting = self.get_repo_settings(path)
                Display::show "#{path}", :notice
                if repo_setting.nil?
                    Display::show 'Do you want to add repository link with bug tracker ? (y/N)'
                    repo_setting=Hash.new
                else
                    Display::show "Do you want to modify repository association with #{repo_setting['bugtracker']}?  (y/N)"
                end
                change_bt=gets
                change_bt.chomp!
                if "#{change_bt}" == 'Y' or "#{change_bt}" == 'y'
                    bt_list=self.list_bug_tracker
                    Display::show 'Choose once in the list :', :notice
                    bt_list.each{ |bt|
                        if !bt[1].nil?
                            Display::show " - #{bt[1]['name']} (#{bt[1]['type']}) @#{bt[1]['url']}"
                        end
                    }
                    Display::show "Enter the choice :"
                    bt_choice=gets
                    bt_choice.chomp!
                    bt_list.each{ |bt|
                        if !bt[0].nil? and bt[0] == bt_choice
                            repo_setting['name'] = File.basename(path)
                            repo_setting['path'] = path
                            repo_setting['bugtracker'] = bt_choice
                            break
                        end
                    }
                    self.update_repo_settings(repo_setting)
                    self.save_settings
                end
            }
        end

        def save_settings
            #Display::show "Settings : #{@settings.to_s}"
            Display::show "Do you want to save settings to file #{CONFIG_FILE}? (y/N)", :notice
            save_settings=gets
            save_settings.chomp!
            if save_settings=='y' or save_settings=='Y'
                FileUtils::mkdir_p CONFIG_DIR
                File.open(CONFIG_FILE, 'w') do |file|
                    file.write @settings.to_yaml
                end
            end
        end

        def list_bug_tracker
            bt_list=[]
            @settings['bugtrackers'].each{ |bt|
                bt_list.push(bt)
            }
            bt_list
        end

        def show_bug_trackers
            @settings['bugtrackers'].each{ |bt|
                Display::show "Name : #{bt[1]['name']}", :notice
                Display::show "Type : #{bt[1]['type']}"
                Display::show "Url  : #{bt[1]['url']}"
                Display::show '----'
            }
        end

        def get_bug_tracker(name)
            bug_tracker = nil
            begin
                bt = @settings['bugtrackers'][name]
                case bt['type']
                    when 'jira'
                        bug_tracker = Gitm::Jira.new(bt['url'], bt['login'], bt['passwd'])
                    when 'redmine'
                        bug_tracker = Gitm::Redmine.new(bt['url'],  (bt['login'].nil?)?'':bt['login'], (bt['passwd'].nil?)?'':bt['passwd'], bt['key'])
                    else
                        bug_tracker = nil
                end
            end
            bug_tracker
        end

        def get_repo_settings(path)
            repo_setting_result = nil
            if !@settings['repositories'].nil?
                @settings['repositories'].each { |repo_setting|
                    if repo_setting['path'] == path
                        repo_setting_result=repo_setting
                        break
                    end
                }
            end
            repo_setting_result
        end

        def update_repo_settings(settings)
            if !@settings['repositories'].nil?
                @settings['repositories'].delete_if{
                    |repo_setting| repo_setting['path'] == settings['path']
                }
            end
            @settings['repositories'].push(settings)
        end

        def get_repo_tracker(repository)
            bt=nil
            path = repository.workdir
            repo_settings = self.get_repo_settings(path)
            if !repo_settings.nil?
                bug_tracker_name = repo_settings['bugtracker']
                if !bug_tracker_name.nil?
                    bt = self.get_bug_tracker(bug_tracker_name)
                end
            end
            bt
        end
    end
end
