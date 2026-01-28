# Checkers ✓

A Google Keep clone built with Elixir, Phoenix LiveView, and TailwindCSS.

![Checkers Screenshot](https://via.placeholder.com/800x400?text=Checkers+-+Google+Keep+Clone)

## Features

- 📝 **Notes** - Create, edit, and delete notes with titles and content
- ✅ **Checklists** - Convert notes to interactive checklists
- 🎨 **Colors** - 11 Google Keep-style background colors
- 📌 **Pin Notes** - Pin important notes to the top
- 📦 **Archive** - Archive notes you don't need right now
- 🗑️ **Trash** - Soft delete with restore capability
- 🏷️ **Labels** - Organize notes with custom labels
- 🔍 **Search** - Find notes by title or content
- 🌙 **Dark Mode** - Toggle between light and dark themes
- 📱 **Responsive** - Works on desktop and mobile
- ⚡ **Real-time** - LiveView for instant updates without page reloads

## Tech Stack

- **Backend**: Elixir 1.17+, Phoenix 1.8, Phoenix LiveView 1.1
- **Database**: SQLite (via ecto_sqlite3) - no setup required!
- **Frontend**: TailwindCSS 4
- **Testing**: ExUnit with 46 passing tests

## Quick Start

### Prerequisites

- Erlang/OTP 27+
- Elixir 1.17+

### Installation

```bash
# Clone the repository
git clone git@github.com:asheehan/checkers.git
cd checkers

# Run setup script (installs deps, creates DB, builds assets)
./setup.sh

# Or manually:
# mix deps.get
# mix ecto.setup
# mix assets.build

# Start the server
mix phx.server
```

Now visit [`localhost:4000`](http://localhost:4000) in your browser!

### Running Tests

```bash
mix test
```

## Project Structure

```
checkers/
├── lib/
│   ├── checkers/
│   │   ├── notes.ex          # Notes context (business logic)
│   │   ├── notes/
│   │   │   ├── note.ex       # Note schema
│   │   │   └── checklist_item.ex
│   │   ├── labels.ex         # Labels context
│   │   ├── labels/
│   │   │   └── label.ex      # Label schema
│   │   └── repo.ex           # Ecto repo (SQLite)
│   └── checkers_web/
│       ├── live/
│       │   ├── notes_live.ex # Main notes LiveView
│       │   └── labels_live.ex # Labels management
│       └── router.ex
├── priv/
│   └── repo/
│       └── migrations/       # Database migrations
└── test/                     # 46 tests
```

## Database

Checkers uses SQLite for simplicity - no database server needed! The database file is created automatically at:
- Development: `config/checkers_dev.db`
- Test: `config/checkers_test.db`
- Production: Set `DATABASE_PATH` environment variable

## Environment Variables (Production)

| Variable | Description | Default |
|----------|-------------|---------|
| `SECRET_KEY_BASE` | Phoenix secret key | Required |
| `PHX_HOST` | Your domain name | `example.com` |
| `PORT` | HTTP port | `4000` |
| `DATABASE_PATH` | SQLite database path | `config/checkers_prod.db` |

Generate a secret key with: `mix phx.gen.secret`

## Routes

| Path | Description |
|------|-------------|
| `/` | Main notes view |
| `/archive` | Archived notes |
| `/trash` | Deleted notes |
| `/label/:id` | Notes filtered by label |
| `/labels` | Manage labels |
| `/notes/:id` | View/edit a specific note |

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

## License

MIT License - feel free to use this project however you like!

---

Built with ❤️ using Phoenix LiveView
