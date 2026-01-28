defmodule CheckersWeb.Router do
  use CheckersWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CheckersWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CheckersWeb do
    pipe_through :browser

    live "/", NotesLive, :index
    live "/archive", NotesLive, :archive
    live "/trash", NotesLive, :trash
    live "/label/:label_id", NotesLive, :label
    live "/notes/:id", NotesLive, :show
    live "/labels", LabelsLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", CheckersWeb do
  #   pipe_through :api
  # end
end
