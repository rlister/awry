# frozen_string_literal: true

require 'thor'
require_relative "awry/version"

## clean exit on ctrl-c for all methods
trap('SIGINT', 'EXIT')

module Awry
  class Error < StandardError; end

  class Cli < Thor

    no_commands do
      def color(string)
        set_color(string, self.class::COLORS.fetch(string.to_sym, :yellow))
      end

      def tag_name(thing, default = nil)
        tn = thing.tags.find { |tag| tag.key == 'Name' }
        tn ? tn.value : default
      end
    end

  end
end
