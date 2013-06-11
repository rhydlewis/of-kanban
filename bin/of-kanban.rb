#! /usr/bin/env ruby

# == Synopsis
#
# == Usage
# Usage: of-kanban [options]
#
# == Options
#   -h, --help                Displays help message
#   -d, --due [yyyy-mm-ss]    Sync available tasks due by [yyyy-mm-dd]
#   -f, --flagged             Sync flagged and available tasks
#   -i, --ignore-start        Ignore start dates
#
# == Author
#   Rhyd Lewis
#
# == Copyright
#   Copyright (c) 2013 Rhyd Lewis

require 'json'
require 'ostruct'
require 'optparse'
require 'chronic'

$: << File.join(File.dirname(__FILE__), "/../lib")
require 'kanban_board'
require 'task_manager'

class OFKanban
  VERSION = '0.1'
  BANNER = "Usage: of-kanban [options]"
  MORE_INFO = "For help use: of-kanban -h"

  attr_reader :options

  def initialize(args, stdin)
    @arguments = args
    @stdin = stdin
    @options = OpenStruct.new
  end

  def run
    if (!parsed_options?)
      usage_and_exit
    end

    sync
  end

  protected

    def parsed_options?
      opts = OptionParser.new
      opts.banner = BANNER
      opts.on('-d', '--due_date [yyyy-mm-dd]', 'Sync available tasks due by [yyyy-mm-dd]') do |date|
        @options.due = true
        @options.due_date = parse_date(date || '')
        puts "due date is #{@options.due_date}"
      end
      opts.on('-c', '--clear-board', 'Remove all cards from Lean Kit board') { @options.clear = true }
      opts.on('-f', '--flagged', 'Sync flagged and available tasks') { @options.flagged = true }
      opts.on('-h', '--help', 'Display this screen' ) do
        puts opts
        puts
        puts FORMAT
        exit(0)
      end

      opts.parse!(@arguments) rescue return false

      true
    end

    def sync
      task_man = TaskManager.new()
      board = KanbanBoard.new()
      tasks = []

      if (@options.clear)
        board.clear_board()
      end

      if (@options.due)
        tasks.concat(task_man.tasks_due_by(@options.due_date))
      end

      if (@options.flagged)
        tasks.concat(task_man.flagged_tasks())
      end

      if (tasks.size > 0)
        puts "Syncing #{tasks.size.to_s} cards to Kanban board"
        board.add_cards(tasks)
      end
    end

    def usage_and_exit
      puts BANNER
      puts
      puts MORE_INFO
      exit(0)
    end

    def parse_date(datestring)
      days = 0
      if datestring =~ /^\+(\d+)d$/
        days = (60 * 60 * 24 * $1.to_i)
        newdate = Time.now + days
      elsif datestring =~ /^\+(\w+)w$/
        days = (7 * 60 * 60 * 24 * $1.to_i)
        newdate = Time.now + days
      else
        newdate = Chronic.parse(datestring, {:context => :future, :ambiguous_time_range => 8})
      end
      return Date.parse(newdate.strftime('%Y/%m/%d'))
    end
end

app = OFKanban.new(ARGV, STDIN)
app.run
