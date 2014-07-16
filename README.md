of-kanban
=========

Tool to sync OmniFocus tasks to a Kanban board

# Pre-requisites

You need a Lean Kit portfolio account (see [Lean Kit's site for comparison](http://leankit.com/compare-editions/)) because of-kanban uses custom ID's.

# Configuration

## of-kanban configuration

1. Create a file called ".leankit-config.yaml" in your home directory (e.g. /Users/rhyd/ or ~)
2. Open this file in a text editor:

Edit these parameters...

    email: your registered lean kit address    
    password: your password    
    account: your Lean Kit account name    

4. Find out your Lean Kit board's identifiers. Open http://your-account-name.leankitkanban.com/Kanban/Api/Board/your-board-id/GetBoardIdentifiers.

Edit these parameters...

    board_id: your-board-id
    board_url: https://your-account-name.leankit.com/boards/view/your-board-id
    type: 28278396                  # This is the default card type (probably called "Task")
    backlog_lane_id: 28280020       # Where do you want your OmniFocus cards to go? I use the default "Backlog" lane provided by Lean Kit.
    inbox_lane_id: 28280028         # Not currently used
    card_types:                     # Specify your list of Contexts here and map them 1:1 with a card type. The Context names in this list must match OmniFocus. You can use the same card type for multiple contexts.
      Call: 104000685
      Email: 28278398
      Office: 104000686
      Task: 28278396
      Waiting: 104540917
    completed_lanes:                # Specify which lanes on your board will contain completed cards. of-kanban looks in OmniFocus for tasks matching these cards and then closes them.
      - 28280021
      - 28280025
      - 102431177

# Running the script

## Usage

    Usage: of-kanban [options]
        -f, --flagged                    Sync flagged and available tasks
        -o, --open-board                 Open the kanban board
        -c, --completed                  Update OmniFocus with done cards from Kanban board
        -h, --help                       Display this screen

    Usage: of-kanban [options]

    For help use: of-kanban -h

