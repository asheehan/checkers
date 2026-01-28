defmodule CheckersWeb.NotesLiveTest do
  use CheckersWeb.ConnCase

  # Tag as live tests for optional exclusion (compatibility issues with Elixir 1.14)
  @moduletag :live

  alias Checkers.Labels
  alias Checkers.Notes

  describe "index" do
    test "renders notes page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Checkers"
      assert html =~ "Take a note..."
    end

    test "creates a new note", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Submit the note creation form (the one with phx-submit="create_note")
      assert view
             |> form("form[phx-submit='create_note']", note: %{title: "Test Note", content: "Test content"})
             |> render_submit() =~ "Test Note"
    end

    test "displays existing notes", %{conn: conn} do
      {:ok, _note} = Notes.create_note(%{title: "Existing Note", content: "Content"})

      {:ok, _view, html} = live(conn, ~p"/")
      assert html =~ "Existing Note"
    end

    test "searches notes", %{conn: conn} do
      {:ok, _note1} = Notes.create_note(%{title: "Meeting Notes", content: "Important meeting"})
      {:ok, _note2} = Notes.create_note(%{title: "Shopping List", content: "Buy groceries"})

      {:ok, view, _html} = live(conn, ~p"/")

      html =
        view
        |> element("form[phx-change='search']")
        |> render_change(%{search: "Meeting"})

      assert html =~ "Meeting Notes"
      refute html =~ "Shopping List"
    end
  end

  describe "archive" do
    test "shows archived notes", %{conn: conn} do
      {:ok, note} = Notes.create_note(%{title: "Archived Note", content: "Content"})
      {:ok, _} = Notes.archive_note(note)

      {:ok, _view, html} = live(conn, ~p"/archive")
      assert html =~ "Archived Note"
    end
  end

  describe "labels" do
    test "filters notes by label", %{conn: conn} do
      {:ok, note1} = Notes.create_note(%{title: "Work Note", content: "Content"})
      {:ok, _note2} = Notes.create_note(%{title: "Personal Note", content: "Content"})
      {:ok, label} = Labels.create_label(%{name: "Work"})
      {:ok, _} = Notes.add_label_to_note(note1, label)

      {:ok, _view, html} = live(conn, ~p"/label/#{label.id}")
      assert html =~ "Work Note"
      refute html =~ "Personal Note"
    end
  end
end
