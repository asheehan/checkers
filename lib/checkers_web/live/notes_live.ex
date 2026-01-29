defmodule CheckersWeb.NotesLive do
  use CheckersWeb, :live_view

  alias Checkers.Labels
  alias Checkers.Notes
  alias Checkers.Notes.Note

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Checkers")
     |> assign(:labels, Labels.list_labels())
     |> assign(:search, "")
     |> assign(:view_mode, :grid)
     |> assign(:dark_mode, false)
     |> assign(:show_sidebar, true)
     |> assign(:editing_note, nil)
     |> assign(:selected_label, nil)
     |> assign(:label_popover_open, false)
     |> assign(:quick_note, %{title: "", content: ""})}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Notes")
    |> assign(:notes, Notes.list_notes(search: socket.assigns.search))
    |> assign(:current_view, :notes)
    |> assign(:selected_label, nil)
    |> assign(:editing_note, nil)
  end

  defp apply_action(socket, :archive, _params) do
    socket
    |> assign(:page_title, "Archive")
    |> assign(:notes, Notes.list_archived_notes())
    |> assign(:current_view, :archive)
    |> assign(:selected_label, nil)
    |> assign(:editing_note, nil)
  end

  defp apply_action(socket, :trash, _params) do
    socket
    |> assign(:page_title, "Trash")
    |> assign(:notes, Notes.list_trashed_notes())
    |> assign(:current_view, :trash)
    |> assign(:selected_label, nil)
    |> assign(:editing_note, nil)
  end

  defp apply_action(socket, :label, %{"label_id" => label_id}) do
    label = Labels.get_label!(label_id)

    socket
    |> assign(:page_title, label.name)
    |> assign(:notes, Notes.list_notes(label_id: label_id))
    |> assign(:current_view, :label)
    |> assign(:selected_label, label)
    |> assign(:editing_note, nil)
  end

  defp apply_action(socket, :show, %{"id" => id}) do
    note = Notes.get_note!(id)

    socket
    |> assign(:page_title, note.title || "Note")
    |> assign(:editing_note, note)
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    notes =
      case socket.assigns.current_view do
        :notes -> Notes.list_notes(search: search)
        :label -> Notes.list_notes(label_id: socket.assigns.selected_label.id, search: search)
        _ -> socket.assigns.notes
      end

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:notes, notes)}
  end

  @impl true
  def handle_event("create_note", %{"note" => note_params}, socket) do
    # Only create if there's content
    if note_params["title"] != "" or note_params["content"] != "" do
      case Notes.create_note(note_params) do
        {:ok, _note} ->
          {:noreply,
           socket
           |> assign(:quick_note, %{title: "", content: ""})
           |> refresh_notes()}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_note", %{"note" => note_params}, socket) do
    case Notes.update_note(socket.assigns.editing_note, note_params) do
      {:ok, _note} ->
        {:noreply,
         socket
         |> assign(:editing_note, nil)
         |> push_patch(to: current_path(socket))
         |> refresh_notes()}

      {:error, _changeset} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("toggle_pin", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.toggle_pin(note)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("set_color", %{"id" => id, "color" => color}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.update_color(note, color)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("archive_note", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.archive_note(note)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("unarchive_note", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.unarchive_note(note)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("trash_note", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.trash_note(note)

    {:noreply,
     socket
     |> assign(:editing_note, nil)
     |> refresh_notes()}
  end

  @impl true
  def handle_event("restore_note", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.restore_note(note)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("delete_note", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.delete_note(note)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("empty_trash", _params, socket) do
    # Delete all trashed notes
    Enum.each(socket.assigns.notes, &Notes.delete_note/1)
    {:noreply, assign(socket, :notes, [])}
  end

  @impl true
  def handle_event("toggle_checklist", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, updated_note} = Notes.toggle_checklist(note)

    {:noreply,
     socket
     |> assign(:editing_note, if(socket.assigns.editing_note, do: updated_note))
     |> refresh_notes()}
  end

  @impl true
  def handle_event("add_checklist_item", %{"note_id" => note_id, "content" => content}, socket) do
    note = Notes.get_note!(note_id)

    if content != "" do
      {:ok, _item} = Notes.create_checklist_item(note, %{content: content})
    end

    updated_note = Notes.get_note!(note_id)

    {:noreply,
     socket
     |> assign(:editing_note, updated_note)
     |> refresh_notes()}
  end

  @impl true
  def handle_event("toggle_checklist_item", %{"id" => id}, socket) do
    item = Notes.get_checklist_item!(id)
    {:ok, _item} = Notes.toggle_checklist_item(item)

    # Refresh the editing note if we're editing
    socket =
      if socket.assigns.editing_note do
        assign(socket, :editing_note, Notes.get_note!(socket.assigns.editing_note.id))
      else
        socket
      end

    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("delete_checklist_item", %{"id" => id}, socket) do
    item = Notes.get_checklist_item!(id)
    {:ok, _item} = Notes.delete_checklist_item(item)

    # Refresh the editing note if we're editing
    socket =
      if socket.assigns.editing_note do
        assign(socket, :editing_note, Notes.get_note!(socket.assigns.editing_note.id))
      else
        socket
      end

    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("add_label_to_note", %{"note_id" => note_id, "label_id" => label_id}, socket) do
    note = Notes.get_note!(note_id)
    label = Labels.get_label!(label_id)
    {:ok, updated_note} = Notes.add_label_to_note(note, label)

    {:noreply,
     socket
     |> assign(:editing_note, if(socket.assigns.editing_note, do: updated_note))
     |> refresh_notes()}
  end

  @impl true
  def handle_event(
        "remove_label_from_note",
        %{"note_id" => note_id, "label_id" => label_id},
        socket
      ) do
    note = Notes.get_note!(note_id)
    label = Labels.get_label!(label_id)
    {:ok, updated_note} = Notes.remove_label_from_note(note, label)

    {:noreply,
     socket
     |> assign(:editing_note, if(socket.assigns.editing_note, do: updated_note))
     |> refresh_notes()}
  end

  @impl true
  def handle_event("toggle_view_mode", _params, socket) do
    new_mode = if socket.assigns.view_mode == :grid, do: :list, else: :grid
    {:noreply, assign(socket, :view_mode, new_mode)}
  end

  @impl true
  def handle_event("toggle_dark_mode", _params, socket) do
    {:noreply, assign(socket, :dark_mode, !socket.assigns.dark_mode)}
  end

  @impl true
  def handle_event("toggle_sidebar", _params, socket) do
    {:noreply, assign(socket, :show_sidebar, !socket.assigns.show_sidebar)}
  end

  @impl true
  def handle_event("open_note", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/notes/#{id}")}
  end

  @impl true
  def handle_event("close_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:editing_note, nil)
     |> assign(:label_popover_open, false)
     |> push_patch(to: current_path(socket))}
  end

  @impl true
  def handle_event("toggle_label_popover", _params, socket) do
    {:noreply, assign(socket, :label_popover_open, !socket.assigns.label_popover_open)}
  end

  @impl true
  def handle_event("close_label_popover", _params, socket) do
    {:noreply, assign(socket, :label_popover_open, false)}
  end

  # Drag and drop handlers
  @impl true
  def handle_event("reorder_notes", %{"ids" => ids}, socket) do
    Notes.update_positions(ids)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("drop_to_archive", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.archive_note(note)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("drop_to_trash", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    {:ok, _note} = Notes.trash_note(note)
    {:noreply, refresh_notes(socket)}
  end

  @impl true
  def handle_event("drop_to_notes", %{"id" => id}, socket) do
    note = Notes.get_note!(id)
    # Restore from archive or trash
    cond do
      note.is_archived ->
        {:ok, _note} = Notes.unarchive_note(note)

      note.deleted_at != nil ->
        {:ok, _note} = Notes.restore_note(note)

      true ->
        :ok
    end

    {:noreply, refresh_notes(socket)}
  end

  defp refresh_notes(socket) do
    notes =
      case socket.assigns.current_view do
        :notes -> Notes.list_notes(search: socket.assigns.search)
        :archive -> Notes.list_archived_notes()
        :trash -> Notes.list_trashed_notes()
        :label -> Notes.list_notes(label_id: socket.assigns.selected_label.id)
      end

    assign(socket, :notes, notes)
  end

  defp current_path(socket) do
    case socket.assigns.current_view do
      :notes -> ~p"/"
      :archive -> ~p"/archive"
      :trash -> ~p"/trash"
      :label -> ~p"/label/#{socket.assigns.selected_label.id}"
    end
  end

  # Colors for Google Keep style
  def note_colors do
    [
      {"default", "Default", "bg-white dark:bg-gray-800",
       "bg-white dark:bg-gray-800 border-gray-200"},
      {"red", "Red", "bg-red-100 dark:bg-red-900/30", "#f28b82"},
      {"orange", "Orange", "bg-orange-100 dark:bg-orange-900/30", "#fbbc04"},
      {"yellow", "Yellow", "bg-yellow-100 dark:bg-yellow-900/30", "#fff475"},
      {"green", "Green", "bg-green-100 dark:bg-green-900/30", "#ccff90"},
      {"teal", "Teal", "bg-teal-100 dark:bg-teal-900/30", "#a7ffeb"},
      {"blue", "Blue", "bg-blue-100 dark:bg-blue-900/30", "#cbf0f8"},
      {"purple", "Purple", "bg-purple-100 dark:bg-purple-900/30", "#d7aefb"},
      {"pink", "Pink", "bg-pink-100 dark:bg-pink-900/30", "#fdcfe8"},
      {"brown", "Brown", "bg-amber-100 dark:bg-amber-900/30", "#e6c9a8"},
      {"gray", "Gray", "bg-gray-100 dark:bg-gray-700/50", "#e8eaed"}
    ]
  end

  def color_class(color) do
    {_, _, class, _} =
      Enum.find(note_colors(), fn {c, _, _, _} -> c == color end) ||
        {"default", "", "bg-white dark:bg-gray-800", ""}

    class
  end

  # Label color mapping (tailwind classes for badges)
  def label_colors do
    %{
      "gray" => {"bg-gray-200 text-gray-700 dark:bg-gray-600 dark:text-gray-200", "#6b7280"},
      "red" => {"bg-red-200 text-red-800 dark:bg-red-900/50 dark:text-red-200", "#ef4444"},
      "orange" =>
        {"bg-orange-200 text-orange-800 dark:bg-orange-900/50 dark:text-orange-200", "#f97316"},
      "yellow" =>
        {"bg-yellow-200 text-yellow-800 dark:bg-yellow-900/50 dark:text-yellow-200", "#eab308"},
      "green" =>
        {"bg-green-200 text-green-800 dark:bg-green-900/50 dark:text-green-200", "#22c55e"},
      "teal" => {"bg-teal-200 text-teal-800 dark:bg-teal-900/50 dark:text-teal-200", "#14b8a6"},
      "blue" => {"bg-blue-200 text-blue-800 dark:bg-blue-900/50 dark:text-blue-200", "#3b82f6"},
      "purple" =>
        {"bg-purple-200 text-purple-800 dark:bg-purple-900/50 dark:text-purple-200", "#a855f7"},
      "pink" => {"bg-pink-200 text-pink-800 dark:bg-pink-900/50 dark:text-pink-200", "#ec4899"},
      "brown" =>
        {"bg-amber-200 text-amber-800 dark:bg-amber-900/50 dark:text-amber-200", "#d97706"}
    }
  end

  def label_badge_class(color) do
    {class, _hex} =
      Map.get(label_colors(), color || "gray", {"bg-gray-200 text-gray-700", "#6b7280"})

    class
  end

  def label_color_hex(color) do
    {_class, hex} = Map.get(label_colors(), color || "gray", {"", "#6b7280"})
    hex
  end

  attr :note, Note, required: true
  attr :view_mode, :atom, required: true
  attr :current_view, :atom, required: true
  attr :labels, :list, required: true

  def note_card(assigns) do
    ~H"""
    <div
      phx-click="open_note"
      phx-value-id={@note.id}
      class={"group cursor-pointer rounded-lg border border-gray-200 dark:border-gray-700 shadow-sm hover:shadow-md transition-shadow " <> color_class(@note.color)}
    >
      <div class="p-4">
        <%= if @note.title && @note.title != "" do %>
          <h3 class="font-medium text-gray-900 dark:text-white mb-2 line-clamp-1">
            <%= @note.title %>
          </h3>
        <% end %>

        <%= if @note.is_checklist && length(@note.checklist_items) > 0 do %>
          <div class="space-y-1">
            <%= for item <- Enum.take(@note.checklist_items, 5) do %>
              <div class="flex items-center text-sm">
                <%= if item.is_checked do %>
                  <svg class="w-4 h-4 mr-2 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                    <path
                      fill-rule="evenodd"
                      d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                      clip-rule="evenodd"
                    />
                  </svg>
                  <span class="line-through text-gray-400"><%= item.content %></span>
                <% else %>
                  <svg
                    class="w-4 h-4 mr-2 text-gray-400"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <circle cx="12" cy="12" r="10" stroke-width="2" />
                  </svg>
                  <span class="text-gray-700 dark:text-gray-300"><%= item.content %></span>
                <% end %>
              </div>
            <% end %>
            <%= if length(@note.checklist_items) > 5 do %>
              <p class="text-sm text-gray-400">+ <%= length(@note.checklist_items) - 5 %> more</p>
            <% end %>
          </div>
        <% else %>
          <%= if @note.content && @note.content != "" do %>
            <p class="text-sm text-gray-700 dark:text-gray-300 line-clamp-4 whitespace-pre-wrap">
              <%= @note.content %>
            </p>
          <% end %>
        <% end %>
        <!-- Labels -->
        <%= if length(@note.labels) > 0 do %>
          <div class="flex flex-wrap gap-1 mt-3">
            <%= for label <- @note.labels do %>
              <span class={"px-2 py-0.5 text-xs rounded-full " <> label_badge_class(label.color)}>
                <%= label.name %>
              </span>
            <% end %>
          </div>
        <% end %>
      </div>
      <!-- Hover actions -->
      <div class="flex items-center justify-between px-2 py-1 opacity-0 group-hover:opacity-100 transition-opacity border-t border-gray-200/50 dark:border-gray-700/50">
        <%= if @current_view == :trash do %>
          <button
            type="button"
            phx-click="restore_note"
            phx-value-id={@note.id}
            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-full hover:bg-gray-200/50 dark:hover:bg-gray-700/50"
            title="Restore"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"
              />
            </svg>
          </button>
          <button
            type="button"
            phx-click="delete_note"
            phx-value-id={@note.id}
            data-confirm="Delete forever?"
            class="p-2 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-200/50 dark:hover:bg-gray-700/50"
            title="Delete forever"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </button>
        <% else %>
          <%= if @current_view != :archive do %>
            <button
              type="button"
              phx-click="toggle_pin"
              phx-value-id={@note.id}
              class={"p-2 rounded-full hover:bg-gray-200/50 dark:hover:bg-gray-700/50 " <> if(@note.is_pinned, do: "text-yellow-600", else: "text-gray-400 hover:text-gray-600 dark:hover:text-gray-300")}
              title={if @note.is_pinned, do: "Unpin", else: "Pin"}
            >
              <svg
                class="w-4 h-4"
                fill={if @note.is_pinned, do: "currentColor", else: "none"}
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z"
                />
              </svg>
            </button>
          <% end %>

          <button
            type="button"
            phx-click={if @current_view == :archive, do: "unarchive_note", else: "archive_note"}
            phx-value-id={@note.id}
            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-full hover:bg-gray-200/50 dark:hover:bg-gray-700/50"
            title={if @current_view == :archive, do: "Unarchive", else: "Archive"}
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"
              />
            </svg>
          </button>

          <button
            type="button"
            phx-click="trash_note"
            phx-value-id={@note.id}
            class="p-2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 rounded-full hover:bg-gray-200/50 dark:hover:bg-gray-700/50"
            title="Delete"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
              />
            </svg>
          </button>
        <% end %>
      </div>
    </div>
    """
  end
end
