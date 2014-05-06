require 'rubygems'
require 'yaml'
require 'json'
require 'date'

# $: << File.join(File.dirname(__FILE__), "/../../leankitkanban/lib")
require 'leankitkanban'

#mark-off all tasks in OmniFocus as done which have been moved to the 'Done' column in my LeanKit KanBan board.

class KanbanBoard

  EXTERNAL_CARD_ID = "ExternalCardID"

  attr_reader :url

  def initialize()
    config = load_config()
    LeanKitKanban::Config.email = config["email"]
    LeanKitKanban::Config.password = config["password"]
    LeanKitKanban::Config.account = config["account"]
    @board_id = config["board_id"]
    @type = config["type"] # TODO - don't do this
    @lane_id = get_backlog_id(config["backlog_lane_id"]) # TODO - don't do this
    @url = config["board_url"]
  end

  def read_board()
    existing_cards = []

    board = LeanKitKanban::Board.find(@board_id)[0]

    puts "Looking for cards in board lanes"
    lanes = board["Lanes"]
    lanes.each { |lane| existing_cards << read_lane(lane) }
    puts "Looking for cards in backlog"
    existing_cards << read_lane(board["Backlog"][0])
    puts "Looking for cards in archive"
    existing_cards << read_lane(board["Archive"][0])
    return existing_cards
  end

  def add_cards(tasks)
    existing_cards = read_board()
    cards = []
    tasks.each { |t|
      task = task_to_hash(t)
      card = { "LaneId" => @lane_id, "Title" => task[:name], "TypeId" => @type,
        "Tags" => task[:context], EXTERNAL_CARD_ID => task[:external_id] }

      if (existing_cards.include?(card[EXTERNAL_CARD_ID]))
        puts "Ignoring pre-existing card " + task[:name]
      else
        puts "Adding " + card.inspect
        cards << card
      end
    }

    if (cards.length > 0)
      reply = LeanKitKanban::Card.add_multiple(@board_id, "updating from omnifocus", cards)
      puts reply
    end
  end

  def task_to_hash(task)
    {:name => task.name.get, :external_id => task.id_.get, :context => task.context.get }
  end

  def clear_board()
    puts "Clearing board..."
    board = LeanKitKanban::Board.find(@board_id)[0]
    board["Lanes"].each { |lane| clear_lane(lane) }
    board["Backlog"].each { |lane| clear_lane(lane) }
  end

  def clear_lane(lane)
    card_ids = []
    lane["Cards"].each { |card| card_ids << card["Id"] }
    LeanKitKanban::Card.delete_multiple(@board_id, card_ids)
  end

  def get_identifiers
    LeanKitKanban::Board.get_identifiers(@board_id)
  end

  def to_json
    LeanKitKanban::Board.find(@board_id).to_json
  end

  protected

  def read_lane(json)
    lane_title = json["Title"]
    found_cards = []
    cards = json["Cards"]
    cards.each { |card|
      found_cards << card["ExternalCardID"]
      # puts "Found " + card["ExternalCardID"].to_s + " in #{lane_title}"
    }

    puts "Found #{found_cards.size.to_s} cards  in #{lane_title}"
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

  def get_backlog_id(id)
    if (id == nil)
      board = LeanKitKanban::Board.find(@board_id)[0]
      puts "No backlog ID specified, looking for default"
      id = board["Backlog"][0]["Id"]
    end
    return id
  end
end

# board = KanbanBoard.new()
# puts board.get_identifiers().to_json()
