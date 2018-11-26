defmodule BitcoinTest do
  use ExUnit.Case
  # doctest Miner

  test "hash generated from previous block's hash has bit size 512" do
    transactionData = %{"btc" => 5.0, "receiversPK" => "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAKIu9h4LEQaEbV0gxOkdqOxSuvH7p1MC\n7IrtmNd2fFiWXhEXRkn2vY1DJ5jxPfxFBYRRCZirMfYeYVCWZkpiJmcCAwEAAQ==\n-----END PUBLIC KEY-----\n", "sendersPublicKey" => "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAOcsMEdvq88SRR+meTbPacVTaFAyzbSU\nBjofC5iAjsW5C+iUsWjVCd3SvPDcnsADdToJ4AhxPrNfVNCY0M1BOPkCAwEAAQ==\n-----END PUBLIC KEY-----\n"}
    prevHash = "0000770c86c0c6336046e6558121b81ff454357f209aaed824dc57bcc67867d5"
    assert :erlang.bit_size(Helpers.hash(transactionData, prevHash)) == 512
  end

  test "hash generated from previous block's hash is a bit string" do
    transactionData = %{"btc" => 5.0, "receiversPK" => "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAKIu9h4LEQaEbV0gxOkdqOxSuvH7p1MC\n7IrtmNd2fFiWXhEXRkn2vY1DJ5jxPfxFBYRRCZirMfYeYVCWZkpiJmcCAwEAAQ==\n-----END PUBLIC KEY-----\n", "sendersPublicKey" => "-----BEGIN PUBLIC KEY-----\nMFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAOcsMEdvq88SRR+meTbPacVTaFAyzbSU\nBjofC5iAjsW5C+iUsWjVCd3SvPDcnsADdToJ4AhxPrNfVNCY0M1BOPkCAwEAAQ==\n-----END PUBLIC KEY-----\n"}
    prevHash = "0000770c86c0c6336046e6558121b81ff454357f209aaed824dc57bcc67867d5"
    assert is_bitstring(Helpers.hash(transactionData, prevHash)) == true
  end

  test "end to end testing of one transaction, matching the returning tuple" do
    assert elem(Bitcoin.start(5, 10, 1, 10), 0) == :allTransactionsDone
  end

  test "end to end testing of ecosystem with 100 users, matching the returning tuple" do
    assert elem(Bitcoin.start(100, 10, 5, 1000), 0) == :allTransactionsDone
  end

  test "end to end testing of one transaction, size of blockchain should increase" do
    assert length(elem(Bitcoin.start(5, 10, 1, 10), 1)) > 1
  end

end
