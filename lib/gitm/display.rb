# encoding: utf-8
# highline.rb

require 'highline'
require 'colorize'
require 'ruby-progressbar'
require 'singleton'
require 'gitm/version'

module Gitm

    class Display

        include Singleton

        VERBOSE_NONE=0
        VERBOSE_LIGHT=10
        VERBOSE_MEDIUM=20
        VERBOSE_FULL=30

        attr_accessor :cli

        # colors @see : http://www.rubydoc.info/gems/highline/HighLine
        def initialize
            @cli = HighLine.new
            theme = HighLine::ColorScheme.new do |cs|
                cs[:default]         = [  ]
                cs[:splash]          = [ :bold, :blue ] #, :on_black ]
                cs[:title]           = [ :bold, :blue ]
                cs[:title2]          = [ :bold, :cyan ]
                cs[:title3]          = [ :bold, :white ]
                cs[:even_row]        = [ :green ]
                cs[:ok]              = [ :bold, :green ]
                cs[:warning]         = [ :bold, :yellow ]
                cs[:error]           = [ :bold, :red ]
                cs[:info]            = [ :blue ]
                cs[:notice]          = [ :yellow ]
                cs[:green]           = [ :green ]
                cs[:grey]            = [ :grey ]
                cs[:red]             = [ :red ]
                cs[:blue]             = [ :blue ]
            end
            HighLine.color_scheme = theme
        end

        # if text and with a space no line return
        def self.show(text='', type=:default, min_size=0, align_right=false, complete_with_dot=false, no_line_return=false)
            size = text.length
            display_text=text
            space=' '

            if complete_with_dot
                space='.'
            end

            if size <= min_size
                if align_right
                    for n in 1..(min_size-size)
                        display_text="#{space}#{display_text}"
                    end
                else
                    for n in 1..(min_size-size)
                        display_text="#{display_text}#{space}"
                    end
                end
            end

            if no_line_return
                display_text="#{display_text} "
            end
            Display.instance.cli.say("<%= color('#{display_text}', '#{type}') %>")
        end

        # Welcome Screen
        def welcome_screen
            screen_color=:splash
            Display::show "# GIT Manager v#{Gitm::VERSION}", screen_color
        end

    end
end