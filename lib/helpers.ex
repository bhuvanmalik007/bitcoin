defmodule Helpers do
  def nonceGenerator(l) do
    :crypto.strong_rand_bytes(l) |> Base.url_encode64 |> binary_part(0, l) |> String.downcase
  end

  def hash(transactionData, prevHash) do
    btc = Float.to_string(Map.get(transactionData, "btc"))
    receiversPK = Map.get(transactionData, "receiversPK")
    msgt = btc <> receiversPK <> prevHash <> nonceGenerator(9)
    :crypto.hash(:sha256, msgt) |> Base.encode16 |> String.downcase
  end

  # Randomly finds pairs of users for transactions
  def pairs(num, participants, map_set) do
    if num == MapSet.size(map_set) do
      map_set
    else
      x = Enum.random(Enum.to_list(1..participants))
      map_set = MapSet.put(map_set,x)
      pairs(num,participants,map_set)
    end
  end
end
