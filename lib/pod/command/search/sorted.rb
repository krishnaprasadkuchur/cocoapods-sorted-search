require 'cocoapods'
require 'sorted_search/printers/pods_printer'
require 'sorted_search/credentials'
require 'sorted_search/providers/github_provider'
require 'sorted_search/printers/github_printer'

module Pod
  class Command
    class Search

      # The pod search sort subcommand
      #
      class Sorted < Search

        attr_reader :sorting_criteria

        self.summary = 'Sort pod search results easily!'

        self.description = <<-DESC
          Sort CocoaPods search results by stars, forks, or repo activity.
        DESC

        self.command = "sort"

        def initialize(argv)
          super
          @sorting_criteria = argv.flag?('stars')      ? :stars    : nil
          @sorting_criteria ||= argv.flag?('forks')    ? :forks    : nil
          @sorting_criteria ||= argv.flag?('activity') ? :activity : nil

          unless @sorting_criteria
            @sorting_criteria = :stars
          end

          @provider_klass = SortedSearch::GithubProvider
          @printer_klass = SortedSearch::GitHubPrinter

        end

        def self.options
          [
            ["--stars",   "Sort by stars"],
            ["--activity", "Sort by most recently changed repo"],
            ["--forks",   "Sort by amount of forks"],
          ].concat(super)
        end

        def run
          specs = find_specs(@query)

          provider = @provider_klass.new(specs, @sorting_criteria)
          sorted_pods = provider.provide_sorted_specs

          printer = @printer_klass.new
          printer.print(sorted_pods)
        end

        def find_specs(query)
          sets = SourcesManager.search_by_name(query.join(' ').strip, @full_text_search)
          if @supported_on_ios
            sets.reject! { |set| !set.specification.available_platforms.map(&:name).include?(:ios) }
          end
          if @supported_on_osx
            sets.reject! { |set| !set.specification.available_platforms.map(&:name).include?(:osx) }
          end

          sets
        end
      end
    end
  end
end
