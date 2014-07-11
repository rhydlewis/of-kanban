require 'omnifocus'

class TaskManager

    attr_reader :omnifocus, :all_tasks

    def initialize()
      @omnifocus = OmniFocus.new()
      @all_tasks = @omnifocus.all_tasks()
    end

    def flagged_tasks()
      tasks = []
      @all_tasks.each { |task|
        next if (task.completed.get)

        if (task.flagged.get)
          tasks << task
        end
      }

      return tasks
    end

    def tasks_due_by(horizon)
      tasks = []
      @all_tasks.each { |task|
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

    def close_tasks(ids)
      @to_close = @all_tasks.select { |task|
        ids.include?(task.id_.get) && !task.completed.get
      }

      closable = @to_close.size

      if (closable > 0)
        puts "Closing #{closable.to_s} cards"
        @to_close.each { |task|
          id = task.id_.get
          name = task.name.get
          puts "Closing task #{id}::#{name}"
          task.completed.set true
        }
      end
    end
end