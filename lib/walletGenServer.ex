defmodule WalletGenServer do
  use GenServer

  def start_link(holderIndex, privateKey, publicKey, btc, minersList, transactionAutomatorPID) do
    GenServer.start_link(__MODULE__, [holderIndex, privateKey, publicKey, btc, minersList, transactionAutomatorPID], name: {:via, Registry, {:node_store, holderIndex}})
  end

  def pidRetriever(holderIndex) do
    case Registry.lookup(:node_store, holderIndex) do
    [{pid, _}] -> pid
    [] -> nil
    end
  end

  def init([holderIndex, privateKey, publicKey, btc, minersList, transactionAutomatorPID]) do
    state = %{"holderIndex" => holderIndex, "privateKey" => privateKey, "publicKey" => publicKey, "btc" => btc, "minersList" => minersList, "transactionAutomatorPID" => transactionAutomatorPID}
    # IO.puts("state: #{inspect(state)}")
    # IO.puts("sdfsdfsdfsdf")
    # IO.puts("tuple: #{inspect(RsaEx.sign("message", privateKey, :sha256))}")
    # {:ok, signature} = RsaEx.sign("message", privateKey, :sha256)

    # IO.puts("signature: #{inspect(signature)}")
    # {:ok, valid} = RsaEx.verify("message", signature, publicKey)
    # IO.puts("verified?: #{inspect(valid)}")

    {:ok, state}
  end

  def handle_call({:initiateTransaction, [selfPID, sendToPK]}, _from, state) do
    IO.puts("*******")
    transactionData = %{
      "btc" => Map.get(state, "btc")/2,
      "receiversPK" => sendToPK,
      "sendersPublicKey" => Map.get(state,"publicKey")
    }
    {:ok, signature} = RsaEx.sign("message", Map.get(state,"privateKey"), :sha256)
    minersList = Map.get(state,"minersList")
    for i <- 0..(length(minersList) - 1) do
      send Enum.at(minersList, i), {:ok, [transactionData, signature, selfPID, minersList]}
    end
    {:reply, state, state}
  end

  def handle_call({:getWallet}, _from, appState) do
    {:reply, appState, appState}
  end

  def handle_call({:verifyBlockChain, [verificationAccumulatorPID, blockChainPID]}, _from, appState) do

    blockChain = GenServer.call(blockChainPID, {:getBlockChain})
    addedBlock = Enum.at(blockChain, length(blockChain) - 1)
    signedMessage = Map.get(addedBlock, :signedMessage)
    sendersPublicKey = Map.get(addedBlock, :sendersPublicKey)
    # IO.puts("***********************************sendersPublicKey: #{inspect(sendersPublicKey)}")
    {:ok, valid} = RsaEx.verify("message", signedMessage, sendersPublicKey)
      # IO.puts("***********************************valid: #{inspect(valid)}")
    send verificationAccumulatorPID, {:ok, valid}
    {:reply, appState, appState}
  end

  def handle_cast({:decrementBTC, spentBTC}, state) do
    currentBTC = Map.get(state, "btc")
    newBTC = currentBTC - spentBTC
    state = Map.replace!(state, "btc", newBTC)
    IO.puts("sender's wallet: #{inspect(newBTC)} btc")
    {:noreply, state}
  end

  def handle_cast({:checkTransactionReceiver, receivedBTC, receiversPK}, state) do
    # IO.puts("***********************************inside #{inspect(receiversPK)}")
    cond do
      Map.get(state, "publicKey") == receiversPK ->
        # IO.puts("matched")
        currentBTC = Map.get(state, "btc")
        newBTC = currentBTC + receivedBTC
        state = Map.replace!(state, "btc", newBTC)
        IO.puts("receiver's wallet: #{inspect(newBTC)} btc")
        send Map.get(state, "transactionAutomatorPID"), {:transactionEnded}
        {:noreply, state}
      true -> {:noreply, state}
      end
  end

  def handle_info(_msg, state) do
    # IO.puts "unknown message"
    {:noreply, state}
  end

end
