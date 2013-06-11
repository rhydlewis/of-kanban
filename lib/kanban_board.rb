require 'rubygems'
require 'yaml'
require 'json'
require 'date'

$: << File.join(File.dirname(__FILE__), "/../../leankitkanban/lib")

require 'leankitkanban'

#mark-off all tasks in OmniFocus as done which have been moved to the 'Done' column in my LeanKit KanBan board.

class KanbanBoard

  EXTERNAL_CARD_ID = "ExternalCardID"

  def initialize()
    config = YAML.load_file(ENV['HOME'] + "/.leankit-config.yaml")
    LeanKitKanban::Config.email = config["email"]
    LeanKitKanban::Config.password = config["password"]
    LeanKitKanban::Config.account = config["account"]
    @board_id = config["board_id"]
  end

  def read_board()
    lanes = LeanKitKanban::Board.find(@board_id)[0]["Lanes"]
    existing_cards = []

    lanes.each { |lane|
      lane["Cards"].each { |card|
        existing_cards << card["ExternalCardID"]
        puts "Found " + card["ExternalCardID"].to_s
      }
    }
    return existing_cards
  end

  def add_cards(tasks)
    type = 31854214 # hard coding this for now
    lane_id = 31854083 # hard coding this for now

    existing_cards = read_board()
    cards = []
    tasks.each { |t|
      task = task_to_hash(t)
      card = { "LaneId" => lane_id, "Title" => task[:name], "TypeId" => type,
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
end