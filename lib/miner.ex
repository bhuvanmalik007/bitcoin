defmodule Miner do
  def miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex) do
    # IO.puts("miner created")
    # Adding result of this process to overall result
    receive do
      {:ok, [newTransactionData, signedMessage, senderPID, minersList]} ->
        # IO.puts("shitFromSender'swallret: #{inspect(newTransactionData)}")
        blockChain = GenServer.call(blockChainPID, {:getBlockChain})
        # IO.puts("blockChain: #{inspect(blockChain)}")
        latestBlock = Enum.at(blockChain, blockChainEndIndex)
        # IO.puts("latestBlock: #{inspect(latestBlock)}")
        hash = Map.get(latestBlock, :hash)
        # IO.puts("hash: #{inspect(hash)}")
        mining(blockChainPID, newTransactionData, signedMessage, hash, blockChainEndIndex, senderPID, verificationAccumulatorPID, minersList, self())
        Miner.miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex)
      {:incrementPointer} ->
        blockChainEndIndex = blockChainEndIndex + 1
        Miner.miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex)
      {:decrementPointer} ->
        blockChainEndIndex = blockChainEndIndex - 1
        Miner.miningNode(blockChainPID, verificationAccumulatorPID, blockChainEndIndex)
    end
  end

  def mining(blockChainPID, transactionData, signature, hash, blockChainEndIndex, senderPID, verificationAccumulatorPID, minersList, selfPID) do
    blockChain = GenServer.call(blockChainPID, {:getBlockChain})

    cond do
      length(blockChain) - 1 > blockChainEndIndex  ->
        #IO.puts("someone else was faster then me, stopping")
        send selfPID, {:incrementPointer}
      length(blockChain) - 1 == blockChainEndIndex ->
            msgt_hash = Miner.hash(transactionData, hash)
            if(String.slice(msgt_hash, 0, 4) === String.duplicate("0", 4)) do
                IO.puts "Transaction successful"
                # IO.puts("###############################signedMessage: #{inspect(signature)}")
                newBlock = %{
                  transactionData: transactionData,
                  prevHash: hash,
                  hash: msgt_hash,
                  signedMessage: signature,
                  timestamp: NaiveDateTime.utc_now,
                  sendersPublicKey: Map.get(transactionData, "sendersPublicKey")
                }
                # IO.puts("newBlock: #{inspect(newBlock)}")
                GenServer.cast(blockChainPID, {:addBlock, newBlock})
                send verificationAccumulatorPID, {:ok, senderPID, minersList}
                send selfPID, {:incrementPointer}
            else
              # IO.puts("###############################signedMessage else: #{inspect(signature)}")
              Miner.mining(blockChainPID, transactionData, signature, hash, blockChainEndIndex, senderPID, verificationAccumulatorPID, minersList, selfPID)
            end
    end
  end

  def randomizer(l) do
    :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
  end

  def hash(transactionData, prevHash) do
    # IO.puts("transaction data: #{inspect(transactionData)}")
    # IO.puts("prevHash: #{inspect(prevHash)}")
    btc = Float.to_string(Map.get(transactionData, "btc"))
    receiversPK = Map.get(transactionData, "receiversPK")
    msgt = btc <> receiversPK <> prevHash <> randomizer(9)
    :crypto.hash(:sha256, msgt) |> Base.encode16 |> String.downcase
  end

end
