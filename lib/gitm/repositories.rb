# encoding: utf-8
# repositories.rb

require 'rugged'

module Gitm

    class Repositories

        attr_accessor :git_repo_list

        def initialize
            @git_repo_list=[]
            @credentials = Rugged::Credentials::SshKeyFromAgent.new(username: 'git')
        end

        #
        # Fetch -p all the repositories founded
        #
        def fetch_all
            @git_repo_list.each do |repo|
                self.fetch(repo)
            end
        end

        #
        # Find git repositories
        #
        def find_repositories(folder)
            Dir.chdir(folder)
            # If we are in a git repository discover it
            begin
                current_repo = Rugged::Repository.discover
                add_git_repository(current_repo)
            rescue
                # If not search repo in sub-folders
                Dir.glob('*') {|f|
                    if File.directory?(f) and File.exist?("#{f}/.git")
                        add_git_repository(f)
                    end
                }
            end
            @git_repo_list
        end

        #
        # Show the founded repo list
        # @param verbose_level The dislay information level
        #   Display::VERBOSE_LIGHT
        #   Display::VERBOSE_FULL
        #
        def show_repo_list(verbose_level)
            if @git_repo_list.length > 0
                @git_repo_list.each do |repo|
                    show_repo_info_full(repo, verbose_level)
                end
            else
                Display::show 'No repository found', :error
            end
            self
        end

        def show_status
            @git_repo_list.each { |repository|
                repository.branches.each(:local) { |branch|
                    puts branch.name # TODO add behind / before
                }
            }
        end

        #
        # Compare a branch with all the over branch of the repository
        #
        def compare(ref_branch_name, verbose_level)
            if ref_branch_name.nil? || ref_branch_name == ''
                ref_branch_name= 'origin/develop'
            end
            @git_repo_list.each { |repository|
                repo_name=File.basename(repository.workdir)
                Display::show "Repository : #{repo_name}", :title

                self.show_repo_branch_compare(repository, ref_branch_name, verbose_level)
            }
        end

        #
        # Show branch information
        #
        def show_branch(branch, repo, is_local=false)
            upstream_info = branch.upstream
            Display::show "   » #{branch.name} ", :default, 30
            if is_local
                if upstream_info.nil?
                    not_found=true
                    repo.remotes.each { |remote|
                        if repo.branches.exist?("#{remote.name}/#{branch.name}")
                            not_found=false
                            Display::show "» Remote exist and is not linked (you should do a git branch -u #{remote.name}/#{branch.name}) ", :error
                        end
                    }
                    if not_found
                        Display::show '» No remote upstream found (you should push) ', :warning
                    end
                else
                    if repo.branches.exist?(branch.upstream.name)
                        Display::show "» #{branch.upstream.name}", :default, 40
                        repo_delta=repo.ahead_behind(branch.target, branch.upstream.target)
                        ahead=repo_delta[0]
                        behind=repo_delta[1]
                        if ahead==0 and behind==0
                            Display::show 'Synchonized ', :ok
                        else
                            Display::show '( '
                            Display::show "ahead by : #{ahead} commits ", (ahead > 0 )?:warning:'default'
                            Display::show '/ '
                            Display::show "behind by : #{behind} commits ", (behind > 0 )?:error:'default'
                            Display::show ') '
                        end
                    else
                        Display::show "X #{branch.upstream.name}", :error, 40
                        Display::show 'Upstream no longer exist', :error
                    end
                end
            end
        end

        #
        # Show repository information
        # Rugged::Repository repo
        #
        def show_repo_info_full (repo, verbose)
            name=File.basename(repo.workdir)
            Display::show "► #{name}", :title
            Display::show "  (#{repo.workdir})", :info

            if verbose >= Display::VERBOSE_LIGHT
                # Rugged::Repository repo
                Display::show '  • Remotes :', :title2
                repo.remotes.each { |remote|
                    Display::show "   » #{remote.name} (#{remote.url})", :notice
                }
                if verbose >= Display::VERBOSE_MEDIUM
                    Display::show '  • Local Branches :', :title2
                    repo.branches.each(:local) { |branch|
                        show_branch(branch, repo, true)
                        Display::show ''
                    }
                    if verbose >= Display::VERBOSE_FULL
                        Display::show '  • Remote Branches :', :title2
                        repo.branches.each(:remote) { |branch|
                            show_branch(branch, repo, false)
                            Display::show ''
                        }
                    end
                end
                Display::show "----"
            end
        end

        #
        # @return Rugged::Repository
        #
        def add_git_repository(repo)
            if repo.is_a?(Rugged::Repository)
                repository=repo
            else
                repository = Rugged::Repository.new(repo)
            end
            @git_repo_list.push(repository)
        end


        def show_progress(progress)
            puts progress
        end

        #
        # Fetch a repository
        #
        def fetch(repo)
            repo.remotes.each{ |remote|
                Display::show "Fetch #{remote.url} on #{File.basename(repo.workdir)}", :info
                if remote.url.include?('git@')
                    remote.fetch(credentials: @credentials, prune: true, progress: lambda {|progress| self.show_progress(progress)})
                else
                    remote.fetch(prune: true,  progress: lambda {|progress| self.show_progress(progress)})
                end
            }
        end

        #
        # Do and Show branch comparison with the reference_branch_name
        # Rugged::Repository repo
        # String ref_branch_name
        #
        def show_repo_branch_compare(repo, ref_branch_name, verbose)
            ref_branch = repo.branches[ref_branch_name]
            if ref_branch.nil?
                Display::show 'Reference branch not found', :error
            else
                Display::show "Compare to #{ref_branch_name}", :notice
                Display::show "--- Local ---", :title2
                repo.branches.each_name(:local) { |branch|
                    self.show_branch_compare(repo, branch, ref_branch_name)
                }
                if verbose >= Display::VERBOSE_MEDIUM
                    Display::show "--- Remote ---", :title2
                    repo.branches.each_name(:remote) { |branch|
                        self.show_branch_compare(repo, branch, ref_branch_name)
                    }
                end
                Display::show ''
                Display::show "Legend :", :notice
                Display::show "branch name : .................................... ", :info
                Display::show "[ Commits in compare branch and not in current branch ] ", :grey
                Display::show "[ Commits in current and not in compared branch ]", :green
            end
        end

        def show_branch_compare(repo, branch_to_compare, branch_ref)
            repo_delta=repo.ahead_behind(branch_to_compare, branch_ref)
            ahead=repo_delta[0]
            behind=repo_delta[1]

            show_behind=''
            if behind > 0
                max=(behind/10 > 50)?50:behind/10
                for i in (0 .. max)
                    show_behind="#{show_behind}|"
                end
            end

            show_ahead=''
            if ahead > 0
                max=(ahead/10 > 50)?50:ahead/10
                for i in (0 .. max)
                    show_ahead="#{show_ahead}|"
                end
            end
            Display::show "#{branch_to_compare} : ", :info, 50, false, true, true
            Display::show "#{show_behind} ", :grey, 52, true, true
            Display::show "#{behind} ", :grey, 5, true
            Display::show "#{ahead} ", :green, 5
            Display::show "#{show_ahead} ", :green, 52
            Display::show "", :grey

            # Display::show "#{branch_to_compare} : ", :info
            # Display::show "( "
            # Display::show "#{behind} ", :grey
            # Display::show "| "
            # Display::show "#{ahead} ", :green
            # Display::show ") "
            # Display::show "#{show_behind} ", :grey
            # Display::show "#{show_ahead} ", :green
            # Display::show "", :grey
        end

        #
        # Use to find the pattern in all repositories branches
        #
        def find_in_logs(pattern, verbose)
            puts "searched pattern : #{pattern}"
            @git_repo_list.each { |repo|
                repo_name=File.basename(repo.workdir)
                repo.branches.each { |branch|
                    find_count=0
                    commits_to_show=[]
                    walker = Rugged::Walker.new(repo)
                    walker.sorting(Rugged::SORT_TOPO | Rugged::SORT_REVERSE)
                    walker.push(branch.target_id)
                    walker.each { |commit|
                        unless commit.message.match("#{pattern}").nil? and commit.oid.match("#{pattern}").nil?
                            commits_to_show.push(commit)
                            find_count = find_count+1
                        end
                    }
                    walker.reset
                    # Show result
                    if find_count > 0
                        Display::show "► #{repo_name} » #{branch.name} » (#{find_count})", :title
                        commits_to_show.uniq.each { |commit|
                            self.show_commit(commit)
                        }
                    end
                }
            }
        end

        def show_commit(commit)
            id = commit.oid
            short_id=id[0...8]
            time=commit.time
            author = commit.author
            message= commit.message

            Display::show "#{short_id} - #{time.strftime '%Y-%m-%d %H:%M'} - #{author[:name]} ", :notice, 60
            puts " -  #{message.lines.first}"
        end

        def show_log(log)
            Display::show "  #{log[:id_new]}", :notice
            Display::show "  #{log[:committer][:name]} - #{log[:committer][:email]} "
            Display::show " : #{log[:message]}"
            Display::show ''
        end

    end

end