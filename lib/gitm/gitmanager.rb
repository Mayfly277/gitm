# encoding: utf-8
# gitmanager.rb

module Gitm
    require 'gitm/display'
    require 'gitm/repositories'
    require 'gitm/version'
    require 'gitm/settings'
    require 'gitm/bugTracker/redmine'
    require 'gitm/bugTracker/jira'

    require 'yaml'

    class GitManager

        attr_accessor :repositories
        attr_accessor :verbose

        attr_reader :settings

        def initialize
            @repositories = Gitm::Repositories.new
            @verbose = Gitm::Display::VERBOSE_NONE
            @settings = Settings.new
        end

        #
        # Run method
        #
        def run
            ARGV << '-h' if ARGV.empty?
            opts = {}
            actions=[]

            begin
                OptionParser.new do |opt|
                    opt.banner = 'Usage: gitm [options] path'

                    opt.on('-l', '--list', 'List founded repositories') do
                        actions.push(:list)
                    end

                    opt.on('-f', '--fetch', 'Play a fetch -p on each repositories') do
                        actions.push(:fetch)
                    end

                    opt.on('-c', '--compare [ref_branch]', 'Show comparaison of the parameter branch with the other branches (use -v to show remote)') do |ref_branch|
                        opts[:ref_branch] = ref_branch
                        actions.push(:compare)
                    end

                    # TODO fix
                    # opt.on('-o', '--overview', 'show repo overview (TODO)') do
                    #     actions.push(:show_status)
                    # end

                    opt.on('-s', '--search [text_to_find]', 'find commits which contains text_to_find') do | text_to_find |
                        opts[:text_to_find] = [text_to_find]
                        actions.push(:find)
                    end

                    opt.separator ''
                    opt.separator 'Linked with bug tracker:'

                    opt.on('-b', '--feature-info', 'Show repositories infos on features') do |repo|
                        opts[:repo] = repo
                        actions.push(:feature_info)
                    end

                    opt.on('-i', '--issue [issue_number]', 'show ticket datas') do | issue_number |
                        opts[:issue] = [issue_number]
                        actions.push(:show_issue)
                    end

                    opt.separator ''
                    opt.separator 'Common options:'

                    opt.on('-v', '--verbose', 'Verbose (use -vv to very verbose)') do
                        # -vv option
                        if self.verbose == Display::VERBOSE_MEDIUM
                            self.verbose = Display::VERBOSE_FULL
                        else
                            self.verbose = Display::VERBOSE_MEDIUM
                        end
                    end

                    # No argument, shows at tail.  This will print an options summary.
                    # Try it and see!
                    opt.on('-h', '--help', 'Show this message') do
                        Display.instance.welcome_screen
                        puts opt

                        puts ''
                        puts 'Examples :'
                        puts ' - Compare with origin/develop on all branches: gitm -c origin/develop -v'
                        puts ' - Search ticket in all branches : gitm -s 17100'
                        puts ' - List all branches and remotes : gitm -lvv'

                        exit
                    end

                    # Another typical switch to print the version.
                    opt.on('--version', 'Show version') do
                        puts Gitm::VERSION
                        exit
                    end

                    opt.separator ''
                    opt.separator 'Setup options:'

                    opt.on_tail('--show-bt', 'Show bug tracker list') do
                        actions.push(:show_bt)
                    end
                    opt.on_tail('--setup-add-bug-tracker', 'Add bug tracker') do
                        actions.push(:add_bt)
                    end
                    opt.on_tail('--setup-add-bt-link', 'Add bug tracker link to repository') do
                        actions.push(:add_repository)
                    end
                end.parse!

                if ARGV[0]
                    path=ARGV[0];
                else
                    path=Dir.pwd
                end

                git_repo_list=repositories.find_repositories(path)
                if git_repo_list.length < 0
                    Display.show 'error no repo found', :error
                    exit 1
                end

                actions.each  do |action|
                    case action
                        when :list
                            @repositories.show_repo_list(@verbose)
                        when :feature_info
                            self.show_feature_info
                        when :fetch
                            @repositories.fetch_all
                        when :show_status
                            @repositories.show_status
                        when :find
                            @repositories.find_in_logs(opts[:text_to_find][0], @verbose)
                        when :compare
                            @repositories.compare(opts[:ref_branch], @verbose)
                        when :add_bt
                            @settings.add_bug_tracker
                        when :show_bt
                            @settings.show_bug_trackers
                        when :add_repository
                            @settings.add_repository_link(@repositories)
                        when :show_issue
                            self.show_issue(opts[:issue])
                        else
                            puts 'option invalid, use help : gitm [-h | --help] to show valid options'
                    end
                end
            rescue
                 puts 'option invalid, use help : gitm [-h | --help] to show valid options'
            end
        end

        private

        #
        # Show the feature information in bug tracker for each feature branch met
        #
        def show_feature_info
            repos_list = @repositories.git_repo_list
            first = true
            repos_list.each do |repo|
                bt = @settings.get_repo_tracker(repo)
                unless first
                    puts ''
                    Display::show '-----------------------------', :default
                    puts ''
                end
                issues=[]
                repo.branches.each { |branch|
                    if /feature\//.match(branch.name)
                        issues.push(/feature\/(.*)/.match(branch.name)[1])
                    end
                }
                repo_name=File.basename(repo.workdir)
                Display::show "Repository : #{repo_name}", :title
                if bt.nil?
                    Display::show ' No bug tracker associated', :notice
                elsif issues.count > 0
                    bt.show_issue_list(issues)
                else
                    Display::show ' No feature branch found', :notice
                end
                first = false
            end
        end

        #
        # Show one issue in bug tracker by using the bt define in the repositories
        #
        def show_issue(issue)
            @repositories.git_repo_list.each { |repository|
                bt = @settings.get_repo_tracker(repository)
                unless bt.nil?
                    bt.show_issue_list(issue)
                end
            }
        end

    end
end

