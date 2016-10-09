defmodule Eavesdrop do

  @moduledoc "A module which represents the current actions of a user
  on the system. The FSM can be in 1 of 3 states at any given time:
  signin, idle, or play. This module defines the actions which take
  each state to the others"

  #External functions

  @doc "External interaction functions"
  def user_signin(name) do
    :gen_fsm.send_event(__MODULE__, {:signin, name})
  end
  def play_track(track) do
    :gen_fsm.send_event(__MODULE__, {:play, track})
  end
  def user_stop() do
    :gen_fsm.send_event(__MODULE__, :stop)
  end
  def user_signout() do
    :gen_fsm.send_event(__MODULE__, :signout)
  end

  # FSM Server functions

  @doc "Kicks off a user process"
  def start_link() do
    :gen_fsm.start_link({:local, __MODULE__}, __MODULE__, [], [])
  end

  @doc "
  Puts the FSM in its initial state and traps exits for loud errors

  service is a callback module responsible for handling actual calls
  and changes on a theoretical server
  "
  def init([]) do
    GenEvent.add_handler(:eavesdrop_event_manager, MusicService, self())

    Process.flag(:trap_exit, true)
    {:ok, :signin, []}
  end

  @doc "Defines a handler for receiving messages while in the _signin_ state"
  def signin({:signin, name}, state) do
    GenEvent.notify(:eavesdrop_event_manager, {:signin, name})

    {:next_state, :play, state}
  end
  def signin(_any, state) do
    {:next_state, :signin, state}
  end

  @doc "Defines a handler for receiving messages while in the _idle_ state"
  def idle(:idle, state) do
    {:next_state, :play, state}
  end
  def idle({:play, track}, state) do
    GenEvent.notify(:eavesdrop_event_manager, {:play, track})

    {:next_state, :play, state}
  end
  def idle(:signout, state) do
    GenEvent.notify(:eavesdrop_event_manager, :signout)

    {:next_state, :signin, state}
  end
  def idle(_any, state) do
    GenEvent.notify(:eavesdrop_event_manager, :idle)
    {:next_state, :idle, state}
  end

  @doc "Defines messages for receiving messages while on the _play_ state"
  def play({:play, track}, state) do
    GenEvent.notify(:eavesdrop_event_manager, {:play, track})

    {:next_state, :play, state}
  end
  def play(:stop, state) do
    GenEvent.notify(:eavesdrop_event_manager, :idle)

    {:next_state, :idle, state}
  end
  def play(:signout, state) do
    GenEvent.notify(:eavesdrop_event_manager, :signout)

    {:next_state, :signin, state}
  end
  def play(_any, state) do
    GenEvent.notify(:eavesdrop_event_manager, :idle)

    {:next_state, :idle, state}
  end

  def terminate(reason, _state_name, _state) do
    GenEvent.notify(:eavesdrop_event_manager, {:shutdown, reason})
  end
end
