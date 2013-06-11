require 'omnifocus'

class TaskManager

    attr_reader :omnifocus

    def initialize()
      @omnifocus = OmniFocus.new()
    end

    def tasks_due_by(horizon)
      tasks = []
      @omnifocus.all_tasks().each { |task|
        next if (task.completed.get)

        due_date = parse_date(task.due_date.get)

        if (due_date != nil)
          comparison = horizon <=> due_date
          if (horizon == nil || comparison > -1)
            # puts "comparison = horizon <=> due_date:           #{comparison} = #{horizon} <=> #{due_date}"
            tasks << task
          end
        end
      }
      return tasks
    end

    def parse_date(date)
      if (date != :missing_value && date != nil)
        val = Date.parse(date.strftime('%Y/%m/%d'))
      else
        val = nil
      end
      return val
    end
end