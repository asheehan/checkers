defmodule CheckersWeb.LabelsLive do
  use CheckersWeb, :live_view

  alias Checkers.Labels
  alias Checkers.Labels.Label

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Edit Labels")
     |> assign(:labels, Labels.list_labels())
     |> assign(:editing_label, nil)
     |> assign(:new_label_name, "")
     |> assign(:new_label_color, "gray")
     |> assign(:editing_color, nil)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_label", %{"name" => name}, socket) do
    if name != "" do
      case Labels.create_label(%{name: name, color: socket.assigns.new_label_color}) do
        {:ok, _label} ->
          {:noreply,
           socket
           |> assign(:labels, Labels.list_labels())
           |> assign(:new_label_name, "")
           |> assign(:new_label_color, "gray")}

        {:error, _changeset} ->
          {:noreply, put_flash(socket, :error, "Label already exists")}
      end
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("set_new_label_color", %{"color" => color}, socket) do
    {:noreply, assign(socket, :new_label_color, color)}
  end

  @impl true
  def handle_event("update_label", %{"id" => id, "name" => name}, socket) do
    label = Labels.get_label!(id)
    color = socket.assigns.editing_color || label.color

    case Labels.update_label(label, %{name: name, color: color}) do
      {:ok, _label} ->
        {:noreply,
         socket
         |> assign(:labels, Labels.list_labels())
         |> assign(:editing_label, nil)
         |> assign(:editing_color, nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update label")}
    end
  end

  @impl true
  def handle_event("set_editing_color", %{"color" => color}, socket) do
    {:noreply, assign(socket, :editing_color, color)}
  end

  @impl true
  def handle_event("delete_label", %{"id" => id}, socket) do
    label = Labels.get_label!(id)
    {:ok, _} = Labels.delete_label(label)

    {:noreply,
     socket
     |> assign(:labels, Labels.list_labels())}
  end

  @impl true
  def handle_event("start_editing", %{"id" => id}, socket) do
    label = Labels.get_label!(id)
    {:noreply, 
     socket
     |> assign(:editing_label, id)
     |> assign(:editing_color, label.color)}
  end

  @impl true
  def handle_event("cancel_editing", _params, socket) do
    {:noreply, 
     socket
     |> assign(:editing_label, nil)
     |> assign(:editing_color, nil)}
  end

  # Label color helpers
  def label_colors do
    Label.colors()
  end

  def color_hex(color) do
    %{
      "gray" => "#6b7280",
      "red" => "#ef4444",
      "orange" => "#f97316",
      "yellow" => "#eab308",
      "green" => "#22c55e",
      "teal" => "#14b8a6",
      "blue" => "#3b82f6",
      "purple" => "#a855f7",
      "pink" => "#ec4899",
      "brown" => "#d97706"
    }[color] || "#6b7280"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-900">
      <!-- Header -->
      <header class="sticky top-0 z-40 bg-white dark:bg-gray-800 border-b border-gray-200 dark:border-gray-700 shadow-sm">
        <div class="flex items-center h-16 px-4">
          <.link
            navigate={~p"/"}
            class="p-2 mr-2 text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-full"
          >
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
          </.link>
          <span class="text-xl font-semibold text-gray-800 dark:text-white">Edit Labels</span>
        </div>
      </header>

      <!-- Main content -->
      <main class="max-w-lg mx-auto p-4">
        <div class="bg-white dark:bg-gray-800 rounded-lg shadow">
          <!-- Create new label -->
          <div class="p-4 border-b border-gray-200 dark:border-gray-700">
            <form phx-submit="create_label" class="flex items-center">
              <div class="relative group mr-4">
                <button 
                  type="button"
                  class="w-6 h-6 rounded-full border-2 border-gray-300"
                  style={"background-color: #{color_hex(@new_label_color)}"}
                />
                <div class="absolute left-0 top-full mt-1 hidden group-hover:flex gap-1 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-2 z-10">
                  <%= for color <- label_colors() do %>
                    <button
                      type="button"
                      phx-click="set_new_label_color"
                      phx-value-color={color}
                      class={"w-6 h-6 rounded-full border-2 " <> if(color == @new_label_color, do: "border-blue-500", else: "border-transparent hover:border-gray-300")}
                      style={"background-color: #{color_hex(color)}"}
                    />
                  <% end %>
                </div>
              </div>
              <input
                type="text"
                name="name"
                value={@new_label_name}
                placeholder="Create new label"
                class="flex-1 bg-transparent border-none focus:ring-0 text-gray-900 dark:text-white placeholder-gray-400"
              />
              <button
                type="submit"
                class="px-3 py-1 text-sm text-gray-600 hover:bg-gray-100 dark:hover:bg-gray-700 rounded"
              >
                Done
              </button>
            </form>
          </div>

          <!-- Labels list -->
          <%= for label <- @labels do %>
            <div class="flex items-center p-4 border-b border-gray-200 dark:border-gray-700 last:border-b-0 group">
              <%= if @editing_label == label.id do %>
                <form
                  phx-submit="update_label"
                  phx-value-id={label.id}
                  class="flex items-center flex-1"
                >
                  <div class="relative group/color mr-4">
                    <button 
                      type="button"
                      class="w-6 h-6 rounded-full border-2 border-gray-300"
                      style={"background-color: #{color_hex(@editing_color || label.color)}"}
                    />
                    <div class="absolute left-0 top-full mt-1 hidden group-hover/color:flex gap-1 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-2 z-10">
                      <%= for color <- label_colors() do %>
                        <button
                          type="button"
                          phx-click="set_editing_color"
                          phx-value-color={color}
                          class={"w-6 h-6 rounded-full border-2 " <> if(color == (@editing_color || label.color), do: "border-blue-500", else: "border-transparent hover:border-gray-300")}
                          style={"background-color: #{color_hex(color)}"}
                        />
                      <% end %>
                    </div>
                  </div>
                  <input
                    type="text"
                    name="name"
                    value={label.name}
                    autofocus
                    class="flex-1 bg-transparent border-b border-gray-300 focus:border-blue-500 focus:ring-0 text-gray-900 dark:text-white"
                  />
                  <button
                    type="button"
                    phx-click="cancel_editing"
                    class="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                    </svg>
                  </button>
                  <button
                    type="submit"
                    class="p-2 text-gray-400 hover:text-green-600 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700"
                  >
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
                    </svg>
                  </button>
                </form>
              <% else %>
                <button
                  type="button"
                  phx-click="delete_label"
                  phx-value-id={label.id}
                  data-confirm={"Delete label '#{label.name}'?"}
                  class="p-2 text-gray-400 hover:text-red-600 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 opacity-0 group-hover:opacity-100"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
                <span 
                  class="w-6 h-6 rounded-full mr-4 flex items-center justify-center"
                  style={"background-color: #{color_hex(label.color)}"}
                >
                  <svg class="w-3 h-3 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                  </svg>
                </span>
                <span class="flex-1 text-gray-700 dark:text-gray-300"><%= label.name %></span>
                <button
                  type="button"
                  phx-click="start_editing"
                  phx-value-id={label.id}
                  class="p-2 text-gray-400 hover:text-gray-600 rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 opacity-0 group-hover:opacity-100"
                >
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
                  </svg>
                </button>
              <% end %>
            </div>
          <% end %>

          <%= if length(@labels) == 0 do %>
            <div class="p-8 text-center text-gray-400">
              <svg class="w-12 h-12 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
              </svg>
              <p>No labels yet</p>
            </div>
          <% end %>
        </div>
      </main>
    </div>
    """
  end
end
