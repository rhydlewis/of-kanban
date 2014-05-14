require 'rubygems'
require 'yaml'
require 'json'
require 'date'

# $: << File.join(File.dirname(__FILE__), "/../../leankitkanban/lib")
require 'leankitkanban'

#mark-off all tasks in OmniFocus as done which have been moved to the 'Done' column in my LeanKit KanBan board.

class KanbanBoard

  EXTERNAL_CARD_ID = "ExternalCardID"
  TITLE = "Title"
  LANE_ID = "LaneId"
  TYPE_ID = "TypeId"
  TAGS = "Tags"
  PRIORITY = "Priority"
  DUE_DATE = "DueDate"
  START_DATE = "StartDate"

  attr_reader :url, :cards

  def initialize()
    config = load_config()
    LeanKitKanban::Config.email = config["email"]
    LeanKitKanban::Config.password = config["password"]
    LeanKitKanban::Config.account = config["account"]
    @board_id = config["board_id"]
    @types = config["card_types"]
    @lane_id = get_backlog_id(config["backlog_lane_id"]) # TODO - don't do this
    @url = config["board_url"]
  end

  def read_board()
    @cards = []

    backlog = []
    archive = []
    in_progress = []

    board = LeanKitKanban::Board.find(@board_id)[0]
    # puts "Looking for cards in board lanes"
    lanes = board["Lanes"]
    lanes.each { |lane| in_progress.concat(read_lane(lane)) }
    # puts "Looking for cards in backlog"
    backlog.concat(read_lane(board["Backlog"][0]))
    # puts "Looking for cards in archive"
    archive.concat(read_lane(board["Archive"][0]))

    @cards.concat(backlog)
    # puts "Found #{@cards.size.to_s} cards in backlog"
    @cards.concat(in_progress)
    # puts "Found #{@cards.size.to_s} cards in backlog and in progress"
    @cards.concat(archive)
    # puts "Found #{@cards.size.to_s} cards on board"

  end

  def add_cards(tasks)
    read_board()
    new_cards = []

    ignored_cards = 0

    tasks.each { |t|
      task = task_to_hash(t)
      context = @types[task[:context]]
      card = { LANE_ID => @lane_id, TITLE => task[:name], TYPE_ID => context,
        EXTERNAL_CARD_ID => task[:external_id], PRIORITY => 1, DUE_DATE => task[:due_date], START_DATE => task[:start_date] }

      if (card_exists_on_board?(card))
        # puts "Ignoring pre-existing card " + task[:name]
        ignored_cards = ignored_cards + 1
      else
        # puts "Adding #{card[TITLE]} as type " + @types.key(context)
        # puts "\t#{card.inspect}"
        new_cards << card
      end
    }

    puts "Found #{new_cards.size.to_s} cards to sync (ignoring #{ignored_cards} already on board)"

    # puts "---"
    # puts new_cards.to_json
    # puts "---"

    if (new_cards.length > 0)
      reply = LeanKitKanban::Card.add_multiple(@board_id, "Imported from OmniFocus", new_cards)
      # puts "RESPONSE\n\t#{reply}"
    end
  end

  def task_to_hash(task)
    name = task.name.get
    due_date = parse_date(task.due_date)
    start_date = parse_date(task.defer_date)

    {:name => name, :external_id => task.id_.get, :context => task.context.name.get, :due_date => due_date, :start_date => start_date }
  end

  def clear_board()
    puts "Clearing board..."
    board = LeanKitKanban::Board.find(@board_id)[0]
    board["Lanes"].each { |lane| clear_lane(lane) }
    board["Backlog"].each { |lane| clear_lane(lane) }
  end

  def clear_lane(lane)
    card_ids = []
    lane["Cards"].each { |card|
      title = card[TITLE]
      if (card[EXTERNAL_CARD_ID] != "")
        puts "removing card #{title}"
        card_ids << card["Id"]
      else
        puts "ignoring non-omnifocus card #{title}"
      end
    }
    # LeanKitKanban::Card.delete_multiple(@board_id, card_ids)
  end

  def get_identifiers
    LeanKitKanban::Board.get_identifiers(@board_id)
  end

  def to_json
    LeanKitKanban::Board.find(@board_id).to_json
  end

  protected

  def read_lane(json)
    lane_title = json[TITLE]
    found_cards = []
    cards = json["Cards"]
    cards.each { |card|
      id = card["ExternalCardID"]
      title = card["Title"]
      found_cards << { EXTERNAL_CARD_ID => id, TITLE => title}
      # puts "\tFound #{id}::#{title} in #{lane_title}"
    }

    # puts "Found #{found_cards.size.to_s} cards  in #{lane_title}"
    return cards
  end

  def load_config()
    path = ENV['HOME'] + "/.leankit-config.yaml"
    config = YAML.load_file(path) rescue nil

    unless config then
      config = { :email => "Your LeanKit username", :password => "Your LeanKit password",
        :account => "Your LeanKit account name",
        :board => "Your LeanKit board ID (copy it from https://<account>.leankit.com/boards/view/<board>)" }
        # :account => ["Done", "Deployed", "Finished", "Cards in these boards are considered done, you add and remove names to fit your workflow."] }

      File.open(path, "w") { |f|
        YAML.dump(config, f)
      }

      abort "Created default LeanKit config in #{path}. Please complete this before re-running of-kanban"
    end

    return config
  end

  def card_exists_on_board?(card)
    title = card[TITLE]
    id = card[EXTERNAL_CARD_ID]

    title_match = false #(@cards.detect { |c| c[TITLE] == title } != nil)
    id_match = (@cards.detect { |c| c[EXTERNAL_CARD_ID] == id } != nil)

    return (title_match || id_match)
  end

  def get_backlog_id(id)
    if (id == nil)
      board = LeanKitKanban::Board.find(@board_id)[0]
      puts "No backlog ID specified, looking for default"
      id = board["Backlog"][0]["Id"]
    end
    return id
  end

  def parse_date(d)
    date = nil
    if (d.get != :missing_value)
      date = Date.parse(d.get.to_s).strftime("%d/%m/%Y")
    end
    return date
  end
end
