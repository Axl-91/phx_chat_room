defmodule PhxChatRoomWeb.ChatRoomLive.Index do
  alias PhxChatRoom.ChatRooms.ChatRoom
  use PhxChatRoomWeb, :live_view

  alias PhxChatRoom.ChatMessages
  alias PhxChatRoom.ChatRooms
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      PhxChatRoomWeb.Endpoint.subscribe("chat_room")
    end

    active_chat_room = ChatRooms.get_first_chat_room()

    chat_messages =
      active_chat_room.id
      |> ChatMessages.list_chat_messages_by_chat_room()

    socket =
      socket
      |> assign(:chat_rooms, ChatRooms.list_chat_rooms())
      |> assign(:active_chat_room, active_chat_room)
      |> stream(:chat_messages, chat_messages)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("change_chatroom", %{"id" => chat_room_id}, socket) do
    new_active_chat_room = ChatRooms.get_chat_room!(chat_room_id)
    new_chat_messages = ChatMessages.list_chat_messages_by_chat_room(chat_room_id)

    socket =
      socket
      |> assign(:active_chat_room, new_active_chat_room)
      |> stream(:chat_messages, new_chat_messages, reset: true)

    {:noreply, socket}
  end

  @impl true
  def handle_info(%Broadcast{topic: "chat_room", event: "new_message", payload: message}, socket) do
    socket =
      socket
      |> stream_insert(:chat_messages, message)
      |> push_event("scroll-down", %{})

    {:noreply, socket}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New ChatRoom")
    |> assign(:chat_room, %ChatRoom{})
  end

  defp apply_action(socket, _, _params) do
    socket
    |> assign(:page_title, "Home")
  end
end
