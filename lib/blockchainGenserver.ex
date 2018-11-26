defmodule BlockChainGenServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def init([]) do
    zeroBlock = %{
      transactionData: %{"btc" => "", "receiverPublicKey" => ""},
      prevHash: "zero_block",
      hash: "zero_block",
      signedMessage: "first_RSA",
      timestamp: NaiveDateTime.utc_now,
      sendersPublicKey: ""
    }
    {:ok, [zeroBlock]}
  end

  def handle_call({:getBlockChain}, _from, appState) do
    {:reply, appState, appState}
  end

  def handle_cast({:addBlock, newBlock}, state) do
    state = state ++ [newBlock]
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    # IO.puts "unknown message"
    {:noreply, state}
  end

end
